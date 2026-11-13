extends Node2D
# Gameplay scene: builds the current room, owns the player, camera and HUD,
# and handles room transitions, death/respawn, boss events and pickups.

const Rooms = preload("res://src/world/Rooms.gd")
const Tiles = preload("res://src/world/Tiles.gd")
const Background = preload("res://src/world/Background.gd")
const Door = preload("res://src/world/Door.gd")
const Player = preload("res://src/actors/Player.gd")
const Walker = preload("res://src/actors/Walker.gd")
const Flyer = preload("res://src/actors/Flyer.gd")
const Sentinel = preload("res://src/actors/Sentinel.gd")
const Bullet = preload("res://src/actors/Bullet.gd")
const Pickup = preload("res://src/actors/Pickup.gd")
const Explosion = preload("res://src/actors/Explosion.gd")
const HUD = preload("res://src/ui/HUD.gd")
const PauseMenu = preload("res://src/ui/PauseMenu.gd")

const TILE := 16

var room_id := ""
var room: Dictionary
var level: Node2D
var background
var player
var camera: Camera2D
var hud
var boss = null
var ending := false


func _ready() -> void:
	hud = HUD.new()
	hud.world = self
	add_child(hud)
	player = Player.new()
	player.world = self
	add_child(player)
	camera = Camera2D.new()
	player.add_child(camera)
	camera.current = true
	Audio.play_music()
	load_room(Game.room, Game.entry_pos)
	if not Game.flags.get("intro_seen", false):
		Game.flags["intro_seen"] = true
		hud.show_message("ARROWS: MOVE   %s: JUMP   %s: SHOOT (HOLD TO CHARGE)\n%s: DASH   %s: SLASH   %s: PAUSE" % [
			Settings.key_name("jump"), Settings.key_name("shoot"), Settings.key_name("dash"),
			Settings.key_name("slash"), Settings.key_name("pause")], 7.0)


func load_room(id: String, pos: Vector2) -> void:
	if not Rooms.ROOMS.has(id):
		id = "start"
		pos = Vector2.ZERO
	room_id = id
	room = Rooms.ROOMS[id]
	boss = null
	hud.boss = null
	if level:
		remove_child(level)
		level.queue_free()
	if background:
		background.queue_free()

	var theme: Dictionary = Rooms.THEMES[room.theme]
	background = Background.new()
	background.theme = theme
	background.camera = camera
	add_child(background)
	level = Node2D.new()
	add_child(level)
	move_child(level, 0)   # draw behind the player
	var tiles := Tiles.new()
	tiles.setup(room.solids, theme)
	level.add_child(tiles)
	for e in room.entities:
		_spawn_entity(e)

	if pos == Vector2.ZERO:
		pos = _spawn_point()
	player.position = pos
	var size: Vector2 = room.size * TILE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	camera.reset_smoothing()
	hud.show_room_name(room.name)

	Game.room = id
	Game.entry_pos = pos
	Game.save_game()


func _foot(x: float, y: float) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)


func _spawn_point() -> Vector2:
	for e in room.entities:
		if e[0] == "spawn":
			return _foot(e[1], e[2]) - Vector2(0, 12)
	return _foot(2, 11) - Vector2(0, 12)


func _boss_beaten() -> bool:
	return Game.flags.get("boss_" + room_id, false)


func _spawn_entity(e: Array) -> void:
	match e[0]:
		"walker":
			_add_enemy(Walker.new(), _foot(e[1], e[2]))
		"flyer":
			_add_enemy(Flyer.new(), _foot(e[1], e[2]) - Vector2(0, 8))
		"sentinel":
			if not _boss_beaten():
				boss = Sentinel.new()
				_add_enemy(boss, _foot(e[1], e[2]))
				hud.boss = boss
		"boss_door":
			if not _boss_beaten():
				_add_door(Rect2(e[1], e[2], e[3], e[4]))
		"reward":
			if _boss_beaten() and not e[1] in Game.unlocked:
				spawn_pickup("core_" + e[1], _foot(e[2], e[3]) - Vector2(0, 10))
		"health":
			spawn_pickup("health", _foot(e[1], e[2]) - Vector2(0, 7))
		"core_gale":
			if not "gale" in Game.unlocked:
				spawn_pickup("core_gale", _foot(e[1], e[2]) - Vector2(0, 10))
		"goal":
			spawn_pickup("goal", _foot(e[1], e[2]) - Vector2(0, 12))


