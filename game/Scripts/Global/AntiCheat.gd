extends Node

var _command_counts: Dictionary = {}
var _last_cooldowns: Dictionary = {}
var _warnings: Dictionary = {}

func validate_kill(player_id: int, monster_type: String, count: int, wave: int) -> bool:
	var expected_max = Constants.MONSTER_BASE_COUNT + (wave * Constants.MONSTER_COUNT_PER_WAVE)
	if count > expected_max:
		log_suspicious(player_id, "kill_count_exceeded", "Claimed %d kills at wave %d" % [count, wave])
		return false
	return true

func validate_gold_change(player_id: int, delta: int) -> bool:
	if delta > 200:
		log_suspicious(player_id, "gold_spike", "Delta: %d" % delta)
		return false
	return true

func validate_position(player_id: int, pos: Vector2, last_pos: Vector2, delta_time: float) -> bool:
	var hero_data = GameManager.players.get(player_id, {})
	var max_speed = hero_data.get("speed", 300.0)
	var max_move = max_speed * delta_time * 3.0
	if pos.distance_squared_to(last_pos) > max_move * max_move:
		log_suspicious(player_id, "speed_hack", "Moved %.1fpx in %.2fs" % [pos.distance_to(last_pos), delta_time])
		return false
	return true

func validate_cooldown(player_id: int, ability: String, cd: float) -> bool:
	var key = str(player_id) + "_" + ability
	var now = Time.get_ticks_msec() / 1000.0
	if _last_cooldowns.has(key):
		var elapsed = now - _last_cooldowns[key]
		if elapsed < cd * 0.5:
			log_suspicious(player_id, "cooldown_skip", "%s used after %.1fs (CD: %.1f)" % [ability, elapsed, cd])
			return false
	_last_cooldowns[key] = now
	return true

func check_rate_limit(player_id: int) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	var window = int(now)
	if not _command_counts.has(player_id):
		_command_counts[player_id] = {}
	var counts = _command_counts[player_id]
	if not counts.has(window):
		counts[window] = 0
		_clean_old_counts(player_id, window)
	counts[window] += 1
	return counts[window] <= Constants.MAX_COMMANDS_PER_SEC

func _clean_old_counts(player_id: int, current_window: int):
	var counts = _command_counts[player_id]
	for w in counts.keys():
		if w < current_window - 2:
			counts.erase(w)

func log_suspicious(player_id: int, reason: String, detail: String = ""):
	var entry = {
		"player": player_id,
		"reason": reason,
		"detail": detail,
		"time": Time.get_datetime_string_from_system()
	}
	print("ANTI-CHEAT: ", JSON.stringify(entry))
	
	if not _warnings.has(player_id):
		_warnings[player_id] = 0
	_warnings[player_id] += 1
	
	if _warnings[player_id] >= 2:
		if GameManager.is_host:
			kick_player(player_id)

func kick_player(player_id: int):
	print("KICKING player ", player_id)
	rpc("_rpc_kick", player_id)

@rpc("authority", "call_local", "reliable")
func _rpc_kick(player_id: int):
	if multiplayer.get_unique_id() == player_id:
		NetworkManager.disconnect_from_server()
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
