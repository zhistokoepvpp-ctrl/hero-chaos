extends Node

signal phase_changed(new_phase: int)
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal duel_started(pairs: Array)
signal duel_ended(winners: Array)
signal game_over(winner_id: int, placements: Array)

var phase: int = Constants.GamePhase.MAIN_MENU:
	set(value):
		phase = value
		phase_changed.emit(value)

var current_wave: int = 0
var players: Dictionary = {}  # peer_id -> PlayerData
var local_player_id: int = 0
var is_host: bool = false

var _lobby_timer: float = 0.0
var _wave_timer: float = 0.0
var _overtime_active: bool = false
var _overtime_seconds: float = 0.0

var _ready_players: Array[int] = []
var _wave_cleared_players: Array[int] = []
var last_placement: int = 0
var last_wave_bonus: int = 0

func _ready():
	phase = Constants.GamePhase.MAIN_MENU

func _process(delta: float):
	match phase:
		Constants.GamePhase.LOBBY:
			_lobby_timer -= delta
			if _lobby_timer <= 0:
				start_wave_phase()
		Constants.GamePhase.WAVE:
			if not _overtime_active:
				_wave_timer -= delta
				if _wave_timer <= 0:
					_overtime_active = true
					_overtime_seconds = 0.0
			else:
				_overtime_seconds += delta

func start_lobby_phase():
	_award_wave_bonus()
	phase = Constants.GamePhase.LOBBY
	_lobby_timer = Constants.LOBBY_TIME
	_ready_players.clear()
	_overtime_active = false
	_register_local_player()

func _award_wave_bonus():
	for i in range(_wave_cleared_players.size()):
		var pid = _wave_cleared_players[i]
		var p = players.get(pid)
		if p and p.alive:
			var bonus = Constants.WAVE_BONUSES[i] if i < Constants.WAVE_BONUSES.size() else 10
			p.add_gold(bonus)
			if pid == local_player_id:
				last_placement = i + 1
				last_wave_bonus = bonus

func start_wave_phase():
	current_wave += 1
	_wave_timer = Constants.WAVE_TIME
	_wave_cleared_players.clear()
	_overtime_active = false
	_overtime_seconds = 0.0
	phase = Constants.GamePhase.WAVE
	wave_started.emit(current_wave)

func on_player_ready(peer_id: int):
	if peer_id not in _ready_players:
		_ready_players.append(peer_id)
	if _ready_players.size() >= get_active_player_count():
		if phase == Constants.GamePhase.LOBBY:
			start_wave_phase()

func on_wave_cleared(peer_id: int):
	if peer_id not in _wave_cleared_players:
		_wave_cleared_players.append(peer_id)

func _register_local_player():
	if not players.has(local_player_id):
		var p = PlayerData.new(local_player_id, "Player" + str(local_player_id))
		p.hero_type = Constants.HeroType.WARRIOR
		players[local_player_id] = p

func get_active_player_count() -> int:
	var count = 0
	for p in players.values():
		if p.alive:
			count += 1
	return max(count, 1)

func check_game_over():
	var alive = get_active_player_count()
	if alive <= 0:
		phase = Constants.GamePhase.GAME_OVER
		game_over.emit(local_player_id, [])

func get_players_sorted_by_gold() -> Array:
	var list = players.values()
	list.sort_custom(func(a, b): return a.gold > b.gold)
	return list
