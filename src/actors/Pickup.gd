extends Area2D
# Collectibles: health capsules, cores and the stage goal.

var kind := "health"   # health, small_health, core_ember, core_gale, goal
var world
var _t := 0.0
var _life := -1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	connect("body_entered", self, "_on_body_entered")
	if kind == "small_health":
		_life = 6.0


func _process(delta: float) -> void:
	_t += delta
	if _life > 0.0:
		_life -= delta
		if _life <= 0.0:
			queue_free()
	update()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.alive:
		Audio.play("pickup")
		world.on_pickup(kind)
		set_deferred("monitoring", false)
		queue_free()


func _draw() -> void:
	if _life > 0.0 and _life < 2.0 and int(_t * 12.0) % 2 == 0:
		return
	var bob := round(sin(_t * 3.0) * 2.0)
	match kind:
		"health", "small_health":
			var s := 1.0 if kind == "small_health" else 1.5
			var r := Rect2(-3 * s, -4 * s + bob, 6 * s, 8 * s)
			draw_rect(r, Color("e8f4ff"))
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y / 2.0, r.size.x, r.size.y / 2.0), Color("ff5a6a"))
			draw_rect(r, Color("2a3550"), false)
		"core_ember", "core_gale":
			var c: Dictionary = Game.CORES[kind.substr(5)]
			draw_arc(Vector2(0, bob), 9.0 + sin(_t * 6.0) * 1.5, 0.0, TAU, 16, c.visor, 1.0)
			draw_circle(Vector2(0, bob), 6.0, c.body)
			draw_circle(Vector2(0, bob), 3.0, c.visor)
			draw_rect(Rect2(-2, -3 + bob, 1, 1), Color(1, 1, 1))
		"goal":
			var glow := Color.from_hsv(fmod(_t * 0.3, 1.0), 0.4, 1.0)
			draw_colored_polygon(PoolVector2Array([Vector2(0, -14 + bob), Vector2(7, bob), Vector2(0, 14 + bob), Vector2(-7, bob)]), glow)
			draw_colored_polygon(PoolVector2Array([Vector2(0, -8 + bob), Vector2(3, bob), Vector2(0, 8 + bob), Vector2(-3, bob)]), Color(1, 1, 1))
			draw_arc(Vector2(0, bob), 16.0 + sin(_t * 4.0) * 2.0, 0.0, TAU, 20, Color(glow.r, glow.g, glow.b, 0.5), 1.0)
