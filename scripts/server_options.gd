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
	join_btn.text = "加入服务器（有BUG别用）"
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
	var connect_cmd = "connect %s:%d" % [current_ip, current_port]
	DisplayServer.clipboard_set(connect_cmd)  # 先复制到剪贴板

	# 方法1：使用PowerShell直接激活窗口
	var ps_script = """
	Add-Type -AssemblyName System.Windows.Forms
	$csgo = Get-Process csgo -ErrorAction SilentlyContinue
	if ($csgo) {
		[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")  # Alt+Tab切换
		Start-Sleep -Milliseconds 500
		[System.Windows.Forms.SendKeys]::SendWait("~")       # 打开控制台
		Start-Sleep -Milliseconds 300
		[System.Windows.Forms.SendKeys]::SendWait("^v")      # 粘贴
		Start-Sleep -Milliseconds 200
		[System.Windows.Forms.SendKeys]::SendWait("{ENTER}") # 执行
	} else {
		Write-Output "CS:GO进程未找到"
	}
	"""

	# 写入临时PS1文件
	var temp_file = "user://csgo_connect.ps1"
	var file = FileAccess.open(temp_file, FileAccess.WRITE)
	file.store_string(ps_script)
	file.close()

	# 执行PowerShell脚本
	var output = []
	var exit_code = OS.execute("powershell", [
		"-ExecutionPolicy", "Bypass",
		"-File", ProjectSettings.globalize_path(temp_file)
	], output, true)

	if exit_code != 0:
		printerr("执行失败: ", output)
		# 方法2：备用AHK方案
		_fallback_ahk_method(connect_cmd)

func _fallback_ahk_method(cmd: String):
	var ahk_script = """
	; 通过进程ID精准激活窗口
	Process, Exist, csgo.exe
	if (ErrorLevel) {
		WinActivate, ahk_pid %ErrorLevel%
		WinWaitActive, ahk_pid %ErrorLevel%,, 3
		if (!ErrorLevel) {
			Send ~
			Sleep 300
			Send ^v
			Sleep 200
			Send {Enter}
	}
	}
	"""
	
	var temp_file = "user://csgo_connect.ahk"
	var file = FileAccess.open(temp_file, FileAccess.WRITE)
	file.store_string(ahk_script)
	file.close()

	var ahk_path = _find_ahk_path()
	if ahk_path:
		OS.execute(ahk_path, [ProjectSettings.globalize_path(temp_file)])

func _find_ahk_path() -> String:
	var paths = [
		"C:\\Program Files\\AutoHotkey\\AutoHotkey.exe",
		"C:\\Program Files (x86)\\AutoHotkey\\AutoHotkey.exe",
		OS.get_environment("LOCALAPPDATA") + "\\Programs\\AutoHotkey\\AutoHotkey.exe"
	]
	for path in paths:
		if FileAccess.file_exists(path):
			return path
	printerr("AutoHotkey未安装")
	return ""
