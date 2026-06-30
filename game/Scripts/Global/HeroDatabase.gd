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
		"w_name": "Shield", "w_desc": "Поглощающий щит на 3 сек",
		"q_cooldown": 8.0, "w_cooldown": 12.0, "q_mana": 30, "w_mana": 50
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
		"w_name": "Mark", "w_desc": "Цель получает +25% урона",
		"q_cooldown": 6.0, "w_cooldown": 10.0, "q_mana": 25, "w_mana": 40
	}
	heroes[Constants.HeroType.MAGE] = {
		"name": "Mage",
		"role": "Ranged Burst",
		"primary": Constants.AttrType.INT,
		"base_str": 15, "base_agi": 12, "base_int": 28,
		"base_dmg": 20, "base_aspd": 0.9, "base_spd": 290.0,
		"attack_range": 400.0,
		"description": "Маг с мощными AoE-атаками. Q: огненный шар (взрыв). W: магический щит.",
		"q_name": "Fireball", "q_desc": "Огненный шар с AoE взрывом",
		"w_name": "Arcane Barrier", "w_desc": "Магический щит, поглощающий урон",
		"q_cooldown": 7.0, "w_cooldown": 15.0, "q_mana": 40, "w_mana": 60
	}
	heroes[Constants.HeroType.ASSASSIN] = {
		"name": "Assassin",
		"role": "Melee Burst",
		"primary": Constants.AttrType.AGI,
		"base_str": 14, "base_agi": 28, "base_int": 8,
		"base_dmg": 28, "base_aspd": 1.3, "base_spd": 330.0,
		"attack_range": 150.0,
		"description": "Скрытный убийца с высоким критом. Q: рывок в тени. W: яд.",
		"q_name": "Shadow Strike", "q_desc": "Рывок к цели с крит. ударом",
		"w_name": "Poison Blade", "w_desc": "Отравляет цель, нанося периодический урон",
		"q_cooldown": 6.0, "w_cooldown": 9.0, "q_mana": 25, "w_mana": 35
	}
	heroes[Constants.HeroType.PALADIN] = {
		"name": "Paladin",
		"role": "Melee Sustain",
		"primary": Constants.AttrType.STR,
		"base_str": 26, "base_agi": 10, "base_int": 14,
		"base_dmg": 28, "base_aspd": 0.95, "base_spd": 295.0,
		"attack_range": 150.0,
		"description": "Святой рыцарь с лечением и баффами. Q: исцеление. W: благословение.",
		"q_name": "Holy Light", "q_desc": "Исцеляет союзника или себя",
		"w_name": "Blessing", "w_desc": "Повышает броню и регенерацию",
		"q_cooldown": 10.0, "w_cooldown": 20.0, "q_mana": 35, "w_mana": 50
	}
	heroes[Constants.HeroType.NECROMANCER] = {
		"name": "Necromancer",
		"role": "Ranged Summoner",
		"primary": Constants.AttrType.INT,
		"base_str": 14, "base_agi": 8, "base_int": 28,
		"base_dmg": 18, "base_aspd": 0.9, "base_spd": 295.0,
		"attack_range": 400.0,
		"description": "Некромант, призывающий скелетов. Q: призыв скелета. W: порча.",
		"q_name": "Summon Skeleton", "q_desc": "Призывает скелета-воина на 10 сек",
		"w_name": "Curse", "w_desc": "Проклинает врага, снижая его броню",
		"q_cooldown": 12.0, "w_cooldown": 8.0, "q_mana": 45, "w_mana": 30
	}
	heroes[Constants.HeroType.BERSERKER] = {
		"name": "Berserker",
		"role": "Melee Glass Cannon",
		"primary": Constants.AttrType.STR,
		"base_str": 26, "base_agi": 14, "base_int": 10,
		"base_dmg": 32, "base_aspd": 1.1, "base_spd": 320.0,
		"attack_range": 150.0,
		"description": "Берсерк с бешенством. Q: топот (AoE станы). W: берсерк (+скорость).",
		"q_name": "Stomp", "q_desc": "Топот, оглушающий врагов в радиусе",
		"w_name": "Berserk", "w_desc": "Увеличивает скорость атаки и передвижения",
		"q_cooldown": 10.0, "w_cooldown": 18.0, "q_mana": 20, "w_mana": 30
	}
	heroes[Constants.HeroType.SHAMAN] = {
		"name": "Shaman",
		"role": "Ranged Hybrid",
		"primary": Constants.AttrType.INT,
		"base_str": 14, "base_agi": 10, "base_int": 26,
		"base_dmg": 20, "base_aspd": 1.0, "base_spd": 305.0,
		"attack_range": 450.0,
		"description": "Шаман с элементальной магией. Q: цепная молния. W: тотем исцеления.",
		"q_name": "Chain Lightning", "q_desc": "Молния, прыгающая между врагами",
		"w_name": "Healing Totem", "w_desc": "Ставит тотем, исцеляющий союзников",
		"q_cooldown": 7.0, "w_cooldown": 14.0, "q_mana": 35, "w_mana": 55
	}
	heroes[Constants.HeroType.GUNSLINGER] = {
		"name": "Gunslinger",
		"role": "Ranged Mobile",
		"primary": Constants.AttrType.AGI,
		"base_str": 12, "base_agi": 28, "base_int": 10,
		"base_dmg": 24, "base_aspd": 1.1, "base_spd": 315.0,
		"attack_range": 500.0,
		"description": "Стрелок с акробатикой. Q: быстрый выстрел. W: сальто рывок.",
		"q_name": "Quick Shot", "q_desc": "Быстрый выстрел с повышенным критом",
		"w_name": "Flip", "w_desc": "Рывок в направлении курсора",
		"q_cooldown": 4.0, "w_cooldown": 10.0, "q_mana": 20, "w_mana": 35
	}
	heroes[Constants.HeroType.SPELLBLADE] = {
		"name": "Spellblade",
		"role": "Melee Magic Hybrid",
		"primary": Constants.AttrType.INT,
		"base_str": 18, "base_agi": 10, "base_int": 24,
		"base_dmg": 22, "base_aspd": 1.0, "base_spd": 310.0,
		"attack_range": 150.0,
		"description": "Маг-мечник с зачарованным клинком. Q: магический удар. W: телепорт.",
		"q_name": "Magic Blade", "q_desc": "Удар с дополнительным магическим уроном",
		"w_name": "Blink", "w_desc": "Телепортация на небольшое расстояние",
		"q_cooldown": 5.0, "w_cooldown": 10.0, "q_mana": 30, "w_mana": 45
	}

