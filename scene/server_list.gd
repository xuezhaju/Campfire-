extends Control

@onready var ip: LineEdit = $"../../AddServerSettings/CenterContainer/VBoxContainer/IP"
@onready var port: LineEdit = $"../../AddServerSettings/CenterContainer/VBoxContainer/PORT"
@onready var add_server_settings: Control = $"../../AddServerSettings"
@onready var create: Button = $"../../AddServerSettings/CenterContainer/VBoxContainer/HBoxContainer/Create"
@onready var cancel: Button = $"../../AddServerSettings/CenterContainer/VBoxContainer/HBoxContainer/Cancle"

# 存储所有服务器及其UI元素
var server_list: Array = []  # 每个元素是字典: {ip, port, label, query, timer}
var ip_text := ""
var port_text := ""

var server_options_scene = preload("res://scene/server_options.tscn") 
var server_options_popup: PopupPanel

var save_path :String = "C://Users/Campfires/Campfire"

func _ready():
	port.text = "端口：" + port_text
	load_servers()

	# 初始化服务器选项弹窗
	server_options_popup = server_options_scene.instantiate()
	add_child(server_options_popup)
	server_options_popup.hide()

	# 连接选项弹窗的信号
	server_options_popup.connect("remove_server", _on_remove_server_requested)
	server_options_popup.connect("refresh_server", _on_refresh_server_requested)
	server_options_popup.move_to_top.connect(_on_move_to_top_requested)  # 新增这行

func _on_server_label_clicked(server: Dictionary):
	# 显示选项弹窗
	server_options_popup.set_server_info(server.ip, server.port)
	server_options_popup.popup_centered()

func _on_remove_server_requested(ip: String, port: int):
	remove_server(ip, port)
	server_options_popup.hide()

func _on_refresh_server_requested(ip: String, port: int):
	for server in server_list:
		if server.ip == ip and server.port == port:
			_query_server(server)
			break
	server_options_popup.hide()

func _process(delta):
	add_server_settings.visible = Global.is_create
	add_server_settings.process_mode = Node.PROCESS_MODE_INHERIT if Global.is_create else Node.PROCESS_MODE_DISABLED
	
	if Input.is_key_pressed(KEY_F5):
		load_servers()
	
	# 更新所有服务器的计时器
	for server in server_list:
		server.timer += delta
		if server.timer >= 1.0:  # 每秒查询一次
			server.timer = 0.0
			_query_server(server)

func _query_server(server: Dictionary):
	# 创建新的查询实例
	var query = ServerQuery.new()
	add_child(query)
	server.query = query  # 更新查询实例
	
	# 连接信号
	query.query_completed.connect(_on_server_query_completed.bind(server))
	query.query_failed.connect(_on_server_query_failed.bind(server))
	
	# 执行查询
	query.query(server.ip, server.port)

func _on_add_server_pressed():
	Global.is_create = true

func _on_ip_text_changed(new_text: String):
	ip_text = new_text.replace("   IP  ：", "").strip_edges()

func _on_port_text_changed(new_text: String):
	port_text = new_text.replace("端口：", "").strip_edges()
	if port_text.is_empty():
		port_text = ""
		port.text = "端口：" + port_text

func _on_create_pressed():
	if ip_text.is_empty():
		print("错误：IP地址不能为空")
		return
	
	# 检查是否已存在相同服务器
	for server in server_list:
		if server.ip == ip_text and server.port == int(port_text):
			print("该服务器已在监控列表中")
			Global.is_create = false
			return
	
	# 创建UI项
	var label = create_line()
	label.text = "[color=gray]查询 %s:%s...[/color]" % [ip_text, port_text]
	
	# 添加到服务器列表
	var new_server = {
		"ip": ip_text,
		"port": int(port_text),
		"label": label,
		"query": null,
		"timer": 1.0  # 立即触发第一次查询
	}
	server_list.append(new_server)
	
	save_servers()  # 保存服务器列表
	
	# 重置表单
	Global.is_create = false
	ip.text = "   IP  ："
	port.text = "端口："

func save_servers():
	var config = ConfigFile.new()

	for i in range(server_list.size()):
		var server = server_list[i]
		config.set_value("server_%d" % i, "ip", server.ip)
		config.set_value("server_%d" % i, "port", server.port)
	
	config.save(save_path)
	print("服务器列表已保存")

