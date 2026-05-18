extends Node

var client_id = "u-s4t2ud-a5639f9346308f15696a5059cab4760d464bd042e004fd521fa9b38765c492c6"
var redirect_uri = "http://10.11.24.6:8080/callback"

func _ready():
	if OS.has_feature("web"):
		var query = str(JavaScriptBridge.eval("window.location.search"))
		if "login=" in query:
			PlayerData.load_from_query()
			JavaScriptBridge.eval("window.history.replaceState({}, '', '/')")
			get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_button_pressed():
	var auth_url = "https://api.intra.42.fr/oauth/authorize" + \
		"?client_id=" + client_id + \
		"&redirect_uri=" + redirect_uri + \
		"&response_type=code"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = '" + auth_url + "'")
	else:
		OS.shell_open(auth_url)
