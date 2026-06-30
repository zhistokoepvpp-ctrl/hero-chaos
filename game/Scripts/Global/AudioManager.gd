extends Node

var _music_player: AudioStreamPlayer
var _bgm_volume: float = 0.8
var _sfx_volume: float = 1.0

func _ready():
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

func play_bgm(phase: String):
	pass

func play_sfx(event: String):
	pass

func set_bgm_volume(vol: float):
	_bgm_volume = vol
	_music_player.volume_db = linear_to_db(vol)

func set_sfx_volume(vol: float):
	_sfx_volume = vol
