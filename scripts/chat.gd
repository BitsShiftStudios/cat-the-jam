extends VBoxContainer

var max_messages = 15
var chat_history = []
var fade_timer = Timer.new() # 1. Zamanlayıcıyı oluşturuyoruz

func _ready():
	$HBoxContainer/LineEdit.visible = false
	PlayersManager.system_message_received.connect(_on_system_message_received)
	# 2. Zamanlayıcı ayarları (5 saniye sonra gizler)
	fade_timer.wait_time = 5.0
	fade_timer.one_shot = true
	fade_timer.timeout.connect(func(): $RichTextLabel.hide()) # Süre bitince yazıları sakla
	add_child(fade_timer)
	
func _on_system_message_received(text: String):
	var formatted_message = "[b][color=yellow]Sunucu:[/color][/b] " + text
	chat_history.append(formatted_message)
	
	if chat_history.size() > max_messages:
		chat_history.pop_front()
		
	$RichTextLabel.text = ""
	for msg in chat_history:
		$RichTextLabel.append_text(msg + "\n")
		
	# Chat kutusunu göster (Önceki adımda eklediğin Timer varsa onu da başlatabilirsin)
	$RichTextLabel.show()
	if fade_timer: fade_timer.start()

func _input(event):
	if event.is_action_pressed("chat_button"):
		if not $HBoxContainer/LineEdit.has_focus():
			get_viewport().set_input_as_handled()
			$HBoxContainer/LineEdit.grab_focus()
			PlayerData.is_chatting = true
			$HBoxContainer/LineEdit.visible = true
			
			# 3. Chat açılınca yazıları göster ve süreyi sıfırla
			$RichTextLabel.show()
			fade_timer.start() 
			
	if event.is_action_pressed("send_message"):
		if $HBoxContainer/LineEdit.has_focus():
			_send()
			$HBoxContainer/LineEdit.release_focus()
			PlayerData.is_chatting = false
			$HBoxContainer/LineEdit.visible = false

func _send():
	var text = $HBoxContainer/LineEdit.text.strip_edges()
	if text == "":
		return
	$HBoxContainer/LineEdit.text = ""
	# Server ise komutu işle
	if multiplayer.is_server():
		var console = get_tree().get_root().find_child("Server", true, false)
		if console:
			console._handle_command(text)
		return

	send_message.rpc(PlayerData.login,PlayerData.color, text)

@rpc("any_peer", "call_local", "reliable")
func send_message(login: String,color_hex: String , text: String):
	var formatted_message = "[b][color=#" + color_hex + "]" + login + ":[/color][/b] " + text
	chat_history.append(formatted_message)
	if chat_history.size() > max_messages:
		chat_history.pop_front()
		
	$RichTextLabel.text = ""
	for msg in chat_history:
		$RichTextLabel.append_text(msg + "\n")
		
	# 4. Yeni mesaj gelince yazıları göster ve süreyi sıfırla
	$RichTextLabel.show()
	fade_timer.start()
