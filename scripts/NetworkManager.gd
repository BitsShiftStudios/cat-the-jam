extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@onready var match_controller = $MatchController
var current_map_path: String = "res://scenes/maps/PoolDay.tscn"
const PORT = 3131
var peer = WebSocketMultiplayerPeer.new()
var connection_timeout_timer: Timer


func _ready():
	if OS.get_name() == "Web":
		_inject_web_guards()

	$MultiplayerSpawner.spawn_function = _on_player_spawn
	connection_timeout_timer = Timer.new()
	connection_timeout_timer.wait_time = 10.0  # 10 saniye timeout
	connection_timeout_timer.one_shot = true
	connection_timeout_timer.timeout.connect(_on_connection_timeout)
	add_child(connection_timeout_timer)

	if OS.get_cmdline_args().has("--server"):
		get_window().title = "Server"
		start_server()
	elif OS.is_debug_build():
		var test_server = WebSocketMultiplayerPeer.new()
		var result = test_server.create_server(PORT)
		test_server.close()
		if result == OK:
			# Port müsait → server ol
			get_window().title = "Server (Editor)"
			start_server()
		else:
			# Port dolu → başka biri server → client ol
			get_window().title = "Client (Editor)"
			_start_as_client()
	else:
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
		start_client()
		
func _start_as_client(): #local client
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	var conn_screen = preload("res://scenes/ConnectionScreen.tscn").instantiate()
	canvas.add_child(conn_screen)
	add_child(canvas)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	ConnectionManager.retry_requested.connect(retry_connection)
	start_client()

func start_server():
	print("Starting WebSocket Server on port: ", PORT)
	peer.inbound_buffer_size = 1024 * 1024
	peer.outbound_buffer_size = 1024 * 1024
	peer.max_queued_packets = 16384

	var error: int
	if OS.has_feature("template"):
		var key = CryptoKey.new()
		var cert = X509Certificate.new()
		var exe_dir = OS.get_executable_path().get_base_dir()
		var key_path = exe_dir + "/certs/server.key"
		var cert_path = exe_dir + "/certs/server.crt"
		print("Dış sertifika modu aktif: ", key_path)
		var key_err = key.load(key_path)
		var cert_err = cert.load(cert_path)
		if key_err != OK or cert_err != OK:
			print("KRİTİK HATA: Sertifikalar yüklenemedi!")
			return
		var tls = TLSOptions.server(key, cert)
		error = peer.create_server(PORT, "*", tls)
	else:
		print("Editör modu: TLS devre dışı")
		error = peer.create_server(PORT)
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
		if OS.get_name() == "Web":
			ip = str(JavaScriptBridge.eval("window.location.hostname"))
		else:
			ip = "127.0.0.1"  # editörde localhost
	var target_url: String
	if OS.has_feature("template") or OS.get_name() == "Web":
		target_url = "wss://" + ip + ":3131"
	else:
		target_url = "ws://" + ip + ":3131"
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
	if groups.size() > 0:
		var spawn_container = groups[0]
		var spawn_points = spawn_container.get_children()
		if spawn_points.size() > 0:
			var rand = randi() % spawn_points.size()
			var random_spawn = spawn_points[rand]
			return random_spawn.global_position
	return Vector3(0, 3, 0)

func _on_player_connected(id: int):
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
		print(p_name + " oyundan ayrıldı.")
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
	match_controller.register_new_player(sender_id, login)

	receive_player_info.rpc(sender_id, player_data)
	broadcast_system_message.rpc(login + " oyuna katıldı!")
	print(login + " oyuna katıldı!")
	if current_map_path != "res://scenes/maps/PoolDay.tscn":
		_change_map.rpc_id(sender_id, current_map_path)


@rpc("authority", "call_remote", "reliable")
func receive_player_info(peer_id: int, player_data: Dictionary):
	PlayersManager.add_player(peer_id, player_data)
	print("Yeni oyuncu: ", player_data.get("login", "Unknown"))



func change_map(map_path: String):
	if not multiplayer.is_server():
		return
	_change_map.rpc(map_path)

func _respawn_all_players():
	for id in PlayersManager.players:
		var wrapper = get_node_or_null(str(id))
		if wrapper == null:
			wrapper = get_tree().get_root().find_child(str(id), true, false)
		if wrapper == null:
			print("Bulunamadı: ", id)
			continue
		var player = wrapper.get_node_or_null("Player")
		if player == null:
			print("Player child bulunamadı: ", id)
			continue
		var new_pos = get_spawn_point()
		player.teleport_client_to_spawn.rpc_id(id, new_pos)
		print("[Map] Oyuncu yeniden spawn: ", id)

func _print_tree(node: Node, depth: int):
	print(" ".repeat(depth * 2), node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_print_tree(child, depth + 1)

@rpc("authority", "call_local", "reliable")
func _change_map(map_path: String):
	current_map_path = map_path
	if has_node("Map"):
		$Map.free()
		await get_tree().process_frame  # silinmesini bekle
	await get_tree().create_timer(0.2).timeout  # biraz daha beklet
	var new_map = load(map_path).instantiate()
	new_map.name = "Map"  # her zaman Map olarak isimlendir
	add_child(new_map)
	print("[Map] Harita değiştirildi: ", map_path)
	await get_tree().create_timer(0.3).timeout
	if multiplayer.is_server():
		_respawn_all_players()
		
func _inject_web_guards():
	JavaScriptBridge.eval("""
		(function() {
			if (window.__ft_guards_loaded) return;
			window.__ft_guards_loaded = true;

			window.addEventListener('keydown', function(e) {
				if ((e.ctrlKey || e.metaKey) && e.key === 'w') {
					e.preventDefault();
					e.stopPropagation();
					// Pointer lock'u bırak ki dialog kullanılabilir olsun
					if (document.pointerLockElement) {
						document.exitPointerLock();
					}
				}
			}, true);

			window.addEventListener('beforeunload', function(e) {
				if (document.pointerLockElement) {
					document.exitPointerLock();
				}
				e.preventDefault();
				e.returnValue = '';
			});
		})();
	""")
