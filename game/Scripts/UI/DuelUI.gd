extends Control

@onready var arena_view: Node2D = $ArenaView
@onready var hero_rect: ColorRect = $ArenaView/HeroRect
@onready var enemy_rect: ColorRect = $ArenaView/EnemyRect
@onready var hero_hp_bar: ColorRect = $ArenaView/HeroRect/HeroHpBar
@onready var enemy_hp_bar: ColorRect = $ArenaView/EnemyRect/EnemyHpBar
@onready var target_pos: ColorRect = $ArenaView/TargetPos
@onready var countdown_label: Label = $CountdownLabel
@onready var timer_label: Label = $TimerLabel
@onready var result_label: Label = $ResultLabel
@onready var level_label: Label = $LevelLabel
@onready var lives_label: Label = $LivesLabel
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
@onready var inv_slots: Array = [
	$InvBox/Slot0/Slot0Label,
	$InvBox/Slot1/Slot1Label,
	$InvBox/Slot2/Slot2Label,
	$InvBox/Slot3/Slot3Label,
	$InvBox/Slot4/Slot4Label,
	$InvBox/Slot5/Slot5Label
]

var _hero: HeroBase = null
var _hero_speed: float = 300.0
var _hero_dmg: int = 30
var _hero_atk_range: float = 150.0
var _hero_max_hp: float = 500.0
var _hero_hp: float = 500.0
var _hero_max_mana: float = 100.0
var _hero_mana: float = 100.0
var _hero_atk_spd: float = 1.0
var _atk_cooldown: float = 0.0

var _enemy_speed: float = 300.0
var _enemy_dmg: int = 25
var _enemy_atk_range: float = 150.0
var _enemy_hp: float = 500.0
var _enemy_max_hp: float = 500.0
var _enemy_atk_spd: float = 1.0
var _enemy_atk_cooldown: float = 0.0

var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _duel_timer: float = Constants.DUEL_TIME
var _fighting: bool = false
var _ended: bool = false

var _attacking_target = null
var _prev_target = null
var _attacking_target_last_pos: Vector2 = Vector2.ZERO

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
	var path = HeroDatabase.get_hero_script_path(h_type)
	var HeroScript = load(path)
	if HeroScript:
		_hero = HeroScript.new()
		_hero.player_data = p
	_hero_max_hp = p.get_hp()
	_hero_hp = _hero_max_hp
	_hero_max_mana = p.get_mana()
	_hero_mana = _hero_max_mana
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
	
	if Input.is_action_just_pressed("ability_q") and _hero:
		_hero.ability_q()
	if Input.is_action_just_pressed("ability_w") and _hero:
		_hero.ability_w()
	
	_duel_timer -= delta
	var t = max(0, int(_duel_timer))
	timer_label.text = "%02d:%02d" % [t / 60, t % 60]
	
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
	_update_hud()
	
	if _duel_timer <= 0 and _fighting:
		_end_duel()
	if _enemy_hp <= 0 and _fighting:
		_end_duel(true)
	if _hero_hp <= 0 and _fighting:
		_end_duel(false)

func _input(event):
	if not _fighting or _ended:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
	if event.position.distance_to(enemy_rect.position) < 50:
		_set_attack_target("enemy")
		_is_moving = false
		target_pos.visible = false
		return
	_set_attack_target(null)
	_move_target = event.position
	_is_moving = true

func _set_attack_target(target):
	_clear_target_highlight()
	_attacking_target = target
	_prev_target = target
	if target == "enemy":
		_apply_target_highlight()

func _apply_target_highlight():
	enemy_rect.modulate = Color.YELLOW

func _clear_target_highlight():
	enemy_rect.modulate = Color.WHITE

func _combat_tick(delta):
	_atk_cooldown -= delta
	_enemy_atk_cooldown -= delta
	
	# Hero attack toward enemy
	if _attacking_target == "enemy" and _enemy_hp > 0:
		var dist = hero_rect.position.distance_to(enemy_rect.position)
		if dist > _hero_atk_range:
			var dir = (enemy_rect.position - hero_rect.position).normalized()
			hero_rect.position += dir * _hero_speed * delta
		elif _atk_cooldown <= 0:
			_atk_cooldown = 1.0 / _hero_atk_spd
			_enemy_hp -= _hero_dmg
	elif _is_moving and _enemy_hp > 0:
		pass # movement handled in _process
	
	# Enemy always moves toward and attacks hero
	if _hero_hp > 0:
		var dist = enemy_rect.position.distance_to(hero_rect.position)
		if dist > _enemy_atk_range:
			var dir = (hero_rect.position - enemy_rect.position).normalized()
			enemy_rect.position += dir * _enemy_speed * delta
		elif _enemy_atk_cooldown <= 0:
			_enemy_atk_cooldown = 1.0 / _enemy_atk_spd
			_hero_hp -= _enemy_dmg
	
	# Update world hp bars
	var hr = clamp(_hero_hp / _hero_max_hp, 0, 1)
	var er = clamp(_enemy_hp / _enemy_max_hp, 0, 1)
	hero_hp_bar.size.x = hero_hp_bar.get_parent().size.x * hr
	enemy_hp_bar.size.x = enemy_hp_bar.get_parent().size.x * er

func _update_hud():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	
	level_label.text = "Lv.%d" % p.level
	gold_label.text = "%dg" % p.gold
	match p.lives:
		2: lives_label.text = "♥♥"
		1: lives_label.text = "♥♡"
		_: lives_label.text = "♡♡"
	
	var hp_ratio = clamp(_hero_hp / _hero_max_hp, 0.0, 1.0)
	var mana_ratio = clamp(_hero_mana / _hero_max_mana, 0.0, 1.0)
	hp_bar.size.x = hp_bg.size.x * hp_ratio
	mana_bar.size.x = mana_bg.size.x * mana_ratio
	
	if _hero:
		q_cooldown_bar.size.x = q_cooldown_bg.size.x * _hero.get_q_progress()
		w_cooldown_bar.size.x = w_cooldown_bg.size.x * _hero.get_w_progress()
	
	for i in range(6):
		if i < p.inventory.size():
			inv_slots[i].text = ItemDatabase.get_item_name(p.inventory[i])
		else:
			inv_slots[i].text = ""

func _end_duel(won: bool = false):
	if _ended:
		return
	_ended = true
	_fighting = false
	set_process(false)
	
	if not won:
		var hero_pct = _hero_hp / _hero_max_hp
		var enemy_pct = _enemy_hp / _enemy_max_hp
		if hero_pct >= enemy_pct:
			won = true
	
	if won:
		result_label.text = "VICTORY! +%dg" % Constants.DUEL_WINNER_GOLD
		result_label.modulate = Color(0, 1, 0)
	else:
		result_label.text = "DEFEAT"
		result_label.modulate = Color(1, 0, 0)
	
	result_label.visible = true
	
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree():
		GameManager.end_duel_phase(won)