func get_hero(type: int) -> Dictionary:
	return heroes.get(type, heroes[Constants.HeroType.WARRIOR])

func get_starting_hp(hero_data: Dictionary) -> float:
	return Constants.BASE_HP + hero_data.base_str * Constants.HP_PER_STR

func get_starting_mana(hero_data: Dictionary) -> float:
	return Constants.BASE_MANA + hero_data.base_int * Constants.MANA_PER_INT

func get_starting_armor(hero_data: Dictionary) -> float:
	return hero_data.base_agi * Constants.ARMOR_PER_AGI

func get_hero_script_path(h_type: int) -> String:
	match h_type:
		Constants.HeroType.WARRIOR: return "res://Scripts/Heroes/HeroWarrior.gd"
		Constants.HeroType.ARCHER: return "res://Scripts/Heroes/HeroArcher.gd"
		Constants.HeroType.MAGE: return "res://Scripts/Heroes/HeroMage.gd"
		Constants.HeroType.ASSASSIN: return "res://Scripts/Heroes/HeroAssassin.gd"
		Constants.HeroType.PALADIN: return "res://Scripts/Heroes/HeroPaladin.gd"
		Constants.HeroType.NECROMANCER: return "res://Scripts/Heroes/HeroNecromancer.gd"
		Constants.HeroType.BERSERKER: return "res://Scripts/Heroes/HeroBerserker.gd"
		Constants.HeroType.SHAMAN: return "res://Scripts/Heroes/HeroShaman.gd"
		Constants.HeroType.GUNSLINGER: return "res://Scripts/Heroes/HeroGunslinger.gd"
		Constants.HeroType.SPELLBLADE: return "res://Scripts/Heroes/HeroSpellblade.gd"
		_: return "res://Scripts/Heroes/HeroWarrior.gd"