func _add_enemy(enemy, foot: Vector2) -> void:
	enemy.world = self
	enemy.position = foot - Vector2(0, enemy.size.y / 2.0 + 0.5)
	level.add_child(enemy)


func _add_door(tiles: Rect2) -> void:
	var door := Door.new()
	door.rect = Rect2(tiles.position * TILE, tiles.size * TILE)
	level.add_child(door)


func spawn_shot(origin: Vector2, velocity: Vector2, damage: int, radius: float, color: Color, kind: String, pierce: bool, team := "player") -> void:
	var b := Bullet.new()
	b.position = origin
	b.vel = velocity
	b.damage = damage
	b.radius = radius
	b.color = color
	b.kind = kind
	b.pierce = pierce
	b.team = team
	level.call_deferred("add_child", b)


func spawn_pickup(kind: String, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.world = self
	p.position = pos
	level.call_deferred("add_child", p)


func explode(pos: Vector2, size: float, color := Color("ffcc66")) -> void:
	var e := Explosion.new()
	e.position = pos
	e.size = size
	e.color = color
	level.add_child(e)


func _physics_process(_delta: float) -> void:
	if not player.alive or ending:
		return
	var size: Vector2 = room.size * TILE
	if player.position.x < -2 and room.left != "":
		var next: Dictionary = Rooms.ROOMS[room.left]
		load_room(room.left, Vector2(next.size.x * TILE - 4, player.position.y))
	elif player.position.x > size.x + 2 and room.right != "":
		load_room(room.right, Vector2(4, player.position.y))
	elif player.position.y > size.y + 24:
		player.die()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and player.alive and not ending:
		Audio.play("select")
		add_child(PauseMenu.new())
		get_tree().set_input_as_handled()


func on_player_died() -> void:
	yield(get_tree().create_timer(1.6), "timeout")
	player.reset()
	load_room(room_id, Game.entry_pos)


func on_boss_awake() -> void:
	call_deferred("_add_door", Rect2(0, 1, 1, 11))
	hud.show_message("WARNING: SENTINEL ONLINE", 2.0)


func on_boss_defeated(pos: Vector2) -> void:
	Game.flags["boss_" + room_id] = true
	Game.save_game()
	for i in range(5):
		explode(pos + Vector2((i * 37) % 24 - 12, (i * 23) % 24 - 12), 30, Color("ff9a4a"))
	yield(get_tree().create_timer(1.2), "timeout")
	for door in get_tree().get_nodes_in_group("boss_door"):
		door.open()
	spawn_pickup("core_ember", pos)
	hud.show_message("SENTINEL DESTROYED", 2.5)


func on_pickup(kind: String) -> void:
	match kind:
		"health":
			player.heal(8)
		"small_health":
			player.heal(3)
		"core_ember", "core_gale":
			var core_id := kind.substr(5)
			Game.unlock(core_id)
			Game.core = core_id
			Game.save_game()
			Audio.play("core")
			var c: Dictionary = Game.CORES[core_id]
			hud.show_message("%s CORE ACQUIRED!\n%s\n%s / %s: SWITCH CORE" % [c.name, c.info,
				Settings.key_name("core_prev"), Settings.key_name("core_next")], 5.0)
		"goal":
			ending = true
			Game.flags["cleared"] = true
			Game.save_game()
			hud.show_message("YOU REACHED THE SUMMIT!\nEND OF PROTOTYPE - THANKS FOR PLAYING", 5.0)
			yield(get_tree().create_timer(5.0), "timeout")
			Game.to_title()
