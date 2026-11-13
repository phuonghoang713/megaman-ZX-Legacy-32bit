extends CanvasLayer
# Life bar, current core, boss life bar, room name and on-screen messages.
# Layer 1: drawn above the Smooth Colors layer, so it stays crisp.

const Font = preload("res://src/ui/PixelFont.gd")
const Drawer = preload("res://src/ui/Drawer.gd")

var world
var boss = null
var message := ""
var message_t := 0.0
var room_name := ""
var room_name_t := 0.0
var _drawer


func _ready() -> void:
	layer = 1
	_drawer = Drawer.new()
	_drawer.target = self
	_drawer.method = "_paint"
	add_child(_drawer)


func show_message(text: String, time := 3.0) -> void:
	message = text
	message_t = time


func show_room_name(text: String) -> void:
	room_name = text
	room_name_t = 2.5


func _process(delta: float) -> void:
	message_t = max(0.0, message_t - delta)
	room_name_t = max(0.0, room_name_t - delta)
	_drawer.update()


func _paint(ci: CanvasItem) -> void:
	var player = world.player
	var core: Dictionary = Game.CORES[Game.core]

	# Life bar
	var x := 8
	var y := 22
	var h: int = player.max_hp * 3 + 3
	ci.draw_rect(Rect2(x, y, 9, h), Color(0.04, 0.05, 0.1, 0.9))
	ci.draw_rect(Rect2(x, y, 9, h), core.trim, false)
	for i in range(player.max_hp):
		var seg_y: int = y + h - 3 - i * 3
		var color: Color = core.visor if i < player.hp else Color(0.18, 0.2, 0.26)
		ci.draw_rect(Rect2(x + 2, seg_y, 5, 2), color)
	# Core badge
	ci.draw_rect(Rect2(x - 1, y + h + 2, 11, 9), core.body)
	ci.draw_rect(Rect2(x - 1, y + h + 2, 11, 9), core.dark, false)
	Font.draw_text(ci, Vector2(x + 3, y + h + 4), core.name.left(1), core.dark, 1, false)
	Font.draw_text(ci, Vector2(8, 8), core.name + " CORE", core.visor)
	if Game.unlocked.size() > 1:
		Font.draw_text(ci, Vector2(8 + Font.width(core.name + " CORE") + 6, 8),
			Settings.key_name("core_prev") + "/" + Settings.key_name("core_next"), Color(0.55, 0.6, 0.7))

	# Boss life bar
	if boss != null and is_instance_valid(boss) and boss.awake:
		var bh: int = boss.max_hp * 2 + 3
		var bx := 381
		ci.draw_rect(Rect2(bx, y, 9, bh), Color(0.04, 0.05, 0.1, 0.9))
		ci.draw_rect(Rect2(bx, y, 9, bh), Color("ff6a4a"), false)
		for i in range(boss.max_hp):
			var col: Color = Color("ff6a4a") if i < boss.hp else Color(0.2, 0.15, 0.18)
			ci.draw_rect(Rect2(bx + 2, y + bh - 2 - i * 2 - 1, 5, 1), col)

	# Room name, top right
	if room_name_t > 0.0:
		var a: float = min(1.0, room_name_t * 2.0)
		Font.draw_text(ci, Vector2(390 - Font.width(room_name), 8), room_name, Color(1, 1, 1, a))

	# Message box
	if message_t > 0.0:
		var alpha: float = min(1.0, message_t * 2.0)
		var lines := message.split("\n")
		var w := Font.width(message) + 16
		var box_h := lines.size() * 7 + 10
		var box := Rect2(199 - w / 2, 34, w, box_h)
		ci.draw_rect(box, Color(0.02, 0.03, 0.08, 0.85 * alpha))
		ci.draw_rect(box, Color(0.41, 0.79, 1.0, alpha), false)
		for i in range(lines.size()):
			Font.draw_centered(ci, 199, 40 + i * 7, lines[i], Color(1, 1, 1, alpha))
