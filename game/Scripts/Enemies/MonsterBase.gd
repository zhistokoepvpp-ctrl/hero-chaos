extends Node2D
class_name MonsterBase

var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 100.0
var damage: float = 10.0
var armor: float = 0.0
var attack_range: float = 60.0
var attack_cooldown: float = 1.0
var gold_reward: int = 10
var xp_reward: int = 20
var monster_type: String = "slime"
var is_spitter: bool = false

var _target = null
var _target_player_data = null
var _atk_timer: float = 0.0
var _alive: bool = true
var _invulnerable: bool = false
var _phase_timer: float = 0.0

signal died(gold: int, xp: int, position: Vector2)
signal dealt_damage(amount: float)
signal spitter_poison_applied()

func _init(data: Dictionary = {}):
	if data.has("hp"): hp = data.hp; max_hp = data.hp
	if data.has("speed"): speed = data.speed
	if data.has("damage"): damage = data.damage
	if data.has("armor"): armor = data.armor
	if data.has("attack_range"): attack_range = data.attack_range
	if data.has("attack_cooldown"): attack_cooldown = data.attack_cooldown
	if data.has("gold_reward"): gold_reward = data.gold_reward
	if data.has("xp_reward"): xp_reward = data.xp_reward
	if data.has("type"): monster_type = data.type
	is_spitter = monster_type == "spitter"

func _ready():
	_setup_visual()

func _process(delta):
	if not _alive or not _target:
		return
	
	if monster_type == "ghost":
		_phase_timer += delta
		if _phase_timer >= 4.0:
			_invulnerable = true
			modulate = Color(0.5, 0.5, 1.0, 0.5)
		if _invulnerable and _phase_timer >= 4.5:
			_invulnerable = false
			_phase_timer = 0.0
			modulate = Color.WHITE
	
	_atk_timer -= delta
	var dist = position.distance_to(_target.position)
	
	if dist > attack_range:
		var dir = (_target.position - position).normalized()
		position += dir * speed * delta
	elif _atk_timer <= 0:
		_atk_timer = attack_cooldown
		_attack_target()

func _attack_target():
	if not _target or not _alive:
		return
	var dmg = max(1, damage - armor)
	_on_deal_damage(dmg)

func _on_deal_damage(amount: float):
	dealt_damage.emit(amount)
	if is_spitter:
		spitter_poison_applied.emit()

func take_damage(amount: float) -> bool:
	if not _alive or _invulnerable:
		return false
	hp -= amount
	if hp <= 0:
		_die()
		return true
	return false

func _die():
	_alive = false
	died.emit(gold_reward, xp_reward, position)
	queue_free()

func set_target(node, player_data):
	_target = node
	_target_player_data = player_data

func _setup_visual():
	var rect = ColorRect.new()
	rect.size = Vector2(24, 24)
	rect.position = Vector2(-12, -12)
	rect.color = _get_monster_color()
	add_child(rect)
	
	var hp_bar = ColorRect.new()
	hp_bar.name = "HpBar"
	hp_bar.size = Vector2(24, 3)
	hp_bar.position = Vector2(-12, -18)
	hp_bar.color = Color.RED
	add_child(hp_bar)

func _get_monster_color() -> Color:
	match monster_type:
		"slime": return Color(0, 0.8, 0.2)
		"skeleton": return Color(0.8, 0.8, 0.6)
		"bat": return Color(0.4, 0.2, 0.6)
		"demon": return Color(0.8, 0.2, 0.1)
		"spitter": return Color(0.9, 0.7, 0.1)
		"shieldbearer": return Color(0.3, 0.3, 0.8)
		"ghost": return Color(0.7, 0.5, 0.9)
		"boss_golem": return Color(0.9, 0.5, 0.0)
		"boss_lich": return Color(0.2, 0.5, 0.9)
		"boss_dragon": return Color(0.8, 0.0, 0.0)
		_: return Color(0.5, 0.0, 0.5)
