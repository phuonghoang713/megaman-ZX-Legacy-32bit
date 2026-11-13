extends CanvasLayer
# Pause screen. Pauses the tree while open; Options opens on top of it.

const Menu = preload("res://src/ui/Menu.gd")
const OptionsMenu = preload("res://src/ui/OptionsMenu.gd")

var menu


func _ready() -> void:
	layer = 20
	pause_mode = PAUSE_MODE_PROCESS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.rect_size = Vector2(398, 224)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	menu = Menu.new()
	menu.handler = self
	menu.title = "PAUSED"
	menu.width = 120
	menu.top = 74
	menu.set_items([["resume", "RESUME"], ["options", "OPTIONS"], ["title", "QUIT TO TITLE"]])
	add_child(menu)


func menu_value(_id: String) -> String:
	return ""


func menu_change(_id: String, _dir: int) -> void:
	pass


func menu_accept(id: String) -> void:
	Audio.play("select")
	match id:
		"resume":
			_resume()
		"options":
			var options = OptionsMenu.new()
			options.base_layer = 21
			options.connect("closed", self, "_on_options_closed")
			add_child(options)
			menu.active = false
			menu.visible = false
		"title":
			Game.save_game()
			Game.to_title()


func menu_cancel() -> void:
	_resume()


func _resume() -> void:
	get_tree().paused = false
	queue_free()


func _on_options_closed() -> void:
	menu.active = true
	menu.visible = true
