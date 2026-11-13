extends Node2D
# Short burst effect.

const DURATION := 0.4

var size := 16.0
var color := Color("ffcc66")
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
	update()


func _draw() -> void:
	var p := _t / DURATION
	draw_circle(Vector2.ZERO, size * 0.5 * (0.4 + p), Color(color.r, color.g, color.b, 1.0 - p))
	draw_circle(Vector2.ZERO, size * 0.25 * (1.0 - p), Color(1, 1, 1, 1.0 - p))
	for i in range(8):
		var a := i * TAU / 8.0 + size
		var r := size * (0.3 + p)
		draw_rect(Rect2(Vector2(cos(a), sin(a)) * r - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, 1.0 - p))
