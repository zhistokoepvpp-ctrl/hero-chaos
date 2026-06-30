extends Node

const SAVE_PATH := "user://profile.json"
var profile: Dictionary = {}

func _ready():
	load_profile()

func load_profile():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var decoded = Marshalls.base64_to_utf8(text)
		if decoded:
			profile = JSON.parse_string(decoded) as Dictionary
		if profile.is_empty():
			_create_default_profile()
	else:
		_create_default_profile()

func _create_default_profile():
	profile = {
		"player_name": "Player",
		"mmr": Constants.BASE_MMR,
		"season": 1,
		"stats": {
			"games_played": 0,
			"games_won": 0,
			"total_kills": 0,
			"total_deaths": 0,
			"total_gold": 0,
			"best_wave": 0,
			"bosses_killed": 0,
			"duels_won": 0
		},
		"heroes": {},
		"unlocks": {
			"titles": [],
			"skins": []
		}
	}
	save_profile()

func save_profile():
	var json_str = JSON.stringify(profile)
	var encoded = Marshalls.utf8_to_base64(json_str)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(encoded)
		file.close()

func add_stat(stat_name: String, value: int):
	if profile.stats.has(stat_name):
		profile.stats[stat_name] += value
	save_profile()

func set_player_name(name: String):
	profile.player_name = name
	save_profile()
