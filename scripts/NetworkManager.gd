extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
const PORT = 3131
var peer = WebSocketMultiplayerPeer.new()

func _ready():
	if OS.get_cmdline_args().has("--server"):
		$Label3D.text = "Server"
		get_window().title = "Server"
		start_server()
	else:
		$Label3D.text = "Client - " + PlayerData.login
		multiplayer.peer_connected.connect(_on_player_connected)
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		start_client()

func _process(_delta):
	if multiplayer.multiplayer_peer != null:
		peer.poll()

func start_server():
	print("Starting WebSocket Server on port: ", PORT)
	var error = peer.create_server(PORT)
	if error != OK:
		print("Failed to start server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func start_client():
	var target_url = "wss://10.11.24.6:3132"
	print("Bağlanıyor: ", target_url)
	var tls = TLSOptions.client_unsafe()
	var error = peer.create_client(target_url, tls)
	if error != OK:
		print("Bağlantı hatası: ", error)
		return
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server():
	print("Sunucuya baglandi!")
	$Label3D.text = "Baglandi: " + PlayerData.login

func _on_player_connected(id: int):
	print("Player connected: ", id)
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	player_instance.set_multiplayer_authority(id)
	add_child(player_instance)

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
