extends Control

@onready var arena_view: Node2D = $ArenaView
@onready var hero_rect: ColorRect = $ArenaView/HeroRect
@onready var enemy_rect: ColorRect = $ArenaView/EnemyRect
@onready var target_pos: ColorRect = $ArenaView/TargetPos
@onready var hero_hp_bar: ColorRect = $ArenaView/HeroHpBar
@onready var hero_hp_bg: ColorRect = $ArenaView/HeroHpBg
@onready var enemy_hp_bar: ColorRect = $ArenaView/EnemyHpBar
@onready var enemy_hp_bg: ColorRect = $ArenaView/EnemyHpBg
@onready var countdown_label: Label = $CountdownLabel
@onready var timer_label: Label = $TimerLabel
@onready var result_label: Label = $ResultLabel

var _hero: HeroBase = null
var _hero_speed: float = 300.0
var _hero_dmg: int = 30
var _hero_atk_range: float = 150.0
var _hero_atk_spd: float = 1.0
var _hero_max_hp: float = 500.0
var _hero_hp: float = 500.0

var _enemy_speed: float = 300.0
var _enemy_dmg: int = 25
var _enemy_atk_range: float = 150.0
var _enemy_atk_spd: float = 1.0
var _enemy_max_hp: float = 500.0
var _enemy_hp: float = 500.0

var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _atk_cooldown: float = 0.0
var _enemy_atk_cooldown: float = 0.0
var _duel_timer: float = Constants.DUEL_TIME
var _fighting: bool = false
var _ended: bool = false



func _ready():
	_setup_hero()
	_setup_enemy()
	GameManager.phase_changed.connect(_on_phase_changed)
	start_countdown()

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.LOBBY:
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://Scenes/Lobby.tscn")

func _setup_hero():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	var h_type = p.hero_type
	hero_rect.color = _get_hero_color(h_type)
	var hero_path = HeroDatabase.get_hero_script_path(h_type)
	var HeroScript = load(hero_path)
	if HeroScript:
		_hero = HeroScript.new()
		_hero.player_data = p
	_hero_max_hp = p.get_hp()
	_hero_hp = _hero_max_hp
	_hero_dmg = p.get_damage()
	_hero_atk_spd = p.get_atk_speed()
	_hero_speed = p.get_speed()
	var data = HeroDatabase.get_hero(h_type)
	_hero_atk_range = data.attack_range

func _get_hero_color(h_type: int) -> Color:
	match h_type:
		Constants.HeroType.WARRIOR: return Color(0.8, 0.3, 0.2)
		Constants.HeroType.ARCHER: return Color(0.2, 0.6, 0.2)
		Constants.HeroType.MAGE: return Color(0.2, 0.3, 0.8)
		Constants.HeroType.ASSASSIN: return Color(0.3, 0.3, 0.3)
		Constants.HeroType.PALADIN: return Color(0.9, 0.8, 0.4)
		Constants.HeroType.NECROMANCER: return Color(0.4, 0.2, 0.6)
		Constants.HeroType.BERSERKER: return Color(0.8, 0.1, 0.1)
		Constants.HeroType.SHAMAN: return Color(0.2, 0.7, 0.7)
		Constants.HeroType.GUNSLINGER: return Color(0.6, 0.5, 0.3)
		Constants.HeroType.SPELLBLADE: return Color(0.5, 0.3, 0.8)
	return Color(0.5, 0.5, 0.5)

func _setup_enemy():
	var opp_type = GameManager.duel_opponent_hero_type
	enemy_rect.color = _get_hero_color(opp_type)
	var data = HeroDatabase.get_hero(opp_type)
	_enemy_speed = data.base_spd
	_enemy_dmg = data.base_dmg + data.base_str
	_enemy_atk_spd = data.base_aspd
	_enemy_atk_range = data.attack_range
	_enemy_max_hp = Constants.BASE_HP + data.base_str * Constants.HP_PER_STR
	_enemy_hp = _enemy_max_hp

func start_countdown():
	countdown_label.visible = true
	set_process(false)
	for i in range(3, 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree():
			return
	countdown_label.text = "FIGHT!"
	await get_tree().create_timer(0.4).timeout
	if is_inside_tree():
		countdown_label.visible = false
	_fighting = true
	set_process(true)

func _process(delta):
	if _ended:
		return
	_duel_timer -= delta
	var t = max(0, int(_duel_timer))
	timer_label.text = "%d" % t
	
	if _is_moving and _fighting:
		var dir = (_move_target - hero_rect.position)
		if dir.length() > 4:
			hero_rect.position += dir.normalized() * _hero_speed * delta
			target_pos.position = _move_target - Vector2(4, 4)
			target_pos.visible = true
		else:
			_is_moving = false
			target_pos.visible = false
	
	_combat_tick(delta)
	_update_hp_bars()
	
	if _duel_timer <= 0:
		_end_duel()
	
	if _enemy_hp <= 0:
		_end_duel(true)
	if _hero_hp <= 0:
		_end_duel(false)

func _input(event):
	if not _fighting or _ended:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_move_target = event.position
		_is_moving = true

func _combat_tick(delta):
	_atk_cooldown -= delta
	_enemy_atk_cooldown -= delta
	
	# Hero attacks enemy
	if hero_rect.position.distance_to(enemy_rect.position) <= _hero_atk_range:
		if _atk_cooldown <= 0:
			_atk_cooldown = 1.0 / _hero_atk_spd
			_enemy_hp -= _hero_dmg
	else:
		if _is_moving:
			var dir = (enemy_rect.position - hero_rect.position).normalized()
			hero_rect.position += dir * _hero_speed * delta
	
	# Enemy attacks hero
	var dist = enemy_rect.position.distance_to(hero_rect.position)
	if dist <= _enemy_atk_range:
		if _enemy_atk_cooldown <= 0:
			_enemy_atk_cooldown = 1.0 / _enemy_atk_spd
			_hero_hp -= _enemy_dmg
	else:
		var dir = (hero_rect.position - enemy_rect.position).normalized()
		enemy_rect.position += dir * _enemy_speed * delta

func _update_hp_bars():
	var hr = clamp(_hero_hp / _hero_max_hp, 0, 1)
	var er = clamp(_enemy_hp / _enemy_max_hp, 0, 1)
	hero_hp_bar.size.x = hero_hp_bg.size.x * hr
	enemy_hp_bar.size.x = enemy_hp_bg.size.x * er

func _end_duel(won: bool = false):
	if _ended:
		return
	_ended = true
	_fighting = false
	set_process(false)
	
	if won:
		result_label.text = "VICTORY! +%dg" % Constants.DUEL_WINNER_GOLD
	else:
		var hero_pct = _hero_hp / _hero_max_hp * 100.0
		var enemy_pct = _enemy_hp / _enemy_max_hp * 100.0
		var actually_won = hero_pct >= enemy_pct
		if actually_won:
			won = true
			result_label.text = "VICTORY (by HP)! +%dg" % Constants.DUEL_WINNER_GOLD
		else:
			result_label.text = "DEFEAT - No bonus gold"
	
	result_label.visible = true
	
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree():
		GameManager.end_duel_phase(won)
