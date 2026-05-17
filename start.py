# start.py
import signal
import os, sys, requests, asyncio, websockets, ssl, threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import socket

# --- IP OTOMATİK AL ---
def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    finally:
        s.close()

SERVER_IP = get_local_ip()

# --- AYARLAR ---
CLIENT_ID     = os.environ["CLIENT_ID"]
CLIENT_SECRET = os.environ["CLIENT_SECRET"]
REDIRECT_URI  = f"http://{SERVER_IP}:8080/callback"
GODOT_URL     = f"https://{SERVER_IP}:9090"

BASE     = os.path.dirname(os.path.abspath(__file__))
SSL_CERT = os.path.join(BASE, "cert.pem")
SSL_KEY  = os.path.join(BASE, "key.pem")

# --- OAUTH BACKEND ---
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/callback":
            code = parse_qs(parsed.query).get("code", [None])[0]
            if not code:
                self._respond(400, {"error": "code yok"})
                return
            r = requests.post("https://api.intra.42.fr/oauth/token", data={
                "grant_type":    "authorization_code",
                "client_id":     CLIENT_ID,
                "client_secret": CLIENT_SECRET,
                "code":          code,
                "redirect_uri":  REDIRECT_URI,
            })
            token = r.json().get("access_token", "")
            me = requests.get("https://api.intra.42.fr/v2/me", headers={
                "Authorization": "Bearer " + token
            }).json()
            login        = me.get("login", "bilinmiyor")
            cursus_users = me.get("cursus_users", [])
            level        = 0.0
            for c in cursus_users:
                if c.get("cursus_id") == 21:
                    level = c.get("level", 0.0)
                    break
            level_str = str(level).replace(".", "_")
            location  = me.get("location") or "offline"
            self.send_response(302)
            self.send_header("Location", GODOT_URL + "/?login=" + login + "&level=" + level_str + "&location=" + location)
            self.end_headers()
        else:
            self._respond(404, {"error": "not found"})

    def _respond(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args): pass

# --- WSS PROXY ---
async def proxy(client_ws):
    try:
        async with websockets.connect("ws://127.0.0.1:3131") as godot_ws:
            async def c2g():
                async for msg in client_ws:
                    await godot_ws.send(msg)
            async def g2c():
                async for msg in godot_ws:
                    await client_ws.send(msg)
            await asyncio.gather(c2g(), g2c())
    except websockets.exceptions.ConnectionClosedOK:
        pass
    except websockets.exceptions.ConnectionClosedError:
        pass

async def start_proxy():
    ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_ctx.load_cert_chain(SSL_CERT, SSL_KEY)
    async with websockets.serve(proxy, "0.0.0.0", 3132, ssl=ssl_ctx):
        print(f"WSS Proxy: wss://{SERVER_IP}:3132 → ws://127.0.0.1:3131")
        await asyncio.Future()

# --- OYUN SUNUCUSU ---
import http.server as hs

class GameHandler(hs.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()
    def log_message(self, *args): pass

def start_game_server():
    os.chdir(os.path.join(BASE, "www"))
    game_ssl = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    game_ssl.load_cert_chain(SSL_CERT, SSL_KEY)
    srv = hs.HTTPServer(("0.0.0.0", 9090), GameHandler)
    srv.socket = game_ssl.wrap_socket(srv.socket, server_side=True)
    print(f"Oyun: https://{SERVER_IP}:9090")
    srv.serve_forever()

def start_backend():
    srv = HTTPServer(("0.0.0.0", 8080), Handler)
    print(f"Backend: http://{SERVER_IP}:8080")
    srv.serve_forever()

def shutdown(sig, frame):
    print("\nKapatılıyor...")
    sys.exit(0)

# --- BAŞLAT ---
if __name__ == "__main__":
    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)
    print(f"Sunucu IP: {SERVER_IP}")
    threading.Thread(target=start_game_server, daemon=True).start()
    threading.Thread(target=start_backend, daemon=True).start()
    print("Tüm servisler başlatılıyor...")
    asyncio.run(start_proxy())