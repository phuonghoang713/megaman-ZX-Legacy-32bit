extends KinematicBody2D
# Kite, the hero. Run, variable-height jump, ground dash, dash-jump, wall
# slide/kick, charge shot (3 levels) and a melee slash. The equipped core
# (Game.CORES) recolors the armor and changes shots and air abilities.

const GRAVITY := 900.0
const RUN_SPEED := 90.0
const DASH_SPEED := 170.0
const JUMP_SPEED := 300.0
const MAX_FALL := 330.0
const WALL_SLIDE := 60.0
const DASH_TIME := 0.35
const WALL_KICK_TIME := 0.12
const COYOTE_TIME := 0.08
const CHARGE_1 := 0.45
const CHARGE_2 := 1.1
const SLASH_TIME := 0.22
const HALF := Vector2(6, 11)

var world
var vel := Vector2.ZERO
var facing := 1
var alive := true
var max_hp := 16
var hp := 16
var on_floor := false

var dash_t := 0.0
var air_dash := false
var dash_momentum := false
var kick_t := 0.0
var kick_dir := 0
var wall_dir := 0
var coyote_t := 0.0
var air_jumps := 0
var air_dashes := 0

var charge := 0.0
var charging := false
var shoot_t := 0.0
var slash_t := 0.0
var slash_hits := []

var invuln := 0.0
var hurt_t := 0.0
var anim_t := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := RectangleShape2D.new()
	shape.extents = HALF
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func get_rect() -> Rect2:
	return Rect2(global_position - HALF, HALF * 2)


func reset() -> void:
	alive = true
	visible = true
	hp = max_hp
	vel = Vector2.ZERO
	invuln = 1.0
	hurt_t = 0.0
	charge = 0.0
	charging = false
	dash_t = 0.0
	kick_t = 0.0
	slash_t = 0.0
	dash_momentum = false


func _physics_process(delta: float) -> void:
	if not alive:
		return
	anim_t += delta
	invuln = max(0.0, invuln - delta)
	hurt_t = max(0.0, hurt_t - delta)
	shoot_t = max(0.0, shoot_t - delta)
	var x_in := 0
	if hurt_t <= 0.0:
		x_in = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))

	on_floor = is_on_floor()
	if on_floor:
		coyote_t = COYOTE_TIME
		dash_momentum = false
		air_jumps = 1 if Game.core == "gale" else 0
		air_dashes = 1 if Game.core == "gale" else 0
	else:
		coyote_t = max(0.0, coyote_t - delta)

	_switch_core()
	_dash(x_in, delta)
	_horizontal(x_in, delta)
	_wall(x_in)
	_vertical(delta)
	_jump()
	vel = move_and_slide(vel, Vector2.UP)
	_attacks(delta)
	update()


func _switch_core() -> void:
	var dir := 0
	if Input.is_action_just_pressed("core_next"):
		dir = 1
	elif Input.is_action_just_pressed("core_prev"):
		dir = -1
	if dir == 0 or Game.unlocked.size() < 2:
		return
	var i: int = Game.unlocked.find(Game.core)
	Game.core = Game.unlocked[wrapi(i + dir, 0, Game.unlocked.size())]
	charge = 0.0
	Audio.play("core")


func _dash(x_in: int, delta: float) -> void:
	if hurt_t > 0.0:
		dash_t = 0.0
		return
	if Input.is_action_just_pressed("dash"):
		if on_floor:
			dash_t = DASH_TIME
			air_dash = false
			Audio.play("dash")
		elif air_dashes > 0 and wall_dir == 0:
			air_dashes -= 1
			dash_t = DASH_TIME * 0.75
			air_dash = true
			dash_momentum = true
			Audio.play("dash")
	if dash_t > 0.0:
		dash_t -= delta
		if not air_dash:
			if not Input.is_action_pressed("dash"):
				dash_t = 0.0
			elif not on_floor:
				# Ran off a ledge mid-dash: keep the speed in the air.
				dash_momentum = true
				dash_t = 0.0
		if x_in != 0 and x_in != facing:
			dash_t = 0.0
		if dash_t <= 0.0:
			air_dash = false


func _horizontal(x_in: int, delta: float) -> void:
	if kick_t > 0.0:
		kick_t -= delta
		vel.x = kick_dir * (DASH_SPEED if dash_momentum else RUN_SPEED)
		return
	if hurt_t > 0.0:
		vel.x = move_toward(vel.x, 0.0, 300.0 * delta)
		return
	if x_in != 0:
		facing = x_in
	if dash_t > 0.0:
		vel.x = facing * DASH_SPEED
	else:
		vel.x = x_in * (DASH_SPEED if dash_momentum else RUN_SPEED)


