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
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER  # Godot 4.0+
	center.add_child(vbox)
	
	# 按钮样式
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.2, 0.2)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.set_content_margin_all(8)
	
	# 置顶按钮
	var top_btn = Button.new()
	top_btn.text = "置顶服务器"
	top_btn.custom_minimum_size = Vector2(200, 40)
	top_btn.add_theme_stylebox_override("normal", btn_style)
	top_btn.pressed.connect(_on_top_button_pressed)
	vbox.add_child(top_btn)
	
	# 删除按钮
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
	
	# 按钮间间距
	vbox.add_theme_constant_override("separation", 10)

func _on_remove_button_pressed():
	emit_signal("remove_server", current_ip, current_port)
	hide()


# 在您的 PopupPanel 脚本中添加这个函数
func _on_top_button_pressed():
	emit_signal("move_to_top", current_ip, current_port)
	hide()
