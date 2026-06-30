extends Node

var heroes: Dictionary = {}

func _ready():
	_register_heroes()

func _register_heroes():
	heroes[Constants.HeroType.WARRIOR] = {
		"name": "Warrior",
		"role": "Melee Tank",
		"primary": Constants.AttrType.STR,
		"base_str": 25, "base_agi": 15, "base_int": 10,
		"base_dmg": 30, "base_aspd": 1.0, "base_spd": 300.0,
		"attack_range": 150.0,
		"description": "Ближний боец с высоким HP и защитой. Q: рывок к врагу. W: щит.",
		"q_name": "Charge", "q_desc": "Рывок к врагу с уроном + оглушение",
		"w_name": "Shield", "w_desc": "Поглощающий щит на 3 сек"
	}
	heroes[Constants.HeroType.ARCHER] = {
		"name": "Archer",
		"role": "Ranged DPS",
		"primary": Constants.AttrType.AGI,
		"base_str": 18, "base_agi": 28, "base_int": 12,
		"base_dmg": 25, "base_aspd": 1.2, "base_spd": 320.0,
		"attack_range": 500.0,
		"description": "Дальний боец с высокой скоростью атаки. Q: град стрел. W: метка урона.",
		"q_name": "Arrow Volley", "q_desc": "3 быстрые стрелы",
		"w_name": "Mark", "q_desc": "Цель получает +25% урона"
	}
	heroes[Constants.HeroType.MAGE] = {
		"name": "Mage",
		"role": "Ranged Burst",
		"primary": Constants.AttrType.INT,
		"base_str": 15, "base_agi": 12, "base_int": 28,
		"base_dmg": 20, "base_aspd": 0.9, "base_spd": 290.0,
		"attack_range": 400.0,
		"description": "Маг с мощными AoE-атаками. Q: огненный шар (взрыв). W: магический щит.",
		"q_name": "Fireball", "w_name": "Arcane Barrier"
	}
	heroes[Constants.HeroType.ASSASSIN] = {
		"name": "Assassin",
		"role": "Melee Burst",
		"primary": Constants.AttrType.AGI,
		"base_str": 14, "base_agi": 28, "base_int": 8,
		"base_dmg": 28, "base_aspd": 1.3, "base_spd": 330.0,
		"attack_range": 150.0
	}
	heroes[Constants.HeroType.PALADIN] = {
		"name": "Paladin",
		"role": "Melee Sustain",
		"primary": Constants.AttrType.STR,
		"base_str": 26, "base_agi": 10, "base_int": 14,
		"base_dmg": 28, "base_aspd": 0.95, "base_spd": 295.0,
		"attack_range": 150.0
	}
	heroes[Constants.HeroType.NECROMANCER] = {
		"name": "Necromancer",
		"role": "Ranged Summoner",
		"primary": Constants.AttrType.INT,
		"base_str": 14, "base_agi": 8, "base_int": 28,
		"base_dmg": 18, "base_aspd": 0.9, "base_spd": 295.0,
		"attack_range": 400.0
	}
	heroes[Constants.HeroType.BERSERKER] = {
		"name": "Berserker",
		"role": "Melee Glass Cannon",
		"primary": Constants.AttrType.STR,
		"base_str": 26, "base_agi": 14, "base_int": 10,
		"base_dmg": 32, "base_aspd": 1.1, "base_spd": 320.0,
		"attack_range": 150.0
	}
	heroes[Constants.HeroType.SHAMAN] = {
		"name": "Shaman",
		"role": "Ranged Hybrid",
		"primary": Constants.AttrType.INT,
		"base_str": 14, "base_agi": 10, "base_int": 26,
		"base_dmg": 20, "base_aspd": 1.0, "base_spd": 305.0,
		"attack_range": 450.0
	}
	heroes[Constants.HeroType.GUNSLINGER] = {
		"name": "Gunslinger",
		"role": "Ranged Mobile",
		"primary": Constants.AttrType.AGI,
		"base_str": 12, "base_agi": 28, "base_int": 10,
		"base_dmg": 24, "base_aspd": 1.1, "base_spd": 315.0,
		"attack_range": 500.0
	}
	heroes[Constants.HeroType.SPELLBLADE] = {
		"name": "Spellblade",
		"role": "Melee Magic Hybrid",
		"primary": Constants.AttrType.INT,
		"base_str": 18, "base_agi": 10, "base_int": 24,
		"base_dmg": 22, "base_aspd": 1.0, "base_spd": 310.0,
		"attack_range": 150.0
	}

func get_hero(type: int) -> Dictionary:
	return heroes.get(type, heroes[Constants.HeroType.WARRIOR])

func get_starting_hp(hero_data: Dictionary) -> float:
	return Constants.BASE_HP + hero_data.base_str * Constants.HP_PER_STR

func get_starting_mana(hero_data: Dictionary) -> float:
	return Constants.BASE_MANA + hero_data.base_int * Constants.MANA_PER_INT

func get_starting_armor(hero_data: Dictionary) -> float:
	return hero_data.base_agi * Constants.ARMOR_PER_AGI
