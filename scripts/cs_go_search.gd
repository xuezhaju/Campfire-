extends Label
@onready var line_edit: LineEdit = $LineEdit
@onready var search: MenuButton = $search

# 添加一个变量存储搜索结果
var search_results := []
var search_thread: Thread
var should_restart := false  # 添加重启标志

func _ready():
	line_edit.text = Global.csgo_path
	# 设置MenuButton的弹出菜单信号
	var popup = search.get_popup()
	popup.id_pressed.connect(_on_search_option_selected)
	
	# 添加菜单项
	popup.clear()
	popup.add_item("在C盘搜索CSGO", 0)
	popup.add_item("在D盘搜索CSGO", 1)
	popup.add_item("在E盘搜索CSGO", 2)

func _on_search_option_selected(id: int):
	match id:
		0:  # 搜索C盘
			start_search("Counter-Strike Global Offensive", "C:/")
		1:  # 搜索D盘
			start_search("Counter-Strike Global Offensive", "D:/")
		2:  # 搜索E盘
			start_search("Counter-Strike Global Offensive", "E:/")

func start_search(folder_name: String, start_path: String):
	# 清空之前的结果
	search_results.clear()
	line_edit.text = "正在搜索 %s..." % folder_name
	should_restart = true  # 设置重启标志
	
	# 如果已有搜索线程在运行，先等待它结束
	if search_thread and search_thread.is_started():
		search_thread.wait_to_finish()
	
	# 创建新线程进行搜索
	search_thread = Thread.new()
	search_thread.start(_threaded_search.bind(folder_name, start_path))

func _threaded_search(folder_name: String, start_path: String):
	search_results = find_folder(folder_name, start_path)
	call_deferred("_on_search_completed")

func _on_search_completed():
	if search_thread and search_thread.is_started():
		search_thread.wait_to_finish()
	
	# 在LineEdit中显示结果
	if search_results.size() > 0:
		line_edit.text = search_results[0]  # 显示第一个找到的路径
		print("找到CSGO安装路径: ", search_results[0])
		
		# 将路径赋值给全局变量
		if Global:
			Global.csgo_path = search_results[0]
			print("已设置Global.csgo_path为: ", Global.csgo_path)
			Global.save_settings()  # 保存设置
	else:
		line_edit.text = "未找到Counter-Strike Global Offensive文件夹"
		# 如果没找到，可以清空全局变量
		if Global:
			Global.csgo_path = ""
	
	# 如果需要重启且找到了路径
	if should_restart and search_results.size() > 0:
		await get_tree().create_timer(1.0).timeout  # 延迟1秒让用户看到结果
		restart_application()

func find_folder(folder_name: String, start_path: String) -> Array:
	var found_paths := []
	
	# 添加安全检查
	if folder_name.strip_edges().is_empty():
		return found_paths
	
	var dir = DirAccess.open(start_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):  # 跳过隐藏文件夹
				if file_name.to_lower() == folder_name.to_lower():  # 不区分大小写
					var full_path = dir.get_current_dir().path_join(file_name)
					found_paths.append(full_path)
					# 找到后立即返回，避免继续搜索
					dir.list_dir_end()
					return found_paths
				# 递归搜索子目录
				found_paths = find_folder(folder_name, dir.get_current_dir().path_join(file_name))
				if found_paths.size() > 0:
					dir.list_dir_end()
					return found_paths
			file_name = dir.get_next()
	else:
		printerr("无法打开目录: ", start_path)
	
	return found_paths

func _exit_tree():
	# 确保线程安全退出
	if search_thread and search_thread.is_started():
		search_thread.wait_to_finish()

func restart_application():
	# 获取当前可执行文件路径
	var executable_path = OS.get_executable_path()

	# 在 Windows 上需要处理路径中的反斜杠
	if OS.get_name() == "Windows":
		executable_path = executable_path.replace("/", "\\")

	# 创建新进程
	var args = []
	if OS.has_feature("editor"):
		# 如果在编辑器中运行，使用项目主场景
		args = ["--path", ProjectSettings.globalize_path("res://"), "res://scene/main_ui.tscn"]
		OS.create_process(OS.get_executable_path(), args, false)
	else:
	# 在导出版本中运行
		OS.create_process(executable_path, args, false)

	# 退出当前实例
	get_tree().quit()

func _on_clear_pressed() -> void:
	Global.csgo_path = ""
	Global.save_settings()
	Global.load_settings()
	line_edit.text = ""
	restart_application()
