extends PopupPanel

signal remove_server(ip: String, port: int)
signal refresh_server(ip: String, port: int)
signal move_to_top(ip: String, port: int)

var current_ip: String = ""
var current_port: int = 0

var udp := PacketPeerUDP.new()
var CSGO_PORT :int = 2121  # Must match launch option

func set_server_info(ip: String, port: int):
	current_ip = ip
	current_port = port

func _ready():
	# Main centered container
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)
	
	# Vertical button container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	# Button style
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.2, 0.2)
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	
	# Join Server button
	var join_btn = Button.new()
	join_btn.text = "加入服务器"
	join_btn.custom_minimum_size = Vector2(200, 40)
	join_btn.add_theme_stylebox_override("normal", btn_style)
	join_btn.pressed.connect(_join_server)
	vbox.add_child(join_btn)
	
	var copy_common = Button.new()
	copy_common.text = "复制控制台指令"
	copy_common.custom_minimum_size = Vector2(200, 40)
	copy_common.add_theme_stylebox_override("normal", btn_style)
	copy_common.pressed.connect(copy_commons)
	vbox.add_child(copy_common)
	
	# Move to Top button
	var top_btn = Button.new()
	top_btn.text = "置顶服务器"
	top_btn.custom_minimum_size = Vector2(200, 40)
	top_btn.add_theme_stylebox_override("normal", btn_style)
	top_btn.pressed.connect(_on_top_button_pressed)
	vbox.add_child(top_btn)
	
	# Remove Server button
	var remove_btn = Button.new()
	remove_btn.text = "删除服务器"
	remove_btn.custom_minimum_size = Vector2(200, 40)
	remove_btn.add_theme_stylebox_override("normal", btn_style)
	remove_btn.pressed.connect(_on_remove_button_pressed)
	vbox.add_child(remove_btn)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(200, 40)
	cancel_btn.add_theme_stylebox_override("normal", btn_style)
	cancel_btn.pressed.connect(hide)
	vbox.add_child(cancel_btn)
	
	# Button spacing
	vbox.add_theme_constant_override("separation", 10)

func _on_remove_button_pressed():
	emit_signal("remove_server", current_ip, current_port)
	hide()

func _on_top_button_pressed():
	emit_signal("move_to_top", current_ip, current_port)
	hide()

func send_csgo_command(cmd: String) -> bool:
	# Check if already connected
	if udp.get_available_packet_count() > 0:  # Alternative connection check
		udp.close()
	
	# Connect to CS:GO
	var err = udp.connect_to_host("127.0.0.1", CSGO_PORT)
	if err != OK:
		print("Connection failed: ", err)
		return false
	
	# Send command (must include newline)
	var packet = (cmd + "\n").to_utf8_buffer()
	udp.put_packet(packet)
	
	# Wait briefly to ensure packet is sent
	await get_tree().create_timer(0.05).timeout
	udp.close()
	return true

func _join_server():
	# Show connection status
	var status_label = get_tree().root.find_child("ConnectionStatus", true, false)
	if status_label:
		status_label.text = "Connecting..."
		status_label.modulate = Color.YELLOW
	
	# Try UDP method first with await
	var success = await send_csgo_command("connect %s:%d" % [current_ip, current_port])
	if success:
		print("Command sent via UDP")
	else:
		print("Falling back to alternative methods")
		_fallback_connect()
	
	# Reset status
	if status_label:
		await get_tree().create_timer(2.0).timeout
		status_label.text = "Ready"
		status_label.modulate = Color.WHITE

func _fallback_connect():
	# Steam protocol fallback
	var steam_url = "steam://connect/%s:%d" % [current_ip, current_port]
	if OS.shell_open(steam_url) == OK:
		return
	
	# OS-specific fallbacks
	match OS.get_name():
		"Windows":
			_windows_keyboard_connect()
		"Linux", "macOS":
			_linux_keyboard_connect()

func _windows_keyboard_connect():
	var ahk_script = """
	WinActivate, Counter-Strike
	Sleep 300
	Send {~}
	Sleep 100
	Send connect %s:%d{Enter}
	""" % [current_ip, current_port]
	
	var temp_file = "temp_csgo.ahk"
	FileAccess.open(temp_file, FileAccess.WRITE).store_string(ahk_script)
	OS.execute("AutoHotkey.exe", [temp_file])

func _linux_keyboard_connect():
	OS.execute("xdotool", [
		"search", "--name", "Counter-Strike",
		"windowactivate",
		"key", "grave",
		"type", "connect %s:%d" % [current_ip, current_port],
		"key", "Return"
	])

func copy_commons():
	var join_ip = str(current_ip) + ":" + str(current_port)
	var common = ("connect" + " " + join_ip).replace('"', "")
	print(common)
	copy_to_clipboard(common)

# 将文本复制到系统剪贴板
func copy_to_clipboard(text: String):
	DisplayServer.clipboard_set(text)
	print("已复制到剪贴板: ", text)
