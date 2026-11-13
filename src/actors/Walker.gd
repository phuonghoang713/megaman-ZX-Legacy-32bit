extends "res://src/actors/Enemy.gd"
# Shell beetle: patrols, turning around at walls and ledges.

var dir := -1


func _init() -> void:
	hp = 3
	size = Vector2(16, 12)
	contact_damage = 2


func _behave(delta: float) -> void:
	vel.y = min(vel.y + 900.0 * delta, 300.0)
	vel.x = dir * 30.0
	vel = move_and_slide(vel, Vector2.UP)
	if is_on_wall():
		dir = -dir
	elif is_on_floor() and not test_move(global_transform.translated(Vector2(dir * 9, 0)), Vector2(0, 4)):
		dir = -dir


func _paint() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	var shell := tint(Color("c8742c"))
	var dark := tint(Color("6b3518"))
	var eye := tint(Color("ff4a3a"))
	var s := int(t * 8.0) % 2
	draw_rect(Rect2(-6, 2 + s, 3, 4 - s), dark)
	draw_rect(Rect2(3, 3 - s, 3, 3 + s), dark)
	draw_rect(Rect2(-8, -2, 16, 5), shell)
	draw_rect(Rect2(-6, -5, 12, 3), shell)
	draw_rect(Rect2(-3, -6, 6, 1), shell.lightened(0.3))
	draw_rect(Rect2(-8, 2, 16, 1), dark)
	draw_rect(Rect2(-5, -7, 1, 2), dark)
	draw_rect(Rect2(-1, -8, 1, 2), dark)
	draw_rect(Rect2(4, -1, 3, 2), eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
