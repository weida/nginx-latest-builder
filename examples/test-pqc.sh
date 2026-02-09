#!/bin/bash
# 测试 nginx 后量子加密支持

echo "=== 检查 OpenSSL 版本 ==="
/usr/local/nginx/sbin/nginx -V 2>&1 | grep "OpenSSL"

echo ""
echo "=== 检查 OpenSSL 支持的后量子算法 ==="
openssl list -kem-algorithms 2>/dev/null | grep -i "mlkem\|kyber" || echo "需要 OpenSSL 3.5+"

echo ""
echo "=== 检查支持的椭圆曲线（包括混合模式）==="
openssl ecparam -list_curves 2>/dev/null | grep -i "x25519\|mlkem" || echo "标准曲线列表"

echo ""
echo "=== 生成自签名证书用于测试 ==="
mkdir -p /tmp/nginx-pqc-test
cd /tmp/nginx-pqc-test

# 生成私钥
openssl genpkey -algorithm RSA -out server.key -pkeyopt rsa_keygen_bits:2048

# 生成自签名证书
openssl req -new -x509 -key server.key -out server.crt -days 365 -subj "/CN=localhost"

echo ""
echo "证书已生成："
echo "  私钥: /tmp/nginx-pqc-test/server.key"
echo "  证书: /tmp/nginx-pqc-test/server.crt"

echo ""
echo "=== 创建测试配置 ==="
cat > /tmp/nginx-pqc-test/nginx.conf << 'EOF'
worker_processes 1;
error_log /tmp/nginx-pqc-test/error.log info;
pid /tmp/nginx-pqc-test/nginx.pid;

events {
    worker_connections 1024;
}

http {
    access_log /tmp/nginx-pqc-test/access.log;
    
    server {
        listen 8443 ssl;
        server_name localhost;
        
        ssl_certificate /tmp/nginx-pqc-test/server.crt;
        ssl_certificate_key /tmp/nginx-pqc-test/server.key;
        
        ssl_protocols TLSv1.3;
        ssl_ecdh_curve X25519MLKEM768:X25519:prime256v1;
        
        add_header X-SSL-Cipher $ssl_cipher always;
        add_header X-SSL-Curve $ssl_curve always;
        add_header Content-Type text/plain;
        
        location / {
            return 200 "SSL Cipher: $ssl_cipher\nSSL Curve: $ssl_curve\nProtocol: $server_protocol\n";
        }
    }
}
EOF

echo "配置文件: /tmp/nginx-pqc-test/nginx.conf"

echo ""
echo "=== 启动测试服务器 ==="
echo "运行命令："
echo "  /usr/local/nginx/sbin/nginx -c /tmp/nginx-pqc-test/nginx.conf"
echo ""
echo "测试连接："
echo "  curl -k https://localhost:8443"
echo ""
echo "查看使用的加密算法："
echo "  curl -k -v https://localhost:8443 2>&1 | grep -i 'cipher\|curve'"
echo ""
echo "停止服务器："
echo "  /usr/local/nginx/sbin/nginx -s stop -c /tmp/nginx-pqc-test/nginx.conf"
