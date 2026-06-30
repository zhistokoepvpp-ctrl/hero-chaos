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
var _hero_speed: float = 300.0
var _max_hp: float = 500.0
var _current_hp: float = 500.0
var _max_mana: float = 100.0
var _current_mana: float = 100.0
var _atk_cooldown: float = 0.0
var _atk_range: float = 150.0
var _atk_damage: int = 30
var _monsters_in_range: Array = []

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

var _poison_timer: float = 0.0
var _poison_active: bool = false
var _wave_completing: bool = false

func _on_monster_spawned(monster: MonsterBase):
	monster.dealt_damage.connect(_on_monster_damage)
	if monster.is_spitter:
		monster.spitter_poison_applied.connect(_on_spitter_poison)

func _on_spitter_poison():
	_poison_active = true
	_poison_timer = 4.0

func _on_monster_damage(amount: float):
	if _current_hp <= 0:
		return
	_current_hp -= amount
	if _current_hp <= 0:
			_current_hp = 0
			_on_hero_death()
			return

func _on_hero_death():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	
	p.alive = false
	hero_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)
	set_process(false)

	var respawn = get_tree().create_timer(Constants.RESPAWN_DELAY)
	await respawn.timeout
	
	if not is_inside_tree() or GameManager.phase != Constants.GamePhase.WAVE:
		return
	
	p.lives -= 1
	if p.lives <= 0:
		GameManager.check_game_over()
		return
	
	p.alive = true
	_current_hp = _max_hp
	hero_rect.modulate = Color.WHITE
	hero_rect.position = Vector2(590, 310)
	set_process(true)

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
	
	_combat_tick(delta)
	_update_hud(delta)

func _combat_tick(delta):
	if _current_hp <= 0:
		return
	
	_atk_cooldown -= delta
	_monsters_in_range.clear()
	
	var snapshot = _wave_manager.monsters.duplicate()
	for m in snapshot:
		if not is_instance_valid(m) or not m._alive:
			continue
		var dist = hero_rect.position.distance_to(m.position)
		if dist <= _atk_range:
			_monsters_in_range.append(m)
	
	if _monsters_in_range.size() > 0 and _atk_cooldown <= 0:
		var nearest = _monsters_in_range[0]
		var min_dist = hero_rect.position.distance_to(nearest.position)
		for m in _monsters_in_range:
			var d = hero_rect.position.distance_to(m.position)
			if d < min_dist:
				min_dist = d
				nearest = m
		var killed = nearest.take_damage(_atk_damage)
		_atk_cooldown = 1.0 / _hero.player_data.get_atk_speed()
		if killed:
			var p = GameManager.players[GameManager.local_player_id]
			p.add_gold(nearest.gold_reward)
			p.add_xp(nearest.xp_reward)
			_max_hp = p.get_hp()
			_max_mana = p.get_mana()
	
	var alive_monsters = 0
	for m in _wave_manager.monsters:
		if is_instance_valid(m) and m._alive:
			alive_monsters += 1
	if alive_monsters == 0 and snapshot.size() > 0 and not _wave_completing:
		_wave_completing = true
		_on_wave_cleared(0, 0)
	
	if GameManager._overtime_active:
		for m in _wave_manager.monsters:
			if is_instance_valid(m) and m._alive:
				var base_dmg = m.get_meta("base_dmg", m.damage)
				var base_spd = m.get_meta("base_spd", m.speed)
				m.set_meta("base_dmg", base_dmg)
				m.set_meta("base_spd", base_spd)
				var ot = GameManager._overtime_seconds
				m.damage = base_dmg * (1.0 + ot * Constants.OVERTIME_DMG_PER_SEC)
				m.speed = base_spd * (1.0 + ot * Constants.OVERTIME_SPD_PER_SEC)
	
	if _poison_active:
		_poison_timer -= delta
		_current_hp -= 3.0 * delta
		if _poison_timer <= 0:
			_poison_active = false
	if _current_hp <= 0:
		_current_hp = 0
		_on_hero_death()
		return

func _on_wave_cleared(_g: int, _x: int):
	GameManager.on_wave_cleared(GameManager.local_player_id)
	GameManager.start_lobby_phase()
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

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
