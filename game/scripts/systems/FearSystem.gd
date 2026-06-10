extends Node

# ═══════════════════════════════════════════════════════
#  FEAR SYSTEM — Global Autoload
#  Controls the psychological horror layer:
#  vignette, blur, heartbeat, visual hallucinations,
#  and the creature's awareness of the player
# ═══════════════════════════════════════════════════════

signal fear_changed(level: float)
signal sanity_event(event_type: String)

var fear_level: float = 0.0          # 0.0 = calm, 1.0 = maximum terror
var sanity: float = 100.0            # depletes over time in high-fear zones
var _recovery_timer: float = 0.0
var _hallucination_timer: float = 0.0

# Fear sources (additive)
var _fear_sources: Dictionary = {}   # { "source_name": float_value }

# Thresholds
const FEAR_RECOVERY_DELAY = 5.0      # seconds before fear starts dropping
const FEAR_RECOVERY_RATE  = 0.05     # per second when calm
const SANITY_DRAIN_RATE   = 0.5      # per second at max fear
const HALLUCINATION_INTERVAL_MIN = 8.0
const HALLUCINATION_INTERVAL_MAX = 30.0

func _ready() -> void:
	_reset_hallucination_timer()

func _process(delta: float) -> void:
	_update_fear(delta)
	_update_sanity(delta)
	_update_hallucinations(delta)
	AudioManager.set_heartbeat(fear_level)

func _update_fear(delta: float) -> void:
	# Sum all active fear sources
	var total: float = 0.0
	for key in _fear_sources:
		total += _fear_sources[key]
	total = clampf(total, 0.0, 1.0)

	if total > fear_level:
		fear_level = move_toward(fear_level, total, delta * 1.5)
		_recovery_timer = FEAR_RECOVERY_DELAY
	else:
		_recovery_timer -= delta
		if _recovery_timer <= 0.0:
			fear_level = move_toward(fear_level, total, delta * FEAR_RECOVERY_RATE)

	fear_changed.emit(fear_level)

func _update_sanity(delta: float) -> void:
	if fear_level > 0.7:
		sanity -= SANITY_DRAIN_RATE * fear_level * delta
		sanity = maxf(sanity, 0.0)

func _update_hallucinations(delta: float) -> void:
	if sanity < 50.0:
		_hallucination_timer -= delta
		if _hallucination_timer <= 0.0:
			_trigger_hallucination()
			_reset_hallucination_timer()

func _trigger_hallucination() -> void:
	var events = ["shadow_figure", "whisper", "distant_knock",
	              "door_slam", "static_burst", "breathing"]
	# Only trigger visual/audio hallucinations, not gameplay-breaking ones
	var intensity = 1.0 - (sanity / 100.0)
	if randf() < intensity:
		sanity_event.emit(events[randi() % events.size()])

func _reset_hallucination_timer() -> void:
	_hallucination_timer = randf_range(HALLUCINATION_INTERVAL_MIN, HALLUCINATION_INTERVAL_MAX)

# ── PUBLIC API ────────────────────────────────────────────

## Add a fear source (e.g. "creature_nearby" = 0.8)
func add_fear(source: String, amount: float) -> void:
	_fear_sources[source] = clampf(amount, 0.0, 1.0)

## Remove a fear source when it's no longer active
func remove_fear(source: String) -> void:
	_fear_sources.erase(source)

## Instant fear spike (jump scare equivalent — use SPARINGLY)
func fear_spike(amount: float) -> void:
	fear_level = minf(fear_level + amount, 1.0)
	_recovery_timer = FEAR_RECOVERY_DELAY

## Restore sanity (finding a safe room, candlelight, etc.)
func restore_sanity(amount: float) -> void:
	sanity = minf(sanity + amount, 100.0)

func get_fear() -> float:
	return fear_level

func get_sanity() -> float:
	return sanity

## Returns intensity multiplier for visual effects (vignette, aberration)
func get_visual_intensity() -> float:
	return fear_level * (1.0 + (1.0 - sanity / 100.0) * 0.5)

func reset() -> void:
	fear_level = 0.0
	sanity = 100.0
	_fear_sources.clear()
	_recovery_timer = 0.0
