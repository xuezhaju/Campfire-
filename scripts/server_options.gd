extends PopupPanel

signal remove_server(ip: String, port: int)
signal refresh_server(ip: String, port: int)
signal move_to_top(ip: String, port: int)

var current_ip: String = ""
var current_port: int = 0

func set_server_info(ip: String, port: int):
	current_ip = ip
	current_port = port

func _ready():
	# 主居中容器
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)
	
	# 垂直按钮容器
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	# 按钮样式
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.2, 0.2)
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	
	# 加入服务器按钮
	var join_btn = Button.new()
	join_btn.text = "加入服务器"
	join_btn.custom_minimum_size = Vector2(200, 40)
	join_btn.add_theme_stylebox_override("normal", btn_style)
	join_btn.pressed.connect(_on_join_button_pressed)
	vbox.add_child(join_btn)
	
	# 复制指令按钮
	var copy_btn = Button.new()
	copy_btn.text = "复制控制台指令"
	copy_btn.custom_minimum_size = Vector2(200, 40)
	copy_btn.add_theme_stylebox_override("normal", btn_style)
	copy_btn.pressed.connect(_on_copy_button_pressed)
	vbox.add_child(copy_btn)
	
	# 置顶服务器按钮
	var top_btn = Button.new()
	top_btn.text = "置顶服务器"
	top_btn.custom_minimum_size = Vector2(200, 40)
	top_btn.add_theme_stylebox_override("normal", btn_style)
	top_btn.pressed.connect(_on_top_button_pressed)
	vbox.add_child(top_btn)
	
	# 删除服务器按钮
	var remove_btn = Button.new()
	remove_btn.text = "删除服务器"
	remove_btn.custom_minimum_size = Vector2(200, 40)
	remove_btn.add_theme_stylebox_override("normal", btn_style)
	remove_btn.pressed.connect(_on_remove_button_pressed)
	vbox.add_child(remove_btn)
	
	# 取消按钮
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(200, 40)
	cancel_btn.add_theme_stylebox_override("normal", btn_style)
	cancel_btn.pressed.connect(hide)
	vbox.add_child(cancel_btn)
	
	# 按钮间距
	vbox.add_theme_constant_override("separation", 10)

func _on_remove_button_pressed():
	emit_signal("remove_server", current_ip, current_port)
	hide()

func _on_top_button_pressed():
	emit_signal("move_to_top", current_ip, current_port)
	hide()

func _on_copy_button_pressed():
	var connect_cmd = "connect %s:%d" % [current_ip, current_port]
	DisplayServer.clipboard_set(connect_cmd)
	print("已复制连接指令到剪贴板: ", connect_cmd)

func _on_join_button_pressed():
	# 修改rev.ini文件
	modify_rev_ini(current_ip, current_port)
	# 这里可以添加启动CSGO的代码
	launch_csgo()
	hide()

func modify_rev_ini(ip: String, port: int):
	var rev_ini_path = "D:/Counter-Strike Global Offensive/rev.ini"
	var temp_path = rev_ini_path + ".tmp"
	var input_file = FileAccess.open(rev_ini_path, FileAccess.READ)
	var output_file = FileAccess.open(temp_path, FileAccess.WRITE)
	
	if input_file and output_file:
		var current_line = 1
		var proc_line_found = false
		
		while not input_file.eof_reached():
			var line = input_file.get_line()
			
			# 处理第二行（ProcName行）
			if current_line == 2 and line.begins_with("ProcName="):
				# 检查是否已经包含connect参数
				if "+connect" in line:
					# 替换现有的connect参数
					var parts = line.split("+connect")
					line = parts[0] + "+connect %s:%d" % [ip, port]
				else:
					# 添加connect参数
					line = line + " +connect %s:%d" % [ip, port]
				proc_line_found = true
			
			output_file.store_line(line)
			current_line += 1
		
		input_file.close()
		output_file.close()
		
		# 替换原文件
		var dir = DirAccess.open("D:/Counter-Strike Global Offensive/")
		if dir:
			dir.remove("rev.ini")
			dir.rename("rev.ini.tmp", "rev.ini")
			print("成功修改rev.ini文件")
		else:
			printerr("无法重命名文件")
		
		if not proc_line_found:
			printerr("警告：未找到ProcName行，可能未成功添加连接参数")
	else:
		printerr("无法打开rev.ini文件进行修改")


func launch_csgo():
	var csgo_path = Global.csgo_path + "/revLoader.exe"
	print(csgo_path)

	# 检查文件是否存在
	if FileAccess.file_exists(csgo_path):
		OS.execute(csgo_path, [], [], false)
	else:
		print("找不到CSGO可执行文件")
		return false
