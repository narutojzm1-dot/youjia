extends SceneTree
const Sequence = preload("res://scripts/game/pond_story_sequence.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(label)
func _initialize() -> void:
	var s = Sequence.new()
	var c := {"turtle_present": true, "chicken_stage": "chick", "goose_present": true,
		"available": true, "owns_participants": true}
	s.tick(40.0, c)
	check(not s.active(), "a chick cannot ride as an adult")
	c.chicken_stage = "hen"
	c.available = false
	s.tick(1.0, c)
	check(not s.active(), "food/other encounter reservation blocks starting")
	c.available = true
	s.tick(1.0, c)
	check(s.phase == "approach_hen" and s.encounter == 1, "start requests approach")
	s.tick(1000.0, c)
	check(s.phase == "approach_hen", "elapsed time cannot fabricate arrival")
	c.paused = true
	var before: float = s.elapsed
	s.tick(60.0, c)
	check(s.elapsed == before, "pause freezes time")
	c.paused = false
	c.hen_arrived = true
	s.tick(0.1, c)
	check(s.phase == "greet", "real arrival begins friendship")
	s.tick(100.0, c)
	check(s.phase == "greet", "large gap cannot skip greeting")
	for i in range(12): s.tick(0.25, c)
	check(s.phase == "ride", "greeting precedes riding")
	c.interrupted = true
	var result: Dictionary = s.tick(0.1, c)
	check(result.release and not s.active(), "interruption releases participants")
	check(not s.cancel().release, "release happens once")
	c.interrupted = false
	s.tick(1.0, c)
	check(not s.active(), "cancellation cannot spam restart")
	s.cooldown = 0.0
	s.tick(0.1, c)
	c.owns_participants = false
	check(s.tick(0.1, c).release, "lost actor ownership cancels safely")
	c.owns_participants = true
	s.cooldown = 0.0
	s.tick(0.1, c)
	c.hen_arrived = false
	for i in range(96): s.tick(0.25, c)
	check(not s.active(), "unreachable partner times out")
	# Full sequence: refusal must occur before attempted peck; goose never rides.
	s.cooldown = 0.0
	c.hen_arrived = true
	c.goose_arrived = true
	c.turtle_home = true
	s.tick(0.1, c)
	var phases: Array[String] = []
	for i in range(100):
		var p: String = s.tick(0.25, c).phase
		if phases.is_empty() or phases.back() != p: phases.append(p)
	check(phases == ["greet", "ride", "dismount", "approach_goose", "refuse", "peck_attempt", "retreat", "idle"], "complete ordered relationship arc")
	check(s.cooldown > 170.0, "completed story has quiet interval")
	print("POND_STORY_SEQUENCE: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
