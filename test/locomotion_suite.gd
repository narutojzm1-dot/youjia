Warning: truncated output (original token count: 10514)
Total output lines: 837

extends Node

# Deterministic motion regressions. Run independently of the generic suite:
# godot --headless --path . res://test/locomotion_suite.tscn
# Ticks are supplied directly so the same scenarios exercise 30/60/120 Hz.
const WORLD_SIZE := Vector2(1280, 720)
const FRAME_RATES := [30, 60, 120]
var _checks := 0
var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(9052026)
	TuningStore.end_run()
	TuningStore.reset_defaults()
	_test_native_skeleton()
	_test_painted_skeleton()
	_test_resident_skeleton()
	_test_default_gait_selection()
	_test_sequence_default()
	_test_cow_horse_cast()
	_test_player_fallback()
	_test_player_frame_rates()
	_test_blocked_phase()
	_test_stopping_settles()
	_test_stationary_leader()
	_test_ground_constraints()
	_test_reduced_motion()
	_test_animal_frame_rates()
	_test_moving_leader()
	_test_mouse_goal_settles()
	_test_facing_and_swimming()
	_test_lead_speed_tuning()
	_test_cancelled_pivot()
	_test_planted_feet()
	_test_rig_expression_fallback()
	_test_rig_reduced_motion_and_teleport()
	_test_rig_pose_transition()
	_test_small_debug_relocation()
	if _failures.is_empty():
		print("[locomotion-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("[locomotion-tests] " + failure)
		print("[locomotion-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
		get_tree().quit(1)


func _player(start: Vector2) -> Vacationer:
	var player := Vacationer.new()
	add_child(player)
	player.setup(start)
	# Rig-specific fixtures explicitly opt in; the real yard uses accepted frames.
	player.set_planted_gait_enabled(true)
	return player


func _animal(start: Vector2, kind: String = "llama") -> FeltActor:
	var animal := FeltActor.new()
	add_child(animal)
	animal.setup({
		"id": kind, "species": kind, "position": start, "speed": 28.0,
		"experimental_planted_gait": true,
		"wander": Rect2(300, 440, 500, 80),
		"textures": {"idle": "res://assets/holiday/characters/%s.png" % kind},
	})
	animal.state = "wander" # This fixture explicitly tests an active walking animal.
	return animal


func _test_player_frame_rates() -> void:
	var distances: Array[float] = []
	var phases := PackedFloat64Array()
	for fps: int in FRAME_RATES:
		var player := _player(Vector2(300, 500))
		for frame: int in fps * 3:
			player.tick(1.0 / fps, Vector2.RIGHT, WORLD_SIZE)
		var distance := player.position.x - 300.0
		distances.append(distance)
		phases.append(player._step_phase)
		_check(distance > 250.0 and distance < 285.0, "player must walk at %d Hz, distance %.3f" % [fps, distance])
		_check(absf(player.position.y - 500.0) < 0.001, "horizontal input preserves y at %d Hz" % fps)
		player.free()
	print("[locomotion-tests] player distance at 30/60/120 Hz: %s; phases: %s" % [distances, phases])
	_check(distances.max() - distances.min() < 2.0, "3s player displacement varies by less than 2px across 30/60/120 Hz")


func _test_blocked_phase() -> void:
	for fps: int in FRAME_RATES:
		var player := _player(Vector2(WORLD_SIZE.x - 40.0, 500))
		player.tick(1.0 / fps, Vector2.RIGHT, WORLD_SIZE)
		var player_phase := player._step_phase
		for frame: int in fps:
			player.tick(1.0 / fps, Vector2.RIGHT, WORLD_SIZE)
		_check(is_equal_approx(player._step_phase, player_phase), "blocked player gait freezes at %d Hz" % fps)
		_check(player.player_state != "walking", "blocked player is not walking at %d Hz" % fps)
		_check(absf(player._sprite.position.y) < 0.01, "blocked player stays grounded at %d Hz" % fps)
		player.free()
		var target := Node2D.new()
		target.position = Vector2(1500, 500)
		add_child(target)
		var animal := _animal(Vector2(WORLD_SIZE.x - 48.0, 500))
		animal.begin_lead(target)
		animal.tick(1.0 / fps, WORLD_SIZE)
		var animal_phase := animal._step_phase
		for frame: int in fps:
			animal.tick(1.0 / fps, WORLD_SIZE)
		_check(is_equal_approx(animal._step_phase, animal_phase), "blocked animal gait freezes at %d Hz" % fps)
		_check(absf(animal._sprite.position.y) < 0.01, "blocked animal stays grounded at %d Hz" % fps)
		animal.free()
		target.free()


func _test_stopping_settles() -> void:
	for fps: int in FRAME_RATES:
		var player := _player(Vector2(300, 500))
		for frame: int in fps:
			player.tick(1.0 / fps, Vector2.RIGHT, WORLD_SIZE)
		for frame: int in fps * 2:
			player.tick(1.0 / fps, Vector2.ZERO, WORLD_SIZE)
		var stopped_position := player.position
		var stopped_phase := player._step_phase
		for frame: int in fps:
			player.tick(1.0 / fps, Vector2.ZERO, WORLD_SIZE)
		_check(player.position.distance_to(stopped_position) < 0.01, "released player stops drifting at %d Hz" % fps)
		_check(is_equal_approx(player._step_phase, stopped_phase), "released player gait stops at %d Hz" % fps)
		_check(player._velocity.length() < 0.01, "released player velocity settles at %d Hz" % fps)
		_check(absf(player._sprite.position.y) < 0.01, "released player feet settle at %d Hz" % fps)
		player.free()
		var animal := _animal(Vector2(400, 500))
		animal._target = Vector2(900, 500)
		for frame: int in fps:
			animal.tick(1.0 / fps, WORLD_SIZE)
		animal.state = "graze"
		animal._idle_time = 10.0
		for frame: int in fps * 2:
			animal.tick(1.0 / fps, WORLD_SIZE)
		stopped_position = animal.position
		stopped_phase = animal._step_phase
		for frame: int in fps:
			animal.tick(1.0 / fps, WORLD_SIZE)
		_check(animal.position.distance_to(stopped_position) < 0.01, "grazing animal stops drifting at %d Hz" % fps)
		_check(is_equal_approx(animal._step_phase, stopped_phase), "grazing animal gait stops at %d Hz" % fps)
		_check(absf(animal._sprite.position.y) < 0.01, "grazing animal feet settle at %d Hz" % fps)
		animal.free()


func _test_stationary_leader() -> void:
	for fps: int in FRAME_RATES:
		for start_x: float in [500.0, 300.0, 700.0]:
			var target := Node2D.new()
			target.position = Vector2(500, 500)
			add_child(target)
			var animal := _animal(Vector2(start_x, 500))
			animal.begin_lead(target)
			for frame: int in fps * 8:
				# YardWorld reissues begin_lead each tick. It must not reset arrival.
				animal.begin_lead(target)
				animal.tick(1.0 / fps, WORLD_SIZE)
			var settled := animal.position
			var travel_after_settle := 0.0
			var flips := 0
			var previous_facing := animal.facing
			for frame: int in fps * 4:
				var before := animal.position
				animal.begin_lead(target)
				animal.tick(1.0 / fps, WORLD_SIZE)
				travel_after_settle += animal.position.distance_to(before)
				if previous_facing != animal.facing:
					flips += 1
				previous_facing = animal.facing
			_check(travel_after_settle < 0.01, "stationary lead must not oscillate at %d Hz from x=%d (travel %.3f)" % [fps, start_x, travel_after_settle])
			_check(flips == 0, "settled lead must not reverse facing at %d Hz from x=%d" % [fps, start_x])
			_check(settled.distance_to(target.position) < 80.0, "lead approaches comfortable range at %d Hz from x=%d" % [fps, start_x])
			animal.free()
			target.free()


func _test_ground_constraints() -> void:
	var player := _player(Vector2(420, 500))
	player.walk_ground = YardGround.lawn()
	player.avoid_pond = true
	var ground_ok := true
	for frame: int in 60 * 30:
		var direction := Vector2.from_angle(float(frame / 120) * TAU / 8.0)
		player.tick(1.0 / 60, direction, WORLD_SIZE)
		ground_ok = ground_ok and YardGround.allows(player.position, player.walk_ground, true)
	_check(ground_ok, "player remains on allowed lawn over 30s directional traversal")
	player.free()
	for kind: String in ["llama", "cow", "goose", "duck"]:
		var animal := _animal(Vector2(550, 500), kind)
		if kind == "duck":
			animal.adopt_ellipse(YardGround.POND_CENTER, YardGround.POND_RADIUS * 0.72)
		else:
			animal.adopt_ground(YardGround.lawn(), true)
		ground_ok = true
		for frame: int in 60 * 45:
			if frame % 240 == 0:
				# Include unreachable goals on both sides of the ground boundary.
				animal._target = Vector2(100, 700) if frame % 480 == 0 else Vector2(1200, 300)
				animal.state = "wander"
			animal.tick(1.0 / 60, WORLD_SIZE)
			ground_ok = ground_ok and animal._stands_on(animal.position)
		_check(ground_ok, "%s stays on its valid ground over 45s including unreachable goals" % kind)
		animal.free()


func _test_reduced_motion() -> void:
	TuningStore.set_value("ui.reduced_motion", true)
	var player := _player(Vector2(300, 500))
	for frame: int in 60:
		player.tick(1.0 / 60, Vector2.RIGHT, WORLD_SIZE)
	_check(player.position.x > 360.0, "reduced motion does not disable travel")
	_check(absf(player._sprite.position.y) < 0.001, "reduced motion suppresses player bob")
	_check(absf(player._sprite.rotation) < 0.001, "reduced motion suppresses player roll")
	player.free()
	TuningStore.reset_defaults()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _test_animal_frame_rates() -> void:
	var distances: Array[float] = []
	for fps: int in FRAME_RATES:
		seed(501)
		var animal := _animal(Vector2(300, 500))
		animal._target = Vector2(900, 500)
		for frame: int in fps * 3:
			animal.tick(1.0 / fps, WORLD_SIZE)
		distances.append(animal.position.x - 300.0)
		_check(animal.position.x > 370.0, "animal walks at %d Hz" % fps)
		animal.free()
	print("[locomotion-tests] animal distance at 30/60/120 Hz: %s" % [distances])
	_check(distances.max() - distances.min() < 0.5, "3s animal displacement varies by less than 0.5px across frame rates")


func _test_moving_leader() -> void:
	for fps: int in FRAME_RATES:
		var target := _player(Vector2(430, 500))
		target.leading = true
		var animal := _animal(Vector2(300, 500))
		animal.begin_lead(target)
		for frame: int in fps * 6:
			target.tick(1.0 / fps, Vector2.RIGHT, WORLD_SIZE)
			animal.begin_lead(target)
			animal.tick(1.0 / fps, WORLD_SIZE)
		_check(animal.position.distance_to(target.position) < 100.0, "lead catches up to walking player at %d Hz" % fps)
		for frame: int in fps * 5:
			target.tick(1.0 / fps, Vector2.ZERO, WORLD_SIZE)
			animal.tick(1.0 / fps, WORLD_SIZE)
		_check(animal._velocity.length() < 0.01, "lead settles after moving player stops at %d Hz" % fps)
		animal.free()
		target.free()


func _test_mouse_goal_settles() -> void:
	var world := YardWorld.new()
	add_child(world)
	world.setup([])
	_check(world._backdrop.z_index < world.z_index, "ground shadows render above backdrop")
	world.debug_place_player(Vector2(400, 500))
	var goal := Vector2(580, 480)
	_check(world.try_walk_to(goal), "mouse goal on lawn is accepted")
	# Clicks near an animal deliberately snap to its ground point.
	goal = world._walk_goal
	for frame: int in 60 * 6:
		world.tick(1.0 / 60, Vector2.ZERO)
	var player := world.get_player()
	_check(player.position.distance_to(goal) < 14.0, "mouse goal arrives within 14px")
	_check(not world._has_walk_goal, "mouse goal clears after arrival")
	var settled := player.position
	for frame: int in 60 * 2:
		world.tick(1.0 / 60, Vector2.ZERO)
	_check(player.position.distance_to(settled) < 0.01, "mouse-goal arrival stays settled")
	_check(player._velocity.length() < 0.01, "mouse-goal velocity settles")
	world.free()


func _test_facing_and_swimming() -> void:
	var world := YardWorld.new()
	add_child(world)
	world.setup([])
	for id: String in ["cow", "horse", "goose", "sheep_b", "sheep_a", "llama", "duck_a", "duck_b"]:
		var animal := world.actor_named(id)
		_check(animal != null, "native-facing fixture exists: " + id)
		if animal == null:
			continue
		var expected := -1.0 if id in ["cow", "horse", "sheep_b"] else 1.0
		_check(animal._native_facing == expected, "native facing is correct for " + id)
	var swimmer := world.actor_named("duck_a")
	if swimmer != null:
		swimmer._target = swimmer.ellipse_center + Vector2(50, 0)
		swimmer.state = "wander"
		for frame: int in 30:
			swimmer.tick(1.0 / 60, WORLD_SIZE)
		_check(float(swimmer._sprite.material.get_shader_parameter("amount")) == 0.0, "swimming duck has no land-leg deformation")
	var walker := world.actor_named("llama")
	w…4514 tokens truncated…qual_approx(sprite.scale.x,sprite.scale.y)
	_check(uniform,"all painted texture transforms use uniform scaling")
	for frame: int in 90:
		walker.animate(1.0/60.0,Vector2.ZERO,1.0,false)
	_check(is_zero_approx(walker.walk_weight),"painted walk settles to approved idle")
	_check(walker.pelvis.position.is_equal_approx(PaintedWalker.REST_PELVIS),"painted idle preserves approved body height")
	for side: int in 2:
		_check(is_equal_approx(walker.thighs[side].rotation,walker.rest_angles[side].x),"painted idle restores approved relaxed stance")
	walker.animate(1.0/60.0,Vector2(1.5,0),1.0,true)
	_check(is_zero_approx(walker.walk_weight),"painted reduced-motion mode stays still")
	walker.reset_motion()
	_check(is_zero_approx(walker.walk_weight) and is_equal_approx(walker.phase,0.30),"painted teleport reset clears motion state")
	walker.free()


func _test_resident_skeleton() -> void:
	var walker:=ResidentWalker.new()
	add_child(walker)
	_check(walker.shoulders.size()==2 and walker.elbows.size()==2,"resident has independent shoulder and elbow Bone2D chains")
	_check(walker.pants_scale>PaintedWalker.PANTS_SCALE,"resident trousers replace the old exposed sock length")
	var approved_only:=true
	var uniform:=true
	for sprite in walker.sprites:
		approved_only=approved_only and sprite.texture.atlas in [ResidentWalker.RESIDENT,PaintedWalker.PANTS]
		uniform=uniform and is_equal_approx(sprite.scale.x,sprite.scale.y)
	_check(approved_only,"resident visible artwork contains no traveler pack camera or hiking boots")
	_check(uniform,"resident art uses uniform scaling only")
	var rigid:=true
	var quiet_arms:=true
	var rigid_arms:=true
	var elbow_motion:=0.0
	for frame: int in 120:
		walker.animate(1.0/60.0,Vector2(1.5,0),1.0,false)
		for side: int in 2:
			rigid=rigid and absf(walker.thighs[side].global_position.distance_to(walker.shins[side].global_position)-walker.thighs[side].length)<0.001
			rigid=rigid and absf(walker.shins[side].global_position.distance_to(walker.feet[side].global_position)-walker.shins[side].length)<0.001
			quiet_arms=quiet_arms and absf(walker.shoulders[side].rotation)<=0.1051
			rigid_arms=rigid_arms and absf(walker.shoulders[side].global_position.distance_to(walker.elbows[side].global_position)-walker.shoulders[side].length)<0.001
			rigid_arms=rigid_arms and walker.elbows[side].scale==Vector2.ONE
			elbow_motion=maxf(elbow_motion,absf(walker.elbows[side].rotation))
	_check(rigid,"resident extended trousers retain rigid leg lengths during walking")
	_check(quiet_arms,"resident shoulder swing remains below seven degrees")
	_check(rigid_arms,"resident elbow attachment keeps arm length without stretching")
	_check(elbow_motion>0.03 and elbow_motion<0.12,"resident forearms articulate gently independently of shoulders")
	_check(is_zero_approx(walker.torso.rotation),"resident face and shirt stay coherent while walking")
	for frame: int in 90:
		walker.animate(1.0/60.0,Vector2.ZERO,1.0,false)
	_check(walker.pelvis.position.is_equal_approx(PaintedWalker.REST_PELVIS),"resident returns to approved relaxed rest height")
	for shoulder in walker.shoulders:
		_check(is_zero_approx(shoulder.rotation),"resident arms settle to their approved rest pose")
	for elbow in walker.elbows:
		_check(is_zero_approx(elbow.rotation),"resident forearms settle softly back to approved rest")
	walker.animate(1.0/60.0,Vector2.RIGHT,1.0,false)
	walker.reset_motion()
	_check(is_zero_approx(walker.shoulders[0].rotation) and is_zero_approx(walker.elbows[0].rotation),"resident teleport reset clears arm lag")
	walker.free()


func _test_sequence_default() -> void:
	var previous:=OS.get_environment("YOUJIA_PLAYER_GAIT")
	OS.set_environment("YOUJIA_PLAYER_GAIT","")
	var distances: Array[float]=[]
	for fps: int in FRAME_RATES:
		var actor:=Vacationer.new()
		add_child(actor)
		actor.setup(Vector2(300,500))
		_check(actor.sequence_walker_enabled and actor._sequence_walker.animation==&"idle","default sequence starts in approved idle")
		for frame: int in fps*3:
			actor.tick(1.0/fps,Vector2.RIGHT,WORLD_SIZE)
		distances.append(actor.position.x-300)
		_check(actor._sequence_walker.animation==&"walk","keyboard travel advances baked walk")
		_check(actor._sequence_walker.frame>=0 and actor._sequence_walker.frame<16,"baked walk stays inside accepted frame range")
		for frame: int in fps*2:
			actor.tick(1.0/fps,Vector2.ZERO,WORLD_SIZE)
		_check(actor._sequence_walker.animation==&"idle","release returns baked walk to static idle")
		for frame: int in fps:
			actor.tick(1.0/fps,Vector2.LEFT,WORLD_SIZE)
		_check(actor._sequence_walker.scale.x<0,"sequence mirrors when turning left")
		actor.reset_locomotion()
		_check(actor._sequence_walker.distance_phase==0.0,"relocation clears sequence phase")
		actor.free()
	_check(distances.max()-distances.min()<1.0,"calibrated sequence movement is frame-rate stable")
	_check(distances[1]>160.0 and distances[1]<175.0,"accepted sequence walk uses the updated leisurely root speed")
	var world:=YardWorld.new()
	add_child(world)
	world.setup([])
	var player:=world.get_player()
	world.debug_place_player(Vector2(340,600))
	world.try_interact()
	_check(player.carrying_grass and world._grass_patch._loose.visible,"harvest grants inventory immediately and shows loose pickup")
	for frame in 30: world.tick(1.0/60,Vector2.ZERO)
	_check(player.carrying_grass and player._grass.visible,"sequence character can carry grass visibly")
	world.debug_place_player(world.actor_named("llama").position+Vector2(-40,0))
	world.try_interact()
	_check(not player.carrying_grass and player.just_fed_seconds>0.0,"sequence character feeds llama")
	_check(world.debug_force_rule("llama_fed_gentle"),"sequence character preserves photo rule collection")
	world.try_interact()
	_check(player.leading and world.actor_named("llama").state=="lead","sequence character can begin leading")
	world.try_interact()
	_check(not player.leading,"sequence character can stop leading")
	TuningStore.set_value("ui.reduced_motion",true)
	var start:=player.position
	for frame: int in 60:
		player.tick(1.0/60,Vector2.LEFT,WORLD_SIZE)
	_check(player.position.distance_to(start)>10.0 and player._sequence_walker.animation==&"idle","reduced motion preserves input while holding static approved pose")
	TuningStore.reset_defaults()
	world.free()
	OS.set_environment("YOUJIA_PLAYER_GAIT",previous)


func _test_cow_horse_cast() -> void:
	var legacy_id:="llama_sheep_cow_smirk"
	var world:=YardWorld.new()
	add_child(world)
	world.setup([legacy_id])
	_check(world._actors.size()==9,"approved cast contains nine actors including horse")
	_check(world.collected.has(legacy_id) and world.collectible_total()==ExpressionCatalog.all_ids().size(),"old smirk photo remains compatible with the current album catalog")
	var horse:=world.actor_named("horse")
	_check(horse!=null and horse.species=="horse" and horse.avoid_pond,"horse shares lawn constraints and avoids water")
	for id: String in world._actors:
		var actor:=world.actor_named(id)
		_check(actor._sprite.texture!=null,"approved cast resource loads: "+id)
		_check(actor._ground_anchor.x>=0,"approved cast has explicit ground anchor: "+id)
		var anchored:=actor._ground_anchor-actor._sprite.texture.get_size()*0.5+actor._sprite.offset
		_check(anchored.length()<0.001,"source ground anchor is at actor origin: "+id)
	var goose:=world.actor_named("goose")
	var goose_at:=goose.position
	goose.state="graze"
	goose._velocity=Vector2.ZERO
	goose.tick(1.0/60.0,WORLD_SIZE)
	_check(goose._sprite.texture.resource_path.ends_with("/goose_calm.png"),"quiet goose has hand-painted folded-wing standing pose")
	var calm_height:=goose.visual_hit_rect().size.y
	goose.state="rest"
	goose.tick(1.0/60.0,WORLD_SIZE)
	_check(goose._sprite.texture.resource_path.ends_with("/goose_rest.png"),"resting goose uses genuinely lying-down painted pose")
	_check(goose.visual_hit_rect().size.y<calm_height*0.9,"lying goose sits visibly lower than calm standing goose")
	_check((goose._ground_anchor-goose._sprite.texture.get_size()*0.5+goose._sprite.offset).length()<0.001,"lying goose ground anchor remains at actor origin")
	_check(goose.position.distance_to(goose_at)<0.001,"goose changes pose without teleporting across the yard")
	world._fish_carry_type="small"
	var lying_target:=YardInteraction.pointer(world,goose.visual_hit_rect().get_center())
	_check(str(lying_target.get("target",""))=="toss_fish:goose","lying goose remains an accurate clickable fish recipient")
	world._fish_carry_type=""
	var lying_photo:=PhotoMoment.capture(world,{"id":"llama_overcast_goose_annoyed"})
	var goose_in_photo:=false
	for item: Dictionary in lying_photo.get("items",[]):
		if str(item.get("subject",""))=="goose" and str(item.get("kind",""))=="sprite":
			goose_in_photo=str(item.texture.get("path", "")).ends_with("/goose_rest.png")
	_check(goose_in_photo,"album captures the actual lying goose rather than an obsolete spread-wing image")
	TuningStore.set_value("ui.reduced_motion",true)
	goose.tick(1.0/60.0,WORLD_SIZE)
	_check(goose._sprite.texture.resource_path.ends_with("/goose_rest.png") and goose.position.distance_to(goose_at)<0.001,"reduced motion preserves a still, legible resting goose")
	TuningStore.set_value("ui.reduced_motion",false)
	goose.state="wander"
	goose._target=goose.position+Vector2(16,0)
	goose.tick(1.0/60.0,WORLD_SIZE)
	_check(goose._sprite.texture.resource_path.ends_with("/goose.png"),"walking goose retains original expressive wing artwork")
	world.debug_place_player(Vector2(570,480))
	world.debug_place_actor("llama",Vector2(600,480))
	world.debug_place_actor("cow",Vector2(450,490))
	world.debug_place_actor("horse",Vector2(690,480))
	var llama:=world.actor_named("llama")
	var canonical:=llama._sprite.texture
	var origin:=llama._sprite.offset
	for expression: String in ["idle","happy","annoyed","smirk"]:
		llama.set_expression(expression)
		_check(llama._sprite.texture==canonical and llama._sprite.offset==origin,"llama body and feet remain canonical for "+expression)
		_check(bool(llama._gait._material.get_shader_parameter("face_override")),"llama changes only the face region for "+expression)
	world.holiday_day=3
	var rule:=ExpressionCatalog.find_rule(legacy_id)
	_check(world._rule_matches(rule,world._world_snapshot()),"cow and horse sharing pasture enables llama teasing")
	world.actor_named("horse").current_zone="pond"
	_check(not world._rule_matches(rule,world._world_snapshot()),"cow alone cannot satisfy cow-horse teasing")
	world.actor_named("horse").current_zone="pasture"
	world.actor_named("cow").current_zone="pond"
	_check(not world._rule_matches(rule,world._world_snapshot()),"horse alone cannot satisfy cow-horse teasing")
	world.actor_named("cow").current_zone="pasture"
	world._apply_rule(rule,false)
	_check(world.actor_named("llama").current_expression=="smirk","teasing displays smirk artwork")
	world.actor_named("llama")._hold_expression=1.0
	world._apply_rule(rule,false)
	_check(is_equal_approx(world.actor_named("llama")._hold_expression,1.0),"teasing cooldown prevents repeated refresh spam")
	world._cooldowns[legacy_id]=0.0
	world._apply_rule(rule,false)
	_check(world.collected.count(legacy_id)==1 and world.actor_named("llama")._hold_expression>1.0,"teasing may recur without duplicating the saved photo")
	_check(int(rule.priority)<int(ExpressionCatalog.find_rule("llama_fed_gentle").priority),"feeding feedback has priority over ambient teasing")
	var inside:=true
	for frame: int in 60*20:
		horse.tick(1.0/60,WORLD_SIZE)
		inside=inside and horse._stands_on(horse.position)
	_check(inside,"horse wandering remains on grass and outside pond")
	world._pose_cast()
	_check(horse.posed and horse.pose_point==world._cast_layout().horse.position,"horse is included in photo layout")
	_check(goose.posed and goose._sprite.texture.resource_path.ends_with("/goose.png")
		and (goose._ground_anchor-goose._sprite.texture.get_size()*0.5+goose._sprite.offset).length()<0.001,
		"staged photo lineup gives goose its grounded original standing painting")
	world.free()
