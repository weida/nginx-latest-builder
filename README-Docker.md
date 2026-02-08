# Nginx Docker 使用指南

## 特性

- ✅ HTTP/2 支持
- ✅ HTTP/3 (QUIC) 支持
- ✅ TLS 1.3
- ✅ 后量子加密算法 (Post-Quantum Cryptography)
- ✅ 多架构支持 (x86_64, ARM64)

## 快速启动

### 使用 Docker

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  weida/nginx-latest:latest
```

### 使用 Docker Compose

1. 创建目录结构：
```bash
mkdir -p conf/conf.d html ssl
```

2. 复制配置文件到对应目录

3. 启动容器：
```bash
docker-compose up -d
```

## 配置文件说明

- `conf/nginx.conf` - 主配置文件
- `conf/conf.d/*.conf` - 站点配置文件
- `html/` - 静态文件目录
- `ssl/` - SSL 证书目录

## 常用命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 重载配置（无需重启）
docker-compose exec nginx /usr/local/nginx/sbin/nginx -s reload

# 查看日志
docker-compose logs -f nginx

# 测试配置
docker-compose exec nginx /usr/local/nginx/sbin/nginx -t

# 查看版本
docker-compose exec nginx /usr/local/nginx/sbin/nginx -V
```

## SSL 证书配置

将证书文件放入 `ssl/` 目录：
- `ssl/cert.pem` - 证书文件
- `ssl/key.pem` - 私钥文件

然后修改 `conf/conf.d/https-example.conf` 中的 `server_name`。

## HTTP/3 测试

```bash
# 使用 curl 测试 HTTP/3
curl --http3 https://your-domain.com

# 使用浏览器测试
# Chrome: chrome://flags/#enable-quic
# Firefox: about:config -> network.http.http3.enabled
```

## 自定义配置

### 挂载自定义配置

```bash
docker run -d \
  -v /path/to/nginx.conf:/usr/local/nginx/conf/nginx.conf:ro \
  -v /path/to/conf.d:/usr/local/nginx/conf/conf.d:ro \
  -v /path/to/html:/usr/local/nginx/html:ro \
  -v /path/to/ssl:/usr/local/nginx/ssl:ro \
  -p 80:80 -p 443:443 -p 443:443/udp \
  weida/nginx-latest:latest
```

## 目录结构

```
.
├── conf/
│   ├── nginx.conf              # 主配置
│   └── conf.d/
│       ├── default.conf        # 默认站点
│       └── https-example.conf  # HTTPS + HTTP/3 示例
├── html/                       # 静态文件
├── ssl/                        # SSL 证书
└── docker-compose.yml
```

## 故障排查

### 查看错误日志
```bash
docker-compose logs nginx
```

### 进入容器
```bash
docker-compose exec nginx bash
```

### 测试配置文件
```bash
docker-compose exec nginx /usr/local/nginx/sbin/nginx -t
```

## 性能优化建议

1. 根据 CPU 核心数调整 `worker_processes`
2. 调整 `worker_connections` 根据并发需求
3. 启用 HTTP/2 和 HTTP/3 以提升性能
4. 配置适当的缓存策略
5. 使用 gzip 压缩减少传输大小

## 安全建议

1. 定期更新镜像获取最新安全补丁
2. 使用强加密套件和 TLS 1.3
3. 配置适当的安全头部
4. 限制请求大小和速率
5. 使用后量子加密算法应对未来威胁

## 支持

- GitHub: https://github.com/weida/nginx-latest-builder
- Issues: https://github.com/weida/nginx-latest-builder/issues
