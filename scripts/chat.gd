extends VBoxContainer

func _ready():
	$HBoxContainer/LineEdit.visible = false

func _input(event):
	if event.is_action_pressed("chat_button"):
		if not $HBoxContainer/LineEdit.has_focus():
			get_viewport().set_input_as_handled()
			$HBoxContainer/LineEdit.grab_focus()
			PlayerData.is_chatting = true
			$HBoxContainer/LineEdit.visible = true	
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
	send_message.rpc(PlayerData.login, text)

@rpc("any_peer", "call_local", "reliable")
func send_message(login: String, text: String):
	$RichTextLabel.append_text("[b]" + login + ":[/b] " + text + "\n")
