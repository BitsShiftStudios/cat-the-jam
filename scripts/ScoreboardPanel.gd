extends PanelContainer

@onready var rows_container = $RowsContainer

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("show_scoreboard"):
		show()
	if Input.is_action_just_released("show_scoreboard"):
		hide()

func refresh_display(scores: Dictionary):
	for child in rows_container.get_children():
		child.queue_free()
		
	for player_id in scores:
		var p_data = scores[player_id]
		
		var row_label = Label.new()
		# Önce yeni bir settings nesnesi oluşturun
		row_label.label_settings = LabelSettings.new() 
		row_label.label_settings.font_size = 25
		row_label.text = "%s   \t|   Kills: %d   \t|\t   Deaths: %d" % [p_data["name"], p_data["kills"], p_data["deaths"]]

		#var row_label = Label.new()
		#row_label.label_settings.font_size = 25
		#row_label.text = "%s   \t|   Kills: %d   \t|\t   Deaths: %d" % [p_data["name"], p_data["kills"], p_data["deaths"]]
		
		rows_container.add_child(row_label)
