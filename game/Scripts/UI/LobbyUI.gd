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

var is_ready: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _hero_speed: float = 300.0

func _ready():
	btn_ready.pressed.connect(_on_ready_pressed)
	GameManager.phase_changed.connect(_on_phase_changed)
	attr_str_btn.pressed.connect(_add_str)
	attr_agi_btn.pressed.connect(_add_agi)
	attr_int_btn.pressed.connect(_add_int)
	_spawn_hero()

func _spawn_hero():
	if not GameManager.players.has(GameManager.local_player_id):
		return
	var p = GameManager.players[GameManager.local_player_id]
	hero_rect.color = _get_hero_color(p.hero_type)
	hero_rect.position = Vector2(590, 310)

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
	if GameManager.phase == Constants.GamePhase.LOBBY:
		var t = max(0, int(GameManager._lobby_timer))
		timer_label.text = "%02d:%02d" % [t / 60, t % 60]
		wave_label.text = "Wave: %d" % (GameManager.current_wave + 1)
		_update_player_list()
	
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
		return
	
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
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
		get_tree().change_scene_to_file("res://Scenes/Arena.tscn")
