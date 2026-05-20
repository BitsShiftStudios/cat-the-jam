extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@onready var match_controller = $MatchController

const PORT = 3131
var peer = WebSocketMultiplayerPeer.new()
var players = {}

# Geliştirme aşamasında yerel test yapmak için bunu true yap.
# Sunucuya yüklerken false yapmayı unutma!
@export var local_test_mode: bool = true 

func _ready():
	$MultiplayerSpawner.spawn_function = _on_player_spawn
	
	if OS.get_cmdline_args().has("--server"):
		get_window().title = "Dedicated Server"
		start_server()
	elif local_test_mode:
		start_local_test()
	else:
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		start_client(false)

func _process(_delta):
	if multiplayer.multiplayer_peer != null:
		peer.poll()

# YENİ: Editörden çoklu pencere açtığında kimin host kimin client olacağını otomatik belirler
func start_local_test():
	var error = peer.create_server(PORT)
	if error == OK:
		# İlk pencere biziz, demek ki port boş. Host oluyoruz.
		get_window().title = "Host (Server + Player)"
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_player_connected)
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
		
		print("Host başlatıldı (Port: ", PORT, "). Kendi karakterim ekleniyor...")
		
		# Host'un kendisini (ID: 1) oyuna dahil etmesi
		var spawn_pos = get_spawn_point()	
		$MultiplayerSpawner.spawn({"id": 1, "pos": spawn_pos})
		
		# Host'un kendi bilgilerini oyuncu listesine kaydetmesi
		players[1] = {"login": PlayerData.login, "level": PlayerData.level, "location": PlayerData.location}
		if match_controller:
			match_controller.register_new_player(1, PlayerData.login)
	else:
		# Port dolu, demek ki başka bir pencere (Host) zaten açık. Client oluyoruz.
		get_window().title = "Local Client"
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		start_client(true)

func start_server():
	print("Starting WebSocket Dedicated Server on port: ", PORT)
	var error = peer.create_server(PORT)
	if error != OK:
		print("Failed to start server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func start_client(is_local: bool):
	var target_url = ""
	var tls = TLSOptions.client_unsafe()
	
	if is_local:
		# Yerel testte SSL (wss) kullanılmaz, düz ws kullanılır. Port sunucu ile aynı (3131) olmalı.
		target_url = "ws://127.0.0.1:" + str(PORT)
	else:
		# Prodüksiyon (Canlı) sunucu bağlantısı
		target_url = "wss://" + PlayerData.server_ip + ":3132"
		
	print("Bağlanıyor: ", target_url)
	
	var error = peer.create_client(target_url, tls)
	if error != OK:
		print("Bağlantı hatası: ", error)
		return
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server():
	print("Sunucuya bağlandı!")
	send_player_info.rpc_id(1, PlayerData.login, PlayerData.level, PlayerData.location)

func get_spawn_point() -> Vector3:
	var groups = get_tree().get_nodes_in_group("spawn_containers")
	if groups.size() > 0:
		var spawn_container = groups[0]
		var spawn_points = spawn_container.get_children()
		
		if spawn_points.size() > 0:
			var rand = randi() % spawn_points.size()
			return spawn_points[rand].global_position
			
	return Vector3(0, 3, 0)

func _on_player_connected(id: int):
	print("Player connected to server! ID assigned: ", id)
	var spawn_pos = get_spawn_point()
	$MultiplayerSpawner.spawn({"id": id, "pos": spawn_pos})

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	if match_controller:
		match_controller.remove_player(id)
	players.erase(id)
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	
func _on_player_spawn(data: Dictionary) -> Node:
	var player_instance = player_scene.instantiate()
	player_instance.name = str(data["id"])
	player_instance.position = data["pos"]
	player_instance.set_multiplayer_authority(data["id"])
	return player_instance
	
@rpc("any_peer", "call_remote", "reliable")
func send_player_info(login: String, level: float, location: String):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	players[sender_id] = {"login": login, "level": level, "location": location}
	print("Oyuncu kaydedildi: ", login, " | Level: ", level, " | Location: ", location)
	if match_controller:
		match_controller.register_new_player(sender_id, players[sender_id]["login"])
	receive_player_info.rpc(sender_id, login, level, location)

@rpc("authority", "call_remote", "reliable")
func receive_player_info(peer_id: int, login: String, level: float, location: String):
	players[peer_id] = {"login": login, "level": level, "location": location}
	print("Yeni oyuncu eklendi: ", login)
