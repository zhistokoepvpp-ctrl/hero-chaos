extends Control

@onready var lobby_view: Node2D = $LobbyView
@onready var hero_rect: ColorRect = $LobbyView/HeroRect
@onready var target_pos: ColorRect = $LobbyView/TargetPos
@onready var title_label: Label = $TitleLabel
@onready var timer_label: Label = $TimerLabel
@onready var wave_label: Label = $WaveLabel
@onready var player_list: VBoxContainer = $PlayerList
@onready var btn_ready: Button = $BtnReady

var is_ready: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _hero_speed: float = 300.0

func _ready():
	btn_ready.pressed.connect(_on_ready_pressed)
	GameManager.phase_changed.connect(_on_phase_changed)
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
	
	if _is_moving:
		var dir = (_move_target - hero_rect.position)
		if dir.length() > 4:
			hero_rect.position += dir.normalized() * _hero_speed * delta
			target_pos.position = _move_target - Vector2(4, 4)
			target_pos.visible = true
		else:
			_is_moving = false
			target_pos.visible = false

func _input(event):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		return
	_move_target = event.position
	_is_moving = true

func _update_player_list():
	for child in player_list.get_children():
		child.queue_free()
	
	for pid in GameManager.players:
		var p = GameManager.players[pid]
		var label = Label.new()
		label.text = "%s | %s | Lv.%d | %dg" % [p.player_name, HeroDatabase.get_hero(p.hero_type).name, p.level, p.gold]
		player_list.add_child(label)

func _on_ready_pressed():
	is_ready = not is_ready
	btn_ready.text = "READY" if not is_ready else "✓ READY"
	NetworkManager.rpc_ready_up.rpc()

func _on_phase_changed(new_phase: int):
	if new_phase == Constants.GamePhase.WAVE:
		get_tree().change_scene_to_file("res://Scenes/Arena.tscn")
