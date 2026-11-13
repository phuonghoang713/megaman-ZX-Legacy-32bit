extends Node2D
# Forwards _draw to another object's method, so scripts that aren't
# CanvasItems (CanvasLayers, data scripts) can still draw.

var target: Object
var method := ""


func _draw() -> void:
	if target and method != "":
		target.call(method, self)
