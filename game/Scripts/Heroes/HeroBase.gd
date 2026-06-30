extends Node
class_name HeroBase

var hero_type: int = Constants.HeroType.WARRIOR
var player_data: PlayerData = null

var cooldown_q: float = 0.0
var cooldown_w: float = 0.0
var cooldown_q_max: float = 5.0
var cooldown_w_max: float = 8.0
var mana_cost_q: int = 30
var mana_cost_w: int = 50
var q_ready: bool = true
var w_ready: bool = true

func _ready():
	var data = HeroDatabase.get_hero(hero_type)
	if data.has("q_cooldown"): cooldown_q_max = data.q_cooldown
	if data.has("w_cooldown"): cooldown_w_max = data.w_cooldown
	if data.has("q_mana"): mana_cost_q = data.q_mana
	if data.has("w_mana"): mana_cost_w = data.w_mana

func _process(delta):
	if not q_ready:
		cooldown_q -= delta
		if cooldown_q <= 0:
			cooldown_q = 0
			q_ready = true
	if not w_ready:
		cooldown_w -= delta
		if cooldown_w <= 0:
			cooldown_w = 0
			w_ready = true

func can_cast_q() -> bool:
	return q_ready and player_data != null and player_data.get_mana() >= mana_cost_q

func can_cast_w() -> bool:
	return w_ready and player_data != null and player_data.get_mana() >= mana_cost_w

func use_mana(amount: int) -> bool:
	if player_data == null or player_data.get_mana() < amount:
		return false
	return true

func ability_q():
	if not can_cast_q():
		return
	q_ready = false
	cooldown_q = cooldown_q_max
	_on_ability_q_used()

func ability_w():
	if not can_cast_w():
		return
	w_ready = false
	cooldown_w = cooldown_w_max
	_on_ability_w_used()

func _on_ability_q_used():
	pass

func _on_ability_w_used():
	pass

func get_q_progress() -> float:
	if q_ready:
		return 1.0
	return 1.0 - (cooldown_q / cooldown_q_max)

func get_w_progress() -> float:
	if w_ready:
		return 1.0
	return 1.0 - (cooldown_w / cooldown_w_max)

func get_ability_q_name() -> String:
	return HeroDatabase.get_hero(hero_type).get("q_name", "Q")

func get_ability_w_name() -> String:
	return HeroDatabase.get_hero(hero_type).get("w_name", "W")
