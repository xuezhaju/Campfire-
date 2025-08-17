extends HBoxContainer

@onready var username_edit: LineEdit = $username/usernameEdit
@onready var tip_edit: LineEdit = $tip/TipEdit
@onready var language_edit: LineEdit = $Language/LanguageEdit

func _ready():
	# 初始化路径
	await get_tree().process_frame
	if Global.rev_ini.is_empty() and not Global.csgo_path.is_empty():
		Global.rev_ini = Global.csgo_path.path_join("rev.ini")
	
	load_config()
	
	# 连接信号
	username_edit.text_changed.connect(update_config)
	tip_edit.text_changed.connect(update_config)
	language_edit.text_changed.connect(update_config)

func load_config():
	var file = FileAccess.open(Global.rev_ini, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		# 提取三个目标字段
		var values = {
			"PlayerName": extract_value(content, "PlayerName"),
			"ClanTag": extract_value(content, "ClanTag"),
			"Language": extract_value(content, "Language")
		}
		
		username_edit.text = values["PlayerName"]
		tip_edit.text = values["ClanTag"]
		language_edit.text = values["Language"]
	else:
		push_error("无法读取配置文件")

# 辅助函数：从内容中提取键值
func extract_value(content: String, key: String) -> String:
	var regex = RegEx.create_from_string('%s=([^\\n\\r]*)' % key)
	var match = regex.search(content)
	if match:
		return match.get_string(1).replace("\"", "").strip_edges()
	return ""

func update_config(_new_text = ""):
	var file = FileAccess.open(Global.rev_ini, FileAccess.READ)
	if not file:
		push_error("无法读取配置文件")
		return
	
	var lines = file.get_as_text().split("\n")
	file.close()
	
	# 准备新值
	var updates = {
		"PlayerName": username_edit.text,
		"ClanTag": tip_edit.text,
		"Language": language_edit.text
	}
	
	# 精确修改目标行
	var current_section = ""
	for i in lines.size():
		var line = lines[i].strip_edges()
		
		# 检测section变化
		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.trim_prefix("[").trim_suffix("]")
			continue
		
		# 在目标section中查找键
		if (current_section == "steamclient" or current_section == "Emulator") and "=" in line:
			var parts = line.split("=", false, 1)
			var key = parts[0].strip_edges()
			if updates.has(key):
				lines[i] = "%s=%s" % [key, updates[key]]
	
	# 保存文件
	file = FileAccess.open(Global.rev_ini, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
		file.close()
		
		# 更新Global
		Global.username = username_edit.text
		Global.teamtip = tip_edit.text
		Global.language = language_edit.text
	else:
		push_error("无法写入配置文件")
