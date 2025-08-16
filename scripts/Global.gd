extends Node

var mainui_mode :String = "server_list"
var is_create :bool = false

var back_color := Color(0.506, 0.776, 0.898)
var main_color := Color(0.333, 0.635, 0.769)

signal font_color_changed
var font_color := Color(0.996, 1.0, 1.0):
	set(value):
		if font_color != value:
			font_color = value
			font_color_changed.emit()
