FROM alpine:3.21
RUN apk add --no-cache curl unzip ca-certificates nginx
RUN XRAY_VER=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && echo "Xray version $XRAY_VER" && curl -L -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-arm64-v8a.zip" && unzip -o /tmp/xray.zip -d /usr/local/bin/ && chmod +x /usr/local/bin/xray && rm /tmp/xray.zip
COPY entrypoint.sh /entrypoint.sh
COPY index.html /usr/share/nginx/html/index.html
RUN chmod +x /entrypoint.sh
EXPOSE 8080
CMD ["/entrypoint.sh"]
