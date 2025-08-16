extends Label

@onready var music_line_edit: LineEdit = $MusicLineEdit
@onready var button: Button = $Button
@onready var music_search: FileDialog = $"../../../../../MusicSearch"
@onready var audio_stream_player: AudioStreamPlayer = $"../../../../../AudioStreamPlayer"

func _ready():
	# 初始化时显示当前保存的音乐路径
	if Global.music_path:
		music_line_edit.text = Global.music_path
		load_and_play_music(Global.music_path)
	
	# 连接信号
	music_line_edit.gui_input.connect(_on_music_line_edit_gui_input)
	music_search.file_selected.connect(_on_file_selected)
	button.pressed.connect(_on_button_pressed)

func _on_music_line_edit_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		music_search.popup_centered()

func _on_button_pressed():
	# 保留按钮功能，但可以隐藏按钮如果不需要
	music_search.popup_centered()

func _on_file_selected(path: String):
	# 保存路径到全局变量
	Global.music_path = path
	music_line_edit.text = path
	load_and_play_music(path)

func load_and_play_music(path: String):
	if FileAccess.file_exists(path):
		var audio_stream: AudioStream
		if path.ends_with(".ogg"):
			audio_stream = AudioStreamOggVorbis.load_from_file(path)
		elif path.ends_with(".wav"):
			audio_stream = AudioStreamWAV.load_from_file(path)
		elif path.ends_with(".mp3"):
			audio_stream = AudioStreamMP3.load_from_file(path)
		else:
			push_error("Unsupported audio format")
			return
		
		if audio_stream:
			audio_stream_player.stream = audio_stream
			audio_stream_player.play()
		else:
			push_error("Failed to load audio file")
	else:
		push_error("File not found: " + path)