func _wall(x_in: int) -> void:
	wall_dir = 0
	if not on_floor and x_in != 0 and kick_t <= 0.0 and test_move(global_transform, Vector2(x_in * 2, 0)):
		wall_dir = x_in
		air_dash = false
		dash_t = 0.0


func _vertical(delta: float) -> void:
	if air_dash and dash_t > 0.0:
		vel.y = 0.0
		return
	vel.y += GRAVITY * delta
	if wall_dir != 0 and vel.y > WALL_SLIDE:
		vel.y = WALL_SLIDE
	vel.y = min(vel.y, MAX_FALL)


func _jump() -> void:
	if hurt_t > 0.0:
		return
	if Input.is_action_just_pressed("jump"):
		if on_floor or coyote_t > 0.0:
			vel.y = -JUMP_SPEED
			coyote_t = 0.0
			dash_momentum = dash_momentum or dash_t > 0.0
			dash_t = 0.0
			Audio.play("jump")
		elif wall_dir != 0:
			vel.y = -JUMP_SPEED * 0.95
			kick_t = WALL_KICK_TIME
			kick_dir = -wall_dir
			dash_momentum = Input.is_action_pressed("dash")
			Audio.play("jump")
		elif air_jumps > 0:
			air_jumps -= 1
			vel.y = -JUMP_SPEED * 0.85
			air_dash = false
			dash_t = 0.0
			Audio.play("jump")
	# Releasing jump early cuts the jump short.
	if not Input.is_action_pressed("jump") and vel.y < -80.0 and kick_t <= 0.0:
		vel.y = -80.0


