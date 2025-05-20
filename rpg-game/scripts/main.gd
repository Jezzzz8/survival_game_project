extends Node

func _ready() -> void:
	# Apply saved camera zoom from global settings
	var cam = $Player/Camera2D
	if cam:
		cam.zoom = GlobalSettings.camera_zoom
