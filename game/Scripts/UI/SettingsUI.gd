extends Control

func _ready():
	$BtnBack.pressed.connect(_on_back)

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
