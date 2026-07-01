extends Control

@onready var lobby_view: Node2D = $LobbyView
@onready var hero_rect: ColorRect = $LobbyView/HeroRect
@onready var target_pos: ColorRect = $LobbyView/TargetPos
@onready var title_label: Label = $TitleLabel
@onready var timer_label: Label = $TimerLabel
@onready var wave_label: Label = $WaveLabel
@onready var player_list: VBoxContainer = $PlayerList
@onready var btn_ready: Button = $BtnReady

# Shop
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_gold: Label = $ShopPanel/ShopGold
@onready var shop_item_list: VBoxContainer = $ShopPanel/ShopItemList
@onready var shop_inv_list: VBoxContainer = $ShopPanel/ShopInvList

# Attributes
@onready var attr_panel: Panel = $AttrPanel
@onready var attr_points: Label = $AttrPanel/AttrPoints
@onready var attr_str_label: Label = $AttrPanel/AttrStrLabel
@onready var attr_agi_label: Label = $AttrPanel/AttrAgiLabel
@onready var attr_int_label: Label = $AttrPanel/AttrIntLabel
@onready var attr_str_btn: Button = $AttrPanel/AttrStrBtn
@onready var attr_agi_btn: Button = $AttrPanel/AttrAgiBtn
@onready var attr_int_btn: Button = $AttrPanel/AttrIntBtn

@onready var notify_label: Label = $NotifyLabel

# Hotbar
@onready var portrait_rect: ColorRect = $PortraitRect
@onready var portrait_level: Label = $PortraitLevel
@onready var lives_label: Label = $LivesLabel
@onready var gold_label: Label = $GoldLabel
@onready var hp_bar: ColorRect = $HpBar
@onready var mana_bar: ColorRect = $ManaBar
@onready var hp_bg: ColorRect = $HpBg
@onready var mana_bg: ColorRect = $ManaBg
@onready var q_label: Label = $AbilityBox/QPanel/QLabel
@onready var w_label: Label = $AbilityBox/WPanel/WLabel
@onready var q_cooldown_bar: ColorRect = $AbilityBox/QPanel/QCooldownBar
@onready var w_cooldown_bar: ColorRect = $AbilityBox/WPanel/WCooldownBar

var _inv_labels: Array[Label] = []
var _stat_tooltip: Panel
var _stat_tooltip_labels: Array[Label] = []
var _stat_tooltip_visible: bool = false

var is_ready: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _hero_speed: float = 300.0
var _control_scheme: String = "click"

func _ready():
	_create_inv_slots()
	_create_stat_tooltip()
	portrait_rect.mouse_entered.connect(_show_stat_tooltip)
	portrait_rect.mouse_exited.connect(_hide_stat_tooltip)
	btn_ready.pressed.connect(_on_ready_pressed)
	GameManager.phase_changed.connect(_on_phase_changed)
	_control_scheme = AudioManager.get_setting("control_scheme", "click")
	if lives_label:
		lives_label.add_theme_color_override("font_color", Color.WHITE)
	attr_str_btn.pressed.connect(_add_str)
	attr_agi_btn.pressed.connect(_add_agi)
	attr_int_btn.pressed.connect(_add_int)
	var shop_btn = get_node("BtnShop")
	if shop_btn:
		shop_btn.pressed.connect(_toggle_shop)
	_spawn_hero()
	_show_wave_result()

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
		"HP: %.0f" % p.get_hp(),
		"Mana: %.0f" % p.get_mana(),
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

func _show_wave_result():
	if GameManager.current_wave > 0:
		var p = GameManager.players.get(GameManager.local_player_id)
		var bonus = GameManager.last_wave_bonus
		var place = GameManager.last_placement
		notify_label.text = "Wave %d cleared! Place #%d | +%dg bonus" % [GameManager.current_wave, place, bonus]
		await get_tree().create_timer(5.0).timeout
		if is_inside_tree():
			notify_label.text = ""

