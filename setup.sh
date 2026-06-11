#!/bin/bash

# 1. Yerel IP Tespit Etme
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="127.0.0.1"
fi
echo "Sunucu IP: $SERVER_IP"

# 2. Node.js ve Godot için Klasör Düzeni
mkdir -p www
mkdir -p server
mkdir -p certs
echo "Klasör yapıları kontrol edildi (www, server, certs)."

# 3. SSL Sertifikalarını Üretme ve Doğru Klasöre Atma
if [ -f "certs/server.crt" ] && [ -f "certs/server.key" ]; then
    echo "Sertifikalar zaten certs/ klasöründe mevcut."
else
    openssl req -x509 -newkey rsa:2048 -keyout certs/server.key -out certs/server.crt \
      -days 365 -nodes \
      -subj "/CN=$SERVER_IP" \
      -addext "subjectAltName=IP:$SERVER_IP"
    echo "certs/server.crt ve certs/server.key başarıyla oluşturuldu."
fi

# Sunucu klasörüne sertifikaların kopyalanması
cp certs/server.crt server/
cp certs/server.key server/
echo "Sertifikalar server/ klasörüne kopyalandı."

if [ -f "server.js" ]; then
    sed -i "s/SUNUCUIP/$SERVER_IP/g" server.js
    echo "server.js dosyasına $SERVER_IP adresi başarıyla işlendi."
else
    echo "UYARI: server.js dosyası bulunamadı, IP değiştirilemedi."
fi

# 5. Bağımlılıkların (Express.js) Otomatik Kurulması
if [ ! -f "package.json" ]; then
    echo "package.json bulunamadı. Node projesi sıfırdan başlatılıyor..."
    npm init -y
    npm install express
else
    echo "package.json mevcut, npm paketleri güncelleniyor..."
    npm install
fi

echo "=========================================="
echo "🚀 Node.js ve Godot Çevre Kurulumu Tamam!"
echo "=========================================="
