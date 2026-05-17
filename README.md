# Kurulum

## Gereksinimler
- Python 3
- openssl

## Python Bağımlılıkları
```bash
pip3 install requests websockets --break-system-packages
```

## Build Dosyaları
`www/` klasörü Godot'tan web export alınarak oluşturulur.
`serverBuild/` klasörü Godot'tan Linux export alınarak oluşturulur.You said: www ve serverBuild klsörü de setup oluştursun varsa oluşturmasın

## 42 API Ayarları
1. https://profile.intra.42.fr/oauth/applications adresine git
2. Yeni uygulama oluştur
3. Redirect URI olarak `http://SUNUCU_IP:8080/callback` ekle
4. `client_id` ve `client_secret` değerlerini al

## Sunucu Kurulumu
1. Repoyu klonla
2. Sertifika oluştur:
```bash
./setup.sh
```

3. Godot sunucusunu başlat:
```bash
cd serverBuild
./index.x86_64 --server --headless
```

4. Servisleri başlat:
```bash
CLIENT_ID="..." \
CLIENT_SECRET="..." \
python3 start.py
```

5. Tarayıcıda aç:
https://SUNUCU_IP:9090
Sertifika uyarısı çıkarsa "Gelişmiş → Yine de devam et" de.

## Oynamak İçin
Tarayıcıdan `https://SUNUCU_IP:9090` adresine git ve 42 hesabınla giriş yap.