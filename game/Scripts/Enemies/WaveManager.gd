extends Node
class_name WaveManager

var arena_view: Node2D = null
var hero_node: Node2D = null
var hero_data = null
var monsters: Array = []

signal all_monsters_died(gold: int, xp: int)
signal monster_spawned(monster: MonsterBase)

func _ready():
	pass

func spawn_wave(wave_number: int):
	_clear_monsters()
	var count = _get_monster_count(wave_number)
	var types = _get_wave_types(wave_number)
	
	for i in range(count):
		var t = types[i % types.size()]
		var data = _get_monster_stats(t, wave_number)
		var m = MonsterBase.new(data)
		m.set_target(hero_node, hero_data)
		m.died.connect(_on_monster_died)
		m.position = _get_spawn_position()
		
		if arena_view:
			arena_view.add_child(m)
		
		monsters.append(m)
		monster_spawned.emit(m)
	
	if wave_number % Constants.BOSS_INTERVAL == 0:
		_spawn_boss(wave_number)

func _spawn_boss(wave_number: int):
	var boss_types = ["boss_giant", "boss_chaos", "boss_dragon"]
	var boss_type = boss_types[(wave_number / Constants.BOSS_INTERVAL - 1) % boss_types.size()]
	var data = _get_monster_stats(boss_type, wave_number)
	data.hp *= 3.0
	data.damage *= 2.0
	data.speed *= 0.7
	data.gold_reward *= 5
	data.xp_reward *= 5
	
	var boss = MonsterBase.new(data)
	boss.set_target(hero_node, hero_data)
	boss.died.connect(_on_monster_died)
	boss.position = _get_spawn_position()
	
	if arena_view:
		arena_view.add_child(boss)
	
	monsters.append(boss)
	monster_spawned.emit(boss)

func _on_monster_died(gold: int, xp: int, pos: Vector2):
	monsters = monsters.filter(func(m): return is_instance_valid(m) and m._alive)
	
	if monsters.is_empty():
		all_monsters_died.emit(0, 0)

func _clear_monsters():
	for m in monsters:
		if is_instance_valid(m):
			m.queue_free()
	monsters.clear()

func _get_monster_count(wave: int) -> int:
	return Constants.MONSTER_BASE_COUNT + wave * Constants.MONSTER_COUNT_PER_WAVE

func _get_wave_types(wave: int) -> Array:
	if wave <= 3:
		return ["slime", "wolf"]
	elif wave <= 6:
		return ["slime", "wolf", "skeleton"]
	elif wave <= 10:
		return ["wolf", "skeleton", "golem"]
	elif wave <= 15:
		return ["skeleton", "ghost", "demon"]
	else:
		return ["demon", "elemental", "ghost"]

func _get_monster_stats(type: String, wave: int) -> Dictionary:
	var base_hp = 50.0
	var base_dmg = 8.0
	var base_spd = 80.0
	
	match type:
		"slime": base_hp = 40; base_dmg = 5; base_spd = 60
		"wolf": base_hp = 30; base_dmg = 8; base_spd = 120
		"skeleton": base_hp = 60; base_dmg = 10; base_spd = 80
		"golem": base_hp = 150; base_dmg = 15; base_spd = 40
		"ghost": base_hp = 35; base_dmg = 12; base_spd = 100
		"demon": base_hp = 80; base_dmg = 18; base_spd = 90
		"elemental": base_hp = 50; base_dmg = 14; base_spd = 70
		"boss_giant": base_hp = 500; base_dmg = 30; base_spd = 50
		"boss_chaos": base_hp = 400; base_dmg = 35; base_spd = 70
		"boss_dragon": base_hp = 600; base_dmg = 40; base_spd = 60
	
	var scale_hp = 1.0 + wave * Constants.MONSTER_HP_MULT
	var scale_dmg = 1.0 + wave * Constants.MONSTER_DMG_MULT
	
	return {
		"hp": base_hp * scale_hp,
		"damage": base_dmg * scale_dmg,
		"speed": base_spd,
		"attack_range": 50.0,
		"attack_cooldown": 1.0,
		"gold_reward": int(10 + wave * 2),
		"xp_reward": int(20 + wave * 5),
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
