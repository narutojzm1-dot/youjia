extends "res://scripts/entities/resident_mill_pose.gd"
## A grounded squat using the approved rigid painted parts. The rear hand
## holds the seed packet while the front hand sows, then both cover the soil.
## No new texture or photograph primitive is needed.

func apply_garden_contact(target: Vector2, amount: float, progress: float) -> void:
	reset_motion()
	var crouch := clampf(amount,0.0,1.0)
	var phase := clampf(progress,0.0,1.0)
	var sweep := sin(phase*TAU*3.0)
	pelvis.position = PaintedWalker.REST_PELVIS + Vector2(4.0,29.0)*crouch
	torso.rotation = 0.36*crouch
	for side: int in 2:
		var hip := pelvis.position+thighs[side].position
		var reach := rest_feet[side]-hip
		var a: float = thighs[side].length
		var b: float = shins[side].length
		var distance := clampf(reach.length(),0.1,a+b)
		var bend := acos(clampf((a*a+distance*distance-b*b)/(2*a*distance),-1.0,1.0))
		var knee := hip+reach.normalized().rotated(-bend)*a
		var upper := (knee-hip).angle()-PI*0.5
		var lower := (rest_feet[side]-knee).angle()-PI*0.5
		thighs[side].rotation = upper
		shins[side].rotation = lower-upper
		feet[side].rotation = -lower
		var palm := Vector2(1.7 if side == 1 else -1.7,11)
		var resting := to_local(elbows[side].to_global(palm))
		var covering := smoothstep(0.42,0.56,phase)
		var sow := target+Vector2(-7,-15) if side == 0 else target+Vector2(5*sweep,-4-2*absf(sweep))
		var cover := target+Vector2((-4 if side == 0 else 5)+4*sweep,0)
		_arm(side,resting.lerp(sow.lerp(cover,covering),crouch))
