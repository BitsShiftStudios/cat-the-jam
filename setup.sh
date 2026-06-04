#!/bin/bash

SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Sunucu IP: $SERVER_IP"

if [ -f "certs/sunucu.crt" ] && [ -f "certs/sunucu.key" ]; then
    echo "Sertifikalar zaten certs/ klasöründe mevcut."
else
    openssl req -x509 -newkey rsa:2048 -keyout sunucu.key -out sunucu.crt \
      -days 365 -nodes \
      -subj "/CN=$SERVER_IP" \
      -addext "subjectAltName=IP:$SERVER_IP"
    echo "sunucu.crt ve sunucu.key başarıyla oluşturuldu."
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

mkdir serverBuild/certs
cp sunucu.crt serverBuild/certs
cp sunucu.key serverBuild/certs
