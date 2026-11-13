extends Node
# Player settings: screen filters, window, audio volume and key bindings.
# Stored in user://settings.cfg. Other nodes listen to the "changed" signal.

signal changed(key)

const PATH := "user://settings.cfg"
const BASE_SIZE := Vector2(398, 224)

const ACTION_ORDER := ["left", "right", "up", "down", "jump", "shoot", "dash", "slash", "core_prev", "core_next", "pause"]
const ACTION_NAMES := {
	"left": "LEFT", "right": "RIGHT", "up": "UP", "down": "DOWN",
	"jump": "JUMP", "shoot": "SHOOT", "dash": "DASH", "slash": "SLASH",
	"core_prev": "PREV CORE", "core_next": "NEXT CORE", "pause": "PAUSE",
}
const DEFAULT_KEYS := {
	"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN,
	"jump": KEY_Z, "shoot": KEY_X, "dash": KEY_C, "slash": KEY_V,
	"core_prev": KEY_A, "core_next": KEY_S, "pause": KEY_ENTER,
}
const PAD_BUTTONS := {
	"left": JOY_DPAD_LEFT, "right": JOY_DPAD_RIGHT, "up": JOY_DPAD_UP, "down": JOY_DPAD_DOWN,
	"jump": JOY_XBOX_A, "shoot": JOY_XBOX_X, "dash": JOY_XBOX_B, "slash": JOY_XBOX_Y,
	"core_prev": JOY_L, "core_next": JOY_R, "pause": JOY_START,
}
const PAD_AXES := {"left": [JOY_AXIS_0, -1.0], "right": [JOY_AXIS_0, 1.0], "up": [JOY_AXIS_1, -1.0], "down": [JOY_AXIS_1, 1.0]}

var values := {
	"smooth": true,       # Smooth Colors upscaling shader
	"crt": 0,             # 0 off, 1 light, 2 strong
	"window_scale": 3,
	"fullscreen": false,
	"music_volume": 7,    # 0..10
	"sfx_volume": 8,      # 0..10
}
var keys := {}


func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	_create_audio_buses()
	keys = DEFAULT_KEYS.duplicate()
	_load()
	values.window_scale = int(clamp(values.window_scale, 1, max_window_scale()))
	_build_input_map()
	for key in values:
		_apply(key)


func get_value(key: String):
	return values.get(key)


func set_value(key: String, value) -> void:
	values[key] = value
	_apply(key)
	save()
	emit_signal("changed", key)


func max_window_scale() -> int:
	var screen := OS.get_screen_size()
	var fit := int(min(floor(screen.x / BASE_SIZE.x), floor((screen.y - 64) / BASE_SIZE.y)))
	return int(clamp(fit, 1, 6))


func key_name(action: String) -> String:
	return OS.get_scancode_string(keys.get(action, 0)).to_upper()


# Binds a key to an action. If another action already used that key, the two swap.
func remap(action: String, scancode: int) -> void:
	for other in keys:
		if other != action and keys[other] == scancode:
			keys[other] = keys[action]
	keys[action] = scancode
	_build_input_map()
	save()
	emit_signal("changed", "keys")


func reset_keys() -> void:
	keys = DEFAULT_KEYS.duplicate()
	_build_input_map()
	save()
	emit_signal("changed", "keys")


func save() -> void:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value("settings", key, values[key])
	for action in keys:
		cfg.set_value("keys", action, keys[action])
	cfg.save(PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key in values:
		values[key] = cfg.get_value("settings", key, values[key])
	for action in keys:
		keys[action] = cfg.get_value("keys", action, keys[action])


func _apply(key: String) -> void:
	match key:
		"window_scale", "fullscreen":
			OS.window_fullscreen = values.fullscreen
			if not values.fullscreen:
				var size: Vector2 = BASE_SIZE * values.window_scale
				OS.window_size = size
				OS.window_position = (OS.get_screen_size() - size) / 2
		"music_volume":
			_set_bus_volume("Music", values.music_volume)
		"sfx_volume":
			_set_bus_volume("SFX", values.sfx_volume)


func _set_bus_volume(bus: String, level: int) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, level <= 0)
	if level > 0:
		AudioServer.set_bus_volume_db(index, linear2db(level / 10.0))


func _create_audio_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")


func _build_input_map() -> void:
	for action in ACTION_ORDER:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.4)
		InputMap.action_erase_events(action)
		var key := InputEventKey.new()
		key.scancode = keys[action]
		InputMap.action_add_event(action, key)
		if action == "pause":
			var esc := InputEventKey.new()
			esc.scancode = KEY_ESCAPE
			InputMap.action_add_event(action, esc)
		var button := InputEventJoypadButton.new()
		button.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, button)
		if PAD_AXES.has(action):
			var motion := InputEventJoypadMotion.new()
			motion.axis = PAD_AXES[action][0]
			motion.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, motion)
