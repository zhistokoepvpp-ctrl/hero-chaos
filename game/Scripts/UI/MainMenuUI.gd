extends Control

@onready var title: Label = $Title
@onready var btn_host: Button = $BtnHost
@onready var btn_join: Button = $BtnJoin
@onready var ip_input: LineEdit = $IpInput
@onready var btn_connect: Button = $BtnConnect
@onready var status: Label = $Status
@onready var mmr_label: Label = $MmrLabel

func _ready():
	btn_host.pressed.connect(_on_host)
	btn_join.pressed.connect(_on_join_toggle)
	btn_connect.pressed.connect(_on_connect)
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	ip_input.visible = false
	btn_connect.visible = false
	
	mmr_label.text = "MMR: " + str(DataManager.profile.get("mmr", 1000))
	
	$BtnSettings.pressed.connect(_on_settings)
	$BtnQuit.pressed.connect(_on_quit)

func _on_host():
	status.text = "Starting server..."
	if NetworkManager.host_game():
		status.text = "Server created! Waiting for players..."
		GameManager.start_lobby_phase()
		get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

func _on_join_toggle():
	ip_input.visible = not ip_input.visible
	btn_connect.visible = ip_input.visible
	status.text = "Enter host IP address" if ip_input.visible else ""

func _on_connect():
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		status.text = "Enter an IP address"
		return
	status.text = "Connecting to " + ip
	NetworkManager.join_game(ip)

func _on_server_created():
	pass

func _on_connected():
	status.text = "Connected!"
	GameManager.start_lobby_phase()
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

func _on_connection_failed():
	status.text = "Connection failed! Check IP"

func _on_settings():
	get_tree().change_scene_to_file("res://Scenes/Settings.tscn")

func _on_quit():
	get_tree().quit()
