extends Node

var login       : String = ""
var displayname : String = ""
var level       : float  = 0.0
var score       : int    = 0
var wins        : int    = 0
var location    : String = ""
var server_ip    : String = ""
var is_chatting : bool = false

func load_from_query():
	if not OS.has_feature("web"):
		return
	var query = str(JavaScriptBridge.eval("window.location.search"))
	if "login=" not in query:
		return
	var params = parse_query(query)
	login    = params.get("login", "")
	level    = params.get("level", "0").replace("_", ".").to_float()
	location = params.get("location", "offline")
	server_ip = params.get("serverip", "")

func parse_query(query: String) -> Dictionary:
	var params = {}
	for part in query.trim_prefix("?").split("&"):
		var kv = part.split("=")
		if kv.size() == 2:
			params[kv[0]] = kv[1]
	return params
