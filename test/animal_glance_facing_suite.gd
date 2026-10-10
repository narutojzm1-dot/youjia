extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	seed(565)
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	for id: String in ["sheep_a", "sheep_b", "cow", "horse"]:
		var actor = world.actor_named(id)
		for side: float in [-1.0, 1.0]:
			# Movement has already selected a heading in actor.tick(). The following
			# world glance tick must not restore the pre-glance heading over it.
			actor.state = "wander"
			actor.facing = side
			actor._glance_saved_facing = -side
			actor._glance_timer = 1.0
			actor.tick_glance(1.0/60.0, actor.position + Vector2(-side*50, 0))
			check(actor.facing == side, id + " walking owns its heading")
			check(actor._glance_timer < 0, id + " interrupted glance enters cooldown")
			actor.state = "rest"
			actor.facing = side
			for offset: float in [-1.0, 0.0, 1.0]:
				actor.facing = side
				for trial in 20:
					actor._glance_timer = 0.0
					actor.tick_glance(1.0/60.0, actor.position + Vector2(offset, 60))
				check(actor.facing == side, id + " vertically aligned observer keeps heading")
			actor._glance_timer = 0.01
			actor._glance_saved_facing = -side
			actor.tick_glance(0.02, actor.position + Vector2(side*50, 0))
			check(actor.facing == -side, id + " completed resting glance restores heading")
	world.free()
	root.get_node("AudioDirector").release_streams()
	print("ANIMAL_GLANCE_FACING checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
