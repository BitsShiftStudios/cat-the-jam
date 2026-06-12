extends PanelContainer

@onready var rows_container = $RowsContainer
var avatar_cache: Dictionary = {}
var cover_cache: Dictionary = {}

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("show_scoreboard"):
		show()
	if Input.is_action_just_released("show_scoreboard"):
		hide()

func create_column_label(text: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 22
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = align
	return label

func refresh_display(scores: Dictionary):
	for child in rows_container.get_children():
		child.queue_free()
		
	var sorted = scores.values()
	sorted.sort_custom(func(a, b): return a["kills"] > b["kills"])

	for p_data in sorted:
		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 5)
		row_margin.add_theme_constant_override("margin_right", 5)
		
		# --- 1. ARKA PLAN RESMİ ---
		var bg_rect = TextureRect.new()
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_rect.modulate = Color(1, 1, 1, 0.4)
		row_margin.add_child(bg_rect)
		
		var cover_url = p_data.get("cover", "")
		if cover_url != "":
			if cover_cache.has(cover_url):
				bg_rect.texture = cover_cache[cover_url]
			else:
				download_image(cover_url, bg_rect, cover_cache)
		
		# --- 2. İÇERİK KUTUSU (ÜST KATMAN) ---
		var row_box = HBoxContainer.new()
		row_margin.add_child(row_box)
		
		# Avatar Kısmı
		var avatar_rect = TextureRect.new()
		avatar_rect.custom_minimum_size = Vector2(40, 40)
		avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row_box.add_child(avatar_rect)
		
		var avatar_url = p_data.get("avatar", "")
		if avatar_url != "":
			if avatar_cache.has(avatar_url):
				avatar_rect.texture = avatar_cache[avatar_url]
			else:
				download_image(avatar_url, avatar_rect, avatar_cache)
		
		# Yazılar
		var campus = p_data.get("campus", "Bilinmiyor")
		var p_name = p_data.get("name", "Bilinmiyor")
		
		row_box.add_child(create_column_label("  %s" % p_name))
		row_box.add_child(create_column_label("Kills: %d" % p_data["kills"], HORIZONTAL_ALIGNMENT_CENTER))
		row_box.add_child(create_column_label("Deaths: %d" % p_data["deaths"], HORIZONTAL_ALIGNMENT_CENTER))
		row_box.add_child(create_column_label(campus, HORIZONTAL_ALIGNMENT_RIGHT))
		rows_container.add_child(row_margin)

# Hem avatarları hem de kapakları indiren ortak fonksiyon
func download_image(url: String, target_rect: TextureRect, cache_dict: Dictionary):
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(result, response_code, headers, body):
		# 1. KONTROL: Hem kod 200 olmalı hem de body (veri) boş olmamalı
		if response_code == 200 and body.size() > 0:
			var image = Image.new()
			var err = FAILED
			
			# 2. BAŞLIK (HEADER) OKUMA: Gelen dosya tam olarak ne tür bir dosya?
			var content_type = ""
			for h in headers:
				# Gelen dizide Content-Type bilgisini arıyoruz
				if h.to_lower().begins_with("content-type:"):
					content_type = h.to_lower()
					break
			
			# 3. NOKTA ATIŞI İŞLEME: Dosya türüne göre doğru okuyucuyu seç
			if "image/png" in content_type:
				err = image.load_png_from_buffer(body)
			elif "image/webp" in content_type:
				err = image.load_webp_from_buffer(body)
			elif "image/jpeg" in content_type or "image/jpg" in content_type:
				err = image.load_jpg_from_buffer(body)
			else:
				# Nadiren başlık eksik gelirse diye eski "sırayla dene" mantığı (Yedek Plan)
				err = image.load_jpg_from_buffer(body)
				if err != OK: err = image.load_png_from_buffer(body)
				if err != OK: err = image.load_webp_from_buffer(body)

			# 4. KONTROL: Resim başarıyla okunduysa Texture yap ve kaydet
			if err == OK:
				var tex = ImageTexture.create_from_image(image)
				cache_dict[url] = tex 
				
				if is_instance_valid(target_rect):
					target_rect.texture = tex
			else:
				print("Uyarı: İndirilen veri desteklenen bir resim formatı değil. URL: ", url)
		else:
			print("Uyarı: Resim indirilemedi. Kod: ", response_code, " URL: ", url)
			
		http.queue_free()
	)
	http.request(url)
