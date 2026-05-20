extends CanvasLayer

@onready var ammo_label = $Control/AmmoContainer/AmmoLabel
@onready var timer_label = $Control/TopCenterContainer/TimerLabel
@onready var health_label = $Control/HealthContainer/HealthLabel
@onready var end_screen_panel = $Control/EndScreenPanel
@onready var winner_text_label = $Control/EndScreenPanel/RowsContainer/WinnerLabel
@onready var restarting_text_label = $Control/EndScreenPanel/RowsContainer/EndScreenSeconds

var timer: int
var health: int = 100

var end_screen_countdown: float

func _ready() -> void:
	update_timer_display()
	update_health_display()
	
func _process(delta: float) -> void:
	if end_screen_panel.visible:
		if end_screen_countdown > 0:
			end_screen_countdown -= delta
			
		restarting_text_label.text = "Restarting in %d seconds..." % ceilf(end_screen_countdown)

func update_timer_value(total_seconds: int) -> void:
	timer = total_seconds

func update_timer_display() -> void:
	var minutes: int = timer / 60
	var seconds: int = timer % 60

	if timer_label:
		timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_health_value(health: int) -> void:
	self.health = health

func update_health_display() -> void:
	if health_label:
		health_label.text = "%d" % health
		
func update_ammo_display(mag: int, total: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [mag, total]
		
func show_game_over(winner_name: String, duration: int):
	winner_text_label.text = "Winner: %s" % winner_name
	end_screen_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	end_screen_countdown = duration
	
func hide_game_over():
	end_screen_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
