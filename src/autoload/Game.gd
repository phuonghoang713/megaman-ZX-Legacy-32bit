extends Node
# Game progress: unlocked cores, current room and story flags.
# Saved to user://save.cfg every time the player enters a room.

const SAVE_PATH := "user://save.cfg"
const TITLE_SCENE := "res://src/ui/Title.tscn"
const WORLD_SCENE := "res://src/world/World.tscn"

# Cores are armor modes the hero, Kite, can switch between.
# Colors: body = main armor, trim = helmet/boots, dark = shading,
# visor = eyes/gem/HP bar, shot = projectile color.
const CORES := {
	"nova": {"name": "NOVA", "body": Color("e6edf2"), "trim": Color("2a9db8"), "dark": Color("1d4b63"), "visor": Color("7cf2ff"), "shot": Color("fff27a"),
		"info": "BALANCED BUSTER"},
	"ember": {"name": "EMBER", "body": Color("d9483b"), "trim": Color("ffb03b"), "dark": Color("6e1f2a"), "visor": Color("ffe9a8"), "shot": Color("ff8a2b"),
		"info": "HEAVY FIRE SHOTS + STRONG SLASH"},
	"gale": {"name": "GALE", "body": Color("5ccf78"), "trim": Color("eef7e8"), "dark": Color("23614a"), "visor": Color("c9fff0"), "shot": Color("aef7ff"),
		"info": "DOUBLE JUMP + AIR DASH"},
}
const CORE_ORDER := ["nova", "ember", "gale"]

var unlocked := ["nova"]
var core := "nova"
var room := "start"
var entry_pos := Vector2.ZERO
var flags := {}


func has_save() -> bool:
	return File.new().file_exists(SAVE_PATH)


func new_game() -> void:
	unlocked = ["nova"]
	core = "nova"
	room = "start"
	entry_pos = Vector2.ZERO
	flags = {}
	save_game()


func unlock(core_id: String) -> void:
	if not core_id in unlocked:
		var sorted := []
		for c in CORE_ORDER:
			if c in unlocked or c == core_id:
				sorted.append(c)
		unlocked = sorted


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "core", core)
	cfg.set_value("progress", "room", room)
	cfg.set_value("progress", "entry_pos", entry_pos)
	cfg.set_value("progress", "flags", flags)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		new_game()
		return
	unlocked = cfg.get_value("progress", "unlocked", ["nova"])
	core = cfg.get_value("progress", "core", "nova")
	room = cfg.get_value("progress", "room", "start")
	entry_pos = cfg.get_value("progress", "entry_pos", Vector2.ZERO)
	flags = cfg.get_value("progress", "flags", {})


func start_game() -> void:
	get_tree().paused = false
	var _err = get_tree().change_scene(WORLD_SCENE)


func to_title() -> void:
	get_tree().paused = false
	var _err = get_tree().change_scene(TITLE_SCENE)
