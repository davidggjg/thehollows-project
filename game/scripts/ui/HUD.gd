extends CanvasLayer

# ═══════════════════════════════════════════════════════
#  HUD — In-Game UI
#  Fear vignette, health, flashlight battery,
#  interact prompt, note display, inventory
# ═══════════════════════════════════════════════════════

@onready var vignette:         ColorRect    = $Vignette
@onready var interact_prompt:  Label        = $InteractPrompt
@onready var flashlight_bar:   ProgressBar  = $FlashlightBar
@onready var health_bar:       ProgressBar  = $HealthBar
@onready var note_panel:       Panel        = $NotePanel
@onready var note_title:       Label        = $NotePanel/Title
@onready var note_body:        Label        = $NotePanel/Body
@onready var level_label:      Label        = $LevelLabel
@onready var inventory_panel:  Panel        = $InventoryPanel
@onready var fear_overlay:     ColorRect    = $FearOverlay
@onready var aberration_rect:  ColorRect    = $AberrationRect
@onready var sanity_blur:      ColorRect    = $SanityBlur
@onready var crossfade_black:  ColorRect    = $CrossfadeBlack
@onready var objective_label:  Label        = $ObjectiveLabel

var _player: Node = null
var _note_tween: Tween = null
var _show_inventory: bool = false

func _ready() -> void:
	add_to_group("hud")
	add_to_group("hud")
	note_panel.visible  = false
	inventory_panel.visible = false
	interact_prompt.visible = false
	crossfade_black.modulate.a = 1.0
	# Connect to systems
	FearSystem.fear_changed.connect(_on_fear_changed)
	FearSystem.sanity_event.connect(_on_sanity_event)
	GameManager.level_loaded.connect(_on_level_loaded)
	# Fade in
	fade_in(1.5)
	level_label.text = GameManager.get_level_name()

func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	_update_bars()
	_update_interact_prompt()
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventory()
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

func _update_bars() -> void:
	if _player.has_method("get_health"):
		health_bar.value = _player.get_health()
	if _player.has_method("get_battery"):
		flashlight_bar.value = _player.get_battery() * 100.0
		flashlight_bar.visible = _player.is_flashlight_on()

func _update_interact_prompt() -> void:
	# Check what's in interact range via raycast result
	# This is polled from the player's interact ray
	pass

func _on_fear_changed(level: float) -> void:
	# Vignette darkens with fear
	var vignette_alpha = smoothstep(0.0, 1.0, level) * 0.85
	vignette.modulate.a = vignette_alpha
	# Red tint at high fear
	fear_overlay.modulate.a = smoothstep(0.6, 1.0, level) * 0.25
	# Chromatic aberration via shader parameter
	if aberration_rect.material:
		aberration_rect.material.set_shader_parameter("strength", level * 8.0)

func _on_sanity_event(event_type: String) -> void:
	match event_type:
		"shadow_figure":
			_flash_shadow()
		"whisper":
			pass  # Handled by AudioManager
		"static_burst":
			_flash_static()
		"distant_knock":
			pass

func _flash_shadow() -> void:
	# Briefly show a shadow figure silhouette on screen edge
	var t = create_tween()
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0.7)
	rect.size = Vector2(80, 200)
	rect.position = Vector2(randf_range(0, 1400), randf_range(100, 700))
	add_child(rect)
	t.tween_property(rect, "modulate:a", 0.0, 0.5)
	await t.finished
	rect.queue_free()

func _flash_static() -> void:
	if sanity_blur.material:
		sanity_blur.material.set_shader_parameter("intensity", 1.0)
		var t = create_tween()
		t.tween_property(sanity_blur.material, "shader_parameter/intensity", 0.0, 0.8)

func _on_level_loaded(_idx: int) -> void:
	level_label.text = GameManager.get_level_name()

# ── NOTE DISPLAY ──────────────────────────────────────────
func show_note(title: String, body: String) -> void:
	if _player and _player.has_method("release_mouse"):
		_player.release_mouse()
	note_title.text = title
	note_body.text  = body
	note_panel.visible = true
	note_panel.modulate.a = 0.0
	if _note_tween:
		_note_tween.kill()
	_note_tween = create_tween()
	_note_tween.tween_property(note_panel, "modulate:a", 1.0, 0.5)
	GameManager.set_state(GameManager.GameState.CUTSCENE)

func close_note() -> void:
	if _note_tween:
		_note_tween.kill()
	_note_tween = create_tween()
	_note_tween.tween_property(note_panel, "modulate:a", 0.0, 0.3)
	await _note_tween.finished
	note_panel.visible = false
	GameManager.set_state(GameManager.GameState.PLAYING)
	if _player and _player.has_method("capture_mouse"):
		_player.capture_mouse()

func _input(event: InputEvent) -> void:
	if note_panel.visible and event.is_action_pressed("interact"):
		close_note()

# ── INVENTORY ─────────────────────────────────────────────
func _toggle_inventory() -> void:
	_show_inventory = !_show_inventory
	inventory_panel.visible = _show_inventory
	if _show_inventory:
		if _player:
			_player.release_mouse()
		GameManager.set_state(GameManager.GameState.PAUSED)
	else:
		if _player:
			_player.capture_mouse()
		GameManager.set_state(GameManager.GameState.PLAYING)

# ── PAUSE ─────────────────────────────────────────────────
func _toggle_pause() -> void:
	if note_panel.visible:
		return
	if GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.set_state(GameManager.GameState.PLAYING)
		if _player:
			_player.capture_mouse()
	else:
		GameManager.set_state(GameManager.GameState.PAUSED)
		if _player:
			_player.release_mouse()

# ── TRANSITIONS ───────────────────────────────────────────
func fade_in(duration: float = 1.0) -> void:
	crossfade_black.visible = true
	crossfade_black.modulate.a = 1.0
	var t = create_tween()
	t.tween_property(crossfade_black, "modulate:a", 0.0, duration)
	await t.finished
	crossfade_black.visible = false

func fade_out(duration: float = 1.0) -> void:
	crossfade_black.visible = true
	crossfade_black.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(crossfade_black, "modulate:a", 1.0, duration)

func set_objective(text: String) -> void:
	objective_label.text = "▶ " + text
	var t = create_tween()
	objective_label.modulate.a = 0.0
	t.tween_property(objective_label, "modulate:a", 1.0, 0.5)
	await get_tree().create_timer(4.0).timeout
	t = create_tween()
	t.tween_property(objective_label, "modulate:a", 0.0, 1.0)
