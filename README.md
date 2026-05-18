# ft_pool_day - Cat the Jam FPS oyunu

## Nedir?
ft_pool_day, 42 Türkiye'nin düzenlediği Cat the Jam yarışması için 3 günden kısa sürede hazırlanmış bir web tabanlı multiplayer
first-person-shooter (FPS) oyunudur. Oyun ilhamını Counter-Strike gibi kült oyunlardan almıştır.

## Özellikler
- Klasik FPS deneyimi
- Çok oyunculu
- Pool Day haritası
- 2 tür silah: Sniper ve otomatik tüfek
- Kontroller: Hareket, koşma, çökme, sağa-sola eğilme, dürbünle nişan alma
- Silah menüsü (B tuşu ile aktif edilir)
- Diğer oyuncuları görebileceğiniz Skor tablosu (Tab tuşu ile aktif edilir)
- Maç tabanlı lobi (her maçın süresi 5 dakika)
- 5 dakika içerisinde en çok rakip öldüren kazanır

## Takım
Bit Shift
- Mustafa Ersin Şişman: 3D artist-animator, 2D artist
- Mikail Kaymaz: Network-Backend developer, API integration
- Muhammed Emin Ayna: FPS and mechanics developer, VFX & SFX, game design
- Yaşam Ensar Demirkıran: Network developer, lobby & matchmaking, game loop

## Kurulum

### Gereksinimler
- Python 3
- openssl

### Python Bağımlılıkları
```bash
pip3 install requests websockets --break-system-packages
```

### Build Dosyaları
`www/` klasörü Godot'tan web export alınarak oluşturulur. (main sahne login.tscn olacak)
`serverBuild/` klasörü Godot'tan Linux export alınarak oluşturulur.You said: www ve serverBuild klsörü de setup oluştursun varsa oluşturmasın (main sahne main.tscn olacak)

### 42 API Ayarları
1. https://profile.intra.42.fr/oauth/applications adresine git
2. Yeni uygulama oluştur
3. Redirect URI olarak `http://SUNUCU_IP:8080/callback` ekle
4. `client_id` ve `client_secret` değerlerini al

### Sunucu Kurulumu
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
SERVER_IP="..." \
python3 start.py
```

5. Tarayıcıda aç:
https://SUNUCU_IP:9090
Sertifika uyarısı çıkarsa "Gelişmiş → Yine de devam et" de.

!UYARI: Firefox'ta çalışmayabilir, Google Chrome önerilir

## Oynamak İçin
Tarayıcıdan `https://SUNUCU_IP:9090` adresine git ve 42 hesabınla giriş yap.