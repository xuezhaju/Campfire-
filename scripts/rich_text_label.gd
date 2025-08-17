extends RichTextLabel

func _ready():
	# 基础设置
	scroll_active = false
	fit_content = true
	bbcode_enabled = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 全部内容居中的BBCode文本
	text = """
[center]
[font_size=24][b]篝火启动器[/b][/font_size]

[font_size=18][b]🎯 核心功能[/b][/font_size]
• 极简设计 • 一键优化 
• 多账号切换 • 安全稳定

[font_size=18][b]💻 技术特点[/b][/font_size]
• Godot开发 • 智能路径识别 
• 低资源占用

[font_size=18][b]📌 获取方式[/b][/font_size]
B站关注@学渣驹
QQ群：1059519859

[font_size=16][b]❓ 常见问题[/b][/font_size]
[b]Q：[/b]安全吗？
[b]A：[/b]平替7L启动器，正常使用无风险

[b]Q：[/b]支持CS2吗？
[b]A：[/b]开发中

[font_size=12]© 爱好者开发，非Valve官方产品[/font_size]
[/center]
	"""
	
	# 字体设置
	var font = load("res://asset/SmileySans-Oblique.ttf")
	if font:
		add_theme_font_override("normal_font", font)
	
	# 边距调整（使居中效果更明显）
	add_theme_constant_override("margin_left", 30)
	add_theme_constant_override("margin_right", 30)
	
	# 信号连接
	meta_clicked.connect(_on_meta_clicked)

func _on_meta_clicked(meta):
	if meta == "bilibili_link":
		OS.shell_open("https://space.bilibili.com/3493127857900357")
