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
var _wave_manager: WaveManager = null
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _attacking_target = null
var _hero_speed: float = 300.0
var _max_hp: float = 500.0
var _current_hp: float = 500.0
var _max_mana: float = 100.0
var _current_mana: float = 100.0
var _atk_cooldown: float = 0.0
var _atk_range: float = 150.0
var _atk_damage: int = 30
var _poison_timer: float = 0.0
var _poison_active: bool = false
var _ending: bool = false

func _ready():
	GameManager.phase_changed.connect(_on_phase_changed)
	_spawn_hero()
	_setup_wave_manager()

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
	_atk_range = data.attack_range
	_atk_damage = p.get_damage()
	_max_hp = p.get_hp()
	_current_hp = _max_hp
	_max_mana = p.get_mana()
	_current_mana = _max_mana
	
	q_label.text = "[Q] " + data.get("q_name", "?")
	w_label.text = "[W] " + data.get("w_name", "?")

func _setup_wave_manager():
	_wave_manager = WaveManager.new()
	_wave_manager.arena_view = arena_view
	_wave_manager.hero_node = hero_rect
	_wave_manager.hero_data = GameManager.players.get(GameManager.local_player_id)
	_wave_manager.monster_spawned.connect(_on_monster_spawned)
	add_child(_wave_manager)
	_wave_manager.spawn_wave(GameManager.current_wave)

func _on_monster_spawned(monster: MonsterBase):
	monster.dealt_damage.connect(_on_monster_damage)
	if monster.is_spitter:
		monster.spitter_poison_applied.connect(_on_spitter_poison)

func _on_spitter_poison():
	_poison_active = true
	_poison_timer = 4.0

func _on_monster_damage(amount: float):
	if _current_hp <= 0 or _ending:
		return
	_current_hp -= amount
	if _current_hp <= 0:
		_current_hp = 0
		_on_hero_death()

func _on_hero_death():
	if _ending:
		return
	_ending = true
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		_ending = false; return
	
	p.alive = false
	hero_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)
	set_process(false)
	
	var respawn = get_tree().create_timer(Constants.RESPAWN_DELAY)
	await respawn.timeout
	
	if not is_inside_tree() or GameManager.phase != Constants.GamePhase.WAVE:
		_ending = false; return
	
	p.lives -= 1
	if p.lives < 0:
		GameManager.check_game_over()
		_ending = false; return
	
	p.alive = true
	_current_hp = _max_hp
	hero_rect.modulate = Color.WHITE
	hero_rect.position = Vector2(590, 310)
	_ending = false
	set_process(true)

func _input(event):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
	
	var click_pos = arena_view.to_local(get_global_mouse_position())
	var hit_monster = _find_monster_at(click_pos)
	if hit_monster:
		_attacking_target = hit_monster
		_is_moving = false
		return
	
	_attacking_target = null
	_move_target = click_pos
	_is_moving = true

func _find_monster_at(pos: Vector2):
	for m in _wave_manager.monsters:
		if is_instance_valid(m) and m._alive:
			if m.position.distance_to(pos) < 30:
				return m
	return null

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
	
	_combat_tick(delta)
	_update_hud(delta)

func _combat_tick(delta):
	if _current_hp <= 0 or _ending:
		return
	
	_atk_cooldown -= delta
	
	if _attacking_target and is_instance_valid(_attacking_target) and _attacking_target._alive:
		var dist = hero_rect.position.distance_to(_attacking_target.position)
		if dist > _atk_range:
			var dir = (_attacking_target.position - hero_rect.position).normalized()
			hero_rect.position += dir * _hero_speed * delta
		elif _atk_cooldown <= 0:
			_atk_cooldown = 1.0 / _hero.player_data.get_atk_speed()
			if _attacking_target.take_damage(_atk_damage):
				var p = GameManager.players[GameManager.local_player_id]
				p.add_gold(_attacking_target.gold_reward)
				p.add_xp(_attacking_target.xp_reward)
				_max_hp = p.get_hp()
				_max_mana = p.get_mana()
				_attacking_target = null
	else:
		_attacking_target = null
	
	var alive = 0
	var snap = _wave_manager.monsters.duplicate()
	for m in snap:
		if is_instance_valid(m) and m._alive:
			alive += 1
	if alive == 0 and snap.size() > 0 and not _ending:
		_ending = true
		if is_inside_tree() and get_tree():
			GameManager.on_wave_cleared(GameManager.local_player_id)
			GameManager.start_lobby_phase()
			get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
	
	if GameManager._overtime_active:
		var ot = GameManager._overtime_seconds
		for m in _wave_manager.monsters:
			if is_instance_valid(m) and m._alive:
				var bd = m.get_meta("base_dmg", m.damage)
				var bs = m.get_meta("base_spd", m.speed)
				m.set_meta("base_dmg", bd)
				m.set_meta("base_spd", bs)
				m.damage = bd * (1.0 + ot * 0.02)
				m.speed = bs * (1.0 + ot * 0.01)
	
	if _poison_active:
		_poison_timer -= delta
		_current_hp -= 3.0 * delta
		if _poison_timer <= 0:
			_poison_active = false
		if _current_hp <= 0:
			_current_hp = 0
			_on_hero_death()

func _update_hud(delta):
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	
	if GameManager._wave_timer > 0:
		var t = int(GameManager._wave_timer)
		timer_label.text = "%02d:%02d" % [t / 60, t % 60]
		timer_label.modulate = Color.WHITE
	elif GameManager._overtime_active:
		var ot = GameManager._overtime_seconds
		timer_label.text = "OVERTIME %.1f" % ot
		if ot < 10:
			timer_label.modulate = Color(1, 1, 0.5)
		elif ot < 20:
			timer_label.modulate = Color(1, 0.7, 0.2)
		else:
			timer_label.modulate = Color(1, 0.2, 0.1)
	
	level_label.text = "Lv.%d" % p.level
	gold_label.text = "%dg" % p.gold
	
	var hp_ratio = clamp(_current_hp / _max_hp, 0.0, 1.0)
	var mana_ratio = clamp(_current_mana / _max_mana, 0.0, 1.0)
	hp_bar.size.x = hp_bg.size.x * hp_ratio
	mana_bar.size.x = mana_bg.size.x * mana_ratio
	
	if _hero:
		q_cooldown_bar.size.x = q_cooldown_bg.size.x * _hero.get_q_progress()
		w_cooldown_bar.size.x = w_cooldown_bg.size.x * _hero.get_w_progress()

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.LOBBY and is_inside_tree():
		get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
