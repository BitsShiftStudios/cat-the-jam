#!/bin/bash
set -e  # Herhangi bir komut hata verirse script durur

# 1. Yerel IP Tespit Etme
# WSL içinde çalışıyorsak Windows'un gerçek LAN IP'sini alırız
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL ortamı tespit edildi. Windows LAN IP'si alınıyor..."
    SERVER_IP=$(powershell.exe -Command \
        "(Get-NetIPAddress -AddressFamily IPv4 | \
        Where-Object { \$_.InterfaceAlias -notlike '*Loopback*' -and \
                       \$_.InterfaceAlias -notlike '*WSL*' -and \
                       \$_.InterfaceAlias -notlike '*vEthernet*' -and \
                       \$_.IPAddress -notlike '169.*' } | \
        Sort-Object PrefixLength | \
        Select-Object -First 1).IPAddress" 2>/dev/null | tr -d '\r\n')
else
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

if [ -z "$SERVER_IP" ]; then
    echo "UYARI: IP otomatik tespit edilemedi, 127.0.0.1 kullanılıyor."
    SERVER_IP="127.0.0.1"
fi
echo "Sunucu IP: $SERVER_IP"

# 2. Node.js ve npm Varlık Kontrolü
if ! command -v node &> /dev/null; then
    echo "HATA: Node.js kurulu değil! Lütfen Node.js 18+ yükleyin: https://nodejs.org"
    exit 1
fi
if ! command -v npm &> /dev/null; then
    echo "HATA: npm kurulu değil! Node.js kurulumunuzu kontrol edin."
    exit 1
fi

# Node.js sürüm kontrolü (fetch() için 18+ gerekli)
NODE_MAJOR=$(node -e "process.stdout.write(process.versions.node.split('.')[0])")
if [ "$NODE_MAJOR" -lt 18 ]; then
    echo "HATA: Node.js 18+ gerekli (mevcut: v$(node -v)). fetch() built-in desteği yok."
    exit 1
fi
echo "Node.js sürümü: $(node -v) ✓"

# 3. Klasör Düzeni
mkdir -p www
mkdir -p server
mkdir -p server/certs
mkdir -p certs
echo "Klasör yapıları kontrol edildi (www, server, certs)."

# 4. SSL Sertifikalarını Üretme ve Doğru Klasöre Atma
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
cp certs/server.crt server/certs
cp certs/server.key server/certs
echo "Sertifikalar server/certs klasörüne kopyalandı."

# 5. IP Adresi Güncelleme
if [ -f "server.js" ]; then
    sed -i "s/SUNUCUIP/$SERVER_IP/g" server.js
    echo "server.js dosyasına $SERVER_IP adresi başarıyla işlendi."
else
    echo "UYARI: server.js dosyası bulunamadı, IP değiştirilemedi."
fi

# 6. Bağımlılıkların (Express.js) Otomatik Kurulması
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
