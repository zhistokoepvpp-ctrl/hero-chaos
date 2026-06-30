extends Control

@onready var title_label: Label = $TitleLabel
@onready var timer_label: Label = $TimerLabel
@onready var wave_label: Label = $WaveLabel
@onready var player_list: VBoxContainer = $PlayerList
@onready var btn_ready: Button = $BtnReady

var is_ready: bool = false

func _ready():
	btn_ready.pressed.connect(_on_ready_pressed)
	GameManager.phase_changed.connect(_on_phase_changed)

func _process(delta):
	if GameManager.phase == Constants.GamePhase.LOBBY:
		var t = max(0, int(GameManager._lobby_timer))
		timer_label.text = "%02d:%02d" % [t / 60, t % 60]
		wave_label.text = "Wave: %d" % (GameManager.current_wave + 1)
		_update_player_list()

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
