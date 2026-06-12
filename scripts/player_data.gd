extends Node

var login		: String = ""
var displayname	: String = ""
var level		: float  = 0.0
var score		: int    = 0
var wins		: int    = 0
var location	: String = ""
var color		: String = "FFFFFF"
var grade: String = ""
var campus : String = ""
var avatar_url : String = ""
var cover_url : String = ""

var server_ip	: String = ""
var is_chatting	: bool   = false
var _http: HTTPRequest = null
signal session_loaded

func load_from_query():
	if not OS.has_feature("web"):
		return
	var query = str(JavaScriptBridge.eval("window.location.search"))
	var params = parse_query(query)

	# server_ip ÖNCE set edilmeli
	server_ip = params.get("serverip", "")
	var session = params.get("session", "")
	if session != "":
		_fetch_session(session)
	else:
		_load_direct(params)

func _fetch_session(token: String):
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_session_received)
	# 8080 değil, 9090 — aynı origin
	var url = "https://" + server_ip + ":9090/session/" + token
	var err = _http.request(url)
	if err != OK:
		print("[PlayerData] Session isteği başlatılamadı: ", err)

func _on_session_received(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
	if code != 200:
		print("[PlayerData] Session alınamadı, kod: ", code)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		print("[PlayerData] JSON parse hatası")
		return
	login    = data.get("login", "")
	level    = data.get("level", "0").replace("_", ".").to_float()
	location = data.get("location", "offline")
	color    = data.get("color", "FFFFFF")
	if data.has("grade"):
		PlayerData.grade = data["grade"]
	if data.has("campus"):
		PlayerData.campus = data["campus"]
	
	if data.has("avatar"):
		PlayerData.avatar_url = data["avatar"]
	if data.has("cover"):
		PlayerData.cover_url = data["cover"]
	_http.queue_free()
	_http = null
	session_loaded.emit()  # ← ekle

func _load_direct(params: Dictionary):
	login    = params.get("login", "")
	level    = params.get("level", "0").replace("_", ".").to_float()
	location = params.get("location", "offline")
	color    = params.get("color", "FFFFFF")
	grade    = params.get("grade", "unknown")
	grade    = params.get("campus", "unknown")
	avatar_url    = params.get("avatar_url", "unknown")
	cover_url = params.get("cover", "unknown")
	session_loaded.emit()  # ← ekle

func parse_query(query: String) -> Dictionary:
	var params = {}
	for part in query.trim_prefix("?").split("&"):
		var kv = part.split("=")
		if kv.size() == 2:
			params[kv[0]] = kv[1]
	return params
