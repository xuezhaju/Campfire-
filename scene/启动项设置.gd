extends HBoxContainer

@onready var line_edit: LineEdit = $启动项/LineEdit
@onready var save: Button = $Save

# 默认启动参数
const DEFAULT_ARGS = "csgo.exe -steam -silent"
# 预设文件保存路径
var PRESET_PATH = Global.settings_save_path

func _ready():
	# 连接按钮信号
	save.pressed.connect(_on_save_pressed)
	# 显示当前非默认启动项
	_display_custom_args()

# 显示当前非默认启动参数
func _display_custom_args():
	var rev_ini = _read_rev_ini()
	if rev_ini != "":
		var proc_args = _get_proc_args(rev_ini)
		if proc_args != "":
			# 移除默认参数部分
			var custom_args = proc_args.replace(DEFAULT_ARGS, "").strip_edges()
			line_edit.text = custom_args


# 获取ProcName=后面的全部内容
func _get_proc_args(content: String) -> String:
	var lines = content.split("\n")
	var in_loader_section = false
	
	for line in lines:
		if line.begins_with("[Loader]"):
			in_loader_section = true
		elif in_loader_section and line.begins_with("ProcName="):
			return line.trim_prefix("ProcName=").strip_edges()
		elif line.begins_with("[") and line != "[Loader]":
			in_loader_section = false
	return ""


# 保存按钮按下时的处理
func _on_save_pressed():
	var input_text = line_edit.text.strip_edges()
	var rev_ini = _read_rev_ini()
	if rev_ini == "":
		print("无法读取rev.ini文件")
		return
	
	# 组合默认参数和用户输入
	var full_args = DEFAULT_ARGS
	if input_text != "":
		full_args += " " + input_text
	
	rev_ini = _update_proc_args(rev_ini, full_args)
	_save_rev_ini(rev_ini)
	
	print("保存成功")
	line_edit.text = input_text  # 保留用户输入
	
func _update_proc_args(content: String, new_args: String) -> String:
	var lines = content.split("\n")
	var new_lines = []
	var in_loader_section = false
	var procname_updated = false
	
	for line in lines:
		if line.begins_with("[Loader]"):
			in_loader_section = true
			new_lines.append(line)
		elif in_loader_section and line.begins_with("ProcName="):
			new_lines.append("ProcName=" + new_args)
			procname_updated = true
		elif line.begins_with("[") and line != "[Loader]":
			in_loader_section = false
			new_lines.append(line)
		else:
			new_lines.append(line)
	
	# 如果没有Loader部分，则创建
	if not procname_updated:
		new_lines.append("[Loader]")
		new_lines.append("ProcName=" + new_args)
	
	return "\n".join(new_lines)	


	
func _append_to_procname(content: String, new_value: String) -> String:
	var lines = content.split("\n")
	var new_lines = []
	var in_loader_section = false
	
	for line in lines:
		if line.begins_with("[Loader]"):
			in_loader_section = true
			new_lines.append(line)
		elif in_loader_section and line.begins_with("ProcName="):
			# 在现有ProcName后追加新内容
			new_lines.append(line + " " + new_value)
		elif line.begins_with("[") and line != "[Loader]":
			in_loader_section = false
			new_lines.append(line)
		else:
			new_lines.append(line)
	
	# 如果没有找到Loader部分，则创建并添加
	if not "[Loader]" in content:
		new_lines.append("[Loader]")
		new_lines.append("ProcName=" + new_value)
	
	return "\n".join(new_lines)


# 选择预设时的处理

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
	var file = FileAccess.open(Global.rev_ini, FileAccess.WRITE)
	if file == null:
		print("无法保存rev.ini文件")
		return
	file.store_string(content)
	file.close()
	
	print("rev.ini已更新")

# 加载预设列表
