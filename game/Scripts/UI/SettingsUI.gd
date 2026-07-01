extends Control

var _bind_actions := ["ability_q", "ability_w", "ability_e", "item_1", "item_2", "item_3", "item_4", "item_5", "item_6", "shop", "attr"]
var _bind_labels: Array = []
var _current_bind_actions: Array = []
var _waiting_for_key: String = ""
var _bind_names := {
	"ability_q": "Skill 1", "ability_w": "Skill 2", "ability_e": "Skill 2",
	"item_1": "Item Slot 1", "item_2": "Item Slot 2", "item_3": "Item Slot 3",
	"item_4": "Item Slot 4", "item_5": "Item Slot 5", "item_6": "Item Slot 6",
	"shop": "Shop", "attr": "Attributes"
}

func _ready():
	var am = AudioManager
	$MasterVolSlider.value = am.master_volume * 100
	$SfxVolSlider.value = am.sfx_volume * 100
	$MusicVolSlider.value = am.bgm_volume * 100
	$MasterVolValue.text = str(int($MasterVolSlider.value))
	$SfxVolValue.text = str(int($SfxVolSlider.value))
	$MusicVolValue.text = str(int($MusicVolSlider.value))

	var f = FileAccess.open("user://settings.cfg", FileAccess.READ)
	if f:
		var json = JSON.parse_string(f.get_as_text())
		if json is Dictionary:
			$FullscreenCheck.button_pressed = json.get("fullscreen", false)
			var saved_res = json.get("resolution", "")
			for i in $ResolutionOption.item_count:
				if $ResolutionOption.get_item_text(i) == saved_res:
					$ResolutionOption.select(i)
					break
		f.close()
	GameManager._apply_window_settings()

	var scheme = AudioManager.get_setting("control_scheme", "click")
	_highlight_panel(scheme)
	_update_preset_labels()

	$MasterVolSlider.value_changed.connect(_on_master_vol_changed)
	$SfxVolSlider.value_changed.connect(_on_sfx_vol_changed)
	$MusicVolSlider.value_changed.connect(_on_music_vol_changed)
	$FullscreenCheck.toggled.connect(_on_fullscreen_toggled)
	$ResolutionOption.item_selected.connect(_on_resolution_selected)
	$BtnCustomize.pressed.connect(_open_bind_panel)
	$BindPanel/BtnCloseBind.pressed.connect(_close_bind_panel)
	$BtnBack.pressed.connect(_on_back)

func _open_bind_panel():
	$BindPanel.visible = true
	_populate_bind_list()

func _close_bind_panel():
	$BindPanel.visible = false
	_waiting_for_key = ""

func _populate_bind_list():
	var list = $BindPanel/BindList
	for c in list.get_children():
		c.queue_free()
	_bind_labels.clear()
	_current_bind_actions.clear()
	var binds = AudioManager._read_settings().get("keybinds", {})
	var scheme = AudioManager.get_setting("control_scheme", "click")
	var actions = _bind_actions.duplicate()
	if scheme == "wasd":
		actions.erase("ability_w")
	else:
		actions.erase("ability_e")
	_current_bind_actions = actions.duplicate()
	for action in actions:
		var hb = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = _bind_names.get(action, action) + ":"
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))
		var key_lbl = Label.new()
		var keycode = binds.get(action, _default_key(action))
		key_lbl.text = _key_name(keycode)
		key_lbl.add_theme_color_override("font_color", Color.WHITE)
		key_lbl.add_theme_font_size_override("font_size", 14)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx = _bind_labels.size()
		key_lbl.gui_input.connect(func(ev): _on_key_label_click(ev, action, idx))
		_bind_labels.append(key_lbl)
		hb.add_child(name_lbl)
		hb.add_child(key_lbl)
		list.add_child(hb)

func _default_key(action: String) -> int:
	var defaults = {
		"ability_q": KEY_Q, "ability_w": KEY_W, "ability_e": KEY_E,
		"item_1": KEY_1, "item_2": KEY_2, "item_3": KEY_3,
		"item_4": KEY_4, "item_5": KEY_5, "item_6": KEY_6,
		"shop": KEY_B, "attr": KEY_U
	}
	return defaults.get(action, 0)

func _key_name(keycode: int) -> String:
	if keycode <= 0:
		return "?"
	var hardcoded = {
		KEY_Q: "Q", KEY_W: "W", KEY_E: "E", KEY_R: "R",
		KEY_1: "1", KEY_2: "2", KEY_3: "3",
		KEY_4: "4", KEY_5: "5", KEY_6: "6",
		KEY_B: "B", KEY_U: "U"
	}
	var name = hardcoded.get(keycode, "")
	if name:
		return name
	name = OS.get_keycode_string(keycode)
	return name if name else "?"

