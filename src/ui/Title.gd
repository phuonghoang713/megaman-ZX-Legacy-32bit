extends Node2D
# Title screen: animated background (drawn in the world canvas, so Smooth
# Colors applies) with the logo and menu on a crisp UI layer.

const Font = preload("res://src/ui/PixelFont.gd")
const Drawer = preload("res://src/ui/Drawer.gd")
const Menu = preload("res://src/ui/Menu.gd")
const OptionsMenu = preload("res://src/ui/OptionsMenu.gd")

var menu
var logo
var t := 0.0
var _stars := []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(60):
		_stars.append(Vector3(rng.randi_range(0, 397), rng.randi_range(0, 140), rng.randf_range(0.2, 1.0)))
	Audio.play_music()

	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	logo = Drawer.new()
	logo.target = self
	logo.method = "_draw_logo"
	ui.add_child(logo)

	menu = Menu.new()
	menu.handler = self
	menu.panel = false
	menu.width = 96
	menu.top = 122
	menu.hint = "ARROWS: MOVE   Z/ENTER: SELECT"
	var items := []
	if Game.has_save():
		items.append(["continue", "CONTINUE"])
	items += [["new", "NEW GAME"], ["options", "OPTIONS"], ["quit", "QUIT"]]
	menu.set_items(items)
	ui.add_child(menu)


func _process(delta: float) -> void:
	t += delta
	update()
	logo.update()


func _draw() -> void:
	# Sky gradient
	for i in range(28):
		draw_rect(Rect2(0, i * 8, 398, 8), Color("070a1c").linear_interpolate(Color("3b2a68"), i / 27.0))
	for s in _stars:
		var twinkle := 0.5 + 0.5 * sin(t * 2.0 + s.x)
		draw_rect(Rect2(s.x, s.y, 1, 1), Color(1, 1, 1, s.z * twinkle))
	# Far mountains
	var far := PoolVector2Array([Vector2(0, 224)])
	for i in range(0, 15):
		far.append(Vector2(i * 30, 150 + (i * 37) % 40))
	far.append(Vector2(398, 224))
	draw_colored_polygon(far, Color("221d48"))
	# Scrolling city of towers
	var scroll := fmod(t * 12.0, 398.0)
	for k in range(2):
		for i in range(12):
			var x := i * 34 - scroll + k * 398
			var h := 40 + (i * 53) % 50
			draw_rect(Rect2(x, 224 - h, 22, h), Color("161233"))
			draw_rect(Rect2(x + 4, 224 - h + 6, 2, 2), Color("ffd36a"))
			draw_rect(Rect2(x + 14, 224 - h + 14, 2, 2), Color("7cf2ff"))
	# Hero silhouette standing on a ledge
	draw_rect(Rect2(272, 176, 80, 48), Color("0d0b22"))
	draw_rect(Rect2(272, 176, 80, 2), Color("7cf2ff"))
	_draw_hero_silhouette(Vector2(310, 164))


func _draw_hero_silhouette(p: Vector2) -> void:
	var c := Color("0d0b22")
	draw_rect(Rect2(p.x - 5, p.y + 3, 4, 9), c)
	draw_rect(Rect2(p.x + 1, p.y + 3, 4, 9), c)
	draw_rect(Rect2(p.x - 5, p.y - 5, 10, 9), c)
	draw_rect(Rect2(p.x - 5, p.y - 13, 10, 8), c)
	draw_colored_polygon(PoolVector2Array([p + Vector2(-4, -13), p + Vector2(-10, -18), p + Vector2(-6, -11)]), c)
	draw_rect(Rect2(p.x + 3, p.y - 3, 8, 4), c)
	var glow := 0.6 + 0.4 * sin(t * 3.0)
	draw_rect(Rect2(p.x, p.y - 10, 4, 2), Color(0.49, 0.95, 1.0, glow))


func _draw_logo(ci: CanvasItem) -> void:
	var bob := round(sin(t * 1.5) * 1.5)
	Font.draw_centered(ci, 200, 38 + bob, "ZX-LEGACY", Color("1d4b63"), 6, false)
	Font.draw_centered(ci, 199, 36 + bob, "ZX-LEGACY", Color("7cf2ff"), 6, false)
	Font.draw_centered(ci, 199, 80, "AN ORIGINAL ACTION PLATFORMER", Color("ffd36a"))
	Font.draw_text(ci, Vector2(4, 214), "PROTOTYPE V0.1", Color(0.45, 0.48, 0.6))


func menu_value(_id: String) -> String:
	return ""


func menu_change(_id: String, _dir: int) -> void:
	pass


func menu_accept(id: String) -> void:
	Audio.play("select")
	match id:
		"continue":
			Game.load_game()
			Game.start_game()
		"new":
			Game.new_game()
			Game.start_game()
		"options":
			var options = OptionsMenu.new()
			options.connect("closed", self, "_on_options_closed")
			add_child(options)
			menu.active = false
			menu.visible = false
		"quit":
			get_tree().quit()


func menu_cancel() -> void:
	pass


func _on_options_closed() -> void:
	menu.active = true
	menu.visible = true
