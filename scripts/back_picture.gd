extends Label

@onready var picture_line_edit: LineEdit = $PictureLineEdit
@onready var picture_search: FileDialog = $"../../../../../PictureSearch"
@onready var picture: TextureRect = $"../../../../../Picture"
@onready var background: ColorRect = $"../../../../../Background"
@onready var clear: Button = $Clear

func _ready():
	picture_line_edit.text = Global.back_picture_path
	# 确保Global单例已加载
	if not Global.has_signal("settings_changed"):
		push_error("Global 单例未正确初始化！")
		return

	# 连接信号
	Global.settings_changed.connect(update_background_picture)
	
	# 初始化UI
	update_background_picture()
	
	# 连接交互信号
	picture_line_edit.gui_input.connect(_on_back_picture_edit_gui_input)
	picture_search.file_selected.connect(_on_back_picture_file_selected)
	
	# 配置文件对话框
	picture_search.filters = ["*.png ; PNG 图片", "*.jpg, *.jpeg ; JPG 图片"]
	picture_search.access = FileDialog.ACCESS_FILESYSTEM

func _on_back_picture_edit_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picture_search.popup_centered(Vector2i(800, 600))

func update_background_picture():
	if Global.back_picture_path.is_empty():
		picture.texture = null
		if is_instance_valid(background):
			background.show()
		return

	# 立即加载并显示新图片
	load_background_preview(Global.back_picture_path)

func _on_back_picture_file_selected(path: String):
	# 1. 规范化路径
	var normalized_path = path.replace("\\", "/").strip_edges()
	
	# 2. 检查文件是否存在
	if not FileAccess.file_exists(normalized_path):
		show_error("文件不存在: " + normalized_path)
		return
	
	# 3. 检查文件扩展名
	var valid_extensions = ["png", "jpg", "jpeg"]
	var extension = normalized_path.get_extension().to_lower()
	
	if not valid_extensions.has(extension):
		show_error("仅支持 PNG/JPG/JPEG 格式")
		return
	
	# 4. 更新全局路径
	Global.back_picture_path = normalized_path
	picture_line_edit.text = normalized_path
	
	# 5. 立即加载并显示
	load_background_preview(normalized_path)
	
	# 6. 保存设置
	if Global.has_method("save_settings"):
		Global.save_settings()

func load_background_preview(image_path: String):
	print("尝试加载图片: ", image_path)  # 调试输出

	var image = Image.new()
	var error = image.load(image_path)

	if error == OK:
		picture.show()  # 强制显示
		print("TextureRect visible:", picture.visible, " size:", picture.size)
		print("图片加载成功，尺寸: ", image.get_width(), "x", image.get_height())
		
		# 确保图片有有效数据
		if image.get_width() == 0 or image.get_height() == 0:
			push_error("图片尺寸无效!")
			picture.texture = null
			background.show()
			return
			
		var texture = ImageTexture.create_from_image(image)
		picture.texture = texture

		# 确保TextureRect设置正确
		picture.expand = true
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

		if is_instance_valid(background):
			background.hide()
	else:
		push_error("图片加载失败，错误码: ", error)
		picture.texture = null
		if is_instance_valid(background):
			background.show()

func show_error(message: String):
	printerr(message)
	# 这里可以添加UI错误提示，例如：
	# $ErrorLabel.text = message
	# $ErrorLabel.show()
	# await get_tree().create_timer(3.0).timeout
	# $ErrorLabel.hide()


func _on_clear_pressed() -> void:
	picture_line_edit.text = ""
	Global.back_picture_path = ""
	Global.save_settings()
	Global.load_settings()
