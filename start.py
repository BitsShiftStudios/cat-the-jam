# start.py
import signal
import os, sys, requests, ssl, threading, uuid, time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import socket
import http.server as hs

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
cert_file     = "server.crt"
key_file      = "server.key"

BASE     = os.path.dirname(os.path.abspath(__file__))
SSL_CERT = os.path.join(BASE, cert_file)
SSL_KEY  = os.path.join(BASE, key_file)

# --- SESSION STORE ---
sessions = {}

def cleanup_sessions():
	while True:
		time.sleep(60)
		now = time.time()
		expired = [t for t, d in sessions.items() if now - d["createdAt"] > 300]
		for t in expired:
			del sessions[t]

threading.Thread(target=cleanup_sessions, daemon=True).start()

# --- OAUTH BACKEND ---
class Handler(BaseHTTPRequestHandler):
	def do_GET(self):
		parsed = urlparse(self.path)

		# Session endpoint
		if parsed.path.startswith("/session/"):
			token = parsed.path.split("/session/")[1]
			if token in sessions:
				data = sessions.pop(token)
				data.pop("createdAt", None)
				self._respond(200, data)
			else:
				self._respond(404, {"error": "session bulunamadı"})
			return

		# OAuth callback
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

			user_id      = me.get("id")
			login        = me.get("login", "bilinmiyor")
			location     = me.get("location") or "offline"
			campus_name  = me.get("campus", [{}])[0].get("name", "Bilinmiyor") if me.get("campus") else "Bilinmiyor"
			avatar_url   = (me.get("image") or {}).get("versions", {}).get("small", "") or \
			               (me.get("image") or {}).get("link", "")

			level = 0.0
			grade = ""
			for c in me.get("cursus_users", []):
				if c.get("cursus_id") == 21:
					level = c.get("level", 0.0)
					grade = c.get("grade", "")
					break

			level_str       = str(level).replace(".", "_")
			coalition_color = "FFFFFF"
			coalition_cover = ""

			if user_id:
				coal_res = requests.get(
					f"https://api.intra.42.fr/v2/users/{user_id}/coalitions",
					headers={"Authorization": "Bearer " + token}
				)
				if coal_res.status_code == 200:
					coal_data = coal_res.json()
					if coal_data:
						coalition_color = coal_data[0].get("color", "#FFFFFF").replace("#", "")
						coalition_cover = coal_data[0].get("cover_url", "")

			session_token = str(uuid.uuid4())
			sessions[session_token] = {
				"login":    login,
				"level":    level_str,
				"grade":    grade,
				"location": location,
				"campus":   campus_name,
				"avatar":   avatar_url,
				"cover":    coalition_cover,
				"color":    coalition_color,
				"createdAt": time.time()
			}

			redirect_url = f"{GODOT_URL}/?session={session_token}&serverip={SERVER_IP}"
			self.send_response(302)
			self.send_header("Location", redirect_url)
			self.end_headers()
			return

		self._respond(404, {"error": "not found"})

	def _respond(self, code, data):
		body = json.dumps(data).encode()
		self.send_response(code)
		self.send_header("Content-Type", "application/json")
		self.send_header("Access-Control-Allow-Origin", "*")
		self.end_headers()
		self.wfile.write(body)

	def log_message(self, *args): pass

# --- OYUN WEB SUNUCUSU ---
class GameHandler(hs.SimpleHTTPRequestHandler):
	def do_GET(self):
		parsed = urlparse(self.path)

		# Session endpoint — 9090 üzerinden de erişilebilir (CORS için)
		if parsed.path.startswith("/session/"):
			token = parsed.path.split("/session/")[1]
			if token in sessions:
				data = sessions.pop(token)
				data.pop("createdAt", None)
				body = json.dumps(data).encode()
				self.send_response(200)
				self.send_header("Content-Type", "application/json")
				self.end_headers()
				self.wfile.write(body)
			else:
				body = json.dumps({"error": "session bulunamadı"}).encode()
				self.send_response(404)
				self.send_header("Content-Type", "application/json")
				self.end_headers()
				self.wfile.write(body)
			return

		# Normal static dosya sun
		super().do_GET()

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
	print("Tüm servisler başlatılıyor...")
	start_backend()