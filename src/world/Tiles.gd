extends StaticBody2D
# Room geometry: one collision box per solid block, drawn as beveled brick
# tiles with a colored cap on exposed tops.

const TILE := 16

var theme: Dictionary
var _cells := {}


func setup(solids: Array, room_theme: Dictionary) -> void:
	theme = room_theme
	add_to_group("solid")
	collision_layer = 1
	collision_mask = 0
	for s in solids:
		var rect := Rect2(s[0], s[1], s[2], s[3])
		var shape := RectangleShape2D.new()
		shape.extents = rect.size * TILE / 2.0
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = (rect.position + rect.size / 2.0) * TILE
		add_child(cs)
		for y in range(s[1], s[1] + s[3]):
			for x in range(s[0], s[0] + s[2]):
				_cells[Vector2(x, y)] = true


func _solid(x: float, y: float) -> bool:
	return _cells.has(Vector2(x, y))


func _draw() -> void:
	for cell in _cells:
		var x: float = cell.x
		var y: float = cell.y
		var p: Vector2 = cell * TILE
		draw_rect(Rect2(p, Vector2(TILE, TILE)), theme.tile)
		# Brick seams, offset every other row
		var off := 8 if int(y) % 2 == 1 else 0
		draw_rect(Rect2(p.x, p.y + 7, TILE, 1), theme.tile_dark)
		draw_rect(Rect2(p.x + off, p.y, 1, 7), theme.tile_dark)
		draw_rect(Rect2(p.x + (off + 8) % 16, p.y + 8, 1, 8), theme.tile_dark)
		draw_rect(Rect2(p.x + off + 1, p.y + 1, 5, 1), theme.tile_light)
		if not _solid(x - 1, y):
			draw_rect(Rect2(p.x, p.y, 1, TILE), theme.tile_light)
		if not _solid(x + 1, y):
			draw_rect(Rect2(p.x + TILE - 1, p.y, 1, TILE), theme.tile_dark)
		if not _solid(x, y + 1):
			draw_rect(Rect2(p.x, p.y + TILE - 1, TILE, 1), theme.tile_dark)
		if not _solid(x, y - 1):
			draw_rect(Rect2(p.x, p.y, TILE, 3), theme.top)
			draw_rect(Rect2(p.x, p.y + 3, TILE, 1), theme.tile_dark)
			var h := int(abs(x * 7 + y * 13)) % 12
			draw_rect(Rect2(p.x + h, p.y - 2, 2, 2), theme.top)
			draw_rect(Rect2(p.x + (h + 6) % 14, p.y - 1, 1, 1), theme.top)
