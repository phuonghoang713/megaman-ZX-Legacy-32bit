extends KinematicBody2D
# Base enemy: life, hit flash, contact damage, death explosion and drops.
# Subclasses set stats in _init() and implement _behave(delta) and _paint().
# (Godot 3 calls _ready/_physics_process/_draw on every class in the chain,
# so subclasses must not define those.)

var world
var hp := 3
var max_hp := 3
var size := Vector2(14, 12)
var contact_damage := 2
var drop_chance := 0.25
var vel := Vector2.ZERO
var flash := 0.0
var dead := false
var t := 0.0


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	max_hp = hp
	var shape := RectangleShape2D.new()
	shape.extents = size / 2.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func get_rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)


func hit(damage: int, _source = null) -> void:
	if dead:
		return
	hp -= damage
	flash = 0.08
	Audio.play("hit")
	if hp <= 0:
		die()


func die() -> void:
	dead = true
	world.explode(global_position, max(size.x, size.y))
	Audio.play("explode")
	if randf() < drop_chance:
		world.spawn_pickup("small_health", global_position)
	if has_method("_on_die"):
		call("_on_die")
	queue_free()


func tint(color: Color) -> Color:
	return Color(1, 1, 1) if flash > 0.0 else color


func _physics_process(delta: float) -> void:
	if dead:
		return
	t += delta
	flash = max(0.0, flash - delta)
	_behave(delta)
	var player = world.player
	if player.alive and get_rect().intersects(player.get_rect()):
		player.take_damage(contact_damage, global_position.x)
	update()


func _behave(_delta: float) -> void:
	pass


func _draw() -> void:
	_paint()


func _paint() -> void:
	pass
