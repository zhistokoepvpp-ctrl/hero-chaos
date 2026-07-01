extends Control

@onready var arena_view: Node2D = $ArenaView
@onready var hero_rect: ColorRect = $ArenaView/Hero
@onready var target_pos: ColorRect = $ArenaView/TargetPos
@onready var timer_label: Label = $TimerLabel
@onready var level_label: Label = $PortraitLevel
@onready var portrait_rect: ColorRect = $PortraitRect
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
@onready var wave_label: Label = $WaveLabel
@onready var lives_label: Label = $LivesLabel
@onready var hero_hp_bar: ColorRect = $ArenaView/Hero/HeroHpBar
@onready var hero_hp_bg: ColorRect = $ArenaView/Hero/HeroHpBg
@onready var hero_hp_label: Label = $ArenaView/Hero/HeroHpLabel
@onready var notify_label: Label = $NotifyLabel
var _inv_labels: Array[Label] = []
var _stat_tooltip: Panel
var _stat_tooltip_labels: Array[Label] = []
var _stat_tooltip_visible: bool = false

var _hero: HeroBase = null
var _wave_manager: WaveManager = null
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _attacking_target = null
var _hero_speed: float = 300.0
var _max_hp: float = 500.0
var _current_hp: float = 500.0
var _max_mana: float = 100.0
var _current_mana: float = 100.0
var _atk_cooldown: float = 0.0
var _atk_range: float = 150.0
var _atk_damage: int = 30
var _attacking_target_last_pos: Vector2 = Vector2.ZERO
var _prev_target = null
var _poison_timer: float = 0.0
var _poison_active: bool = false
var _ending: bool = false
var _control_scheme: String = "click"
var _wasd_moving: bool = false

func _ready():
	_create_inv_slots()
	_create_stat_tooltip()
	portrait_rect.mouse_entered.connect(_show_stat_tooltip)
	portrait_rect.mouse_exited.connect(_hide_stat_tooltip)
	GameManager.phase_changed.connect(_on_phase_changed)
	_spawn_hero()
	_setup_wave_manager()
	_control_scheme = AudioManager.get_setting("control_scheme", "click")
	if lives_label:
		lives_label.add_theme_color_override("font_color", Color.WHITE)

func _create_inv_slots():
	var positions = [
		Vector2(5, 620), Vector2(47, 620), Vector2(89, 620),
		Vector2(5, 662), Vector2(47, 662), Vector2(89, 662)
	]
	for i in 6:
		var slot = ColorRect.new()
		slot.position = positions[i]
		slot.size = Vector2(42, 42)
		slot.color = Color(0.1, 0.1, 0.15, 0.8)
		add_child(slot)
		var label = Label.new()
		label.position = Vector2(1, 1)
		label.size = Vector2(40, 40)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color.WHITE)
		slot.add_child(label)
		_inv_labels.append(label)

func _create_stat_tooltip():
	_stat_tooltip = Panel.new()
	_stat_tooltip.position = Vector2(412, 610 - 280 - 5)
	_stat_tooltip.size = Vector2(240, 280)
	_stat_tooltip.visible = false
	add_child(_stat_tooltip)
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(8, 8)
	vbox.size = Vector2(224, 264)
	_stat_tooltip.add_child(vbox)
	var stat_names = ["Level", "HP", "Mana", "HP Regen", "Damage", "Atk Speed", "Armor", "Speed", "STR", "AGI", "INT", "Gold", "Lives"]
	for name in stat_names:
		var lbl = Label.new()
		lbl.text = name + ": --"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(lbl)
		_stat_tooltip_labels.append(lbl)

func _show_stat_tooltip():
	_stat_tooltip_visible = true

func _hide_stat_tooltip():
	_stat_tooltip_visible = false
	_stat_tooltip.visible = false