func _spawn_hero():
	if not GameManager.players.has(GameManager.local_player_id):
		return
	var p = GameManager.players[GameManager.local_player_id]
	hero_rect.color = _get_hero_color(p.hero_type)
	hero_rect.position = Vector2(590, 310)
	var h_type = p.hero_type
	if portrait_rect:
		portrait_rect.color = _get_hero_color(h_type)
	var data = HeroDatabase.get_hero(h_type)
	if data:
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

func _process(delta):
	if not is_inside_tree():
		return
	if GameManager.phase == Constants.GamePhase.LOBBY:
		var t = max(0, int(GameManager._lobby_timer))
		if timer_label:
			timer_label.text = "%02d:%02d" % [t / 60, t % 60]
		if wave_label:
			wave_label.text = "Wave: %d" % (GameManager.current_wave + 1)
		_update_player_list()
		_update_inv_slots()
		_update_hotbar()
		if _stat_tooltip_visible:
			_update_stat_tooltip()
	
	if _control_scheme == "wasd":
		var wasd = Vector2.ZERO
		if Input.is_key_pressed(KEY_D): wasd.x += 1
		if Input.is_key_pressed(KEY_A): wasd.x -= 1
		if Input.is_key_pressed(KEY_S): wasd.y += 1
		if Input.is_key_pressed(KEY_W): wasd.y -= 1
		if wasd != Vector2.ZERO and not shop_panel.visible and not attr_panel.visible:
			hero_rect.position += wasd.normalized() * _hero_speed * delta
			target_pos.visible = false
	
	if _is_moving and not shop_panel.visible and not attr_panel.visible:
		var dir = (_move_target - hero_rect.position)
		if dir.length() > 4:
			hero_rect.position += dir.normalized() * _hero_speed * delta
			target_pos.position = _move_target - Vector2(4, 4)
			target_pos.visible = true
		else:
			_is_moving = false
			target_pos.visible = false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B: _toggle_shop()
			KEY_U: _toggle_attr()
		for i in 6:
			if event.keycode == KEY_1 + i and i < _inv_labels.size():
				_sell_item(i)
		return
	
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
	if _control_scheme == "wasd":
		return
	if shop_panel.visible or attr_panel.visible:
		return
	_move_target = event.position
	_is_moving = true

# ─── Shop ───

func _toggle_shop():
	shop_panel.visible = not shop_panel.visible
	attr_panel.visible = false
	if shop_panel.visible:
		_refresh_shop()

func _refresh_shop():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	shop_gold.text = "Gold: %d" % p.gold
	
	for child in shop_item_list.get_children():
		child.queue_free()
	
	for id in range(1, 16):
		var item = ItemDatabase.get_item(id)
		if item.is_empty():
			continue
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = item.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost_lbl = Label.new()
		cost_lbl.text = "%dg" % item.cost
		cost_lbl.custom_minimum_size.x = 60
		var effect_text = ""
		for k in item.effects:
			effect_text += "%s: %s " % [k, str(item.effects[k])]
		var effect_lbl = Label.new()
		effect_lbl.text = effect_text
		effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var buy_btn = Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(_buy_item.bind(id))
		row.add_child(name_lbl)
		row.add_child(effect_lbl)
		row.add_child(cost_lbl)
		row.add_child(buy_btn)
		shop_item_list.add_child(row)
	
	for child in shop_inv_list.get_children():
		child.queue_free()
	
	for i in range(p.inventory.size()):
		var item_id = p.inventory[i]
		var item = ItemDatabase.get_item(item_id)
		if item.is_empty():
			item = {"name": "Item #%d" % item_id}
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = item.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sell_btn = Button.new()
		sell_btn.text = "Sell %dg" % int(item.get("cost", 0) * Constants.SELL_RATIO)
		sell_btn.pressed.connect(_sell_item.bind(i))
		row.add_child(name_lbl)
		row.add_child(sell_btn)
		shop_inv_list.add_child(row)

