extends ColorPickerButton

func _ready():
	# 初始化颜色为 Global.font_color 的当前值
	color = Global.font_color
	
	# 连接信号，当颜色改变时调用 _on_color_changed
	color_changed.connect(_on_color_changed)

# 颜色改变时的回调函数
func _on_color_changed(new_color: Color):
	# 更新全局字体颜色
	Global.font_color = new_color
	
	# 可选：打印调试信息
	print("字体颜色已更新: ", new_color)
	

# 可选：提供一个方法来获取当前颜色
func get_current_font_color() -> Color:
	return color
