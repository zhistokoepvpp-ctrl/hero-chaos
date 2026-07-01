extends Control

@onready var arena_view: Node2D = $ArenaView
@onready var hero_rect: ColorRect = $ArenaView/HeroRect
@onready var enemy_rect: ColorRect = $ArenaView/EnemyRect
@onready var hero_hp_bar: ColorRect = $ArenaView/HeroRect/HeroHpBar
@onready var enemy_hp_bar: ColorRect = $ArenaView/EnemyRect/EnemyHpBar
@onready var target_pos: ColorRect = $ArenaView/TargetPos
@onready var countdown_label: Label = $CountdownLabel
@onready var timer_label: Label = $TimerLabel
@onready var result_label: Label = $ResultLabel
@onready var level_label: Label = $PortraitLevel
@onready var portrait_rect: ColorRect = $PortraitRect
@onready var lives_label: Label = $LivesLabel
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
@onready var hero_hp_label: Label = $ArenaView/HeroRect/HeroHpLabel
var _inv_labels: Array[Label] = []
var _stat_tooltip: Panel
var _stat_tooltip_labels: Array[Label] = []
var _stat_tooltip_visible: bool = false

var _hero: HeroBase = null
var _hero_speed: float = 300.0
var _hero_dmg: int = 30
var _hero_atk_range: float = 150.0
var _hero_max_hp: float = 500.0
var _hero_hp: float = 500.0
var _hero_max_mana: float = 100.0
var _hero_mana: float = 100.0
var _hero_atk_spd: float = 1.0
var _atk_cooldown: float = 0.0

var _enemy_speed: float = 300.0
var _enemy_dmg: int = 25
var _enemy_atk_range: float = 150.0
var _enemy_hp: float = 500.0
var _enemy_max_hp: float = 500.0
var _enemy_atk_spd: float = 1.0
var _enemy_atk_cooldown: float = 0.0

var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _duel_timer: float = Constants.DUEL_TIME
var _fighting: bool = false
var _ended: bool = false

var _attacking_target = null
var _prev_target = null
var _attacking_target_last_pos: Vector2 = Vector2.ZERO
var _control_scheme: String = "click"
var _wasd_moving: bool = false

func _ready():
	_create_inv_slots()
	_create_stat_tooltip()
	portrait_rect.mouse_entered.connect(_show_stat_tooltip)
	portrait_rect.mouse_exited.connect(_hide_stat_tooltip)
	_control_scheme = AudioManager.get_setting("control_scheme", "click")
	_setup_hero()
	_setup_enemy()
	GameManager.phase_changed.connect(_on_phase_changed)
	start_countdown()
	if lives_label:
		lives_label.add_theme_color_override("font_color", Color.WHITE)

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.LOBBY:
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://Scenes/Lobby.tscn")

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
		"HP: %d/%d" % [_hero_hp, _hero_max_hp],
		"Mana: %d/%d" % [_hero_mana, _hero_max_mana],
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

func _setup_hero():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	var h_type = p.hero_type
	hero_rect.color = _get_hero_color(h_type)
	var path = HeroDatabase.get_hero_script_path(h_type)
	var HeroScript = load(path)
	if HeroScript:
		_hero = HeroScript.new()
		_hero.player_data = p
		arena_view.add_child(_hero)
	_hero_max_hp = p.get_hp()
	_hero_hp = _hero_max_hp
	_hero_max_mana = p.get_mana()
	_hero_mana = _hero_max_mana
	_hero_dmg = p.get_damage()
	_hero_atk_spd = p.get_atk_speed()
	_hero_speed = p.get_speed()
	var data = HeroDatabase.get_hero(h_type)
	_hero_atk_range = data.attack_range
	if portrait_rect:
		portrait_rect.color = _get_hero_color(h_type)
	if q_label:
		q_label.text = "[%s] %s" % [_action_key_name("ability_q"), data.get("q_name", "?")]
	if w_label:
		var w_action = "ability_e" if _control_scheme == "wasd" else "ability_w"
		w_label.text = "[%s] %s" % [_action_key_name(w_action), data.get("w_name", "?")]