func _update_stat_tooltip():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	var data = HeroDatabase.get_hero(p.hero_type)
	var primary_str = ""
	match data.get("primary", -1):
		Constants.AttrType.STR: primary_str = "STR"
		Constants.AttrType.AGI: primary_str = "AGI"
		Constants.AttrType.INT: primary_str = "INT"
		_: primary_str = "N/A"
	var vals = [
		"Level: %d" % p.level,
		"HP: %d/%d" % [_current_hp, _max_hp],
		"Mana: %d/%d" % [_current_mana, _max_mana],
		"HP Regen: %.1f/sec" % p.get_hp_regen(),
		"Damage: %d" % p.get_damage(),
		"Atk Speed: %.2f" % p.get_atk_speed(),
		"Armor: %.1f" % p.get_armor(),
		"Speed: %.0f" % p.get_speed(),
		"STR: %d %s" % [p.str_attr, "(Primary)" if primary_str == "STR" else ""],
		"AGI: %d %s" % [p.agi_attr, "(Primary)" if primary_str == "AGI" else ""],
		"INT: %d %s" % [p.int_attr, "(Primary)" if primary_str == "INT" else ""],
		"Gold: %d" % p.gold,
		"Lives: %s" % ("♥♥" if p.lives == 2 else ("♥♡" if p.lives == 1 else "♡♡"))
	]
	for i in vals.size():
		_stat_tooltip_labels[i].text = vals[i]
	_stat_tooltip.visible = true

func _spawn_hero():
	if not GameManager.players.has(GameManager.local_player_id):
		return
	var p = GameManager.players[GameManager.local_player_id]
	var h_type = p.hero_type
	var path = HeroDatabase.get_hero_script_path(h_type)
	var HeroScript = load(path)
	if not HeroScript:
		return
	_hero = HeroScript.new()
	_hero.hero_type = h_type
	_hero.player_data = p
	add_child(_hero)
	
	var data = HeroDatabase.get_hero(h_type)
	_hero_speed = data.base_spd
	_atk_range = data.attack_range
	_atk_damage = p.get_damage()
	_max_hp = p.get_hp()
	_current_hp = _max_hp
	_max_mana = p.get_mana()
	_current_mana = _max_mana
	if portrait_rect:
		portrait_rect.color = _get_hero_portrait_color(h_type)
	
	if q_label:
		q_label.text = "[Q] " + data.get("q_name", "?")
	if w_label:
		w_label.text = "[W] " + data.get("w_name", "?")

func _setup_wave_manager():
	_wave_manager = WaveManager.new()
	_wave_manager.arena_view = arena_view
	_wave_manager.hero_node = hero_rect
	_wave_manager.hero_data = GameManager.players.get(GameManager.local_player_id)
	_wave_manager.monster_spawned.connect(_on_monster_spawned)
	add_child(_wave_manager)
	_wave_manager.spawn_wave(GameManager.current_wave)

func _on_monster_spawned(monster: MonsterBase):
	monster.dealt_damage.connect(_on_monster_damage)
	if monster.is_spitter:
		monster.spitter_poison_applied.connect(_on_spitter_poison)

func _on_spitter_poison():
	_poison_active = true
	_poison_timer = 4.0

func _set_lives_label(lives: int):
	if lives_label:
		lives_label.visible = true
		lives_label.text = "♥♥" if lives >= 2 else ("♥♡" if lives == 1 else "♡♡")
		lives_label.add_theme_font_size_override("font_size", 20)
		lives_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))

func _on_monster_damage(amount: float):
	if _current_hp <= 0 or _ending:
		return
	_current_hp -= amount
	if _current_hp <= 0:
		_current_hp = 0
		_on_hero_death()

func _on_hero_death():
	if _ending:
		return
	_ending = true
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		_ending = false; return
	
	p.lives -= 1
	_set_lives_label(p.lives)
	
	if p.lives < 0:
		notify_label.text = "ELIMINATED!"
		GameManager.check_game_over()
		_ending = false
		return
	
	if p.lives == 0:
		notify_label.text = "Last chance! One more death and you're out."
	else:
		notify_label.text = "You died! Respawn in %ds..." % Constants.RESPAWN_DELAY
	
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		notify_label.text = ""
	
	p.alive = false
	hero_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)
	set_process(false)
	
	var respawn = get_tree().create_timer(Constants.RESPAWN_DELAY)
	await respawn.timeout
	
	if not is_inside_tree() or GameManager.phase != Constants.GamePhase.WAVE:
		_ending = false
		set_process(true)
		return
	
	_set_lives_label(p.lives)
	p.alive = true
	_current_hp = _max_hp
	hero_rect.modulate = Color.WHITE
	hero_rect.position = Vector2(590, 310)
	_ending = false
	set_process(true)

