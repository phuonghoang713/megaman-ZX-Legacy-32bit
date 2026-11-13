extends "res://src/actors/Enemy.gd"
# Boss: a hulking gate guardian. Wakes when the hero approaches, then hops
# toward them and fires spread volleys. Faster with more shots below half life.

var state := "sleep"
var timer := 0.0
var awake := false
var facing := -1


func _init() -> void:
	hp = 28
	size = Vector2(26, 30)
	contact_damage = 3
	drop_chance = 0.0


func angry() -> bool:
	return hp <= max_hp / 2


func _behave(delta: float) -> void:
	var player = world.player
	vel.y = min(vel.y + 900.0 * delta, 400.0)
	timer -= delta
	var dx: float = player.global_position.x - global_position.x
	match state:
		"sleep":
			vel.x = 0.0
			if player.alive and abs(dx) < 170.0:
				state = "intro"
				timer = 1.2
				awake = true
				Audio.play("core")
				world.on_boss_awake()
		"intro":
			if timer <= 0.0:
				state = "idle"
				timer = 0.6
		"idle":
			vel.x = 0.0
			if dx != 0.0:
				facing = int(sign(dx))
			if timer <= 0.0:
				state = "hop"
				timer = 0.2
				vel.y = -330.0
				vel.x = clamp(dx * 1.2, -110.0, 110.0)
		"hop":
			if is_on_floor() and timer <= 0.0:
				state = "shoot"
				timer = 0.25
				vel.x = 0.0
		"shoot":
			if timer <= 0.0:
				_volley()
				state = "idle"
				timer = 0.5 if angry() else 0.9
	vel = move_and_slide(vel, Vector2.UP)


func _volley() -> void:
	var player = world.player
	var aim: Vector2 = (player.global_position - global_position).normalized()
	var spread := [-0.5, -0.25, 0.0, 0.25, 0.5] if angry() else [-0.3, 0.0, 0.3]
	for a in spread:
		world.spawn_shot(global_position + Vector2(facing * 12, -6), aim.rotated(a) * 130.0, 2, 3.5, Color("ff6040"), "orb", false, "enemy")
	Audio.play("shot_mid")


func hit(damage: int, source = null) -> void:
	if not awake:
		return
	.hit(damage, source)


func _on_die() -> void:
	world.on_boss_defeated(global_position)


func _paint() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var armor := tint(Color("4a5a7a"))
	var plate := tint(Color("9ab0d0"))
	var dark := tint(Color("232a3c"))
	var eye := tint(Color("ff9a3a") if angry() else Color("ff4a4a"))
	if not awake:
		eye = Color("3a2020")
	var crouch := 2 if state == "shoot" else 0
	# Legs
	draw_rect(Rect2(-11, 8 + crouch, 7, 7 - crouch), dark)
	draw_rect(Rect2(4, 8 + crouch, 7, 7 - crouch), dark)
	draw_rect(Rect2(-13, 13, 10, 2), plate)
	draw_rect(Rect2(3, 13, 10, 2), plate)
	# Body
	draw_colored_polygon(PoolVector2Array([Vector2(-12, -10 + crouch), Vector2(12, -10 + crouch), Vector2(10, 9), Vector2(-10, 9)]), armor)
	draw_rect(Rect2(-12, -10 + crouch, 24, 2), plate)
	# Shoulders
	draw_rect(Rect2(-16, -12 + crouch, 7, 9), plate)
	draw_rect(Rect2(9, -12 + crouch, 7, 9), plate)
	draw_rect(Rect2(10, -3 + crouch, 5, 6), dark)
	# Head with a single eye
	draw_rect(Rect2(-6, -15 + crouch, 12, 6), armor)
	draw_rect(Rect2(-6, -15 + crouch, 12, 1), plate)
	draw_rect(Rect2(0, -13 + crouch, 5, 3), eye)
	if state == "intro" and int(t * 12.0) % 2 == 0:
		draw_rect(Rect2(-1, -14 + crouch, 7, 5), Color(1, 1, 1, 0.6))
	# Chest vent
	for i in range(3):
		draw_rect(Rect2(-6, -4 + i * 3 + crouch, 12, 1), dark)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