func _action_key_name(action: String) -> String:
	if InputMap.has_action(action):
		var events = InputMap.action_get_events(action)
		if events.size() > 0 and events[0] is InputEventKey:
			var name = OS.get_keycode_string(events[0].keycode)
			if name:
				return name
	var defaults = {
		"ability_q": "Q", "ability_w": "W", "ability_e": "E",
		"item_1": "1", "item_2": "2", "item_3": "3",
		"item_4": "4", "item_5": "5", "item_6": "6",
		"shop": "B", "attr": "U"
	}
	var saved = AudioManager._read_settings().get("keybinds", {})
	var keycode = saved.get(action, 0)
	if keycode > 0:
		var name = OS.get_keycode_string(keycode)
		if name:
			return name
	return defaults.get(action, "?")

func _get_hero_color(h_type: int) -> Color:
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

func _setup_enemy():
	var opp_type = GameManager.duel_opponent_hero_type
	enemy_rect.color = _get_hero_color(opp_type)
	var data = HeroDatabase.get_hero(opp_type)
	_enemy_speed = data.base_spd
	_enemy_dmg = data.base_dmg + data.base_str
	_enemy_atk_spd = data.base_aspd
	_enemy_atk_range = data.attack_range
	_enemy_max_hp = Constants.BASE_HP + data.base_str * Constants.HP_PER_STR
	_enemy_hp = _enemy_max_hp

