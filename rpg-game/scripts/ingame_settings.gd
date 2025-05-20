extends Control

@onready var SFX_Bus_ID = AudioServer.get_bus_index("sound effects")
@onready var Music_Bus_ID = AudioServer.get_bus_index("bg music")
@onready var Master_Bus_ID = AudioServer.get_bus_index("Master")
@onready var camera_2d: Camera2D = null

@onready var master_slider: HSlider = $"CanvasLayer/Sound Settings/VBoxContainer/Volume/MasterSlider"
@onready var music_slider: HSlider = $"CanvasLayer/Sound Settings/VBoxContainer/Volume/MusicSlider"
@onready var sfx_slider: HSlider = $"CanvasLayer/Sound Settings/VBoxContainer/Volume/SFXSlider"
@onready var camera_zoom_slider: HSlider = $"CanvasLayer/Sound Settings/VBoxContainer/Camera/CameraZoomSlider"

func _ready() -> void:
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		camera_2d = current_scene.get_node_or_null("Main/Player/Camera2D")
		if camera_2d:
			camera_2d.zoom = GlobalSettings.camera_zoom

	# Restore slider values
	music_slider.value = GlobalSettings.music_volume
	sfx_slider.value = GlobalSettings.sfx_volume
	master_slider.value = GlobalSettings.master_volume
	camera_zoom_slider.value = GlobalSettings.camera_zoom.x

func _on_music_slider_value_changed(value: float) -> void:
	GlobalSettings.music_volume = value
	AudioServer.set_bus_volume_db(Music_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(Music_Bus_ID, value <= 0)

func _on_sfx_slider_value_changed(value: float) -> void:
	GlobalSettings.sfx_volume = value
	AudioServer.set_bus_volume_db(SFX_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(SFX_Bus_ID, value <= 0)

func _on_master_slider_value_changed(value: float) -> void:
	GlobalSettings.master_volume = value
	AudioServer.set_bus_volume_db(Master_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(Master_Bus_ID, value <= 0)

func _on_resume_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_camera_zoom_slider_value_changed(value: float) -> void:
	var zoom_vec = Vector2(value, value)
	GlobalSettings.camera_zoom = zoom_vec
	
	if camera_2d:
		camera_2d.zoom = zoom_vec
