extends Timer

@onready var waiting_label = $/root/Node/GameUI/WaitingContainer/WaitingLabel

@export var default_match_time:int = 300
@export var min_players_to_start: int = 2

var match_time_left:int
var match_started: bool = false

@onready var match_controller = $/root/Node/MatchController
@onready var game_ui = $/root/Node/GameUI

func _ready():
	match_time_left = default_match_time
	game_ui.update_timer_value(match_time_left)
	
	# Oyuncu değişikliklerini dinle
	if multiplayer.is_server():
		PlayersManager.player_added.connect(_on_player_count_changed)
		PlayersManager.player_removed.connect(_on_player_count_changed)
		game_ui.update_timer_value(match_time_left)

	
func _on_player_count_changed(_a = null, _b = null):
	if not multiplayer.is_server():
		return

	var count = PlayersManager.get_player_count()

	if count >= min_players_to_start and not match_started:
		sync_waiting_label.rpc(false)  # gizle
		start_timer()
	elif count < min_players_to_start and match_started:
		sync_waiting_label.rpc(true)   # göster
		_pause_match()  # İstersen oyunu durdur

@rpc("authority", "call_local", "reliable")
func sync_waiting_label(visible: bool) -> void:
	waiting_label.visible = visible


func _on_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	if match_time_left > 0:
		match_time_left -= 1
	else:
		_end_match()
		return
	sync_timer.rpc(match_time_left)
	
@rpc("authority", "call_local", "reliable")
func sync_timer(time_left: int) -> void:
	game_ui.update_timer_value(time_left)
	game_ui.update_timer_display()

func start_timer() -> void:
	match_started = true
	match_time_left = default_match_time
	game_ui.update_timer_value(match_time_left)
	game_ui.update_timer_display()
	start()

func _pause_match() -> void:
	match_started = false
	stop()
	match_time_left = default_match_time
	game_ui.update_timer_value(match_time_left)
	print("[Timer] Match paused, waiting for players...")

func _end_match() -> void:
	stop()
	match_controller.end_match()