func start_countdown():
	countdown_label.visible = true
	set_process(false)
	for i in range(3, 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree():
			return
	countdown_label.text = "FIGHT!"
	await get_tree().create_timer(0.4).timeout
	if is_inside_tree():
		countdown_label.visible = false
	_fighting = true
	set_process(true)

func _process(delta):
	if _ended:
		return
	
	if Input.is_action_just_pressed("ability_q") and _hero:
		_hero.ability_q()
	if _control_scheme == "wasd":
		if Input.is_action_just_pressed("ability_e") and _hero:
			_hero.ability_w()
	else:
		if Input.is_action_just_pressed("ability_w") and _hero:
			_hero.ability_w()
	
	_duel_timer -= delta
	var t = max(0, int(_duel_timer))
	timer_label.text = "%02d:%02d" % [t / 60, t % 60]
	
	_wasd_moving = false
	if _control_scheme == "wasd":
		var wasd = Vector2.ZERO
		if Input.is_key_pressed(KEY_D): wasd.x += 1
		if Input.is_key_pressed(KEY_A): wasd.x -= 1
		if Input.is_key_pressed(KEY_S): wasd.y += 1
		if Input.is_key_pressed(KEY_W): wasd.y -= 1
		if wasd != Vector2.ZERO and _fighting:
			if _attacking_target:
				_set_attack_target(null)
				_is_moving = false
			hero_rect.position += wasd.normalized() * _hero_speed * delta
			target_pos.visible = false
			_wasd_moving = true
	
	if _is_moving and _fighting:
	
	_combat_tick(delta)
	_update_hud()
	
	if _duel_timer <= 0 and _fighting:
		_end_duel()
	if _enemy_hp <= 0 and _fighting:
		_end_duel(true)
	if _hero_hp <= 0 and _fighting:
		_end_duel(false)

func _input(event):
	if not _fighting or _ended:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
	if event.position.distance_to(enemy_rect.position) < 50:
		_set_attack_target("enemy")
		_is_moving = false
		target_pos.visible = false
		return
	if _control_scheme == "wasd":
		return
	_set_attack_target(null)
	_move_target = event.position
	_is_moving = true

func _set_attack_target(target):
	_clear_target_highlight()
	_attacking_target = target
	_prev_target = target
	if target == "enemy":
		_apply_target_highlight()

func _apply_target_highlight():
	var ring = ColorRect.new()
	ring.name = "TargetRing"
	ring.size = Vector2(38, 38)
	ring.position = Vector2(-3, -3)
	ring.color = Color(1, 1, 0, 0.4)
	ring.mouse_filter = Control.MOUSE_FILTER_PASS
	enemy_rect.add_child(ring)
	enemy_rect.move_child(ring, 0)

func _clear_target_highlight():
	if _prev_target == "enemy" and is_instance_valid(enemy_rect):
		for child in enemy_rect.get_children():
			if child.name == "TargetRing":
				enemy_rect.remove_child(child)
				child.queue_free()
				break

func _combat_tick(delta):
	if _fighting and _hero_hp > 0:
		var p = GameManager.players.get(GameManager.local_player_id)
		if p:
			_hero_hp = min(_hero_max_hp, _hero_hp + p.get_hp_regen() * delta)
			var mp_regen = p.int_attr * Constants.MANA_REGEN_PER_INT + p.get_item_effects().get("mana_regen", 0)
			_hero_mana = min(_hero_max_mana, _hero_mana + mp_regen * delta)
	
	_atk_cooldown -= delta
	_enemy_atk_cooldown -= delta
	
	# Hero attack toward enemy
	if not _wasd_moving and _attacking_target == "enemy" and _enemy_hp > 0:
		var dist = hero_rect.position.distance_to(enemy_rect.position)
		if dist > _hero_atk_range:
			var dir = (enemy_rect.position - hero_rect.position).normalized()
			hero_rect.position += dir * _hero_speed * delta
		elif _atk_cooldown <= 0:
			_atk_cooldown = 1.0 / _hero_atk_spd
			_enemy_hp -= _hero_dmg
	elif _is_moving and _enemy_hp > 0:
		pass # movement handled in _process
	
	# Enemy always moves toward and attacks hero
	if _hero_hp > 0:
		var dist = enemy_rect.position.distance_to(hero_rect.position)
		if dist > _enemy_atk_range:
			var dir = (hero_rect.position - enemy_rect.position).normalized()
			enemy_rect.position += dir * _enemy_speed * delta
		elif _enemy_atk_cooldown <= 0:
			_enemy_atk_cooldown = 1.0 / _enemy_atk_spd
			_hero_hp -= _enemy_dmg
	
	# Update world hp bars
	var hr = clamp(_hero_hp / _hero_max_hp, 0, 1)
	var er = clamp(_enemy_hp / _enemy_max_hp, 0, 1)
	hero_hp_bar.size.x = hero_hp_bar.get_parent().size.x * hr
	enemy_hp_bar.size.x = enemy_hp_bar.get_parent().size.x * er

func _update_hud():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	
	if level_label:
		level_label.text = "Lv.%d" % p.level
	if gold_label:
		gold_label.text = "%dg" % p.gold
	_set_lives_label(p.lives)
	
	var hp_ratio = clamp(_hero_hp / _hero_max_hp, 0.0, 1.0)
	var mana_ratio = clamp(_hero_mana / _hero_max_mana, 0.0, 1.0)
	if hp_bar and hp_bg:
		hp_bar.size.x = hp_bg.size.x * hp_ratio
	if mana_bar and mana_bg:
		mana_bar.size.x = mana_bg.size.x * mana_ratio
	
	if _hero and q_cooldown_bar and q_cooldown_bg:
		q_cooldown_bar.size.x = q_cooldown_bg.size.x * _hero.get_q_progress()
	if _hero and w_cooldown_bar and w_cooldown_bg:
		w_cooldown_bar.size.x = w_cooldown_bg.size.x * _hero.get_w_progress()
	
	if hero_hp_label:
		hero_hp_label.text = "%d/%d" % [_hero_hp, _hero_max_hp]
	
	for i in 6:
		if i < p.inventory.size():
			_inv_labels[i].text = ItemDatabase.get_item_name(p.inventory[i])
		else:
			_inv_labels[i].text = ""
	
	if _stat_tooltip_visible:
		_update_stat_tooltip()

func _end_duel(won: bool = false):
	if _ended:
		return
	_ended = true
	_fighting = false
	set_process(false)
	
	if not won:
		var hero_pct = _hero_hp / _hero_max_hp
		var enemy_pct = _enemy_hp / _enemy_max_hp
		if hero_pct >= enemy_pct:
			won = true
	
	if won:
		result_label.text = "VICTORY! +%dg" % Constants.DUEL_WINNER_GOLD
		result_label.modulate = Color(0, 1, 0)
	else:
		result_label.text = "DEFEAT"
		result_label.modulate = Color(1, 0, 0)
	
	result_label.visible = true
	
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree():
		GameManager.end_duel_phase(won)

func _set_lives_label(lives: int):
	if lives_label:
		lives_label.visible = true
		lives_label.text = "♥♥" if lives >= 2 else ("♥♡" if lives == 1 else "♡♡")
		lives_label.add_theme_font_size_override("font_size", 20)
		lives_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
