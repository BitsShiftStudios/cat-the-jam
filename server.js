const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');
const express = require('express');

const SERVER_IP = "SUNUCUIP";

// --- AYARLAR ---
// Ortam değişkenleri (Örn: terminalde set CLIENT_ID=xxx && set CLIENT_SECRET=yyy komutuyla verilebilir)
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;
const REDIRECT_URI = `http://${SERVER_IP}:8080/callback`;
const GODOT_URL = `https://${SERVER_IP}:9090`;

// Tailscale Sertifikaları
const certFile = "sunucu.crt";
const keyFile = "sunucu.key";

const sslCert = fs.readFileSync(path.join(__dirname, certFile), 'utf8');
const sslKey = fs.readFileSync(path.join(__dirname, keyFile), 'utf8');
const credentials = { key: sslKey, cert: sslCert };

// ==========================================
// 1. OAUTH BACKEND SUNUCUSU (HTTP - 8080)
// ==========================================
const backendApp = express();

backendApp.get('/callback', async (req, res) => {
    const code = req.query.code;
    
    if (!code) {
        return res.status(400).json({ error: "code yok" });
    }

    try {
        // 1. 42 API'den Access Token Al
        const tokenRes = await fetch("https://api.intra.42.fr/oauth/token", {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({
                grant_type: "authorization_code",
                client_id: CLIENT_ID,
                client_secret: CLIENT_SECRET,
                code: code,
                redirect_uri: REDIRECT_URI
            })
        });
        
        const tokenData = await tokenRes.json();
        const token = tokenData.access_token;

        if (!token) throw new Error("Token alınamadı!");

        // 2. Kullanıcı Bilgilerini Al (/v2/me)
        const meRes = await fetch("https://api.intra.42.fr/v2/me", {
            headers: { "Authorization": `Bearer ${token}` }
        });
        const me = await meRes.json();

        const userId = me.id;
        const login = me.login || "bilinmiyor";
        const location = me.location || "offline";
        
        let level = 0.0;
        const cursus = me.cursus_users.find(c => c.cursus_id === 21);
        if (cursus) level = cursus.level;
        const levelStr = level.toString().replace(".", "_");

        let coalitionColor = "FFFFFF"; // Varsayılan renk

        // 3. Koalisyon (Coalition) Rengini Al
        if (userId) {
            const coalRes = await fetch(`https://api.intra.42.fr/v2/users/${userId}/coalitions`, {
                headers: { "Authorization": `Bearer ${token}` }
            });
            
            if (coalRes.ok) {
                const coalitionsData = await coalRes.json();
                if (coalitionsData.length > 0 && coalitionsData[0].color) {
                    // Rengi alıp başındaki '#' işaretini siliyoruz (URL bozulmasın diye)
                    coalitionColor = coalitionsData[0].color.replace("#", "");
                }
            }
        }

        // 4. Godot Oyun Sunucusuna Yönlendir
        const redirectUrl = `${GODOT_URL}/?login=${login}&level=${levelStr}&location=${location}&color=${coalitionColor}&serverip=${SERVER_IP}`;
        res.redirect(302, redirectUrl);

    } catch (error) {
        console.error("OAuth İşleminde Hata:", error);
        res.status(500).json({ error: "Sunucu hatasi" });
    }
});

// Bulunamayan rotalar için 404
backendApp.use((req, res) => res.status(404).json({ error: "not found" }));


// ==========================================
// 2. OYUN WEB SUNUCUSU (HTTPS - 9090)
// ==========================================
const gameApp = express();

// Godot Web Export'u için zorunlu olan Cross-Origin Güvenlik Header'ları
gameApp.use((req, res, next) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    next();
});

// 'www' klasöründeki Godot HTML5 dosyalarını otomatik olarak yayına al
gameApp.use(express.static(path.join(__dirname, 'www')));


// ==========================================
// BAŞLATMA İŞLEMLERİ
// ==========================================
console.log(`Sunucu IP: ${SERVER_IP}`);
console.log("Tüm servisler başlatılıyor...");

// Oyun sunucusunu Tailscale HTTPS sertifikalarıyla başlat
const httpsGameServer = https.createServer(credentials, gameApp);
httpsGameServer.listen(9090, '0.0.0.0', () => {
    console.log(`Oyun: https://${SERVER_IP}:9090`);
});

// Backend OAuth sunucusunu HTTP ile başlat
const httpBackendServer = http.createServer(backendApp);
httpBackendServer.listen(8080, '0.0.0.0', () => {
    console.log(`Backend: http://${SERVER_IP}:8080`);
});