func _on_key_label_click(event, action: String, idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _waiting_for_key == action:
			_waiting_for_key = ""
			return
		_waiting_for_key = action
		_bind_labels[idx].text = "PRESS KEY..."
		_bind_labels[idx].add_theme_color_override("font_color", Color(1, 1, 0, 1))

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if $BindPanel.visible:
			return
		var scheme = _get_panel_at(event.position)
		if scheme:
			_highlight_panel(scheme)
			var data = AudioManager._read_settings()
			data["control_scheme"] = scheme
			AudioManager._write_settings(data)
			_update_preset_labels()
	
	if _waiting_for_key and event is InputEventKey and event.pressed:
		var keycode = event.keycode
		if keycode == KEY_ESCAPE:
			_waiting_for_key = ""
			_rebuild_labels()
			return
		var binds = AudioManager._read_settings().get("keybinds", {})
		binds[_waiting_for_key] = keycode
		var data = AudioManager._read_settings()
		data["keybinds"] = binds
		AudioManager._write_settings(data)
		_apply_bind(_waiting_for_key, keycode)
		_waiting_for_key = ""
		_rebuild_labels()

func _apply_bind(action: String, keycode: int):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev = InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)
	_update_preset_labels()

func _rebuild_labels():
	var binds = AudioManager._read_settings().get("keybinds", {})
	for i in _bind_labels.size():
		if i >= _current_bind_actions.size():
			break
		var action = _current_bind_actions[i]
		var keycode = binds.get(action, _default_key(action))
		_bind_labels[i].text = _key_name(keycode)
		_bind_labels[i].add_theme_color_override("font_color", Color.WHITE)

func _get_panel_at(pos: Vector2) -> String:
	if pos.x >= 240 and pos.x <= 600 and pos.y >= 370 and pos.y <= 600:
		return "click"
	if pos.x >= 680 and pos.x <= 1040 and pos.y >= 370 and pos.y <= 600:
		return "wasd"
	return ""

func _update_preset_labels():
	var binds = AudioManager._read_settings().get("keybinds", {})
	var k = func(action: String) -> String:
		return _key_name(binds.get(action, _default_key(action)))
	var click_text = "Move:           Right-click\nAttack target:  Right-click on enemy\n"
	click_text += "Skill 1:        %s\nSkill 2:        %s\n" % [k.call("ability_q"), k.call("ability_w")]
	click_text += "Items 1-6:      %s %s %s %s %s %s\n" % [k.call("item_1"), k.call("item_2"), k.call("item_3"), k.call("item_4"), k.call("item_5"), k.call("item_6")]
	click_text += "Shop:           %s\nAttributes:     %s" % [k.call("shop"), k.call("attr")]
	$ClickPanel/ClickList.text = click_text

	var wasd_text = "Move:           W A S D\nAttack target:  Right-click on enemy\n"
	wasd_text += "Skill 1:        %s\nSkill 2:        %s\n" % [k.call("ability_q"), k.call("ability_e")]
	wasd_text += "Items 1-6:      %s %s %s %s %s %s\n" % [k.call("item_1"), k.call("item_2"), k.call("item_3"), k.call("item_4"), k.call("item_5"), k.call("item_6")]
	wasd_text += "Shop:           %s\nAttributes:     %s" % [k.call("shop"), k.call("attr")]
	$WASDPanel/WASDList.text = wasd_text

func _highlight_panel(scheme: String):
	var click_border = $ClickPanel/ClickBorder
	var wasd_border = $WASDPanel/WASDBorder
	if scheme == "wasd":
		click_border.color = Color(0.3, 0.6, 1.0, 0.0)
		wasd_border.color = Color(0.3, 0.6, 1.0, 0.3)
		$WASDPanel.color = Color(0.2, 0.22, 0.3, 1)
		$ClickPanel.color = Color(0.15, 0.15, 0.2, 1)
	else:
		click_border.color = Color(0.3, 0.6, 1.0, 0.3)
		wasd_border.color = Color(0.3, 0.6, 1.0, 0.0)
		$ClickPanel.color = Color(0.2, 0.22, 0.3, 1)
		$WASDPanel.color = Color(0.15, 0.15, 0.2, 1)

func _on_master_vol_changed(val: float):
	$MasterVolValue.text = str(int(val))
	AudioManager.set_master_volume(val / 100.0)

func _on_sfx_vol_changed(val: float):
	$SfxVolValue.text = str(int(val))
	AudioManager.set_sfx_volume(val / 100.0)

func _on_music_vol_changed(val: float):
	$MusicVolValue.text = str(int(val))
	AudioManager.set_bgm_volume(val / 100.0)

func _on_fullscreen_toggled(toggled: bool):
	var data = AudioManager._read_settings()
	data["fullscreen"] = toggled
	AudioManager._write_settings(data)
	GameManager._apply_window_settings()

func _on_resolution_selected(idx: int):
	var text = $ResolutionOption.get_item_text(idx)
	var data = AudioManager._read_settings()
	if text == "Auto":
		data.erase("resolution")
	else:
		data["resolution"] = text
	AudioManager._write_settings(data)
	GameManager._apply_window_settings()

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
