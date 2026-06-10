extends CanvasLayer

@onready var vignette:        ColorRect   = $Vignette
@onready var fear_overlay:    ColorRect   = $FearOverlay
@onready var crossfade_black: ColorRect   = $CrossfadeBlack
@onready var health_bar:      ProgressBar = $HealthBar
@onready var flashlight_bar:  ProgressBar = $FlashlightBar
@onready var interact_prompt: Label       = $InteractPrompt
@onready var objective_label: Label       = $ObjectiveLabel
@onready var note_panel:      Panel       = $NotePanel
@onready var note_title:      Label       = $NotePanel/Title
@onready var note_body:       Label       = $NotePanel/Body
@onready var inventory_panel: Panel       = $InventoryPanel
@onready var level_label:     Label       = $LevelLabel

var _player: Node = null

func _ready() -> void:
	add_to_group("hud")
	note_panel.visible      = false
	inventory_panel.visible = false
	interact_prompt.visible = false
	# Start fully black then fade to transparent
	crossfade_black.color = Color(0, 0, 0, 1)
	crossfade_black.visible = true
	FearSystem.fear_changed.connect(_on_fear_changed)
	FearSystem.sanity_event.connect(_on_sanity_event)
	level_label.text = GameManager.get_level_name()
	fade_in(1.5)

func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	if _player.has_method("get_health"):
		health_bar.value = _player.get_health()
	if _player.has_method("get_battery") and _player.has_method("is_flashlight_on"):
		flashlight_bar.visible = _player.is_flashlight_on()
		flashlight_bar.value   = _player.get_battery() * 100.0
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventory()
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

func _on_fear_changed(level: float) -> void:
	vignette.color.a    = smoothstep(0.0, 1.0, level) * 0.85
	fear_overlay.color.a = smoothstep(0.6, 1.0, level) * 0.25

func _on_sanity_event(event_type: String) -> void:
	if event_type == "shadow_figure":
		_flash_shadow()

func _flash_shadow() -> void:
	var rect = ColorRect.new()
	rect.color    = Color(0, 0, 0, 0.6)
	rect.size     = Vector2(60, 180)
	rect.position = Vector2(randf_range(50, 1800), randf_range(100, 700))
	add_child(rect)
	var t = create_tween()
	t.tween_property(rect, "color:a", 0.0, 0.6)
	await t.finished
	rect.queue_free()

func show_note(title: String, body: String) -> void:
	note_title.text = title
	note_body.text  = body
	note_panel.visible = true
	note_panel.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(note_panel, "modulate:a", 1.0, 0.4)
	if _player and _player.has_method("release_mouse"):
		_player.release_mouse()
	GameManager.set_state(GameManager.GameState.CUTSCENE)

func close_note() -> void:
	var t = create_tween()
	t.tween_property(note_panel, "modulate:a", 0.0, 0.3)
	await t.finished
	note_panel.visible = false
	GameManager.set_state(GameManager.GameState.PLAYING)
	if _player and _player.has_method("capture_mouse"):
		_player.capture_mouse()

func _input(event: InputEvent) -> void:
	if note_panel.visible and event.is_action_pressed("interact"):
		close_note()

func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		if _player: _player.release_mouse()
		GameManager.set_state(GameManager.GameState.PAUSED)
	else:
		if _player: _player.capture_mouse()
		GameManager.set_state(GameManager.GameState.PLAYING)

func _toggle_pause() -> void:
	if note_panel.visible:
		return
	if GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.set_state(GameManager.GameState.PLAYING)
		if _player: _player.capture_mouse()
	else:
		GameManager.set_state(GameManager.GameState.PAUSED)
		if _player: _player.release_mouse()

func fade_in(duration: float = 1.0) -> void:
	crossfade_black.visible = true
	crossfade_black.color   = Color(0, 0, 0, 1)
	var t = create_tween()
	t.tween_property(crossfade_black, "color:a", 0.0, duration)
	await t.finished
	crossfade_black.visible = false

func fade_out(duration: float = 1.0) -> void:
	crossfade_black.visible = true
	crossfade_black.color   = Color(0, 0, 0, 0)
	var t = create_tween()
	t.tween_property(crossfade_black, "color:a", 1.0, duration)

func set_objective(text: String) -> void:
	objective_label.text       = "▶ " + text
	objective_label.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(objective_label, "modulate:a", 1.0, 0.5)
	await get_tree().create_timer(5.0).timeout
	t = create_tween()
	t.tween_property(objective_label, "modulate:a", 0.0, 1.0)
