extends StaticBody2D
# Boss shutter. Solid until open() is called.

var rect := Rect2()   # pixels
var _open_t := -1.0


func _ready() -> void:
	add_to_group("solid")
	add_to_group("boss_door")
	collision_layer = 1
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.extents = rect.size / 2.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = rect.position + rect.size / 2.0
	add_child(cs)


func open() -> void:
	if _open_t >= 0.0:
		return
	_open_t = 0.0
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)


func _process(delta: float) -> void:
	if _open_t >= 0.0:
		_open_t += delta
		if _open_t > 0.6:
			queue_free()
		update()


func _draw() -> void:
	var h := rect.size.y
	if _open_t >= 0.0:
		h *= max(0.0, 1.0 - _open_t / 0.6)
	var r := Rect2(rect.position, Vector2(rect.size.x, h))
	draw_rect(r, Color("3a3f55"))
	var y := 0.0
	while y < h:
		draw_rect(Rect2(r.position.x, r.position.y + y, r.size.x, 2), Color("8890b0"))
		y += 6.0
	draw_rect(Rect2(r.position.x, r.position.y, 2, h), Color("ffcc33"))
	draw_rect(Rect2(r.end.x - 2, r.position.y, 2, h), Color("ffcc33"))
