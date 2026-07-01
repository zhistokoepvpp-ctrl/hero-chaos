extends Node
class_name WaveManager

var arena_view: Node2D = null
var hero_node: Node = null
var hero_data = null
var monsters: Array = []

signal monster_spawned(monster: MonsterBase)

func spawn_wave(wave_number: int):
	_clear_monsters()
	var count = _get_monster_count(wave_number)
	var pool = _build_type_pool(wave_number, count)
	
	for t in pool:
		var data = _get_monster_stats(t, wave_number)
		var m = MonsterBase.new(data)
		m.set_target(hero_node, hero_data)
		m.position = _get_spawn_position()
		_setup_special(m, t)
		
		if arena_view:
			arena_view.add_child(m)
		monsters.append(m)
		monster_spawned.emit(m)
	
	if wave_number % Constants.BOSS_INTERVAL == 0:
		_spawn_boss(wave_number)

func _setup_special(m: MonsterBase, t: String):
	match t:
		"demon": m.attack_range = 300.0
		"spitter": m.attack_range = 280.0
		"shieldbearer": m.set_meta("block_aura", true)
		"ghost": m.set_meta("phasing", true)

func _spawn_boss(wave_number: int):
	var boss_type = "boss_golem"
	if wave_number >= 20: boss_type = "boss_lich"
	if wave_number >= 30: boss_type = "boss_dragon"
	
	var data = _get_monster_stats(boss_type, wave_number)
	var boss = MonsterBase.new(data)
	boss.set_target(hero_node, hero_data)
	boss.position = Vector2(590, 50)
	
	if arena_view:
		arena_view.add_child(boss)
	monsters.append(boss)
	monster_spawned.emit(boss)

func _clear_monsters():
	for m in monsters:
		if is_instance_valid(m):
			m.queue_free()
	monsters.clear()

func _get_monster_count(wave: int) -> int:
	return Constants.MONSTER_BASE_COUNT + wave * Constants.MONSTER_COUNT_PER_WAVE

func _build_type_pool(wave: int, count: int) -> Array:
	var types = []
	
	if wave <= 2:
		types = ["slime"]
	elif wave <= 4:
		types = ["slime", "slime", "slime", "skeleton", "skeleton"]
	elif wave <= 6:
		types = ["slime", "slime", "skeleton", "skeleton", "bat", "bat", "bat"]
	elif wave == 7:
		types = ["slime", "slime", "slime", "skeleton", "skeleton", "bat", "bat", "demon", "demon"]
	elif wave <= 9:
		types = ["slime", "skeleton", "bat", "demon", "spitter", "spitter"]
	elif wave <= 11:
		types = ["slime", "skeleton", "bat", "demon", "spitter"]
	elif wave <= 14:
		types = ["skeleton", "bat", "demon", "spitter", "shieldbearer"]
	elif wave <= 19:
		types = ["skeleton", "demon", "spitter", "shieldbearer", "ghost", "ghost"]
	else:
		types = ["demon", "spitter", "shieldbearer", "ghost"]
	
	var pool = []
	for i in range(count):
		pool.append(types[i % types.size()])
	pool.shuffle()
	return pool

func _get_monster_stats(type: String, wave: int) -> Dictionary:
	var base_hp = 50.0
	var base_dmg = 5.0
	var base_spd = 100.0
	var base_arm = 0.0
	var base_gold = 8
	var base_xp = 10
	var atk_range = 50.0
	
	match type:
		"slime": base_hp = 50; base_dmg = 5; base_spd = 100; base_arm = 0; base_gold = 8; base_xp = 10
		"skeleton": base_hp = 40; base_dmg = 8; base_spd = 140; base_arm = 2; base_gold = 12; base_xp = 15
		"bat": base_hp = 25; base_dmg = 6; base_spd = 200; base_arm = 0; base_gold = 6; base_xp = 8
		"demon": base_hp = 80; base_dmg = 12; base_spd = 130; base_arm = 3; base_gold = 15; base_xp = 20; atk_range = 300
		"spitter": base_hp = 35; base_dmg = 7; base_spd = 110; base_arm = 1; base_gold = 10; base_xp = 12; atk_range = 280
		"shieldbearer": base_hp = 120; base_dmg = 4; base_spd = 80; base_arm = 8; base_gold = 20; base_xp = 25
		"ghost": base_hp = 20; base_dmg = 10; base_spd = 180; base_arm = 0; base_gold = 12; base_xp = 18
		"boss_golem": base_hp = 500; base_dmg = 25; base_spd = 80; base_arm = 10; base_gold = 200; base_xp = 500
		"boss_lich": base_hp = 800; base_dmg = 15; base_spd = 100; base_arm = 5; base_gold = 200; base_xp = 500
		"boss_dragon": base_hp = 1200; base_dmg = 35; base_spd = 120; base_arm = 8; base_gold = 200; base_xp = 500
	
	var scale_hp = 1.0 + wave * Constants.MONSTER_HP_MULT
	var scale_dmg = 1.0 + wave * Constants.MONSTER_DMG_MULT
	var boss_div = 10.0 if "boss" in type else 1.0
	var wave_div = wave / boss_div if "boss" in type else 1.0
	
	var ot_hp_mult = 1.0
	var ot_dmg_mult = 1.0
	var ot_spd_mult = 1.0
	if GameManager._overtime_active:
		ot_dmg_mult = 1.0 + GameManager._overtime_seconds * Constants.OVERTIME_DMG_PER_SEC * 2
		ot_spd_mult = 1.0 + GameManager._overtime_seconds * Constants.OVERTIME_SPD_PER_SEC * 3
		ot_hp_mult = 1.0 + GameManager._overtime_seconds * 0.015
	
	return {
		"hp": ((base_hp * scale_hp * wave_div) if "boss" in type else (base_hp * scale_hp)) * ot_hp_mult,
		"damage": ((base_dmg * scale_dmg * wave_div) if "boss" in type else (base_dmg * scale_dmg)) * ot_dmg_mult,
		"speed": base_spd * ot_spd_mult,
		"armor": base_arm,
		"attack_range": atk_range,
		"attack_cooldown": 1.0,
		"gold_reward": base_gold,
		"xp_reward": base_xp,
		"type": type
	}

func _get_spawn_position() -> Vector2:
	var margin = 80.0
	var view_size = Vector2(1280, 720)
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(margin, view_size.x - margin), margin)
		1: return Vector2(randf_range(margin, view_size.x - margin), view_size.y - margin)
		2: return Vector2(margin, randf_range(margin, view_size.y - margin))
		_: return Vector2(view_size.x - margin, randf_range(margin, view_size.y - margin))
