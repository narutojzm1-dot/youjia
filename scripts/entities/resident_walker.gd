class_name ResidentWalker
extends PaintedWalker

# Approved relaxed resident outfit. Reuses the tested rigid leg structure;
# new painted core, independent resting arms, and canvas shoes replace gear.
const RESIDENT := preload("res://assets/holiday/characters/approved_resident_upper_v1.png")
var shoulders: Array[Bone2D]=[]
var elbows: Array[Bone2D]=[]
var upper_arm_sprites: Array[Sprite2D]=[]
var forearm_sprites: Array[Sprite2D]=[]

func _ready() -> void:
	# Longer continuous trouser legs occupy the former boot/sock space.
	pants_scale=0.049
	super._ready()

func _body_art(parent: Bone2D) -> void:
	_part(parent,RESIDENT,Rect2(556,1,412,844),Vector2(780,771),0.060)
	var attachments: Array[Vector2]=[Vector2(605,403),Vector2(893,399)]
	var pivots: Array[Vector2]=[Vector2(385,226),Vector2(1140,226)]
	var upper_regions: Array[Rect2]=[Rect2(245,178,191,391),Rect2(1088,174,207,415)]
	var lower_regions: Array[Rect2]=[Rect2(245,530,191,313),Rect2(1088,548,207,299)]
	var elbow_pivots: Array[Vector2]=[Vector2(324,542),Vector2(1217,561)]
	for side: int in 2:
		var joint: Vector2=(elbow_pivots[side]-pivots[side])*0.052
		var shoulder:=_bone(parent,"RearShoulder" if side==0 else "FrontShoulder",(attachments[side]-Vector2(780,771))*0.060,joint.length())
		shoulder.z_index=-1 if side==0 else 1
		var upper:=_part(shoulder,RESIDENT,upper_regions[side],pivots[side],0.052)
		var elbow:=_bone(shoulder,"Elbow",joint,14.0)
		# The rolled sleeve covers the elbow overlap. Forearm and hand stay
		# rigid; no texture stretching or skin mesh deformation is involved.
		elbow.z_index=-1
		var forearm:=_part(elbow,RESIDENT,lower_regions[side],elbow_pivots[side],0.052)
		shoulders.append(shoulder)
		elbows.append(elbow)
		upper_arm_sprites.append(upper)
		forearm_sprites.append(forearm)

func _boot_art(foot: Bone2D,side: int) -> void:
	if side==0:
		_part(foot,RESIDENT,Rect2(426,846,166,161),Vector2(524,874),0.048)
	else:
		_part(foot,RESIDENT,Rect2(874,871,314,135),Vector2(958,884),0.050)

func animate(delta: float,moved: Vector2,depth: float,reduced: bool) -> void:
	super.animate(delta,moved,depth,reduced)
	# Relaxed shoulders lead. Elbows/forearms respond more slowly instead of
	# shoulder-to-fingertip movement being a single metronomic rigid pendulum.
	var shoulder_response:=1.0-exp(-delta*9.0)
	var forearm_response:=1.0-exp(-delta*6.0)
	for side: int in shoulders.size():
		var cycle:=phase*TAU+float(side)*PI
		var wave:=cos(cycle)+0.12*sin(cycle*2.0)
		var shoulder_target:=wave*(0.047 if side==0 else 0.065)*walk_weight
		var trailing:=cos(cycle-0.48)
		# Small forward elbow flex, then a relaxed trailing release. The far
		# arm stays subdued and behind the torso, rather than both flapping out.
		var elbow_target:=-(0.025+0.09*maxf(trailing,0.0))*walk_weight
		shoulders[side].rotation=lerp_angle(shoulders[side].rotation,shoulder_target,shoulder_response)
		elbows[side].rotation=lerp_angle(elbows[side].rotation,elbow_target,forearm_response)
		if walk_weight==0.0 and absf(shoulders[side].rotation)<0.0001:
			shoulders[side].rotation=0.0
		if walk_weight==0.0 and absf(elbows[side].rotation)<0.0001:
			elbows[side].rotation=0.0

func reset_motion() -> void:
	super.reset_motion()
	for side: int in shoulders.size():
		shoulders[side].rotation=0.0
		elbows[side].rotation=0.0
