extends Label

# 使用数组存储所有需要同步颜色的Label节点
@onready var all_labels := [
	$".",  # title
	$"../Setting/CenterContainer/VBoxContainer/ColorSetings/BackColor",
	$"../Setting/CenterContainer/VBoxContainer/ColorSetings/MainColor",
	$"../Setting/CenterContainer/VBoxContainer/ColorSetings/FontColor",
	$"../Setting/CenterContainer/VBoxContainer/PicturesSettings/BackPicture",
	$"../Setting/CenterContainer/VBoxContainer/PicturesSettings/Music",
	$"../Setting/CenterContainer/VBoxContainer/启动项设置/启动器预设",
	$"../Setting/CenterContainer/VBoxContainer/启动项设置/启动项",
	$"../Setting/CenterContainer/VBoxContainer/UserSettings/头像",
	$"../Setting/CenterContainer/VBoxContainer/UserSettings/username",
	$"../Setting/CenterContainer/VBoxContainer/UserSettings/tip",
	$"../Setting/CenterContainer/VBoxContainer/HBoxContainer/CS_GO路径",
	$"../Setting/分割线"
]

func _ready() -> void:
	# 初始设置所有标签颜色
	update_all_labels()
	
	# 连接全局颜色变化信号（如果Global有信号）
	if Global.has_signal("font_color_changed"):
		Global.font_color_changed.connect(update_all_labels)
	else:
		# 如果没有信号，使用process检测（效率较低）
		set_process(true)

func _process(delta: float) -> void:
	# 只有当Global没有信号时才需要process检测
	if !Global.has_signal("font_color_changed"):
		update_all_labels()

# 更新所有标签的颜色
func update_all_labels() -> void:
	for label in all_labels:
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", Global.font_color)

# 可选：清理信号连接
func _exit_tree() -> void:
	if Global.has_signal("font_color_changed"):
		Global.font_color_changed.disconnect(update_all_labels)
