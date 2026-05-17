extends Node

@onready var match_timer = $/root/Node/Timer
@onready var game_ui = $/root/Node/GameUI

@export var end_screen_duration:float = 10.0
			
var scoreboard_data: Dictionary = {}

# Scoreboard
func register_new_player(id: int, username: String):
	if not multiplayer.is_server(): return
	scoreboard_data[id] = {
		"name": username,
		"kills": 0,
		"deaths": 0
	}
	_broadcast_scoreboard()

func remove_player(id: int):
	if not multiplayer.is_server(): return
	if scoreboard_data.has(id):
		scoreboard_data.erase(id)
		_broadcast_scoreboard()

func record_kill_death(killer_id: int, victim_id: int):
	if not multiplayer.is_server(): return
	
	if scoreboard_data.has(killer_id) and killer_id != victim_id:
		scoreboard_data[killer_id]["kills"] += 1

	if scoreboard_data.has(victim_id):
		scoreboard_data[victim_id]["deaths"] += 1
		
	#for id in scoreboard_data.keys():
		#print(id, " K-D: ", scoreboard_data[id]["kills"], "-", scoreboard_data[id]["deaths"])
		
	_broadcast_scoreboard()

func _broadcast_scoreboard():
	rpc("update_client_scoreboard", scoreboard_data)
	
@rpc("any_peer", "call_local", "reliable")
func update_client_scoreboard(server_data: Dictionary):
	scoreboard_data = server_data
	
	var score_ui = get_tree().get_first_node_in_group("score_ui")
	if score_ui:
		score_ui.refresh_display(scoreboard_data)

# Round management
func end_match():
	rpc("show_match_finished_screen")
	
	await get_tree().create_timer(end_screen_duration).timeout
	reset_match()
	
func reset_match():
	for id in scoreboard_data.keys():
		scoreboard_data[id]["kills"] = 0
		scoreboard_data[id]["deaths"] = 0
		
	_broadcast_scoreboard()
	
	get_tree().call_group("players", "trigger_server_respawn")
	rpc("hide_match_finished_screen")
	match_timer.start_timer()
	
# End screen
@rpc("any_peer", "call_local", "reliable")
func show_match_finished_screen():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_ui.show_game_over()

@rpc("any_peer", "call_local", "reliable")
func hide_match_finished_screen():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_ui.hide_game_over()
