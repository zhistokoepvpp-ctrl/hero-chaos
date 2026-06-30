extends Control

@onready var arena_view: Node2D = $ArenaView
@onready var hero_rect: ColorRect = $ArenaView/Hero
@onready var target_pos: ColorRect = $ArenaView/TargetPos
@onready var timer_label: Label = $TimerLabel
@onready var level_label: Label = $LevelLabel
@onready var hp_bar: ColorRect = $HpBar
@onready var mana_bar: ColorRect = $ManaBar
@onready var hp_bg: ColorRect = $HpBg
@onready var mana_bg: ColorRect = $ManaBg
@onready var q_label: Label = $AbilityBox/QPanel/QLabel
@onready var w_label: Label = $AbilityBox/WPanel/WLabel
@onready var q_cooldown_bar: ColorRect = $AbilityBox/QPanel/QCooldownBar
@onready var w_cooldown_bar: ColorRect = $AbilityBox/WPanel/WCooldownBar
@onready var q_cooldown_bg: ColorRect = $AbilityBox/QPanel/QCooldownBg
@onready var w_cooldown_bg: ColorRect = $AbilityBox/WPanel/WCooldownBg
@onready var gold_label: Label = $GoldLabel

var _hero: HeroBase = null
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _hero_speed: float = 300.0
var _max_hp: float = 500.0
var _max_mana: float = 100.0

func _ready():
	GameManager.phase_changed.connect(_on_phase_changed)
	_spawn_hero()

func _spawn_hero():
	if not GameManager.players.has(GameManager.local_player_id):
		return
	var p = GameManager.players[GameManager.local_player_id]
	var h_type = p.hero_type
	var path = HeroDatabase.get_hero_script_path(h_type)
	var HeroScript = load(path)
	if not HeroScript:
		return
	_hero = HeroScript.new()
	_hero.hero_type = h_type
	_hero.player_data = p
	add_child(_hero)
	
	var data = HeroDatabase.get_hero(h_type)
	_hero_speed = data.base_spd
	_max_hp = p.get_hp()
	_max_mana = p.get_mana()
	
	q_label.text = "[Q] " + data.get("q_name", "?")
	w_label.text = "[W] " + data.get("w_name", "?")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_move_to_mouse()

func _process(delta):
	if Input.is_action_just_pressed("ability_q") and _hero:
		_hero.ability_q()
	if Input.is_action_just_pressed("ability_w") and _hero:
		_hero.ability_w()
	
	if _is_moving:
		var dir = (_move_target - hero_rect.position)
		if dir.length() > 4:
			hero_rect.position += dir.normalized() * _hero_speed * delta
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
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	
	if GameManager._wave_timer > 0:
		var t = int(GameManager._wave_timer)
		timer_label.text = "%02d:%02d / 60" % [t / 60, t % 60]
	elif GameManager._overtime_active:
		timer_label.text = "OVERTIME"
	
	level_label.text = "Lv.%d" % p.level
	gold_label.text = "%dg" % p.gold
	
	var hp = p.get_hp()
	var mana = p.get_mana()
	var hp_ratio = clamp(hp / _max_hp, 0.0, 1.0)
	var mana_ratio = clamp(mana / _max_mana, 0.0, 1.0)
	
	var hp_w = hp_bg.size.x * hp_ratio
	var mana_w = mana_bg.size.x * mana_ratio
	hp_bar.size.x = hp_w
	mana_bar.size.x = mana_w
	
	if _hero:
		var qp = _hero.get_q_progress()
		var wp = _hero.get_w_progress()
		q_cooldown_bar.size.x = q_cooldown_bg.size.x * qp
		w_cooldown_bar.size.x = w_cooldown_bg.size.x * wp

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.LOBBY:
		get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
