extends Timer

@export var default_match_time:int = 300
var match_time_left:int

@onready var match_controller = $/root/Node/MatchController
@onready var game_ui = $/root/Node/GameUI

func _ready():
	match_time_left = default_match_time
	game_ui.update_timer_value(match_time_left)

func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		if match_time_left > 0:
			match_time_left -= 1
		else:
			_end_match()
			
	game_ui.update_timer_value(match_time_left)
	game_ui.update_timer_display()

func start_timer() -> void:
	match_time_left = default_match_time
	game_ui.update_timer_value(match_time_left)
	game_ui.update_timer_display()
	start()

func _end_match() -> void:
	stop()
	match_controller.end_match()