func _input(event):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
	
	var hit_monster = _find_monster_at(event.position)
	if hit_monster:
		_set_attack_target(hit_monster)
		_is_moving = false
		target_pos.visible = false
		return
	
	if _control_scheme == "wasd":
		return
	
	_set_attack_target(null)
	_move_target = event.position
	_is_moving = true

func _find_monster_at(pos: Vector2):
	for m in _wave_manager.monsters:
		if is_instance_valid(m) and m._alive:
			if m.position.distance_to(pos) < 50:
				return m
	return null

func _find_nearest_monster():
	var nearest = null
	var min_dist = 999999.0
	for m in _wave_manager.monsters:
		if is_instance_valid(m) and m._alive:
			var d = hero_rect.position.distance_to(m.position)
			if d < min_dist:
				min_dist = d
				nearest = m
	return nearest

func _process(delta):
	if Input.is_action_just_pressed("ability_q") and _hero:
		_hero.ability_q()
	if _control_scheme == "wasd":
		if Input.is_action_just_pressed("ability_e") and _hero:
			_hero.ability_w()
	else:
		if Input.is_action_just_pressed("ability_w") and _hero:
			_hero.ability_w()
	
		_wasd_moving = false
	if _control_scheme == "wasd":
		var wasd = Vector2.ZERO
		if Input.is_key_pressed(KEY_D): wasd.x += 1
		if Input.is_key_pressed(KEY_A): wasd.x -= 1
		if Input.is_key_pressed(KEY_S): wasd.y += 1
		if Input.is_key_pressed(KEY_W): wasd.y -= 1
		if wasd != Vector2.ZERO:
			hero_rect.position += wasd.normalized() * _hero_speed * delta
			target_pos.visible = false
			_wasd_moving = true
	
	if _is_moving:
		var dir = (_move_target - hero_rect.position)
		if dir.length() > 4:
			hero_rect.position += dir.normalized() * _hero_speed * delta
			target_pos.position = _move_target - Vector2(4, 4)
			target_pos.visible = true
		else:
			_is_moving = false
			target_pos.visible = false
	
	_combat_tick(delta)
	_update_hud(delta)

func _combat_tick(delta):
	if _current_hp <= 0 or _ending:
		return
	
	var p = GameManager.players.get(GameManager.local_player_id)
	if p:
		_current_hp = min(_max_hp, _current_hp + p.get_hp_regen() * delta)
		var mp_regen = p.int_attr * Constants.MANA_REGEN_PER_INT + p.get_item_effects().get("mana_regen", 0)
		_current_mana = min(_max_mana, _current_mana + mp_regen * delta)
	
	_atk_cooldown -= delta
	
	if not _wasd_moving and _attacking_target and is_instance_valid(_attacking_target) and _attacking_target._alive:
		_attacking_target_last_pos = _attacking_target.position
		var dist = hero_rect.position.distance_to(_attacking_target_last_pos)
		if dist > _atk_range:
			var dir = (_attacking_target_last_pos - hero_rect.position).normalized()
			hero_rect.position += dir * _hero_speed * delta
		elif _atk_cooldown <= 0:
			_atk_cooldown = 1.0 / _hero.player_data.get_atk_speed()
			if _attacking_target.take_damage(_atk_damage):
				p = GameManager.players[GameManager.local_player_id]
				p.add_gold(_attacking_target.gold_reward)
				p.add_xp(_attacking_target.xp_reward)
				_max_hp = p.get_hp()
				_max_mana = p.get_mana()
				_set_attack_target(_find_nearest_monster())
	else:
		_attacking_target = null
	
	var alive = 0
	var snap = _wave_manager.monsters.duplicate()
	for m in snap:
		if is_instance_valid(m) and m._alive:
			alive += 1
	if alive == 0 and snap.size() > 0 and not _ending:
		_ending = true
		var tree = get_tree()
		if tree:
			GameManager.on_wave_cleared(GameManager.local_player_id)
			GameManager.start_lobby_phase()
			tree.call_deferred("change_scene_to_file", "res://Scenes/Lobby.tscn")
	
	if GameManager._overtime_active:
		var ot = GameManager._overtime_seconds
		for m in _wave_manager.monsters:
			if is_instance_valid(m) and m._alive:
				var bd = m.get_meta("base_dmg", m.damage)
				var bs = m.get_meta("base_spd", m.speed)
				m.set_meta("base_dmg", bd)
				m.set_meta("base_spd", bs)
				m.damage = bd * (1.0 + ot * 0.02)
				m.speed = bs * (1.0 + ot * 0.01)
	
	if _poison_active:
		_poison_timer -= delta
		_current_hp -= 3.0 * delta
		if _poison_timer <= 0:
			_poison_active = false
		if _current_hp <= 0:
			_current_hp = 0
			_on_hero_death()

