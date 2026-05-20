extends Node

# === ALL PLAYERS DATA ===
var players: Dictionary = {}

# === SIGNALS ===
signal player_added(peer_id: int, player_data: Dictionary)
signal player_removed(peer_id: int)
signal player_updated(peer_id: int, player_data: Dictionary)
signal system_message_received(text: String)


# === PLAYER MANAGEMENT ===
func add_player(peer_id: int, player_data: Dictionary):
	"""
	player_data = {
		"login": String,
		"level": float,
		"location": String,
		"color": String,
		# İleride eklenecekler:
		# "avatar_url": String,
		# "wallet": String,
		# "achievements": Array,
		# vs...
	}
	"""
	players[peer_id] = player_data.duplicate()
	player_added.emit(peer_id, players[peer_id])
	print("[PlayersManager] Player added: ", player_data.get("login", "Unknown"), " (ID: ", peer_id, ")")

func remove_player(peer_id: int):
	if players.has(peer_id):
		var login = players[peer_id].get("login", "Unknown")
		players.erase(peer_id)
		player_removed.emit(peer_id)
		print("[PlayersManager] Player removed: ", login, " (ID: ", peer_id, ")")

func update_player(peer_id: int, key: String, value):
	if players.has(peer_id):
		players[peer_id][key] = value
		player_updated.emit(peer_id, players[peer_id])

func update_player_bulk(peer_id: int, data: Dictionary):
	"""Birden fazla alanı aynı anda güncelle"""
	if players.has(peer_id):
		for key in data:
			players[peer_id][key] = data[key]
		player_updated.emit(peer_id, players[peer_id])

func get_player(peer_id: int) -> Dictionary:
	return players.get(peer_id, {})

func get_player_field(peer_id: int, field: String, default = null):
	"""Tek bir field'ı al"""
	if players.has(peer_id):
		return players[peer_id].get(field, default)
	return default

func has_player(peer_id: int) -> bool:
	return players.has(peer_id)

func get_all_players() -> Dictionary:
	return players.duplicate()

func get_player_count() -> int:
	return players.size()

func clear_all():
	players.clear()
	print("[PlayersManager] All players cleared")

# === CONVENIENCE HELPERS (opsiyonel) ===
func get_player_login(peer_id: int) -> String:
	return get_player_field(peer_id, "login", "Unknown")

func get_player_color(peer_id: int) -> String:
	return get_player_field(peer_id, "color", "FFFFFF")

func get_player_level(peer_id: int) -> float:
	return get_player_field(peer_id, "level", 0.0)
