#!/bin/bash

SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Sunucu IP: $SERVER_IP"

if [ -f "cert.pem" ] && [ -f "key.pem" ]; then
    echo "Sertifikalar zaten mevcut, atlanıyor."
else
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
      -days 365 -nodes \
      -subj "/CN=$SERVER_IP" \
      -addext "subjectAltName=IP:$SERVER_IP"
    echo "cert.pem ve key.pem oluşturuldu"
fi

cp cert.pem key.pem serverBuild/