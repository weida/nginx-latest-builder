# 后量子加密 (Post-Quantum Cryptography) 配置指南

本构建使用 OpenSSL 3.6.1，内置支持 NIST 标准化的后量子加密算法。

## 支持的算法

### 密钥交换 (KEM)
- **ML-KEM-768** (FIPS 203) - 推荐用于 TLS
- **ML-KEM-1024** (FIPS 203) - 更高安全级别

### 混合模式（推荐）
结合传统和后量子算法，提供双重保护：
- `X25519MLKEM768` - X25519 + ML-KEM-768
- `SecP256r1MLKEM768` - P-256 + ML-KEM-768  
- `SecP384r1MLKEM1024` - P-384 + ML-KEM-1024

### 数字签名
- **ML-DSA** (FIPS 204) - 后量子数字签名
- **SLH-DSA** (FIPS 205) - 基于哈希的签名

## 快速配置

### 基础配置

```nginx
server {
    listen 443 ssl http2;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # 启用 TLS 1.3
    ssl_protocols TLSv1.3;
    
    # 后量子密钥交换（混合模式）
    ssl_ecdh_curve X25519MLKEM768:X25519:prime256v1;
    
    # TLS 1.3 加密套件
    ssl_ciphers TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;
}
```

### 完整示例

参考 [examples/nginx-pqc.conf](examples/nginx-pqc.conf)

## 测试验证

### 1. 运行测试脚本

```bash
bash examples/test-pqc.sh
```

### 2. 手动测试

```bash
# 启动测试服务器
/usr/local/nginx/sbin/nginx -c /tmp/nginx-pqc-test/nginx.conf

# 测试连接
curl -k https://localhost:8443

# 查看使用的加密算法
curl -k -v https://localhost:8443 2>&1 | grep -i 'cipher\|curve'
```

### 3. 验证后量子支持

```bash
# 检查 OpenSSL 版本
/usr/local/nginx/sbin/nginx -V 2>&1 | grep OpenSSL

# 应该显示：OpenSSL 3.6.1 或更高版本
```

## 客户端兼容性

### 支持后量子加密的客户端
- **Chrome 116+** (2023年8月)
- **Firefox 119+** (2023年10月)
- **OpenSSL 3.5+** (2025年4月)
- **curl 8.5+** (需要 OpenSSL 3.5+)

### 不支持的客户端
配置中的回退机制会自动使用传统算法（X25519, P-256）：

```nginx
ssl_ecdh_curve X25519MLKEM768:X25519:prime256v1;
#              ^^^^^^^^^^^^^^ 优先  ^^^^^^ 回退
```

## 性能影响

- **握手时间**：增加 5-15ms（后量子密钥交换）
- **CPU 使用**：增加 10-20%（握手阶段）
- **带宽**：增加 1-2KB（密钥交换数据）
- **连接后性能**：无影响

## 安全建议

1. **使用混合模式**：`X25519MLKEM768` 提供双重保护
2. **保持 TLS 1.3**：后量子算法需要 TLS 1.3
3. **定期更新**：关注 NIST 标准更新
4. **监控兼容性**：检查客户端支持情况

## 故障排查

### 问题：客户端连接失败

**原因**：客户端不支持后量子算法

**解决**：确保配置了回退算法
```nginx
ssl_ecdh_curve X25519MLKEM768:X25519:prime256v1;
```

### 问题：nginx 启动失败

**原因**：OpenSSL 版本过低

**解决**：确认使用 OpenSSL 3.5+
```bash
/usr/local/nginx/sbin/nginx -V 2>&1 | grep OpenSSL
```

### 问题：无法验证是否使用后量子算法

**解决**：添加响应头显示加密信息
```nginx
add_header X-SSL-Cipher $ssl_cipher always;
add_header X-SSL-Curve $ssl_curve always;
```

## 参考资源

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [OpenSSL 3.5 Release Notes](https://www.openssl.org/news/openssl-3.5-notes.html)
- [Open Quantum Safe Project](https://openquantumsafe.org/)
- [ML-KEM (FIPS 203)](https://csrc.nist.gov/pubs/fips/203/final)
- [ML-DSA (FIPS 204)](https://csrc.nist.gov/pubs/fips/204/final)
