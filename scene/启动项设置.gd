extends HBoxContainer

@onready var menu_button: MenuButton = $启动器预设/MenuButton
@onready var line_edit: LineEdit = $启动项/LineEdit
@onready var save: Button = $启动项/Save

# 预设文件保存路径
var PRESET_PATH = Global.settings_save_path

func _ready():
	# 连接按钮信号
	save.pressed.connect(_on_save_pressed)
	menu_button.get_popup().id_pressed.connect(_on_preset_selected)
	
	# 加载现有预设列表
	_load_presets()
	
	# 初始化时显示当前rev.ini的Loader内容
	_display_current_loader()

# 显示当前rev.ini的Loader内容
func _display_current_loader():
	var rev_ini = _read_rev_ini()
	if rev_ini != "":
		var loader_value = _get_loader_value(rev_ini)
		if loader_value != "":
			line_edit.text = loader_value

# 获取当前Loader值
func _get_loader_value(content: String) -> String:
	var lines = content.split("\n")
	var in_loader_section = false
	
	for line in lines:
		if line.begins_with("[Loader]"):
			in_loader_section = true
		elif in_loader_section and line.begins_with("ProcName="):
			return line.trim_prefix("ProcName=")
		elif line.begins_with("[") and line != "[Loader]":
			in_loader_section = false
	
	return ""

# 保存按钮按下时的处理
func _on_save_pressed():
	var input_text = line_edit.text.strip_edges()
	if input_text == "":
		print("输入为空")
		return
	
	# 读取当前rev.ini内容
	var rev_ini = _read_rev_ini()
	if rev_ini == "":
		print("无法读取rev.ini文件")
		return
	
	# 更新Loader部分
	rev_ini = _update_loader_section(rev_ini, input_text)
	
	# 保存到本地
	_save_rev_ini(rev_ini)
	
	print("保存成功")

# 选择预设时的处理
func _on_preset_selected(id):
	var preset_name = menu_button.get_popup().get_item_text(id)
	if preset_name == "无可用预设":
		return
		
	var preset_path = PRESET_PATH.path_join(preset_name + ".ini")
	
	if FileAccess.file_exists(preset_path):
		var preset_content = FileAccess.get_file_as_string(preset_path)
		_save_rev_ini(preset_content)
		# 更新LineEdit显示
		line_edit.text = _get_loader_value(preset_content)
		print("已加载预设: " + preset_name)
	else:
		print("预设文件不存在: " + preset_path)

# 读取rev.ini内容
func _read_rev_ini() -> String:
	var file = FileAccess.open(Global.rev_ini, FileAccess.READ)
	if file == null:
		return ""
	var content = file.get_as_text()
	file.close()
	return content

# 更新Loader部分
func _update_loader_section(content: String, new_value: String) -> String:
	var lines = content.split("\n")
	var new_lines = []
	var in_loader_section = false
	var procname_added = false
	
	for line in lines:
		if line.begins_with("[Loader]"):
			in_loader_section = true
			new_lines.append(line)
			# 在[Loader]后直接添加新的ProcName
			new_lines.append("ProcName=" + new_value)
			procname_added = true
		elif in_loader_section and line.begins_with("ProcName="):
			# 跳过旧的ProcName行
			continue
		elif line.begins_with("[") and line != "[Loader]":
			in_loader_section = false
			# 如果之前没有添加ProcName，现在添加
			if not procname_added:
				new_lines.append("ProcName=" + new_value)
				procname_added = true
			new_lines.append(line)
		else:
			new_lines.append(line)
	
	# 如果整个文件中都没有[Loader]部分，添加它
	if not procname_added:
		new_lines.append("[Loader]")
		new_lines.append("ProcName=" + new_value)
	
	return "\n".join(new_lines)

# 保存rev.ini文件
func _save_rev_ini(content: String):
	# 保存到本地
	var file = FileAccess.open(Global.rev_ini, FileAccess.WRITE)
	if file == null:
		print("无法保存rev.ini文件")
		return
	file.store_string(content)
	file.close()
	
	print("rev.ini已更新")

# 加载预设列表
func _load_presets():
	var dir = DirAccess.open(PRESET_PATH)
	if dir == null:
		print("无法访问预设目录: ", PRESET_PATH)
		_show_no_presets()
		return
	
	var popup = menu_button.get_popup()
	popup.clear()
	
	var presets_found = false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not file_name.begins_with(".") and file_name.ends_with(".ini"):
			var preset_name = file_name.trim_suffix(".ini")
			popup.add_item(preset_name)
			presets_found = true
		file_name = dir.get_next()
	
	if not presets_found:
		_show_no_presets()

func _show_no_presets():
	var popup = menu_button.get_popup()
	popup.clear()
	popup.add_item("无可用预设")
	popup.set_item_disabled(0, true)
