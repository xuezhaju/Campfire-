extends Control
@onready var server_list: Control = $ServerList
@onready var add_server_settings: Control = $AddServerSettings
@onready var setting: Control = $Setting
@onready var background: ColorRect = $Background
@onready var main_color: ColorRect = $Main/MainColor


func _on_server_list_pressed() -> void:
	Global.mainui_mode = "server_list"


func _on_settings_pressed() -> void:
	Global.mainui_mode = "settings"
	print(Global.mainui_mode)


func _on_abaot_pressed() -> void:
	Global.mainui_mode = "abaot"

func _process(delta: float) -> void:
	change_color()
	if Global.mainui_mode == "server_list":
		server_list.show()
		server_list.process_mode = Node.PROCESS_MODE_INHERIT
		add_server_settings.show()
		add_server_settings.process_mode = Node.PROCESS_MODE_INHERIT
		
		setting.hide()
		setting.process_mode = Node.NOTIFICATION_DISABLED
		
	elif Global.mainui_mode == "settings":
		setting.show()
		setting.process_mode = Node.PROCESS_MODE_INHERIT
		# 确保控件在视图最前
		setting.set_as_top_level(true)
		setting.z_index = 100
		
		server_list.hide()
		server_list.process_mode = Node.PROCESS_MODE_DISABLED
		add_server_settings.hide()
		add_server_settings.process_mode = Node.PROCESS_MODE_DISABLED
		
	else:
		server_list.hide()
		server_list.process_mode = Node.PROCESS_MODE_DISABLED
		add_server_settings.hide()
		add_server_settings.process_mode = Node.PROCESS_MODE_DISABLED

func change_color():
	background.color = Global.back_color
	main_color.color = Global.main_color
