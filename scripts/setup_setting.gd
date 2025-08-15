extends Control

@onready var setting: Control = $"."  # 引用自身

func _ready():
	# 初始隐藏设置界面
	setting.hide()
	setting.process_mode = Node.PROCESS_MODE_DISABLED
