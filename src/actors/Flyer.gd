extends "res://src/actors/Enemy.gd"
# Moth drone: bobs in the air, drifts toward the hero and fires slow pellets.

var base_y := 0.0
var started := false
var fire_t := 2.0
var facing := -1


func _init() -> void:
	hp = 2
	size = Vector2(14, 12)
	contact_damage = 2
	drop_chance = 0.3


func _behave(delta: float) -> void:
	if not started:
		base_y = position.y
		started = true
	var player = world.player
	var dx: float = player.global_position.x - global_position.x
	if player.alive and abs(dx) < 180.0:
		vel.x = move_toward(vel.x, sign(dx) * 35.0, 60.0 * delta)
		if dx != 0.0:
			facing = int(sign(dx))
	else:
		vel.x = move_toward(vel.x, 0.0, 60.0 * delta)
	position.x += vel.x * delta
	position.y = base_y + sin(t * 2.4) * 10.0
	fire_t -= delta
	if fire_t <= 0.0:
		fire_t = 2.6
		if player.alive and global_position.distance_to(player.global_position) < 170.0:
			var aim: Vector2 = (player.global_position - global_position).normalized() * 90.0
			world.spawn_shot(global_position + Vector2(0, 4), aim, 2, 2.5, Color("ff70d0"), "pellet", false, "enemy")


func _paint() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var body := tint(Color("7a5ac8"))
	var wing := tint(Color("c9b6ff"))
	var flap := (int(t * 12.0) % 2) * 4
	draw_colored_polygon(PoolVector2Array([Vector2(-3, -2), Vector2(-10, -7 + flap), Vector2(-6, 1)]), wing)
	draw_colored_polygon(PoolVector2Array([Vector2(1, -2), Vector2(8, -7 + flap), Vector2(4, 1)]), wing.darkened(0.15))
	draw_rect(Rect2(-5, -4, 10, 7), body)
	draw_rect(Rect2(-4, 3, 8, 2), body.darkened(0.3))
	draw_rect(Rect2(1, -2, 3, 3), tint(Color("ffe14a")))
	draw_rect(Rect2(-1, -6, 1, 2), body.darkened(0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
