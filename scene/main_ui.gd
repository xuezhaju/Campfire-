extends Control


func _on_server_list_pressed() -> void:
	Global.mainui_mode = "server_list"


func _on_setup_settings_pressed() -> void:
	Global.mainui_mode = "setup_settings"


func _on_color_settings_pressed() -> void:
	Global.mainui_mode = "color_settings"
