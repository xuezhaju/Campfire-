extends ColorPickerButton

# 定义一个信号，当颜色改变时发出
signal color_selected(color)

func _ready():
	# 连接颜色变化信号
	color_changed.connect(_on_color_changed)
	
	# 初始化颜色（从 Global 读取）
	color = Global.back_color

# 当颜色改变时的处理函数
func _on_color_changed(new_color: Color):
	# 更新全局变量
	Global.back_color = new_color
	
	# 发出信号
	color_selected.emit(new_color)
	
	# 调试输出
	print("用户选择的颜色: ", new_color)

# 获取当前颜色（可选，因为可以直接访问 Global.back_color）
func get_selected_color() -> Color:
	return color
