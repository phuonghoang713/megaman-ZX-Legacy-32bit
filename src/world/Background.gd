extends CanvasLayer
# Three background layers behind the room: a fixed sky gradient, a slow far
# ridge and faster near scenery (trees, pillars or clouds by room theme).
# Scrolled by hand from the camera position (ParallaxBackground is offset
# incorrectly with the "2d" stretch mode in Godot 3).

const Drawer = preload("res://src/ui/Drawer.gd")
const W := 398.0
const FAR_SPEED := 0.15
const NEAR_SPEED := 0.45

var theme: Dictionary
var camera: Camera2D
var _far
var _near


func _ready() -> void:
	layer = -10
	_make_drawer("_sky")
	_far = _make_drawer("_far")
	_near = _make_drawer("_near")


func _make_drawer(method: String):
	var d := Drawer.new()
	d.target = self
	d.method = method
	add_child(d)
	return d


func _process(_delta: float) -> void:
	if camera == null:
		return
	var left := camera.get_camera_screen_center().x - W / 2.0
	_far.position.x = -fposmod(left * FAR_SPEED, W)
	_near.position.x = -fposmod(left * NEAR_SPEED, W)


func _sky(ci: CanvasItem) -> void:
	for i in range(28):
		ci.draw_rect(Rect2(0, i * 8, W, 8), theme.sky_top.linear_interpolate(theme.sky_bottom, i / 27.0))
	if theme.stars:
		for i in range(50):
			ci.draw_rect(Rect2((i * 97) % 398, (i * 53) % 130, 1, 1), Color(1, 1, 1, 0.3 + (i % 5) * 0.12))


# Far and near layers are drawn twice side by side so they tile while scrolling.
func _far(ci: CanvasItem) -> void:
	for copy in range(2):
		var ox := copy * W
		var points := PoolVector2Array([Vector2(ox, 224)])
		var steps := 12
		for i in range(steps + 1):
			var h := 120.0 + ((i % steps) * 41 % 50)
			points.append(Vector2(ox + i * W / steps, h))
		points.append(Vector2(ox + W, 224))
		ci.draw_colored_polygon(points, theme.far)


func _near(ci: CanvasItem) -> void:
	var c: Color = theme.near
	for copy in range(2):
		var ox := copy * W
		match theme.style:
			"trees":
				for i in range(8):
					var x := ox + i * 50.0 + (i * 17) % 20
					var h := 70.0 + (i * 29) % 40
					ci.draw_rect(Rect2(x + 8, 224 - h, 6, h), c.darkened(0.2))
					ci.draw_circle(Vector2(x + 11, 224 - h), 18.0, c)
					ci.draw_circle(Vector2(x + 2, 224 - h + 10), 12.0, c)
					ci.draw_circle(Vector2(x + 21, 224 - h + 8), 13.0, c)
			"pillars":
				for i in range(6):
					var x := ox + i * 66.0 + (i * 23) % 18
					var h := 80.0 + (i * 37) % 60
					ci.draw_rect(Rect2(x, 224 - h, 18, h), c)
					ci.draw_rect(Rect2(x - 3, 224 - h, 24, 5), c.lightened(0.08))
					ci.draw_rect(Rect2(x + 4, 224 - h + 12, 2, h - 12), c.darkened(0.25))
			"clouds":
				for i in range(5):
					var x := ox + i * 80.0 + (i * 31) % 30
					var y := 60.0 + (i * 43) % 70
					ci.draw_circle(Vector2(x, y), 14.0, c.lightened(0.5))
					ci.draw_circle(Vector2(x + 16, y - 6), 18.0, c.lightened(0.55))
					ci.draw_circle(Vector2(x + 34, y), 13.0, c.lightened(0.5))
					ci.draw_rect(Rect2(x - 6, y, 54, 8), c.lightened(0.5))
