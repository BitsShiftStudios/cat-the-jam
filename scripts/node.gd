extends Node

# Called when the node enters the scene tree for the first time.
var server = TCPServer.new()

func _ready():
	server.listen(8060) # 8060 portunu dinlemeye başla
	print("Godot 8060 portunda terminali bekliyor...")
	
	
func _process(_delta):
	if server.is_connection_available():
		var peer = server.take_connection()
		print("Terminalden bir istek geldi!")
		var data = peer.get_utf8_string(peer.get_available_bytes())
		print("Gelen Veri: ", data)
		peer.put_data("HTTP/1.1 200 OK\r\n\r\nMerhaba terminal!".to_utf8_buffer())
	

func _on_button_2_pressed() -> void:
	var url = "https://httpbin.org/get" # Bu site ne gönderirsen sana geri yansıtır
	server.request(url)
	print("Test isteği atıldı...")
	pass # Replace with function body.