func _update_hud(delta):
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	
	if GameManager._wave_timer > 0:
		var t = int(GameManager._wave_timer)
		if timer_label:
			timer_label.text = "%02d:%02d" % [t / 60, t % 60]
			timer_label.modulate = Color.WHITE
	elif GameManager._overtime_active:
		var ot = GameManager._overtime_seconds
		if timer_label:
			timer_label.text = "OVERTIME %.1f" % ot
		if ot < 10:
			timer_label.modulate = Color(1, 1, 0.5)
		elif ot < 20:
			timer_label.modulate = Color(1, 0.7, 0.2)
		else:
			timer_label.modulate = Color(1, 0.2, 0.1)
	
	if level_label:
		level_label.text = "Lv.%d" % p.level
	if gold_label:
		gold_label.text = "%dg" % p.gold
	if wave_label:
		wave_label.text = "Wave %d" % GameManager.current_wave
	_set_lives_label(p.lives)
	
	var hp_ratio = clamp(_current_hp / _max_hp, 0.0, 1.0)
	var mana_ratio = clamp(_current_mana / _max_mana, 0.0, 1.0)
	if hp_bar and hp_bg:
		hp_bar.size.x = hp_bg.size.x * hp_ratio
	if mana_bar and mana_bg:
		mana_bar.size.x = mana_bg.size.x * mana_ratio
	
	if _hero and q_cooldown_bar and q_cooldown_bg:
		q_cooldown_bar.size.x = q_cooldown_bg.size.x * _hero.get_q_progress()
	if _hero and w_cooldown_bar and w_cooldown_bg:
		w_cooldown_bar.size.x = w_cooldown_bg.size.x * _hero.get_w_progress()
	
	var world_hp = clamp(_current_hp / _max_hp, 0, 1)
	if hero_hp_bar and hero_hp_bg:
		hero_hp_bar.size.x = hero_hp_bg.size.x * world_hp
	if hero_hp_label:
		hero_hp_label.text = "%d/%d" % [_current_hp, _max_hp]
	
	for i in 6:
		if i < p.inventory.size():
			_inv_labels[i].text = ItemDatabase.get_item_name(p.inventory[i])
		else:
			_inv_labels[i].text = ""
	
	if _stat_tooltip_visible:
		_update_stat_tooltip()

func _set_attack_target(monster):
	_clear_target_highlight()
	_attacking_target = monster
	_prev_target = monster
	if monster:
		_attacking_target_last_pos = monster.position
		_apply_target_highlight(monster)

func _apply_target_highlight(monster):
	if not is_instance_valid(monster):
		return
	var ring = ColorRect.new()
	ring.name = "TargetRing"
	ring.size = Vector2(30, 30)
	ring.position = Vector2(-15, -15)
	ring.color = Color(1, 1, 0, 0.4)
	ring.mouse_filter = Control.MOUSE_FILTER_PASS
	monster.add_child(ring)
	monster.move_child(ring, 0)

func _clear_target_highlight():
	if _prev_target and is_instance_valid(_prev_target):
		for child in _prev_target.get_children():
			if child.name == "TargetRing":
				_prev_target.remove_child(child)
				child.queue_free()
				break

func _get_hero_portrait_color(h_type: int) -> Color:
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

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.DUEL:
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://Scenes/Duel.tscn")
	if new_phase == Constants.GamePhase.LOBBY:
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://Scenes/Lobby.tscn")
