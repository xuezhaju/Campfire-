extends Control
@onready var server_list: Control = $ServerList
@onready var add_server_settings: Control = $AddServerSettings


func _on_server_list_pressed() -> void:
	Global.mainui_mode = "server_list"


func _on_setup_settings_pressed() -> void:
	Global.mainui_mode = "setup_settings"


func _on_color_settings_pressed() -> void:
	Global.mainui_mode = "color_settings"

func _process(delta: float) -> void:
	if Global.mainui_mode == "server_list":
		server_list.show()
		server_list.process_mode = Node.PROCESS_MODE_INHERIT
		add_server_settings.show()
		add_server_settings.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		server_list.hide()
		server_list.process_mode = Node.PROCESS_MODE_DISABLED
		add_server_settings.hide()
		add_server_settings.process_mode = Node.PROCESS_MODE_DISABLED
