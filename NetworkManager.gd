extends Node

@export var player_scene: PackedScene = preload("res://scenes/Player.tscn")

const PORT = 8080
var peer = WebSocketMultiplayerPeer.new()

func _ready():
	# If we pass a "--server" command line argument, run as the host.
	# Otherwise, run as a client trying to connect.
	if OS.get_cmdline_args().has("--server"):
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
	# Listen for when students join or leave the server
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func start_client():
	# Replace "localhost" with your server's IP address when deploying!
	var target_url = "ws://localhost:" + str(PORT) 
	print("Connecting to server at: ", target_url)
	
	var error = peer.create_client(target_url)
	if error != OK:
		print("Failed to initialize client: ", error)
		return
		
	multiplayer.multiplayer_peer = peer

func _on_player_connected(id: int):
	print("Player connected to server! ID assigned: ", id)
	
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id) # Name must be the network ID
	player_instance.set_multiplayer_authority(id) # Assign control to that specific client
	
	add_child(player_instance)

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
