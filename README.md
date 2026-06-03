# Kurulum

## Gereksinimler
- **Node.js** (v18 veya üzeri)
- **openssl**

## Bağımlılıkların Kurulması
Projenin çalışması için gerekli olan Express.js ve diğer paketler `setup.js` betiği tarafından otomatik olarak kurulacaktır. Manuel kurmak isterseniz:
```bash
npm install express
```

## Build Dosyaları
* **`www/` klasörü:** Godot'tan **Web (HTML5)** export alınarak oluşturulur. 
    * *Kritik Ayar 1:* Projenin ana sahnesi **`Login.tscn`** olmalıdır.
    * *Kritik Ayar 2:* Export ayarlarından **Thread Support** seçeneği `Enabled` (Açık) hale getirilmelidir.
* **`certs/` klasörü:** Sunucunun güvenli (`https://` ve `wss://`) çalışabilmesi için gerekli SSL sertifikalarını barındırır.

> 💡 `www/` ve `certs/` klasörleri eğer dizinde yoksa `node setup.js` komutu çalıştırıldığında otomatik olarak oluşturulur.

## 42 API Ayarları
1. https://profile.intra.42.fr/oauth/applications adresine git.
2. Yeni bir uygulama (Application) oluştur.
3. **Redirect URI** olarak `http://SUNUCU_IP:8080/callback` değerini ekle.
4. Uygulamayı kaydedip `client_id` ve `client_secret` değerlerini güvenli bir yere not et.

---

## Sunucu Kurulumu ve Başlatma

### 1. Ortamın Hazırlanması
Repoyu klonladıktan sonra klasörleri otomatik oluşturmak, bağımlılıkları yüklemek ve SSL sertifikalarını üretmek için kurulum betiğini çalıştırın:
```bash
node setup.js
```

### 2. Godot Dedicated Server'ı Başlatma
Oyun içi ağ trafiğinin şifreli (WSS) pürüzsüz akabilmesi için oluşturulan `certs/` klasörünü sunucu `.exe` dosyanızın yanına koyun. Ardından terminalden konsol destekli sürümü başlatın:

```powershell
.\Poolday.console.exe --server --headless
```

### 3. Node.js Web ve OAuth Servisini Başlatma
42 OAuth giriş mekanizmasının ve web sunucusunun ayağa kalkması için ortam değişkenlerini besleyerek ana sunucu kodunu ateşleyin:
```powershell
$env:CLIENT_ID="42_CLIENT_ID_BURAYA"; $env:CLIENT_SECRET="42_CLIENT_SECRET_BURAYA"; node server.js
```

---

## Oynamak İçin
1. Tarayıcınızdan `https://SUNUCU_IP:9090` adresine gidin.
2. Geliştirme aşamasındaki yerel SSL sertifikasından ötürü tarayıcı uyarı verirse **"Gelişmiş → Yine de devam et"** seçeneğine tıklayın.
3. Açılan ekranda 42 hesabınızla giriş yapın, sunucu sizi otomatik olarak güvenli oyun odasına yönlendirecektir.