#!/bin/bash

SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Sunucu IP: $SERVER_IP"

if [ -f "cert.pem" ] && [ -f "key.pem" ]; then
    echo "Sertifikalar zaten mevcut."
else
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
      -days 365 -nodes \
      -subj "/CN=$SERVER_IP" \
      -addext "subjectAltName=IP:$SERVER_IP"
    echo "cert.pem ve key.pem oluşturuldu"
fi

if [ -d "www" ]; then
    echo "www klasörü zaten mevcut."
else
    mkdir www
    echo "www klasörü oluşturuldu"
fi

if [ -d "serverBuild" ]; then
    echo "serverBuild klasörü zaten mevcut."
else
    mkdir serverBuild
    echo "serverBuild klasörü oluşturuldu"
fi
cp cert.pem key.pem serverBuild/