func _buy_item(item_id: int):
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	var item = ItemDatabase.get_item(item_id)
	if item.is_empty():
		return
	if not p.spend_gold(item.cost):
		return
	if not p.add_item(item_id):
		p.add_gold(item.cost)
		return
	_auto_combine()
	_refresh_shop()

func _sell_item(slot: int):
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	if slot < 0 or slot >= p.inventory.size():
		return
	var item = ItemDatabase.get_item(p.inventory[slot])
	if not item.is_empty():
		p.add_gold(int(item.cost * Constants.SELL_RATIO))
	p.remove_item(slot)
	_refresh_shop()

func _auto_combine():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	for rid in ItemDatabase.recipes:
		var recipe = ItemDatabase.get_recipe(rid)
		if recipe.is_empty():
			continue
		var can_combine = true
		for comp_id in recipe.components:
			if p.count_item(comp_id) < 1:
				can_combine = false
				break
		if not can_combine:
			continue
		for comp_id in recipe.components:
			p.remove_item_by_id(comp_id)
		p.add_item(rid)

# ─── Attributes ───

func _toggle_attr():
	attr_panel.visible = not attr_panel.visible
	shop_panel.visible = false
	if attr_panel.visible:
		_refresh_attr()

func _refresh_attr():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	attr_points.text = "Free points: %d" % p.free_attr_points
	attr_str_label.text = "STR: %d" % p.str_attr
	attr_agi_label.text = "AGI: %d" % p.agi_attr
	attr_int_label.text = "INT: %d" % p.int_attr
	attr_str_btn.disabled = p.free_attr_points <= 0
	attr_agi_btn.disabled = p.free_attr_points <= 0
	attr_int_btn.disabled = p.free_attr_points <= 0

func _add_str():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p or p.free_attr_points <= 0:
		return
	p.free_attr_points -= 1
	p.str_attr += 1
	_refresh_attr()

func _add_agi():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p or p.free_attr_points <= 0:
		return
	p.free_attr_points -= 1
	p.agi_attr += 1
	_refresh_attr()

func _update_inv_slots():
	var p = GameManager.players.get(GameManager.local_player_id)
	for i in 6:
		if p and i < p.inventory.size():
			_inv_labels[i].text = ItemDatabase.get_item_name(p.inventory[i])
		else:
			_inv_labels[i].text = ""

func _update_hotbar():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p:
		return
	if portrait_level:
		portrait_level.text = "Lv.%d" % p.level
	if gold_label:
		gold_label.text = "%dg" % p.gold
	_set_lives_label(p.lives)

func _add_int():
	var p = GameManager.players.get(GameManager.local_player_id)
	if not p or p.free_attr_points <= 0:
		return
	p.free_attr_points -= 1
	p.int_attr += 1
	_refresh_attr()

func _update_player_list():
	for child in player_list.get_children():
		child.queue_free()
	
	for pid in GameManager.players:
		var p = GameManager.players[pid]
		var label = Label.new()
		var hearts = "♥♥" if p.lives == 2 else ("♥♡" if p.lives == 1 else "♡♡")
		label.text = "%s | %s | Lv.%d | %dg | %s" % [p.player_name, HeroDatabase.get_hero(p.hero_type).name, p.level, p.gold, hearts]
		player_list.add_child(label)

func _on_ready_pressed():
	is_ready = not is_ready
	btn_ready.text = "READY" if not is_ready else "✓ READY"
	NetworkManager.rpc_ready_up.rpc()

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.WAVE:
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://Scenes/Arena.tscn")
	if new_phase == Constants.GamePhase.DUEL:
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://Scenes/Duel.tscn")

func _set_lives_label(lives: int):
	if lives_label:
		lives_label.visible = true
		lives_label.text = "♥♥" if lives >= 2 else ("♥♡" if lives == 1 else "♡♡")
		lives_label.add_theme_font_size_override("font_size", 20)
		lives_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
