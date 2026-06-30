extends Control

@onready var arena_view: Node2D = $ArenaView
@onready var hero: ColorRect = $ArenaView/Hero
@onready var target_pos: ColorRect = $ArenaView/TargetPos
@onready var timer_label: Label = $TimerLabel
@onready var hp_bar: ColorRect = $HpBar

var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _hero_speed: float = 300.0

func _ready():
	GameManager.phase_changed.connect(_on_phase_changed)
	_hero_speed = HeroDatabase.get_hero(GameManager.players[GameManager.local_player_id].hero_type).base_spd

func _process(delta):
	if Input.is_mouse_button_just_pressed(MOUSE_BUTTON_RIGHT):
		_move_to_mouse()
	
	if _is_moving:
		var dir = (_move_target - hero.position)
		if dir.length() > 4:
			hero.position += dir.normalized() * _hero_speed * delta
			target_pos.position = _move_target - Vector2(4, 4)
			target_pos.visible = true
		else:
			_is_moving = false
			target_pos.visible = false
	
	_update_hud(delta)

func _move_to_mouse():
	var mouse_pos = get_global_mouse_position()
	_move_target = mouse_pos - arena_view.position
	_is_moving = true

func _update_hud(delta):
	if GameManager._wave_timer > 0:
		var t = int(GameManager._wave_timer)
		timer_label.text = "%02d:%02d / 60" % [t / 60, t % 60]
	elif GameManager._overtime_active:
		timer_label.text = "OVERTIME"
		timer_label.modulate = Color.RED

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.LOBBY:
		get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
