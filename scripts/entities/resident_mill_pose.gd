extends ResidentWalker
## Live rigid painted layers, with planted shoes and two hands on the real grip.
## Every Sprite2D uses the original approved texture/region, so photographs need
## neither a new texture identifier nor an extra snapshot primitive.

func _ready() -> void:
	super._ready()
	# PhotoMoment already freezes sprite transforms/colors, not arbitrary shaders.
	# Keep both live and frozen trouser overlaps on that same existing contract.
	for sprite: Sprite2D in sprites:
		sprite.material = null

func apply_contact(target: Vector2, amount: float, stroke: float) -> void:
	reset_motion()
	var grip := clampf(amount,0.0,1.0)
	var pressure := clampf(stroke,0.0,1.0)*grip
	pelvis.position = PaintedWalker.REST_PELVIS + Vector2(4.0*grip+2.0*pressure,3.0*grip)
	torso.rotation = 0.08*grip+0.04*pressure
	for side: int in 2:
		var hip := pelvis.position + thighs[side].position
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
		_arm(side,resting.lerp(target+Vector2(-2.0,-1.0) if side == 0 else target,grip))

func _arm(side: int, palm: Vector2) -> void:
	var shoulder: Bone2D = shoulders[side]
	var elbow: Bone2D = elbows[side]
	var hand := Vector2(1.7 if side == 1 else -1.7,11)
	var target: Vector2 = shoulder.get_parent().to_local(to_global(palm))
	var reach: Vector2 = target-shoulder.position
	var a := elbow.position.length()
	var b := hand.length()
	var distance := clampf(reach.length(),0.1,a+b-0.005)
	var bend := acos(clampf((a*a+distance*distance-b*b)/(2*a*distance),-1.0,1.0))
	var joint: Vector2 = shoulder.position+reach.normalized().rotated(-bend)*a
	shoulder.rotation = (joint-shoulder.position).angle()-elbow.position.angle()
	elbow.rotation = (target-joint).angle()-hand.angle()-shoulder.rotation
