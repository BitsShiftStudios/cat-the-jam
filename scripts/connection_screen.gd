extends Control

@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel
@onready var spinner = $CenterContainer/VBoxContainer/Spinner
@onready var error_panel = $ErrorPanel
@onready var error_label = $ErrorPanel/MarginContainer/VBoxContainer/ErrorLabel
@onready var retry_button = $ErrorPanel/MarginContainer/VBoxContainer/CenterContainer/RetryButton


var dots = 0
var dot_timer = 0.0

func _ready():
	error_panel.hide()
	
	# Signals
	ConnectionManager.state_changed.connect(_on_connection_state_changed)
	_update_ui(ConnectionManager.get_state())
	

var spinner_frames = ["|", "/", "-", "\\"]
var spinner_index = 0
var spinner_timer = 0.0
func _process(delta):
	if spinner is Label:
		spinner_timer += delta
		if spinner_timer >= 0.1: # Dönüş hızı
			spinner_timer = 0.0
			spinner_index = (spinner_index + 1) % 4
			spinner.text = "[ " + spinner_frames[spinner_index] + " ]"

	if ConnectionManager.current_state == ConnectionManager.ConnectionState.CONNECTING:
		dot_timer += delta
		if dot_timer >= 0.5:
			dot_timer = 0.0
			dots = (dots + 1) % 4
			var dot_string = ".".repeat(dots)
			status_label.text = "Sunucuya bağlanılıyor" + dot_string

func _on_connection_state_changed(new_state):
	_update_ui(new_state)

func _update_ui(state):
	match state:
		ConnectionManager.ConnectionState.DISCONNECTED:
			status_label.text = "Bağlantı bekleniyor..."
			spinner.show()
			error_panel.hide()
		
		ConnectionManager.ConnectionState.CONNECTING:
			status_label.text = "Sunucuya bağlanılıyor..."
			spinner.show()
			error_panel.hide()
		
		ConnectionManager.ConnectionState.CONNECTED:
			status_label.text = "Bağlantı başarılı!"
			spinner.hide()
			error_panel.hide()
			# 1 saniye sonra game scene'e geç
			await get_tree().create_timer(1.0).timeout
			queue_free()
			
		ConnectionManager.ConnectionState.CONNECTION_FAILED:
			status_label.text = "Bağlantı hatası!"
			spinner.hide()
			_show_error(ConnectionManager.get_error())
		
		ConnectionManager.ConnectionState.SERVER_SHUTDOWN:
			status_label.text = "Sunucu kapatıldı"
			spinner.hide()
			_show_error("Sunucu beklenmedik şekilde kapandı.")

func _show_error(error_message: String):
	error_panel.show()
	error_label.text = "[center]" + error_message + "[/center]"
	retry_button.grab_focus()

func _on_retry_button_pressed():
	error_panel.hide()
	ConnectionManager.set_state(ConnectionManager.ConnectionState.CONNECTING)
	ConnectionManager.retry_requested.emit()
