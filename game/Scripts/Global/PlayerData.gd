class_name PlayerData
extends RefCounted

var peer_id: int
var player_name: String = "Player"
var hero_type: int = Constants.HeroType.WARRIOR

# Attributes
var str_attr: int = 0
var agi_attr: int = 0
var int_attr: int = 0
var free_attr_points: int = 0

# Derived stats
var level: int = 1
var xp: int = 0
var gold: int = Constants.STARTING_GOLD
var lives: int = Constants.STARTING_LIVES
var alive: bool = true

# Equipment
var inventory: Array = []  # item ids (max 6 slots)
var consumables: Array = []  # {item_id: count}

# Wave tracking
var current_wave: int = 0
var kills_this_wave: Dictionary = {}
var wave_clear_time: float = 0.0
var placement: int = 0

func _init(id: int, name: String = "Player"):
	peer_id = id
	player_name = name

func setup_hero(h_type: int):
	hero_type = h_type
	var data = HeroDatabase.get_hero(h_type)
	str_attr = data.base_str
	agi_attr = data.base_agi
	int_attr = data.base_int

func add_xp(amount: int) -> bool:
	xp += amount
	while level < Constants.MAX_LEVEL:
		var needed = get_xp_for_level(level)
		if xp >= needed:
			xp -= needed
			level += 1
			free_attr_points += Constants.ATTR_POINTS_PER_LEVEL
		else:
			break
	return true

func get_xp_for_level(lvl: int) -> int:
	return 50 + (lvl * 50)

func add_gold(amount: int):
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

func add_item(item_id: int) -> bool:
	if inventory.size() >= 6:
		return false
	inventory.append(item_id)
	return true

func remove_item(slot: int) -> bool:
	if slot < 0 or slot >= inventory.size():
		return false
	inventory.remove_at(slot)
	return true

func has_item(item_id: int) -> bool:
	return item_id in inventory

func remove_item_by_id(item_id: int) -> bool:
	var idx = inventory.find(item_id)
	if idx >= 0:
		inventory.remove_at(idx)
		return true
	return false

func count_item(item_id: int) -> int:
	var c = 0
	for id in inventory:
		if id == item_id:
			c += 1
	return c

func get_item_effects() -> Dictionary:
	var total = {}
	for id in inventory:
		var item = ItemDatabase.get_item(id)
		if item.is_empty():
			continue
		for key in item.effects:
			total[key] = total.get(key, 0) + item.effects[key]
	return total

func get_hp() -> float:
	var base = Constants.BASE_HP + str_attr * Constants.HP_PER_STR
	var eff = get_item_effects()
	return base + eff.get("max_hp", 0)

func get_mana() -> float:
	var base = Constants.BASE_MANA + int_attr * Constants.MANA_PER_INT
	var eff = get_item_effects()
	return base + eff.get("max_mana", 0)

func get_hp_regen() -> float:
	var base = str_attr * Constants.HP_REGEN_PER_STR
	var eff = get_item_effects()
	return base + eff.get("hp_regen", 0)

func get_armor() -> float:
	var base = agi_attr * Constants.ARMOR_PER_AGI
	var eff = get_item_effects()
	return base + eff.get("armor", 0)

func get_atk_speed() -> float:
	var data = HeroDatabase.get_hero(hero_type)
	var base = data.base_aspd + agi_attr * Constants.ATK_SPD_PER_AGI
	var eff = get_item_effects()
	return base + eff.get("atk_speed", 0)

func get_damage() -> int:
	var data = HeroDatabase.get_hero(hero_type)
	var primary = data.primary
	var primary_val = 0
	match primary:
		Constants.AttrType.STR: primary_val = str_attr
		Constants.AttrType.AGI: primary_val = agi_attr
		Constants.AttrType.INT: primary_val = int_attr
	var eff = get_item_effects()
	return data.base_dmg + primary_val + eff.get("damage", 0)

func get_speed() -> float:
	var data = HeroDatabase.get_hero(hero_type)
	var eff = get_item_effects()
	return data.base_spd + eff.get("speed", 0)

func get_primary_value() -> int:
	var data = HeroDatabase.get_hero(hero_type)
	match data.primary:
		Constants.AttrType.STR: return str_attr
		Constants.AttrType.AGI: return agi_attr
		Constants.AttrType.INT: return int_attr
	return 0

func serialize() -> Dictionary:
	return {
		"peer_id": peer_id,
		"player_name": player_name,
		"hero_type": hero_type,
		"str": str_attr, "agi": agi_attr, "int": int_attr,
		"level": level, "xp": xp, "gold": gold, "lives": lives,
		"alive": alive, "inventory": inventory.duplicate(),
		"current_wave": current_wave
	}

static func deserialize(data: Dictionary) -> PlayerData:
	var p = PlayerData.new(data.peer_id, data.player_name)
	p.hero_type = data.hero_type
	p.str_attr = data.str; p.agi_attr = data.agi; p.int_attr = data.int
	p.level = data.level; p.xp = data.xp; p.gold = data.gold
	p.lives = data.lives; p.alive = data.alive
	p.inventory = data.inventory.duplicate()
	p.current_wave = data.current_wave
	return p
