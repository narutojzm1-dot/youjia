class_name NativeWalker
extends Node2D

# A clean native 2D puppet. Every visible segment is rigid geometry parented to
# a real Bone2D; no photographed cutout, image warp, atlas, or limb stretching.
const THIGH := 21.0
const SHIN := 21.0
const STRIDE := 60.0
const DUTY := 0.60
const INK := Color("334953")
const TROUSERS := Color("397d82")
const JACKET := Color("e5b858")
const SKIN := Color("edb994")
var skeleton: Skeleton2D
var pelvis: Bone2D
var spine: Bone2D
var head: Bone2D
var thighs: Array[Bone2D] = []
var shins: Array[Bone2D] = []
var feet: Array[Bone2D] = []
var upper_arms: Array[Bone2D] = []
var forearms: Array[Bone2D] = []
var phase := 0.0
var walk_weight := 0.0
var foot_targets: Array[Vector2] = [Vector2(-3,-3),Vector2(3,-3)]
var stance: Array[bool] = [true,true]
var _idle_time := 0.0

func _ready() -> void:
	_build()
	animate(0.0,Vector2.ZERO,1.0,false)

func _bone(parent: Node2D, label: String, point: Vector2, length: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.name=label
	bone.position=point
	bone.set_autocalculate_length_and_angle(false)
	bone.length=length
	bone.bone_angle=PI*0.5
	parent.add_child(bone)
	bone.rest=bone.transform
	return bone

func _build() -> void:
	skeleton=Skeleton2D.new()
	skeleton.name="Skeleton2D"
	add_child(skeleton)
	pelvis=_bone(skeleton,"Pelvis",Vector2(0,-43),28)
	spine=_bone(pelvis,"Spine",Vector2.ZERO,28)
	# Rear limbs first, front limbs last. Geometry overlaps at round joints.
	for side: int in 2:
		var back := side==0
		var hip := Vector2(-2 if back else 2,0)
		var thigh := _bone(pelvis,"RearThigh" if back else "FrontThigh",hip,THIGH)
		var shin := _bone(thigh,"Shin",Vector2(0,THIGH),SHIN)
		var foot := _bone(shin,"Foot",Vector2(0,SHIN),10)
		thigh.z_index=-2 if back else 2
		var trouser := TROUSERS.darkened(0.18) if back else TROUSERS
		_capsule(thigh,THIGH,3.8,trouser)
		_capsule(shin,SHIN,3.3,trouser)
		_polygon(foot,[Vector2(-4,-2),Vector2(3,-2),Vector2(10,1),Vector2(10,4),Vector2(-4,4)],INK)
		thighs.append(thigh)
		shins.append(shin)
		feet.append(foot)
		var shoulder:=_bone(spine,"RearShoulder" if back else "FrontShoulder",Vector2(-6 if back else 6,-27),14)
		var elbow:=_bone(shoulder,"Elbow",Vector2(0,14),12)
		shoulder.z_index=-3 if back else 3
		_capsule(shoulder,14,3.5,JACKET.darkened(0.14) if back else JACKET)
		_capsule(elbow,12,2.8,JACKET.darkened(0.10) if back else JACKET)
		_circle(elbow,Vector2(0,12),3.1,SKIN)
		upper_arms.append(shoulder)
		forearms.append(elbow)
	_polygon(spine,[Vector2(-8,-28),Vector2(6,-29),Vector2(10,-20),Vector2(8,1),Vector2(-8,1),Vector2(-10,-19)],JACKET)
	_polygon(spine,[Vector2(-10,-23),Vector2(-14,-21),Vector2(-15,-5),Vector2(-10,-2)],Color("49766e"))
	_polygon(spine,[Vector2(-7,-1),Vector2(8,-1),Vector2(7,4),Vector2(-7,4)],TROUSERS)
	_line(spine,[Vector2(4,-23),Vector2(4,-4)],Color("bf923f"),1.0)
	head=_bone(spine,"Head",Vector2(1,-39),15)
	_circle(head,Vector2(-2,-1),12,Color("62483d"))
	_circle(head,Vector2(1,1),10.5,SKIN)
	_polygon(head,[Vector2(-9,-5),Vector2(-7,-12),Vector2(2,-14),Vector2(10,-8),Vector2(7,-5),Vector2(1,-9),Vector2(-4,-3)],Color("62483d"))
	_polygon(head,[Vector2(9,-1),Vector2(13,2),Vector2(9,4)],SKIN)
	_circle(head,Vector2(5,-1),1.35,INK)
	_circle(head,Vector2(-6,3),2.5,SKIN.lightened(0.10))
	_line(head,[Vector2(5,6),Vector2(8,6)],Color("a86550"),1.1)
	_polygon(spine,[Vector2(-6,-30),Vector2(7,-31),Vector2(9,-26),Vector2(-5,-25)],Color("d76c59"))

func animate(delta: float, moved: Vector2, depth: float, reduced: bool) -> void:
	if skeleton==null:
		return
	_idle_time+=delta
	var speed:=moved.length()/maxf(delta*depth,0.0001)
	var moving:=speed>2.0 and not reduced
	walk_weight=move_toward(walk_weight,1.0 if moving else 0.0,delta*(7.0 if moving else 5.0))
	if moving:
		phase=fmod(phase+moved.length()/maxf(depth*STRIDE,0.01),1.0)
	elif walk_weight>0.0:
		# A short authored settle, rather than freezing a raised toe on release.
		phase=fmod(phase+delta*1.4,1.0)
	var hip_height:=41.7
	for side: int in 2:
		var cycle:=fmod(phase+float(side)*0.5,1.0)
		var x:=0.0
		var y:=-3.0
		stance[side]=cycle<DUTY or walk_weight<0.1
		if cycle<DUTY:
			x=lerpf(18.0,-18.0,cycle/DUTY)
		else:
			var u:=(cycle-DUTY)/(1.0-DUTY)
			x=lerpf(-18.0,18.0,smoothstep(0.0,1.0,u))
			y-=sin(PI*u)*8.0
		foot_targets[side]=Vector2(lerpf(-3.0 if side==0 else 3.0,x,walk_weight),lerpf(-3.0,y,walk_weight))
		if stance[side]:
			# Rise over a straight support leg and lower only at step transfer.
			# This supplies a natural upright mid-stance, not a permanent crouch.
			var dx:=foot_targets[side].x-(-2.0 if side==0 else 2.0)
			hip_height=minf(hip_height,sqrt(maxf(1.0,41.7*41.7-dx*dx)))
	pelvis.position=Vector2(0,-3.0-lerpf(41.7,hip_height,walk_weight))
	spine.rotation=sin(phase*TAU)*0.018*walk_weight
	spine.position.y=sin(_idle_time*1.6)*0.18*(1.0-walk_weight) if not reduced else 0.0
	head.rotation=-spine.rotation*0.55
	for side: int in 2:
		var hip:=pelvis.position+thighs[side].position
		var reach:=foot_targets[side]-hip
		var distance:=minf(reach.length(),THIGH+SHIN-0.01)
		var bend:=acos(clampf((THIGH*THIGH+distance*distance-SHIN*SHIN)/(2.0*THIGH*maxf(distance,0.01)),-1.0,1.0))
		var knee:=hip+reach.normalized().rotated(-bend)*THIGH
		var thigh_angle:=(knee-hip).angle()-PI*0.5
		var shin_absolute:=(foot_targets[side]-knee).angle()-PI*0.5
		thighs[side].rotation=thigh_angle
		shins[side].rotation=shin_absolute-thigh_angle
		feet[side].rotation=-shin_absolute
		# Contralateral relaxed arms, with a soft elbow rather than pinwheel hands.
		var cycle:=phase*TAU+float(side)*PI
		upper_arms[side].rotation=-sin(cycle)*0.34*walk_weight+(-0.08 if side==0 else 0.08)
		forearms[side].rotation=-0.16-maxf(0.0,sin(cycle))*0.18*walk_weight

func _polygon(parent: Node2D, points: Array, color: Color) -> void:
	var shape:=Polygon2D.new()
	shape.polygon=PackedVector2Array(points)
	shape.color=color
	shape.antialiased=true
	parent.add_child(shape)

func _circle(parent: Node2D, center: Vector2, radius: float, color: Color) -> void:
	var points: Array=[]
	for i: int in 24:
		points.append(center+Vector2.from_angle(float(i)*TAU/24.0)*radius)
	_polygon(parent,points,color)

func _capsule(parent: Node2D, length: float, radius: float, color: Color) -> void:
	_polygon(parent,[Vector2(-radius,0),Vector2(radius,0),Vector2(radius,length),Vector2(-radius,length)],color)
	_circle(parent,Vector2.ZERO,radius,color)
	_circle(parent,Vector2(0,length),radius,color)

func _line(parent: Node2D, points: Array, color: Color, width: float) -> void:
	var line:=Line2D.new()
	line.points=PackedVector2Array(points)
	line.default_color=color
	line.width=width
	line.antialiased=true
	parent.add_child(line)
