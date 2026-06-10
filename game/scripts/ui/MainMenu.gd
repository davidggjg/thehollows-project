extends Control

@onready var main_panel:     Control   = $MainPanel
@onready var settings_panel: Control   = $SettingsPanel
@onready var controls_panel: Control   = $ControlsPanel
@onready var credits_panel:  Control   = $CreditsPanel
@onready var title_label:    Label     = $TitleLabel
@onready var subtitle_label: Label     = $SubtitleLabel
@onready var version_label:  Label     = $VersionLabel
@onready var fade_rect:      ColorRect = $FadeRect
@onready var volume_slider:      HSlider  = $SettingsPanel/VolumeSlider
@onready var music_slider:       HSlider  = $SettingsPanel/MusicSlider
@onready var sensitivity_slider: HSlider  = $SettingsPanel/SensitivitySlider
@onready var brightness_slider:  HSlider  = $SettingsPanel/BrightnessSlider
@onready var fullscreen_check:   CheckBox = $SettingsPanel/FullscreenCheck

func _ready() -> void:
	version_label.text = "v1.0.0"
	var settings = SaveSystem.load_settings()
	if settings.is_empty():
		settings = SaveSystem.default_settings()
	_apply_settings(settings)
	var shown = ProjectSettings.get_setting("application/first_launch_shown", false)
	_show_panel(controls_panel if not shown else main_panel)
	fade_rect.modulate.a = 1.0
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	title_label.modulate.a    = 0.0
	subtitle_label.modulate.a = 0.0
	await get_tree().create_timer(0.5).timeout
	create_tween().tween_property(title_label,    "modulate:a", 1.0, 1.0)
	await get_tree().create_timer(0.8).timeout
	create_tween().tween_property(subtitle_label, "modulate:a", 1.0, 1.5)

func _show_panel(panel: Control) -> void:
	for p in [main_panel, settings_panel, controls_panel, credits_panel]:
		if p: p.visible = false
	panel.visible = true

func _on_new_game_pressed() -> void:
	SaveSystem.delete_save()
	FearSystem.reset()
	_fade_and_load(0)

func _on_continue_pressed() -> void:
	if not SaveSystem.save_exists():
		return
	SaveSystem.load_game()
	FearSystem.reset()
	_fade_and_load(GameManager.current_level)

func _on_settings_pressed() -> void:
	_show_panel(settings_panel)

func _on_exit_pressed() -> void:
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	await t.finished
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sensitivity_changed(_value: float) -> void:
	pass

func _on_brightness_changed(value: float) -> void:
	RenderingServer.global_shader_parameter_set("brightness_mult", value)

func _on_fullscreen_toggled(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on
		else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_from_settings() -> void:
	SaveSystem.save_settings({
		"master_volume":     volume_slider.value,
		"music_volume":      music_slider.value,
		"mouse_sensitivity": sensitivity_slider.value,
		"brightness":        brightness_slider.value,
		"fullscreen":        fullscreen_check.button_pressed,
	})
	_show_panel(main_panel)

func _apply_settings(s: Dictionary) -> void:
	if volume_slider:      volume_slider.value              = s.get("master_volume",     0.8)
	if music_slider:       music_slider.value               = s.get("music_volume",      0.6)
	if sensitivity_slider: sensitivity_slider.value         = s.get("mouse_sensitivity", 0.3)
	if brightness_slider:  brightness_slider.value          = s.get("brightness",        1.0)
	if fullscreen_check:   fullscreen_check.button_pressed  = s.get("fullscreen",        true)

func _on_understood_pressed() -> void:
	ProjectSettings.set_setting("application/first_launch_shown", true)
	_show_panel(main_panel)

func _on_back_from_credits() -> void:
	_show_panel(main_panel)

func _fade_and_load(level_index: int) -> void:
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await t.finished
	GameManager.load_level(level_index)
