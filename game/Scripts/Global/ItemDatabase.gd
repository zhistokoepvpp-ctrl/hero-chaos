extends Node

var items: Dictionary = {}
var recipes: Dictionary = {}

func _ready():
	_register_items()

func _register_items():
	items[1] = {"name": "Health Crystal", "cost": 150, "effects": {"max_hp": 200}}
	items[2] = {"name": "Mana Crystal", "cost": 100, "effects": {"max_mana": 150}}
	items[3] = {"name": "Blade", "cost": 150, "effects": {"damage": 15}}
	items[4] = {"name": "Armor Plate", "cost": 120, "effects": {"armor": 5}}
	items[5] = {"name": "Boots", "cost": 100, "effects": {"speed": 20}}
	items[6] = {"name": "Gloves of Attack", "cost": 120, "effects": {"atk_speed": 0.15}}
	items[7] = {"name": "Ring of Regen", "cost": 80, "effects": {"hp_regen": 3}}
	items[8] = {"name": "Staff of Power", "cost": 130, "effects": {"abl_dmg": 15}}
	items[9] = {"name": "Iron Shield", "cost": 200, "effects": {"armor": 10, "max_hp": 100}}
	items[10] = {"name": "Evasion Charm", "cost": 150, "effects": {"dodge": 0.15}}
	items[11] = {"name": "Mystic Orb", "cost": 180, "effects": {"cooldown_reduction": 0.1}}
	items[12] = {"name": "Cloak of Shadows", "cost": 130, "effects": {"dodge": 0.05, "speed": 5}}
	items[13] = {"name": "Power Gauntlets", "cost": 160, "effects": {"lifesteal": 0.1}}
	items[14] = {"name": "Sage's Crown", "cost": 100, "effects": {"mana_regen": 1}}
	items[15] = {"name": "Spike Shield", "cost": 140, "effects": {"reflect": 0.1}}

	_register_recipes()

func _register_recipes():
	recipes[101] = {"result": {"name": "Vitality Booster", "effects": {"max_hp": 400, "hp_regen": 5}}, "components": [7, 1], "combine_cost": 50}
	recipes[102] = {"result": {"name": "Shadow Blade", "effects": {"damage": 30, "atk_speed": 0.30}}, "components": [3, 6], "combine_cost": 50}
	recipes[103] = {"result": {"name": "Guardian Armor", "effects": {"armor": 20, "max_hp": 200}}, "components": [4, 9], "combine_cost": 70}
	recipes[104] = {"result": {"name": "Arcane Staff", "effects": {"abl_dmg": 30, "max_mana": 250}}, "components": [8, 2], "combine_cost": 50}
	recipes[105] = {"result": {"name": "Swift Boots", "effects": {"speed": 40, "dodge": 0.15}}, "components": [5, 10], "combine_cost": 40}
	recipes[106] = {"result": {"name": "Battle Fury", "effects": {"damage": 40, "max_hp": 200, "cleave": 0.30}}, "components": [3, 1], "combine_cost": 60}
	recipes[107] = {"result": {"name": "Echo Blade", "effects": {"damage": 25, "atk_speed": 0.25, "double_strike": 0.10}}, "components": [3, 6, 11], "combine_cost": 80}
	recipes[108] = {"result": {"name": "Immortal Vest", "effects": {"armor": 25, "max_hp": 300, "hp_regen": 5}}, "components": [4, 9, 1], "combine_cost": 100}
	recipes[109] = {"result": {"name": "Phantom Cloak", "effects": {"dodge": 0.25, "speed": 10}}, "components": [10, 12], "combine_cost": 60}
	recipes[110] = {"result": {"name": "Arcane Crown", "effects": {"abl_dmg": 40, "cooldown_reduction": 0.15, "mana_regen": 2}}, "components": [8, 11, 14], "combine_cost": 80}

func get_item(item_id: int) -> Dictionary:
	return items.get(item_id, {})

func get_recipe(recipe_id: int) -> Dictionary:
	return recipes.get(recipe_id, {})

func find_recipes_for_item(item_id: int) -> Array:
	var found = []
	for rid in recipes:
		var r = recipes[rid]
		if item_id in r.components:
			found.append(rid)
	return found
