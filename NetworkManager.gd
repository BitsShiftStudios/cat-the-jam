extends Node

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
	# This is where your code will call a function to spawn the player's 3D avatar

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
