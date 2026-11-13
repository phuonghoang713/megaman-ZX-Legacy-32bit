extends Node
# Full-screen filters, same layering as the 32-bit project:
#  - Smooth Colors: canvas layer 0, above the game world but below the HUD
#    (layer 1+) and menus, so text and UI stay crisp.
#  - CRT filter: layer 100, over everything.

const SmoothShader = preload("res://src/screen/smooth_upscale.shader")
const CrtShader = preload("res://src/screen/crt.shader")

const SMOOTH_PARAMS := {
	"resolution": Vector2(398, 224), "strength": 1.0, "edge_softness": 2.0,
	"equal_threshold": 0.06, "corner_coverage": 0.25, "shade_blend": 0.7, "shade_threshold": 0.12,
}
const CRT_PRESETS := [
	{},
	{"scanline": 0.18, "curvature": 0.0, "vignette": 0.2, "mask": 0.05},
	{"scanline": 0.4, "curvature": 0.05, "vignette": 0.45, "mask": 0.12},
]

var smooth_rect: ColorRect
var crt_rect: ColorRect


func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	var smooth_layer := CanvasLayer.new()
	smooth_layer.name = "SmoothLayer"
	smooth_layer.layer = 0
	smooth_rect = _make_rect(SmoothShader, SMOOTH_PARAMS)
	smooth_layer.add_child(smooth_rect)

	var crt_layer := CanvasLayer.new()
	crt_layer.name = "CRTLayer"
	crt_layer.layer = 100
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	crt_layer.add_child(copy)
	crt_rect = _make_rect(CrtShader, {})
	crt_layer.add_child(crt_rect)

	# Added after the main scene so layer 0 draws on top of the world.
	get_tree().root.call_deferred("add_child", smooth_layer)
	get_tree().root.call_deferred("add_child", crt_layer)
	Settings.connect("changed", self, "_on_setting_changed")
	_apply()


func _make_rect(shader: Shader, params: Dictionary) -> ColorRect:
	var rect := ColorRect.new()
	var material := ShaderMaterial.new()
	material.shader = shader
	for key in params:
		material.set_shader_param(key, params[key])
	rect.material = material
	rect.rect_size = Vector2(398, 224)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _on_setting_changed(key: String) -> void:
	if key == "smooth" or key == "crt":
		_apply()


func _apply() -> void:
	smooth_rect.visible = Settings.get_value("smooth")
	var crt: int = Settings.get_value("crt")
	crt_rect.visible = crt > 0
	if crt > 0:
		var preset: Dictionary = CRT_PRESETS[crt]
		for key in preset:
			crt_rect.material.set_shader_param(key, preset[key])
