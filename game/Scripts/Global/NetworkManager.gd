extends Node

signal connected_to_server()
signal connection_failed()
signal server_created()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var peer: ENetMultiplayerPeer = null

func host_game(port: int = Constants.DEFAULT_PORT) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, Constants.MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: ", err)
		return false
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	server_created.emit()
	GameManager.is_host = true
	GameManager.local_player_id = multiplayer.get_unique_id()
	return true

func join_game(ip: String, port: int = Constants.DEFAULT_PORT) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to connect: ", err)
		return false
	multiplayer.multiplayer_peer = peer
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	return true

func _on_peer_connected(peer_id: int):
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int):
	peer_disconnected.emit(peer_id)

func _on_connected_to_server():
	connected_to_server.emit()
	GameManager.local_player_id = multiplayer.get_unique_id()

func _on_connection_failed():
	connection_failed.emit()

func disconnect_from_server():
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
	GameManager.is_host = false

@rpc("any_peer", "call_local", "reliable")
func rpc_ready_up():
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = GameManager.local_player_id
	GameManager.on_player_ready(sender)

@rpc("any_peer", "call_local", "reliable")
func rpc_wave_cleared():
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = GameManager.local_player_id
	GameManager.on_wave_cleared(sender)

@rpc("authority", "call_local", "reliable")
func rpc_start_wave(wave_number: int):
	pass

@rpc("authority", "call_local", "reliable")
func rpc_sync_player_state(peer_id: int, data: Dictionary):
	pass
