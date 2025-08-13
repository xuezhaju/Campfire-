extends Control  # 假设你的场景根节点是Control类型

func _ready():
	# 获取按钮节点并连接信号
	var button = $"../AddServer"  # 替换为你的按钮实际路径
	button.pressed.connect(_on_add_server_pressed)


func _on_add_server_pressed() -> void:
	# 1. 创建RichTextLabel节点
	var rich_text_label = RichTextLabel.new()
	
	# 2. 设置文本内容和基本属性
	Server.start_server()
	var server_text: String = Server.return_text
	rich_text_label.text = server_text
	rich_text_label.bbcode_enabled = true  # 启用BBCode格式
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # 自动换行
	rich_text_label.scroll_active = true  # 禁用滚动
	rich_text_label.custom_minimum_size = Vector2(0, 40)
	
	# 3. 设置自定义样式（Godot 4正确方法）
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # 深色半透明背景
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	
	# Godot 4 设置样式的方法
	rich_text_label.set("theme_override_styles/normal", style)
	
	# 4. 添加到VBoxContainer
	var vbox = $VBoxContainer  # 替换为你的VBoxContainer实际路径
	vbox.add_child(rich_text_label)
	
	# 5. 确保可见并排在最后
	rich_text_label.show()
