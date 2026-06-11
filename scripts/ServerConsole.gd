extends Node

var thread: Thread
@onready var match_controller = $/root/Node/MatchController
@onready var match_timer = $/root/Node/Timer

func _ready():
	print("server Console")
	if not multiplayer.is_server():
		return
	if not OS.has_feature("template"):
		return
	if not OS.get_cmdline_args().has("--server"):
		return
	thread = Thread.new()
	thread.start(_console_thread)

func _console_thread():
	print("[Console] Sunucu hazır. 'help' yaz.")
	while true:
		var input = OS.read_string_from_stdin().strip_edges()
		_handle_command.call_deferred(input)

# ── Oyuncu ──────────────────────────────────────────────
func _list_players():
	print("=== Oyuncular (%d) ===" % PlayersManager.get_player_count())
	for id in PlayersManager.players:
		var p = PlayersManager.players[id]
		print("  [%d] %s | Level: %s | Color: %s" % [
			id,
			p.get("login", "?"),
			p.get("level", "?"),
			p.get("color", "?")
		])

func _kick_player(parts: Array):
	if parts.size() < 2:
		print("Kullanım: kick <peer_id>")
		return
	var id = int(parts[1])
	if PlayersManager.has_player(id):
		print("Kick: ", PlayersManager.get_player_login(id))
		multiplayer.multiplayer_peer.disconnect_peer(id)
	else:
		print("Oyuncu bulunamadı: ", id)

func _broadcast(parts: Array):
	if parts.size() < 2:
		print("Kullanım: broadcast <mesaj>")
		return
	var msg = " ".join(parts.slice(1))
	get_parent().broadcast_system_message.rpc(msg)
	print("Yayınlandı: ", msg)

# ── Harita ──────────────────────────────────────────────
func _map_change(parts: Array):
	if parts.size() < 2:
		print("Kullanım: map <harita_adı>")
		print("Haritalar: poolday")
		return
	var maps = {
		"poolday": "res://scenes/maps/PoolDay.tscn",
		"campus": "res://scenes/maps/Campus.tscn"
		}
	if not maps.has(parts[1]):
		print("Bilinmeyen harita: ", parts[1], " | Mevcut: ", ", ".join(maps.keys()))
		return
	get_parent().change_map(maps[parts[1]])
	print("Harita değiştiriliyor: ", parts[1])

# ── Maç ─────────────────────────────────────────────────
func _restart():
	match_controller.reset_match()
	print("[Console] Maç yeniden başlatıldı.")

func _end():
	match_controller.end_match()
	print("[Console] Maç sonlandırıldı.")

func _pause():
	if not match_controller.match_active:
		print("[Console] Aktif maç yok.")
		return
	match_timer.pause_timer()
	print("[Console] Maç duraklatıldı.")

func _resume():
	if not match_controller.match_active:
		print("[Console] Aktif maç yok.")
		return
	match_timer.resume_timer()
	print("[Console] Maç devam ediyor.")

func _set_timer(parts: Array):
	if parts.size() < 2:
		print("Kullanım: timer <saniye>")
		return
	var seconds = parts[1].to_int()
	if seconds <= 0:
		print("[Console] Geçersiz değer.")
		return
	match_timer.set_time(seconds)
	print("[Console] Timer ", seconds, " saniyeye ayarlandı.")

# ── İstatistik ───────────────────────────────────────────
func _stats():
	print("=== Skor Tablosu ===")
	var data = match_controller.scoreboard_data
	if data.is_empty():
		print("  Henüz veri yok.")
		return
	for id in data:
		var p = data[id]
		var kd = "%.2f" % (float(p["kills"]) / max(p["deaths"], 1))
		print("  [%d] %s | K: %d | D: %d | K/D: %s" % [
			id, p["name"], p["kills"], p["deaths"], kd
		])

func _uptime():
	var secs = int(Time.get_ticks_msec() / 1000.0)
	var h: int = secs / 3600
	var m: int = (secs % 3600) / 60
	var s = secs % 60
	print("[Console] Uptime: %02d:%02d:%02d" % [h, m, s])

# ── Ana handler ──────────────────────────────────────────
func _handle_command(cmd: String):
	var parts = cmd.split(" ")
	var base = parts[0]

	match base:
		"players":  _list_players()
		"kick":     _kick_player(parts)
		"broadcast":_broadcast(parts)
		"map":      _map_change(parts)
		"restart":  _restart()
		"end":      _end()
		"pause":    _pause()
		"resume":   _resume()
		"timer":    _set_timer(parts)
		"stats":    _stats()
		"uptime":   _uptime()
		"ping":
			print("[Console] Pong! Oyuncu sayısı: ", PlayersManager.get_player_count())
		"help":
			print("""
Komutlar:
  players            → oyuncu listesi
  kick <id>          → oyuncu at
  broadcast <msg>    → tüm oyunculara mesaj
  map <isim>         → harita değiştir (poolday, newmap, rpmap, dust2)
  restart            → maçı yeniden başlat
  end                → maçı sonlandır
  pause              → maçı durdur
  resume             → maçı devam ettir
  timer <saniye>     → sayacı ayarla
  stats              → K/D skor tablosu
  uptime             → sunucu çalışma süresi
  ping               → sunucu durumu
  help               → komut listesi
			""")
		_:
			if base != "":
				print("Bilinmeyen komut: '", base, "' | 'help' yaz")

func _exit_tree():
	if thread and thread.is_started():
		thread.wait_to_finish()
