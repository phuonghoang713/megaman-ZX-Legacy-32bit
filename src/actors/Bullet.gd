extends Area2D
# A projectile from the hero ("player" team) or an enemy ("enemy" team).
# Pierce shots pass through enemies; every shot stops at walls.

var vel := Vector2.ZERO
var damage := 1
var radius := 3.0
var color := Color.white
var kind := "pellet"   # pellet, orb, fire, blade
var pierce := false
var team := "player"
var life := 1.3
var _t := 0.0
var _hit := []


func _ready() -> void:
	add_to_group(team + "_shot")
	collision_layer = 0
	collision_mask = 1 | (4 if team == "player" else 2)
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	connect("body_entered", self, "_on_body_entered")


func _physics_process(delta: float) -> void:
	_t += delta
	position += vel * delta
	life -= delta
	if life <= 0.0:
		queue_free()
	update()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("solid"):
		_pop()
	elif team == "player" and body.is_in_group("enemy"):
		if body in _hit or body.dead:
			return
		_hit.append(body)
		body.hit(damage, self)
		if not pierce:
			_pop()
	elif team == "enemy" and body.is_in_group("player"):
		body.take_damage(damage, global_position.x)
		_pop()


func _pop() -> void:
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	match kind:
		"pellet":
			draw_circle(Vector2.ZERO, radius, color)
			draw_rect(Rect2(-1, -1, 2, 2), Color(1, 1, 1))
		"orb":
			var pulse := 1.0 if int(_t * 20.0) % 2 == 0 else 0.0
			draw_circle(Vector2.ZERO, radius + pulse, color)
			draw_circle(Vector2.ZERO, radius * 0.55, Color(1, 1, 1))
			draw_rect(Rect2(-vel.normalized().x * radius * 2.0 - 1, -1, 3, 2), Color(color.r, color.g, color.b, 0.6))
		"fire":
			var flick := 1.0 if int(_t * 24.0) % 2 == 0 else 0.0
			draw_circle(Vector2.ZERO, radius + flick, color)
			draw_circle(Vector2(-sign(vel.x) * 1.0, 0), radius * 0.6, Color("ffe36a"))
			draw_circle(Vector2(-sign(vel.x) * radius, flick - 1.0), radius * 0.5, color.darkened(0.2))
		"blade":
			draw_set_transform(Vector2.ZERO, vel.angle(), Vector2.ONE)
			draw_colored_polygon(PoolVector2Array([Vector2(radius * 1.6, 0), Vector2(0, -radius * 0.7), Vector2(-radius, 0), Vector2(0, radius * 0.7)]), color)
			draw_rect(Rect2(-radius * 0.5, -0.5, radius * 1.5, 1), Color(1, 1, 1))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
