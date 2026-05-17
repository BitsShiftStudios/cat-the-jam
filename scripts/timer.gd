extends Timer

@onready var network_manager = get_parent()
@onready var game_ui = $/root/Node/GameUI

func _ready():
	game_ui.update_timer_value(network_manager.match_time_left)

func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		if network_manager.match_time_left > 0:
			network_manager.match_time_left -= 1
		else:
			end_match()
			
	game_ui.update_timer_value(network_manager.match_time_left)
	game_ui.update_timer_display()

func end_match() -> void:
	print("Game Over!")
	stop()
	rpc("show_game_over_screen")
