extends Node

const MASTER_SERVER_URL := "http://localhost:8000"
var http: HTTPRequest

func _ready():
	http = HTTPRequest.new()
	add_child(http)

func list_rooms(callback: Callable):
	var err = http.request(MASTER_SERVER_URL + "/rooms")
	if err != OK:
		push_error("Master server request failed")

func create_room(room_name: String, port: int):
	var body = JSON.stringify({
		"host_name": DataManager.profile.get("player_name", "Player"),
		"host_port": port,
		"game_version": "1.0.0",
		"max_players": Constants.MAX_PLAYERS
	})
	var headers = ["Content-Type: application/json"]
	http.request(MASTER_SERVER_URL + "/rooms", headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(result: int, code: int, _headers: Array, body: PackedByteArray):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and code == 200:
		pass