func _attacks(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		_fire(0)
		charging = true
		charge = 0.0
	elif charging and Input.is_action_pressed("shoot"):
		charge += delta
	if charging and not Input.is_action_pressed("shoot"):
		if charge >= CHARGE_2:
			_fire(2)
		elif charge >= CHARGE_1:
			_fire(1)
		charging = false
		charge = 0.0

	if Input.is_action_just_pressed("slash") and slash_t <= 0.0:
		slash_t = SLASH_TIME
		slash_hits.clear()
		Audio.play("slash")
	if slash_t > 0.0:
		slash_t -= delta
		if slash_t > 0.06:
			_slash_hit()


func _shots_out() -> int:
	return get_tree().get_nodes_in_group("player_shot").size()


func _fire(level: int) -> void:
	var dir := facing
	if wall_dir != 0:
		dir = -wall_dir
	var c: Dictionary = Game.CORES[Game.core]
	var origin := global_position + Vector2(dir * 11, -1)
	match Game.core:
		"nova":
			if level == 0:
				if _shots_out() >= 3:
					return
				world.spawn_shot(origin, Vector2(dir * 260, 0), 1, 2.5, c.shot, "pellet", false)
			elif level == 1:
				world.spawn_shot(origin, Vector2(dir * 240, 0), 2, 4.5, c.shot, "orb", false)
			else:
				world.spawn_shot(origin, Vector2(dir * 220, 0), 4, 7.0, c.shot, "orb", true)
		"ember":
			if level == 0:
				if _shots_out() >= 2:
					return
				world.spawn_shot(origin, Vector2(dir * 210, 0), 2, 3.0, c.shot, "fire", false)
			elif level == 1:
				world.spawn_shot(origin, Vector2(dir * 200, 0), 3, 5.0, c.shot, "fire", false)
			else:
				for a in [-0.22, 0.0, 0.22]:
					world.spawn_shot(origin, Vector2(dir * 200, 0).rotated(a), 3, 5.0, c.shot, "fire", false)
		"gale":
			if level == 0:
				if _shots_out() >= 4:
					return
				for a in [-0.1, 0.1]:
					world.spawn_shot(origin, Vector2(dir * 300, 0).rotated(a), 1, 2.0, c.shot, "blade", false)
			elif level == 1:
				world.spawn_shot(origin, Vector2(dir * 260, 0), 2, 4.0, c.shot, "blade", true)
			else:
				world.spawn_shot(origin, Vector2(dir * 210, 0), 3, 7.0, c.shot, "blade", true)
	shoot_t = 0.25
	Audio.play(["shot", "shot_mid", "shot_big"][level])


func _slash_hit() -> void:
	var damage := 3
	var reach := 22.0
	if Game.core == "ember":
		damage = 4
		reach = 26.0
	elif Game.core == "gale":
		damage = 2
	var area := Rect2(global_position + Vector2(-reach if facing < 0 else 0.0, -15), Vector2(reach, 27))
	for e in get_tree().get_nodes_in_group("enemy"):
		if not e in slash_hits and not e.dead and area.intersects(e.get_rect()):
			slash_hits.append(e)
			e.hit(damage, self)
	# The slash also cuts enemy bullets.
	for b in get_tree().get_nodes_in_group("enemy_shot"):
		if area.has_point(b.global_position):
			b.queue_free()


func take_damage(amount: int, from_x: float) -> void:
	if not alive or invuln > 0.0:
		return
	hp -= amount
	Audio.play("hurt")
	if hp <= 0:
		hp = 0
		die()
		return
	invuln = 1.2
	hurt_t = 0.3
	dash_t = 0.0
	kick_t = 0.0
	dash_momentum = false
	var away := 1.0 if global_position.x >= from_x else -1.0
	vel = Vector2(away * 80.0, -160.0)


func heal(amount: int) -> void:
	hp = int(min(max_hp, hp + amount))


func die() -> void:
	if not alive:
		return
	alive = false
	visible = false
	world.explode(global_position, 34, Game.CORES[Game.core].visor)
	Audio.play("explode")
	world.on_player_died()


func _draw() -> void:
	if not alive:
		return
	if invuln > 0.0 and int(invuln * 20) % 2 == 0:
		return
	var c: Dictionary = Game.CORES[Game.core]
	var body: Color = c.body
	var trim: Color = c.trim
	var dark: Color = c.dark
	var visor: Color = c.visor
	if hurt_t > 0.0:
		body = body.lightened(0.6)
		trim = trim.lightened(0.6)

	# Dash afterimage
	if dash_t > 0.0 or dash_momentum:
		for i in range(3):
			draw_rect(Rect2(-facing * (10 + i * 5) - 2, -4 + i * 4, 4, 1), Color(visor.r, visor.g, visor.b, 0.6 - i * 0.18))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))

	# Legs: alternate while running, tucked in the air, spread while dashing
	var back_y := 0
	var front_y := 0
	var back_x := 0
	var front_x := 0
	if not on_floor:
		back_y = -2
		front_y = -3
	elif dash_t > 0.0:
		back_x = -3
		front_x = 2
	elif abs(vel.x) > 1.0:
		var step := int(anim_t * 10.0) % 4
		if step == 1:
			back_y = -2
			front_x = 1
		elif step == 3:
			front_y = -2
			back_x = -1
	draw_rect(Rect2(-5 + back_x, 3 + back_y, 4, 7), dark)
	draw_rect(Rect2(-6 + back_x, 9 + back_y, 5, 2), trim.darkened(0.3))
	draw_rect(Rect2(1 + front_x, 3 + front_y, 4, 7), body)
	draw_rect(Rect2(1 + front_x, 9 + front_y, 5, 2), trim)

	# Torso with a core gem
	var lean := 1 if dash_t > 0.0 else 0
	draw_rect(Rect2(-5 + lean, -4, 10, 8), body)
	draw_rect(Rect2(-5 + lean, 2, 10, 1), dark)
	draw_rect(Rect2(-1 + lean, -2, 3, 3), visor)
	draw_rect(Rect2(-6 + lean, -5, 4, 4), trim)

	# Helmet: swept fin crest and a single visor stripe
	draw_rect(Rect2(-5 + lean, -12, 10, 8), trim)
	draw_rect(Rect2(-5 + lean, -12, 10, 1), trim.lightened(0.3))
	draw_colored_polygon(PoolVector2Array([Vector2(-3 + lean, -12), Vector2(-10 + lean, -17), Vector2(-7 + lean, -11)]), trim.lightened(0.15))
	draw_rect(Rect2(-1 + lean, -9, 6, 2), visor)
	draw_rect(Rect2(-4 + lean, -9, 3, 3), dark)

	# Arm: cannon forward while shooting or charging, otherwise at the side
	if shoot_t > 0.0 or charging or wall_dir != 0:
		draw_rect(Rect2(3 + lean, -3, 7, 4), body)
		draw_rect(Rect2(9 + lean, -3, 2, 4), dark)
	else:
		draw_rect(Rect2(2 + lean, -4, 3, 7), body)
		draw_rect(Rect2(2 + lean, 2, 3, 2), trim)

	# Slash arc
	if slash_t > 0.0:
		var p := 1.0 - slash_t / SLASH_TIME
		var reach := 26.0 if Game.core == "ember" else 22.0
		var start := deg2rad(-110.0 + p * 60.0)
		draw_arc(Vector2(2, -2), reach - 4.0, start, start + deg2rad(150.0), 14, visor, 3.0)
		draw_arc(Vector2(2, -2), reach - 6.0, start, start + deg2rad(150.0), 14, Color(1, 1, 1, 0.9), 1.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Charge aura
	if charging and charge >= CHARGE_1 and int(anim_t * 30.0) % 2 == 0:
		var aura: Color = c.shot if charge < CHARGE_2 else visor
		draw_arc(Vector2(0, -1), 15.0 + sin(anim_t * 25.0), 0.0, TAU, 16, aura, 1.0)
		if charge >= CHARGE_2:
			draw_arc(Vector2(0, -1), 18.0, 0.0, TAU, 16, Color(1, 1, 1, 0.7), 1.0)
