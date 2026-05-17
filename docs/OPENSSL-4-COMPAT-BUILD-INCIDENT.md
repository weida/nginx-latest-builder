# OpenSSL 4.0 and nginx 1.31.0 Build Incident

Date: 2026-05-16

## Summary

The nginx security update build initially did not produce a new image for the
latest upstream nginx tag. After the version detection was fixed, the pipeline
hit multiple independent build failures:

- nginx version discovery used GitHub Releases, while upstream nginx published
  the security version as `release-*` tags first.
- `openssl/openssl` GitHub latest had advanced to `openssl-4.0.0`, which exposed
  the CentOS 7 compat build's old GCC toolchain.
- The standard Ubuntu 24.04 builder copied its nginx binary into a Debian 12
  distroless runtime, causing a glibc mismatch at runtime.
- The compat Dockerfile needed CentOS SCL repositories for both `x86_64` and
  `aarch64` under Docker buildx.

The current target is to support OpenSSL 4.0 in both standard and compat builds,
including the compat glibc 2.17 runtime track.

## Initial Failure: Latest nginx Was Not Built

The original `docker-publish.yml` resolved nginx with:

```sh
curl https://api.github.com/repos/nginx/nginx/releases?per_page=1
```

That is not reliable for nginx security releases because nginx can publish
`release-*` tags before GitHub Releases are updated. The workflow therefore did
not see the latest upstream source even though the official tag existed.

Fix:

- `.github/workflows/docker-publish.yml` now resolves the highest
  `release-X.Y.Z` tag from `nginx/nginx` tags.
- `nginx-builder.sh` also resolves nginx from tags, with `NGINX_RAW_TAG` as an
  override so the Docker image builds the same source version that the workflow
  tags and releases.

## Failure: Existing Release Caused Push Builds To Skip

After `v1.31.0` had been created, later code changes were skipped because the
workflow skipped any build when the release tag already existed. That made CI
look green without actually rebuilding OpenSSL 4.0.

Fix:

- `.github/workflows/docker-publish.yml`
- `.github/workflows/freenginx-publish.yml`

The skip condition is now limited to scheduled runs. Pushes and manual dispatch
runs build even when the release tag already exists.

## Failure: OpenSSL Latest Became 4.0.0

`nginx-builder.sh` originally used `openssl/openssl/releases/latest`. On
2026-05-16 this resolved to `openssl-4.0.0`. The standard Ubuntu 24.04 build was
able to build with OpenSSL 4.0, but the compat build used CentOS 7's default
GCC 4.8 toolchain, which is too old for current OpenSSL major-version builds.

Temporary mitigation:

- OpenSSL was pinned to the 3.5 LTS line to unblock the urgent nginx security
  build.

Final direction:

- OpenSSL 4.0 is now the default again.
- `OPENSSL_RAW_TAG` remains available as an override.
- The fallback OpenSSL tag is `openssl-4.0.0`.

## Failure: Standard Runtime glibc Mismatch

The standard Dockerfile built nginx on Ubuntu 24.04, whose glibc is newer than
Debian 12, then copied the binary into `gcr.io/distroless/base-debian12`.

Symptom:

- `Build and push` completed.
- `Smoke test image` failed with `curl: (7)`.
- The container did not serve HTTP because nginx could not start.

Fix:

- `Dockerfile`
- `Dockerfile.freenginx`

The standard runtime stage now uses Ubuntu 24.04, matching the builder glibc.
The smoke test was also changed to print `docker ps -a` and container logs before
the final failing `curl`, so future failures show container startup errors.

## Failure: Compat Toolchain Too Old for OpenSSL 4.0

The compat image intentionally builds on CentOS 7 so the generated nginx binary
targets glibc 2.17. That part must remain for compatibility. The issue was the
compiler, not glibc.

Fix:

- `Dockerfile.compat`
- `Dockerfile.freenginx.compat`

The compat builder still uses CentOS 7, but installs CentOS SCL `devtoolset-9`
and places `/opt/rh/devtoolset-9/root/usr/bin` first in `PATH`.

This keeps the compat ABI target while giving OpenSSL 4.0 and nginx a modern
enough compiler.

## Failure: SCL Repository Path for buildx arm64

The first devtoolset attempt used `devtoolset-11`, which was not available in
the CentOS 7 SCL vault. The next attempt used `devtoolset-9`, but hard-coded the
SCL root to:

```text
https://vault.centos.org/centos/7/sclo/$basearch/...
```

That works for `x86_64`, but Docker buildx also builds `linux/arm64`; CentOS 7
SCL packages for `aarch64` are under:

```text
https://vault.centos.org/altarch/7/sclo/$basearch/...
```

Fix:

- `Dockerfile.compat`
- `Dockerfile.freenginx.compat`

The Dockerfiles now select the SCL root using `uname -m`:

- `x86_64`: `https://vault.centos.org/centos/7`
- `aarch64`: `https://vault.centos.org/altarch/7`

## OpenSSL Build Scope

OpenSSL is built only as an nginx dependency. The build does not need tests,
documentation, or OpenSSL command-line apps.

Fix:

- `nginx-builder.sh`

The default OpenSSL options now include:

```sh
OPENSSL_BUILD_OPTS="${OPENSSL_BUILD_OPTS:-no-tests no-docs no-apps}"
```

The nginx configure command passes:

```sh
--with-openssl-opt="enable-tls1_3 ${OPENSSL_BUILD_OPTS} ${OPENSSL_EXTRA_OPTS}"
```

Compat adds:

```sh
OPENSSL_EXTRA_OPTS="-D_GNU_SOURCE"
```

Earlier compat builds used `-std=c99 no-asm -D_GNU_SOURCE` to work around the
old CentOS 7 GCC 4.8 compiler. After moving compat builds to devtoolset-9, the
`-std=c99` and `no-asm` workarounds are no longer needed. Keeping `no-asm` made
OpenSSL 4.0 multi-architecture builds much slower, especially under buildx/QEMU.

## Verification Checklist

The OpenSSL 4.0 support is considered complete only when the following are true:

- `nginx-builder.sh` defaults to OpenSSL 4.0 or latest OpenSSL, not 3.5-only.
- `Dockerfile` standard build succeeds with OpenSSL 4.0.
- `Dockerfile.compat` compat build succeeds with OpenSSL 4.0.
- Standard smoke test succeeds.
- Compat smoke test succeeds.
- The push workflow does not skip build just because a release tag already
  exists.
- freenginx Dockerfiles receive the same OpenSSL 4.0 and compat toolchain fixes.

## CI Runs

Important runs during the incident:

- `25952282265`: nginx 1.31.0 build succeeded after reverting to OpenSSL 3.5
  and fixing the standard runtime glibc mismatch.
- `25966772284`: OpenSSL 4.0 standard succeeded, compat failed while installing
  unavailable `devtoolset-11`.
- `25975273658`: compat moved to `devtoolset-9`, but arm64 still failed because
  the SCL repository root used `centos/7` instead of `altarch/7`.
- `25975404562`: SCL arch path fixed; standard succeeded, compat continued long
  build verification.
- `25975811397`: current OpenSSL 4.0 verification run after trimming OpenSSL
  build scope.

Update this section with the final successful run URL after CI completes.
