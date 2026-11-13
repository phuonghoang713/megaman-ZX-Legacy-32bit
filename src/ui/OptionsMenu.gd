extends CanvasLayer
# Options screen: Smooth Colors, CRT filter, window, audio and key remapping.
# Opened from the title screen and the pause menu.

signal closed

const Menu = preload("res://src/ui/Menu.gd")

const MAIN_ITEMS := [
	["smooth", "SMOOTH COLORS"], ["crt", "CRT FILTER"], ["window", "WINDOW SIZE"],
	["fullscreen", "FULLSCREEN"], ["music", "MUSIC VOLUME"], ["sfx", "SOUND VOLUME"],
	["controls", "CONTROLS"], ["back", "BACK"],
]
const CRT_NAMES := ["OFF", "LIGHT", "STRONG"]

var base_layer := 10
var menu
var mode := "main"
var waiting := ""


func _ready() -> void:
	layer = base_layer
	pause_mode = PAUSE_MODE_PROCESS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.rect_size = Vector2(398, 224)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	menu = Menu.new()
	menu.handler = self
	menu.width = 230
	add_child(menu)
	_show_main()


func _show_main(cursor := 0) -> void:
	mode = "main"
	menu.title = "OPTIONS"
	menu.top = 40
	menu.hint = "ARROWS: CHANGE   Z: SELECT   X: BACK"
	menu.set_items(MAIN_ITEMS)
	menu.cursor = cursor


func _show_controls() -> void:
	mode = "controls"
	var list := []
	for action in Settings.ACTION_ORDER:
		list.append([action, Settings.ACTION_NAMES[action]])
	list.append(["reset", "RESET TO DEFAULTS"])
	list.append(["back", "BACK"])
	menu.title = "CONTROLS"
	menu.top = 22
	menu.hint = "Z: REMAP KEY   X: BACK   ESC: CANCEL REMAP"
	menu.set_items(list)


func menu_value(id: String) -> String:
	match id:
		"smooth":
			return "ON" if Settings.get_value("smooth") else "OFF"
		"crt":
			return CRT_NAMES[Settings.get_value("crt")]
		"window":
			return str(Settings.get_value("window_scale")) + "X"
		"fullscreen":
			return "ON" if Settings.get_value("fullscreen") else "OFF"
		"music":
			return str(Settings.get_value("music_volume")) + "/10"
		"sfx":
			return str(Settings.get_value("sfx_volume")) + "/10"
	if mode == "controls" and Settings.DEFAULT_KEYS.has(id):
		return "PRESS A KEY..." if waiting == id else Settings.key_name(id)
	return ""


func menu_change(id: String, dir: int) -> void:
	match id:
		"smooth":
			Settings.set_value("smooth", not Settings.get_value("smooth"))
		"crt":
			Settings.set_value("crt", wrapi(Settings.get_value("crt") + dir, 0, CRT_NAMES.size()))
		"window":
			var top := Settings.max_window_scale()
			Settings.set_value("window_scale", wrapi(Settings.get_value("window_scale") - 1 + dir, 0, top) + 1)
		"fullscreen":
			Settings.set_value("fullscreen", not Settings.get_value("fullscreen"))
		"music":
			Settings.set_value("music_volume", int(clamp(Settings.get_value("music_volume") + dir, 0, 10)))
		"sfx":
			Settings.set_value("sfx_volume", int(clamp(Settings.get_value("sfx_volume") + dir, 0, 10)))
			Audio.play("shot")
			return
		_:
			return
	Audio.play("select")


func menu_accept(id: String) -> void:
	Audio.play("select")
	match id:
		"controls":
			_show_controls()
		"back":
			if mode == "controls":
				_show_main(MAIN_ITEMS.size() - 2)
			else:
				emit_signal("closed")
				queue_free()
		"reset":
			Settings.reset_keys()
		_:
			if mode == "controls":
				waiting = id
				menu.active = false
			else:
				menu_change(id, 1)
	menu.update()


func menu_cancel() -> void:
	menu_accept("back")


func _input(event: InputEvent) -> void:
	if waiting == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode != KEY_ESCAPE:
			Settings.remap(waiting, event.scancode)
		waiting = ""
		menu.active = true
		menu.update()
		get_tree().set_input_as_handled()
