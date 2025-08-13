extends Control

@onready var ip: LineEdit = $"../../AddServerSettings/CenterContainer/VBoxContainer/IP"
@onready var port: LineEdit = $"../../AddServerSettings/CenterContainer/VBoxContainer/PORT"
@onready var add_server_settings: Control = $"../../AddServerSettings"
@onready var create: Button = $"../../AddServerSettings/CenterContainer/VBoxContainer/HBoxContainer/Create"
@onready var cancel: Button = $"../../AddServerSettings/CenterContainer/VBoxContainer/HBoxContainer/Cancle"

var ip_text := ""
var port_text := "27015"
var is_querying := false

func _ready():
	$"../AddServer".pressed.connect(_on_add_server_pressed)
	ip.text_changed.connect(_on_ip_text_changed)
	port.text_changed.connect(_on_port_text_changed)
	create.pressed.connect(_on_create_pressed)
	cancel.pressed.connect(_on_cancel_pressed)
	
	# 初始化默认值
	port.text = "端口：" + port_text

func _process(delta):
	add_server_settings.visible = Global.is_create
	add_server_settings.process_mode = Node.PROCESS_MODE_INHERIT if Global.is_create else Node.PROCESS_MODE_DISABLED
	
	# 查询超时处理
	if is_querying:
		if Server.udp.get_available_packet_count() > 0:
			_handle_server_response()
			is_querying = false

func _on_add_server_pressed():
	Global.is_create = true

func _on_ip_text_changed(new_text: String):
	ip_text = new_text.replace("   IP  ：", "").strip_edges()

func _on_port_text_changed(new_text: String):
	port_text = new_text.replace("端口：", "").strip_edges()
	if port_text.is_empty():
		port_text = "27015"
		port.text = "端口：" + port_text

func _on_create_pressed():
	if ip_text.is_empty():
		print("错误：IP地址不能为空")
		return
	
	# 设置服务器参数
	Server.server_ip = ip_text
	Server.server_port = int(port_text)
	
	# 开始查询
	Server.start_server()
	is_querying = true
	
	# 立即创建显示项
	create_line()
	
	# 重置表单
	Global.is_create = false
	ip.text = "   IP  ："
	port.text = "端口：27015"

func _on_cancel_pressed():
	Global.is_create = false

func create_line():
	var rich_text_label = RichTextLabel.new()
	rich_text_label.name = "Server_%s_%s" % [ip_text, port_text]
	
	# 初始显示"查询中..."
	rich_text_label.text = "[color=gray]查询 %s:%s...[/color]" % [ip_text, port_text]
	rich_text_label.bbcode_enabled = true
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich_text_label.scroll_active = true
	rich_text_label.custom_minimum_size = Vector2(0, 40)
	
	# 样式设置
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.set_content_margin_all(10)
	rich_text_label.set("theme_override_styles/normal", style)
	
	$VBoxContainer.add_child(rich_text_label)

func _handle_server_response():
	# 获取查询结果并更新UI
	var label = $VBoxContainer.get_child($VBoxContainer.get_child_count() - 1)
	if Server.return_text != "":
		label.text = Server.return_text
	else:
		label.text = "[color=red]查询失败 %s:%s[/color]" % [ip_text, port_text]
