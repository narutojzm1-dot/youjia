extends Node
## One shared audio backend; these are bounded ambience layers, not game clocks.
const Player := preload("res://scripts/manus/browser_bgm_player.gd")
const CUES := ["night.ambience", "rain.ambience", "sleep.ambience"]
var players: Dictionary = {}
var gains := {"yard.ambience":1.0, "night.ambience":0.0, "rain.ambience":0.0, "sleep.ambience":0.0}
var targets: Dictionary = gains.duplicate()
var running := false
var suspended := false
var sleeping_paused := false
var headless := false
var streams: Dictionary = {}

func _ready() -> void:
	for cue: String in CUES:
		var player := Player.new()
		player.name = cue.replace(".", "_")
		player.bus = "Ambience"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.force_loop = true
		player.volume_linear = 0.0
		add_child(player)
		players[cue] = player

static func weights(night: bool, rain: bool, sleeping: bool) -> Dictionary:
	# Sum stays exactly one, including transitions: the authored 30% ceiling
	# cannot be bypassed by stacking individually full-volume ambience tracks.
	var outside := 0.35 if sleeping else 1.0
	var bed := outside * (0.6 if rain else 1.0)
	return {"yard.ambience":0.0 if night else bed,
		"night.ambience":bed if night else 0.0,
		"rain.ambience":outside * 0.4 if rain else 0.0,
		"sleep.ambience":0.65 if sleeping else 0.0}

func configure(source: Dictionary, night: bool, rain: bool, sleeping: bool,
		active: bool, background: bool, paused: bool, silent_test: bool) -> void:
	streams = source
	targets = weights(night, rain, sleeping)
	running = active
	suspended = background
	sleeping_paused = paused
	headless = silent_test
	if not running:
		stop()
		return
	for cue: String in CUES:
		players[cue].stream_paused = suspended or (cue == "sleep.ambience" and paused)

func tick(delta: float) -> void:
	if not running or suspended: return
	# A single interpolation factor preserves the mix budget at every frame.
	var blend := 1.0 - exp(-maxf(delta, 0.0) * 1.5)
	for cue: String in gains:
		gains[cue] = lerpf(gains[cue], targets[cue], blend)
	for cue: String in CUES:
		var player: Node = players[cue]
		var stream: AudioStream = streams.get(cue)
		# Stop snoring immediately when the confirmed sleep stage ends. No
		# snore tail after wake/title/rejected save, even if the bed is fading.
		var wanted := float(gains[cue]) > 0.0001 and stream != null
		if cue == "sleep.ambience" and targets[cue] <= 0.0: wanted = false
		if not wanted:
			player.stop()
			player.stream = null
			continue
		if player.stream != stream:
			player.stream = stream
			player.volume_linear = gains[cue]
			if not headless: player.play()
		player.volume_linear = gains[cue]
		player.stream_paused = suspended or (cue == "sleep.ambience" and sleeping_paused)

func stop() -> void:
	running = false
	for cue: String in players:
		players[cue].stop()
		players[cue].stream = null
		players[cue].stream_paused = false
	# Re-entry fades only from the latest facts, never from a previous night.
	gains = targets.duplicate()

func forget(stream: AudioStream) -> void:
	for cue: String in players:
		if players[cue].stream == stream:
			players[cue].stop()
			players[cue].stream = null
