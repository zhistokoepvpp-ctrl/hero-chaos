extends Control

@onready var timer_label: Label = $TimerLabel
@onready var hero_grid: GridContainer = $HeroGrid
@onready var info_panel: Panel = $InfoPanel
@onready var selected_name: Label = $InfoPanel/SelectedName
@onready var selected_role: Label = $InfoPanel/SelectedRole
@onready var stats_label: Label = $InfoPanel/StatsLabel
@onready var ability_label: Label = $InfoPanel/AbilityLabel
@onready var btn_confirm: Button = $BtnConfirm

var _selected_type: int = -1
var _cards: Array = []
var _timer: float = Constants.HERO_SELECT_TIME

func _ready():
	btn_confirm.pressed.connect(_on_confirm)
	GameManager.phase = Constants.GamePhase.HERO_SELECT
	GameManager._register_local_player()
	_populate_grid()

func _process(delta):
	if GameManager.phase == Constants.GamePhase.HERO_SELECT:
		_timer -= delta
		timer_label.text = str(max(0, int(_timer)))
		if _timer <= 0:
			_confirm_selection()

func _populate_grid():
	for h_type in range(Constants.HeroType.size()):
		var data = HeroDatabase.get_hero(h_type)
		var card = Panel.new()
		card.custom_minimum_size = Vector2(140, 160)
		card.size = Vector2(140, 160)
		
		var vbox = VBoxContainer.new()
		vbox.size = Vector2(140, 160)
		vbox.position = Vector2(5, 5)
		
		var icon = ColorRect.new()
		icon.size = Vector2(48, 48)
		icon.position = Vector2(40, 5)
		icon.color = _get_hero_color(h_type)
		vbox.add_child(icon)
		
		var name_lbl = Label.new()
		name_lbl.text = data.name
		name_lbl.horizontal_alignment = 1
		vbox.add_child(name_lbl)
		
		var role_lbl = Label.new()
		role_lbl.text = data.role
		role_lbl.horizontal_alignment = 1
		role_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(role_lbl)
		
		card.add_child(vbox)
		card.gui_input.connect(_on_card_input.bind(h_type, card))
		
		_cards.append(card)
		hero_grid.add_child(card)

func _on_card_input(event: InputEvent, h_type: int, card: Panel):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_hero(h_type)

func _select_hero(h_type: int):
	_selected_type = h_type
	for i in _cards.size():
		var c = _cards[i] as Panel
		c.modulate = Color(1, 1, 0.5) if i == h_type else Color.WHITE
	
	var data = HeroDatabase.get_hero(h_type)
	selected_name.text = data.get("name", "")
	selected_role.text = data.get("role", "")
	stats_label.text = "STR: %d | AGI: %d | INT: %d\nDMG: %d | SPD: %.0f | RNG: %.0f" % [
		data.base_str, data.base_agi, data.base_int,
		data.base_dmg, data.base_spd, data.attack_range
	]
	ability_label.text = "[Q] %s\n%s\n\n[W] %s\n%s" % [
		data.get("q_name", "?"), data.get("q_desc", ""),
		data.get("w_name", "?"), data.get("w_desc", "")
	]

func _on_confirm():
	if _selected_type >= 0:
		_confirm_selection()

func _confirm_selection():
	if _selected_type < 0:
		_selected_type = Constants.HeroType.WARRIOR
	
	var p = GameManager.players[GameManager.local_player_id]
	p.setup_hero(_selected_type)
	
	GameManager.start_lobby_phase()
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/Lobby.tscn")

func _get_hero_color(h_type: int) -> Color:
	match h_type:
		Constants.HeroType.WARRIOR: return Color(0.7, 0.3, 0.2)
		Constants.HeroType.ARCHER: return Color(0.2, 0.7, 0.3)
		Constants.HeroType.MAGE: return Color(0.2, 0.4, 0.8)
		Constants.HeroType.ASSASSIN: return Color(0.5, 0.2, 0.5)
		Constants.HeroType.PALADIN: return Color(0.9, 0.8, 0.3)
		Constants.HeroType.NECROMANCER: return Color(0.3, 0.8, 0.7)
		Constants.HeroType.BERSERKER: return Color(0.8, 0.2, 0.2)
		Constants.HeroType.SHAMAN: return Color(0.2, 0.6, 0.4)
		Constants.HeroType.GUNSLINGER: return Color(0.9, 0.6, 0.1)
		Constants.HeroType.SPELLBLADE: return Color(0.6, 0.3, 0.8)
		_: return Color.WHITE
