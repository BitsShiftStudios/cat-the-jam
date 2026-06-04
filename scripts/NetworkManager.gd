extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@onready var match_controller = $MatchController

const PORT = 3131
var peer = WebSocketMultiplayerPeer.new()
var connection_timeout_timer: Timer


func _ready():
	$MultiplayerSpawner.spawn_function = _on_player_spawn
	connection_timeout_timer = Timer.new()
	connection_timeout_timer.wait_time = 10.0  # 10 saniye timeout
	connection_timeout_timer.one_shot = true
	connection_timeout_timer.timeout.connect(_on_connection_timeout)
	add_child(connection_timeout_timer)

	if OS.get_cmdline_args().has("--server"):
		get_window().title = "Server"
		start_server()
	else:
		# 1. Sahne değiştirme komutunu (change_scene_to_file) TAMAMEN SİLDİK!
		# Bunun yerine ekranı her şeyin üstünü örtecek bir CanvasLayer olarak ekliyoruz.
		var canvas = CanvasLayer.new()
		canvas.layer = 100 # En üst katman
		
		var conn_screen = preload("res://scenes/ConnectionScreen.tscn").instantiate()
		canvas.add_child(conn_screen)
		add_child(canvas) # NetworkManager'ın altına güvenle ekledik
		# 2. Artık silinme tehlikemiz olmadığı için sinyaller null hatası vermeyecek:
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		ConnectionManager.retry_requested.connect(retry_connection)
		# 3. İstemciyi güvenle başlat
		start_client()

func _process(_delta):
	if multiplayer.multiplayer_peer != null:
		peer.poll()

func start_server():
	print("Starting WebSocket Server on port: ", PORT)
	print("Starting WebSocket Dedicated Server on port: ", PORT)
	var key = CryptoKey.new()
	var cert = X509Certificate.new()
	
	# Varsayılan yollar
	var key_path = "res://certs/mikail.tail2f421e.ts.net.key"
	var cert_path = "res://certs/mikail.tail2f421e.ts.net.crt"
	peer.inbound_buffer_size = 1024 * 1024
	peer.outbound_buffer_size = 1024 * 1024
	peer.max_queued_packets = 16384
	if OS.has_feature("template"):
		var exe_dir = OS.get_executable_path().get_base_dir()
		key_path = exe_dir + "/certs/sunucu.key"
		cert_path = exe_dir + "/certs/sunucu.crt"
		print("Dış sertifika modu aktif: ", key_path)

	var key_err = key.load(key_path)
	var cert_err = cert.load(cert_path)
	if key_err != OK or cert_err != OK:
		print("KRİTİK HATA: Sertifikalar yüklenemedi! Güvenli sunucu başlatılamıyor.")
		return
		
	var tls = TLSOptions.server(key, cert)
	var error = peer.create_server(PORT, "*", tls)
	if error != OK:
		print("Failed to start server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func start_client():
	ConnectionManager.set_state(ConnectionManager.ConnectionState.CONNECTING)
	peer.inbound_buffer_size = 1024 * 1024
	peer.outbound_buffer_size = 1024 * 1024
	peer.max_queued_packets = 16384

	var ip = PlayerData.server_ip
	if ip == "":
		ip = str(JavaScriptBridge.eval("window.location.hostname"))
	var target_url = ("wss://" + ip + ":3131")
	print("Bağlanıyor: ", target_url)
	var tls = TLSOptions.client_unsafe()
	var error = peer.create_client(target_url, tls)
	if error != OK:
		print("Bağlantı hatası: ", error)
		ConnectionManager.set_state(
			ConnectionManager.ConnectionState.CONNECTION_FAILED,
			"Bağlantı başlatılamadı (Error: " + str(error) + ")")
		return
	multiplayer.multiplayer_peer = peer
	connection_timeout_timer.start()

func retry_connection():
	"""ConnectionScreen'den retry için"""
	print("Yeniden bağlanma isteği alındı!")
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = WebSocketMultiplayerPeer.new()
	start_client()

func _on_connected_to_server():
	print("Sunucuya baglandi!")
	connection_timeout_timer.stop()
	ConnectionManager.set_state(ConnectionManager.ConnectionState.CONNECTED)
	var my_data = {
		"login": PlayerData.login,
		"level": PlayerData.level,
		"location": PlayerData.location,
		"color": PlayerData.color
	}
	send_player_info.rpc_id(1, my_data)

func _on_connection_failed():
	print("Bağlantı başarısız!")
	connection_timeout_timer.stop()
	ConnectionManager.set_state(
		ConnectionManager.ConnectionState.CONNECTION_FAILED,
		"Sunucuya ulaşılamadı. Sunucu çalışmıyor olabilir."
	)

func _on_server_disconnected():
	print("Sunucu bağlantısı koptu!")
	ConnectionManager.set_state(
		ConnectionManager.ConnectionState.SERVER_SHUTDOWN,
		"Sunucu ile bağlantı kesildi."
	)
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # En üst katman
	var conn_screen = preload("res://scenes/ConnectionScreen.tscn").instantiate()
	canvas.add_child(conn_screen)
	add_child(canvas)

func _on_connection_timeout():
	print("Bağlantı zaman aşımı!")
	ConnectionManager.set_state(
		ConnectionManager.ConnectionState.CONNECTION_FAILED,
		"Bağlantı zaman aşımına uğradı (10 saniye)."
	)

func get_spawn_point() -> Vector3:
	var groups = get_tree().get_nodes_in_group("spawn_containers")
	
	if (groups.size() > 0):
		var spawn_container = groups[0]
		var spawn_points = spawn_container.get_children()
		
		if spawn_points.size() > 0:
			var rand = randi() % spawn_points.size()
			var random_spawn = spawn_points[rand]
			return random_spawn.global_position
			
	return Vector3(0, 3, 0)


func _on_player_connected(id: int):
	print("Player connected to server! ID assigned: ", id)
	var spawn_pos = get_spawn_point() 
	$MultiplayerSpawner.spawn({"id": id, "pos": spawn_pos})

@rpc("authority", "call_local", "reliable")
func broadcast_system_message(msg_text: String):
	PlayersManager.system_message_received.emit(msg_text)

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	match_controller.remove_player(id)
	if PlayersManager.has_player(id):
		var p_name = PlayersManager.get_player_login(id)
		broadcast_system_message.rpc(p_name + " oyundan ayrıldı.")
		PlayersManager.remove_player(id)
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	
func _on_player_spawn(data: Dictionary) -> Node:
	var player_instance = player_scene.instantiate()
	player_instance.name = str(data["id"])
	player_instance.position = data["pos"]
	player_instance.set_multiplayer_authority(data["id"])
	
	return player_instance
	
@rpc("any_peer", "call_remote", "reliable")
func send_player_info(player_data: Dictionary):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	PlayersManager.add_player(sender_id, player_data)
	var login = player_data.get("login", "Unknown")
	print("Oyuncu kaydedildi: ", login, " | Data: ", player_data)
	match_controller.register_new_player(sender_id, login)

	receive_player_info.rpc(sender_id, player_data)
	broadcast_system_message.rpc(login + " oyuna katıldı!")

@rpc("authority", "call_remote", "reliable")
func receive_player_info(peer_id: int, player_data: Dictionary):
	PlayersManager.add_player(peer_id, player_data)
	print("Yeni oyuncu: ", player_data.get("login", "Unknown"))
