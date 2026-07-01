extends Node

var _music_player: AudioStreamPlayer
var master_volume: float = 1.0
var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready():
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_load_settings()

static func _read_settings() -> Dictionary:
	var f = FileAccess.open("user://settings.cfg", FileAccess.READ)
	if f:
		var json = JSON.parse_string(f.get_as_text())
		f.close()
		if json is Dictionary:
			return json
	return {}

static func _write_settings(data: Dictionary):
	var f = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

static func get_setting(key: String, default_value = null):
	return _read_settings().get(key, default_value)

func _load_settings():
	var data = _read_settings()
	master_volume = data.get("master_vol", 1.0)
	bgm_volume = data.get("bgm_vol", 1.0)
	sfx_volume = data.get("sfx_vol", 1.0)
	_apply_volumes()

func _apply_volumes():
	_music_player.volume_db = linear_to_db(master_volume * bgm_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func save_settings():
	var data = _read_settings()
	data["master_vol"] = master_volume
	data["bgm_vol"] = bgm_volume
	data["sfx_vol"] = sfx_volume
	_write_settings(data)

func set_master_volume(vol: float):
	master_volume = vol
	_apply_volumes()
	save_settings()

func set_bgm_volume(vol: float):
	bgm_volume = vol
	_apply_volumes()
	save_settings()

func set_sfx_volume(vol: float):
	sfx_volume = vol
	save_settings()

func play_bgm(phase: String):
	pass

func play_sfx(event: String):
	pass
	
