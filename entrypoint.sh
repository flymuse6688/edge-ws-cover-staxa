#!/bin/sh
set -e
PORT="${PORT:-8080}"
WSPATH="${WSPATH:-$WS_PATH}"
case "$WSPATH" in /*) ;; *) WSPATH="/$WSPATH" ;; esac
if [ -z "$UUID" ] || [ -z "$WSPATH" ]; then echo "missing UUID or WSPATH" >&2; exit 1; fi
mkdir -p /etc/xray /var/log/nginx /var/lib/nginx/tmp
cat > /etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "$WSPATH"}
      }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes 1;
pid /tmp/nginx.pid;
error_log /var/log/nginx/error.log warn;
events { worker_connections 1024; }
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  sendfile on;
  server {
    listen $PORT;
    server_name _;
    location = $WSPATH {
      proxy_pass http://127.0.0.1:10000;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
    }
    location / {
      root /usr/share/nginx/html;
      index index.html;
    }
  }
}
EOF
/usr/local/bin/xray run -c /etc/xray/config.json &
exec nginx -g 'daemon off;'
