extends Control
@onready var server_list: Control = $ServerList
@onready var add_server_settings: Control = $AddServerSettings
@onready var setting: Control = $Setting
@onready var background: ColorRect = $Background
@onready var main_color: ColorRect = $Main/MainColor
@onready var picture: TextureRect = $Picture
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var about_ui: Control = $AboutUI


var is_about :bool = false

func _ready() -> void:
	# 调试输出
	print("Initializing main UI...")
	
	# 音频设置
	if Global.music_path != "":
		audio_stream_player.play()
	else:
		audio_stream_player.stop()
	
	# 背景图片设置
	if Global.back_picture_path == "":
		picture.hide()
		picture.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		picture.show()
		picture.process_mode = Node.PROCESS_MODE_INHERIT
	
	# 初始化界面
	_update_ui()
	
	# 打印初始状态
	print("Initial UI mode: ", Global.mainui_mode)

func _on_server_list_pressed() -> void:
	print("Server list button pressed")
	Global.mainui_mode = "server_list"
	is_about = false
	_update_ui()

func _on_settings_pressed() -> void:
	print("Settings button pressed")
	Global.mainui_mode = "settings"
	is_about = false
	_update_ui()

func _on_about_pressed() -> void:
	print("About button pressed")
	Global.mainui_mode = "about"
	is_about = true
	_update_ui()

func _process(delta: float) -> void:
	change_color()

func _update_ui():
	print("Updating UI to mode: ", Global.mainui_mode)
	
	# 先隐藏所有界面
	server_list.hide()
	server_list.process_mode = Node.PROCESS_MODE_DISABLED
	add_server_settings.hide()
	add_server_settings.process_mode = Node.PROCESS_MODE_DISABLED
	setting.hide()
	setting.process_mode = Node.PROCESS_MODE_DISABLED
	about_ui.hide()
	about_ui.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 根据模式显示对应界面
	match Global.mainui_mode:
		"server_list":
			server_list.show()
			server_list.process_mode = Node.PROCESS_MODE_INHERIT
			add_server_settings.show()
			add_server_settings.process_mode = Node.PROCESS_MODE_INHERIT
			
		"settings":
			Global.save_settings()
			setting.show()
			setting.process_mode = Node.PROCESS_MODE_INHERIT
			setting.set_as_top_level(true)
			setting.z_index = 100
			
		"about":
			about_ui.show()
			about_ui.process_mode = Node.PROCESS_MODE_INHERIT
			about_ui.z_index = 1
	
	# 强制重绘
	queue_redraw()

func change_color():
	background.color = Global.back_color
	main_color.color = Global.main_color
