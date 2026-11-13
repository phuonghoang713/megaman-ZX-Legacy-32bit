extends Node2D
# Keyboard/gamepad list menu. The handler object supplies the behavior:
#   menu_value(id) -> String, menu_change(id, dir), menu_accept(id), menu_cancel()
# Up/Down move, Left/Right change a value, Z/Enter accept, X/Esc go back.

const Font = preload("res://src/ui/PixelFont.gd")
const IDLE := Color(0.41, 0.79, 1.0)
const FOCUS := Color(0.98, 1.0, 0.69)
const VALUE := Color(0.82, 0.84, 0.9)

var handler: Object
var items := []   # [[id, label], ...]
var cursor := 0
var active := true
var title := ""
var hint := ""
var width := 200
var top := 60
var panel := true


func set_items(list: Array, keep_cursor := false) -> void:
	items = list
	if not keep_cursor:
		cursor = 0
	cursor = int(clamp(cursor, 0, max(0, items.size() - 1)))
	update()


func current_id() -> String:
	return items[cursor][0] if not items.empty() else ""


func _input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree() or items.empty():
		return
	var id := current_id()
	if event.is_action_pressed("ui_up", true):
		cursor = wrapi(cursor - 1, 0, items.size())
		Audio.play("select")
	elif event.is_action_pressed("ui_down", true):
		cursor = wrapi(cursor + 1, 0, items.size())
		Audio.play("select")
	elif event.is_action_pressed("ui_left", true):
		handler.menu_change(id, -1)
	elif event.is_action_pressed("ui_right", true):
		handler.menu_change(id, 1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		handler.menu_accept(id)
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("shoot"):
		handler.menu_cancel()
	else:
		return
	get_tree().set_input_as_handled()
	update()


func _draw() -> void:
	var x0 := int((398 - width) / 2)
	var height := items.size() * 11 + 8 + (16 if title != "" else 0)
	if panel:
		draw_rect(Rect2(x0 - 10, top - 6, width + 20, height), Color(0.02, 0.03, 0.08, 0.88))
		draw_rect(Rect2(x0 - 10, top - 6, width + 20, height), IDLE.darkened(0.5), false)
	var y := top
	if title != "":
		Font.draw_centered(self, 199, y, title, IDLE, 2)
		y += 16
	for i in range(items.size()):
		var id: String = items[i][0]
		var focused := i == cursor and active
		var color := FOCUS if focused else IDLE
		if focused:
			Font.draw_text(self, Vector2(x0 - 7, y), ">", FOCUS)
		Font.draw_text(self, Vector2(x0, y), items[i][1], color)
		var value: String = handler.menu_value(id)
		if value != "":
			Font.draw_text(self, Vector2(x0 + width - Font.width(value), y), value, FOCUS if focused else VALUE)
		y += 11
	if hint != "":
		Font.draw_centered(self, 199, 212, hint, Color(0.55, 0.58, 0.7))
