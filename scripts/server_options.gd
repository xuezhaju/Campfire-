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
	
	# 第一次修改：添加connect参数
	var add_success = _modify_file(rev_ini_path, temp_path, func(line: String, current_line: int):
		if current_line == 2 and line.begins_with("ProcName="):
			if "+connect" in line:
				var parts = line.split("+connect")
				return parts[0] + "+connect %s:%d" % [ip, port]
			else:
				return line + " +connect %s:%d" % [ip, port]
		return line
	)
	
	if not add_success:
		printerr("添加connect参数失败")
		return
	
	# 30秒后异步移除connect参数
	var timer = Timer.new()
	timer.wait_time = 30.0
	timer.one_shot = true
	timer.timeout.connect(func():
		# 在后台线程执行文件修改
		_thread_safe_modify(rev_ini_path, temp_path, func(line: String, current_line: int):
			if current_line == 2 and line.begins_with("ProcName=") and "+connect" in line:
				return line.split("+connect")[0].strip_edges()
			return line
		)
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

# 线程安全的文件修改
func _thread_safe_modify(path: String, temp_path: String, modifier: Callable):
	var thread = Thread.new()
	thread.start(func():
		_modify_file(path, temp_path, modifier)
		thread.wait_to_finish()
	)

# 通用文件修改函数
func _modify_file(path: String, temp_path: String, modifier: Callable) -> bool:
	var input_file = FileAccess.open(path, FileAccess.READ)
	if not input_file:
		printerr("无法打开文件: %s" % path)
		return false
	
	var output_file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not output_file:
		input_file.close()
		printerr("无法创建临时文件: %s" % temp_path)
		return false
	
	var current_line = 1
	var modified = false
	
	while not input_file.eof_reached():
		var line = input_file.get_line()
		var new_line = modifier.call(line, current_line)
		if new_line != line:
			modified = true
		output_file.store_line(new_line)
		current_line += 1
	
	input_file.close()
	output_file.close()
	
	var dir = DirAccess.open(path.get_base_dir())
	if not dir:
		printerr("无法访问目录")
		return false
	
	if dir.file_exists(path):
		if dir.remove(path) != OK:
			printerr("无法删除原文件")
			return false
	
	if dir.rename(temp_path, path) != OK:
		printerr("无法重命名临时文件")
		return false
	
	return true


func launch_csgo():
	var csgo_path = Global.csgo_path + "/revLoader.exe"

	# 检查文件是否存在
	if FileAccess.file_exists(csgo_path):
		OS.execute(csgo_path, [], [], false)
	else:
		print("找不到CSGO可执行文件")
		return false
