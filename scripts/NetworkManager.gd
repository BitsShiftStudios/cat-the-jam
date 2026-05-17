extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")
@onready var match_controller = $MatchController

const PORT = 3131
var peer = WebSocketMultiplayerPeer.new()

func _ready():
	$MultiplayerSpawner.spawn_function = _on_player_spawn
	
	if OS.get_cmdline_args().has("--server"):
		get_window().title = "Server" 
		start_server()
	else:
		start_client()

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
	var target_url = "ws://10.11.25.4:" + str(PORT)
	print("Connecting to server at: ", target_url)
	
	var error = peer.create_client(target_url)
	if error != OK:
		print("Failed to initialize client: ", error)
		return
		
	multiplayer.multiplayer_peer = peer

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
	match_controller.register_new_player(id, "Test")
	
	var spawn_pos = get_spawn_point() 
	$MultiplayerSpawner.spawn({"id": id, "pos": spawn_pos})

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	match_controller.remove_player(id)
	
func _on_player_spawn(data: Dictionary) -> Node:
	var player_instance = player_scene.instantiate()
	player_instance.name = str(data["id"])
	player_instance.position = data["pos"]
	player_instance.set_multiplayer_authority(data["id"])
	
	return player_instance
