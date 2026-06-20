const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');
const express = require('express');
const { randomUUID } = require('crypto');
require("dotenv").config();

// ==========================================
// ⚠️ CRITICAL CLUSTER AYARI
// ==========================================
// Eğer tarayıcıda oyunu "http://k1m01s07:8080" üzerinden açıyorsan, 
// burayı kesinlikle "k1m01s07" yapmalısın. Intra Dashboard'daki URL ile BİREBİR aynı olmalı!
const SERVER_IP = "10.11.1.7"; 

const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;
const REDIRECT_URI = `http://${SERVER_IP}:8080/callback`;
const GODOT_URL = `https://${SERVER_IP}:9090`;

const certFile = "certs/server.crt";
const keyFile = "certs/server.key";
const sslCert = fs.readFileSync(path.join(__dirname, certFile), 'utf8');
const sslKey = fs.readFileSync(path.join(__dirname, keyFile), 'utf8');
const credentials = { key: sslKey, cert: sslCert };

// ==========================================
// 1. OAUTH BACKEND SUNUCUSU (HTTP - 8080)
// ==========================================
const backendApp = express();
const sessions = new Map();

backendApp.get('/session/:token', (req, res) => {
    const data = sessions.get(req.params.token);
    if (!data) return res.status(404).json({ error: "session bulunamadı" });
    sessions.delete(req.params.token);
    res.json(data);
});

setInterval(() => {
    const now = Date.now();
    for (const [token, data] of sessions) {
        if (now - data.createdAt > 5 * 60 * 1000)
            sessions.delete(token);
    }
}, 60 * 1000);

console.log("Ayarlanan REDIRECT_URI:", REDIRECT_URI);


	backendApp.get('/login', (req, res) => {
    const authorizeUrl = `https://api.intra.42.fr/oauth/authorize?client_id=${CLIENT_ID}&redirect_uri=${encodeURIComponent(REDIRECT_URI)}&response_type=code&scope=public`;
    console.log("Generat edilen giriş linki:", authorizeUrl);
    res.redirect(authorizeUrl);
});
backendApp.get('/callback', async (req, res) => {
	
    console.log("=> /callback endpoint'ine istek geldi!");
    const code = req.query.code;
    if (!code) return res.status(400).json({ error: "code yok" });
    
    try {
        const params = new URLSearchParams({
            grant_type: "authorization_code",
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            code,
            redirect_uri: REDIRECT_URI,
        });

        console.log("CODE =", code);

        const tokenRes = await fetch(
            "https://api.intra.42.fr/oauth/token",
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                body: params.toString(),
            }
        );

        const tokenData = await tokenRes.json();
        
        // Eğer 42 API'si hata döndürürse detayını konsola basıp durduruyoruz
        if (tokenData.error) {
            console.error("❌ 42 API OAuth Hatası:", tokenData);
            return res.status(400).json({ error: tokenData.error_description });
        }

        const token = tokenData.access_token;
        if (!token) throw new Error("Token bulunamadı!");

        const meRes = await fetch("https://api.intra.42.fr/v2/me", {
            headers: { "Authorization": `Bearer ${token}` }
        });
        const me = await meRes.json();

        const userId = me.id;
        const login = me.login || "bilinmiyor";
        const location = me.location || "offline";

        // Değişken tanımlamaları düzeltildi (Implicit global bug'ı çözüldü)
        let level = 0.0;
        let grade = "Bilinmiyor"; 
        
        const cursus = me.cursus_users.find(c => c.cursus_id === 21);
        if (cursus) {
            level = cursus.level;
            grade = cursus.grade;
        }
        
        const campusName = me.campus && me.campus.length > 0 ? me.campus[0].name : "Bilinmiyor";
        const levelStr = level.toString().replace(".", "_");
        const avatarUrl = me.image?.versions?.small || me.image?.versions?.micro || me.image?.link || "";
        
        let coalitionColor = "FFFFFF";
        let coalitionCover = "";
        
        if (userId) {
            const coalRes = await fetch(`https://api.intra.42.fr/v2/users/${userId}/coalitions`, {
                headers: { "Authorization": `Bearer ${token}` }
            });
            if (coalRes.ok) {
                const coalitionsData = await coalRes.json();
                if (coalitionsData.length > 0 && coalitionsData[0].color) {
                    coalitionColor = coalitionsData[0].color.replace("#", "");
                }
                if (coalitionsData.length > 0 && coalitionsData[0].cover_url) {
                    coalitionCover = coalitionsData[0].cover_url;
                }
            }
        }

        const sessionToken = randomUUID();
        sessions.set(sessionToken, {
            login,
            level: levelStr,
            grade,
            location,
            cover: coalitionCover,
            avatar: avatarUrl,
            campus: campusName,
            color: coalitionColor,
            createdAt: Date.now()
        });

        const redirectUrl = `${GODOT_URL}/?session=${sessionToken}&serverip=${SERVER_IP}`;
        console.log("Oyuncu Godot'ya yönlendiriliyor:", redirectUrl);
        res.redirect(302, redirectUrl);

    } catch (error) {
        console.error("OAuth İşleminde Hata:", error);
        res.status(500).json({ error: "Sunucu hatasi" });
    }
});

backendApp.use((req, res) => res.status(404).json({ error: "not found" }));

// ==========================================
// 2. OYUN WEB SUNUCUSU (HTTPS - 9090)
// ==========================================
const gameApp = express();

gameApp.use((req, res, next) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    next();
});

gameApp.get('/session/:token', (req, res) => {
    const data = sessions.get(req.params.token);
    if (!data) return res.status(404).json({ error: "session bulunamadı" });
    sessions.delete(req.params.token);
    res.json(data);
});

gameApp.use(express.static(path.join(__dirname, 'www')));

// ==========================================
// BAŞLATMA
// ==========================================
console.log(`Sunucu IP: ${SERVER_IP}`);
console.log("Tüm servisler başlatılıyor...");

const httpsGameServer = https.createServer(credentials, gameApp);
httpsGameServer.listen(9090, '0.0.0.0', () => {
    console.log(`Oyun: https://${SERVER_IP}:9090`);
});

const httpBackendServer = http.createServer(backendApp);
httpBackendServer.listen(8080, '0.0.0.0', () => {
    console.log(`Backend: http://${SERVER_IP}:8080`);
    console.log(`Oyuna ilk giriş için : https://${SERVER_IP}:3131 adresine gidin. Gelişmiş seçeneğinden izin verin.`);
});