func load_servers():
	var config = ConfigFile.new()
	var err = config.load(save_path)

	if err != OK:
		print("没有找到保存的服务器列表或加载失败，错误代码: ", err)
		return
	
	print("正在从 ", save_path, " 加载服务器列表...")
	
	# 清空现有列表（避免重复加载）
	for server in server_list:
		if is_instance_valid(server.label):
			server.label.queue_free()
	server_list.clear()
	
	# 获取所有服务器部分
	var server_keys = config.get_sections()
	server_keys.sort()  # 确保按顺序加载
	
	for key in server_keys:
		var ip = config.get_value(key, "ip")
		var port = config.get_value(key, "port")

		print("加载服务器: ", ip, ":", port)

		# 创建UI项
		var label = create_line()
		label.text = "[color=gray]加载中 %s:%s...[/color]" % [ip, port]

		# 添加到服务器列表
		var server = {
			"ip": ip,
			"port": port,
			"label": label,
			"query": null,
			"timer": 0.0  # 立即触发查询
		}
		server_list.append(server)
	
	print("已加载 %d 个服务器" % server_list.size())

func remove_server(ip: String, port: int):
	for i in range(server_list.size() - 1, -1, -1):
		var server = server_list[i]
		if server.ip == ip and server.port == port:
			if is_instance_valid(server.label):
				server.label.queue_free()
			if is_instance_valid(server.query):
				server.query.queue_free()
			server_list.remove_at(i)
	
	save_servers()  # 更新保存



func create_line() -> RichTextLabel:
	var rich_text_label = RichTextLabel.new()
	rich_text_label.name = "Server_%s_%s" % [ip_text, port_text]
	rich_text_label.bbcode_enabled = true
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich_text_label.scroll_active = true
	rich_text_label.custom_minimum_size = Vector2(0, 40)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.set_content_margin_all(10)
	rich_text_label.set("theme_override_styles/normal", style)
	
	# 添加点击检测
	rich_text_label.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for server in server_list:
				if server.label == rich_text_label:
					_on_server_label_clicked(server)
					break
	)
	
	$VBoxContainer.add_child(rich_text_label)
	return rich_text_label

func _on_server_query_completed(info: Dictionary, server: Dictionary):
	if is_instance_valid(server.label):  # 检查label是否仍然有效
		server.label.text = "服务器: [color=green]%s[/color]\nIP: %s:%d\n地图: %s\n玩家: %d/%d\n延迟: %s\n更新时间: %s" % [
			info["name"],
			server.ip,
			server.port,
			info["map"],
			info["players"],
			info["max_players"],
			info["ping"],
			Time.get_time_string_from_system()
		]
	
	# 清理旧的查询实例
	if is_instance_valid(server.query):
		server.query.queue_free()
	server.query = null

func _on_server_query_failed(server: Dictionary):
	if is_instance_valid(server.label):
		server.label.text = "[color=red]%s:%d 查询失败[/color]\n最后尝试: %s" % [
			server.ip,
			server.port,
			Time.get_time_string_from_system()
		]
	
	# 清理旧的查询实例
	if is_instance_valid(server.query):
		server.query.queue_free()
	server.query = null

func _on_cancle_pressed():
	Global.is_create = false


func _on_f_5_pressed() -> void:
	load_servers()

# 在主脚本中添加以下代码：

func _on_move_to_top_requested(ip: String, port: int):
	# 读取当前配置文件
	var config = ConfigFile.new()
	var err = config.load("C://Users/Campfires/Campfire")
	if err != OK:
		print("无法加载服务器配置文件")
		return

	# 找出要置顶的服务器
	var target_section = ""
	var target_data = {}
	var other_sections = []

	# 收集所有服务器并找到目标服务器
	for section in config.get_sections():
		var server_ip = config.get_value(section, "ip")
		var server_port = config.get_value(section, "port")

		if server_ip == ip and server_port == port:
			target_section = section
			target_data = {"ip": server_ip, "port": server_port}
		else:
			other_sections.append({"section": section, "ip": server_ip, "port": server_port})

	if target_section == "":
		print("未找到要置顶的服务器")
		return

	# 重新排序服务器（目标服务器到顶部）
	var new_config = ConfigFile.new()

	# 添加目标服务器为第一个
	new_config.set_value("server_0", "ip", target_data.ip)
	new_config.set_value("server_0", "port", target_data.port)

	# 添加其他服务器，重新编号
	for i in range(other_sections.size()):
		var server = other_sections[i]
		new_config.set_value("server_%d" % (i + 1), "ip", server.ip)
		new_config.set_value("server_%d" % (i + 1), "port", server.port)
	
	# 保存新配置
	new_config.save("C://Users/Campfires/Campfire")
	print("服务器已置顶")

	# 重新加载服务器列表
	load_servers()
