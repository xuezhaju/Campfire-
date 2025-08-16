extends Node

var mainui_mode :String = "server_list"
var is_create :bool = false

var back_color := Color(0.506, 0.776, 0.898)
var main_color := Color(0.333, 0.635, 0.769)

var settings_save_path := "C://Users/Campfires/CampfireSettings"
var music_path :String = ""

signal settings_changed

# 背景图片路径（带setter监听）
var back_picture_path: String = "":
	set(value):
		if back_picture_path != value:
			back_picture_path = value
			settings_changed.emit()  # 正确发射信号
			save_settings()


signal font_color_changed
var font_color := Color(0.996, 1.0, 1.0):
	set(value):
		if font_color != value:
			font_color = value
			font_color_changed.emit()


# 保存设置到 config.cfg
func save_settings():
	var config = ConfigFile.new()

	# 存储颜色值（转换为数组格式）
	config.set_value("Settings", "back_color", Global.back_color)
	config.set_value("Settings", "main_color", Global.main_color)
	config.set_value("Settings", "font_color", Global.font_color)
	config.set_value("Settings", "back_picture_path", Global.back_picture_path)
	config.set_value("Settings", "music_path", Global.music_path)

	# 保存到用户目录
	var err = config.save(settings_save_path)
	if err != OK:
		print("保存失败: ", error_string(err))

# 加载设置
func load_settings():
	var config = ConfigFile.new()
	var result = config.load(settings_save_path)
	if not FileAccess.file_exists(settings_save_path):
		push_error("配置文件不存在: ", settings_save_path)
		save_settings()
	
	if result != OK:
		printerr("erro on load settings cfg!")

		back_color = Color(0.506, 0.776, 0.898)
		main_color = Color(0.333, 0.635, 0.769)
		font_color = Color(0.996, 1.0, 1.0)
		back_picture_path = ""

	else:
		back_color = config.get_value("Settings", "back_color", Color(0.506, 0.776, 0.898))
		main_color = config.get_value("Settings", "main_color", Color(0.333, 0.635, 0.769))
		font_color = config.get_value("Settings", "font_color", Color(0.996, 1.0, 1.0))
		back_picture_path = config.get_value("Settings", "back_picture_path", "")
		music_path = config.get_value("Settings", "music_path", "")


func create_folder(path: String):
	# 规范化路径（Windows 下推荐用 / 或 \\）
	var normalized_path = path.replace("//", "/")
	print("尝试创建目录: ", normalized_path)

	# 1. 先尝试打开父目录（确保有权限）
	var dir = DirAccess.open(normalized_path.get_base_dir())

	if dir:
		# 2. 使用实例方法 make_dir_recursive()
		var error = dir.make_dir_recursive(normalized_path)
		if error == OK:
			print("目录创建成功: ", normalized_path)
		else:
			print("目录创建失败，错误码: ", error)
	else:
		print("无法访问父目录，请检查权限或路径是否正确")

		

func folder():
	if DirAccess.dir_exists_absolute("C://Users/Campfires"):
		print("目标目录存在！")
	else:
		create_folder("C://Users/Campfires")

func _ready() -> void:
	load_settings()
	folder()
