class_name PaintedWalker
extends Node2D

# Approved painted traveler. All art is rigidly attached to actual Bone2D nodes;
# atlas pixels are sampled unchanged, with uniform scaling only.
const UPPER := preload("res://assets/holiday/characters/approved_traveler_upper_v1.png")
const PANTS := preload("res://assets/holiday/characters/approved_traveler_pants_v1.png")
const PANTS_SCALE := 0.043
var pants_scale:=PANTS_SCALE
var skeleton: Skeleton2D
var pelvis: Bone2D
var torso: Bone2D
var thighs: Array[Bone2D]=[]
var shins: Array[Bone2D]=[]
var feet: Array[Bone2D]=[]
var rest_angles: Array[Vector2]=[]
var sprites: Array[Sprite2D]=[]
var phase:=0.30
var walk_weight:=0.0
var rest_feet: Array[Vector2]=[]
var stance: Array[bool]=[true,true]
var _last_facing:=1.0
const STRIDE:=52.0
const DUTY:=0.60
const REST_PELVIS:=Vector2(0,-47.8)

func _ready() -> void:
	skeleton=Skeleton2D.new()
	add_child(skeleton)
	pelvis=_bone(skeleton,"Pelvis",Vector2(0,-47.8),1.0)
	torso=_bone(pelvis,"PaintedUpperBody",Vector2.ZERO,45.0)
	torso.z_index=4
	_body_art(torso)
	var upper_rects=[Rect2(248,68,321,537),Rect2(757,75,241,528)]
	var lower_rects=[Rect2(267,659,291,516),Rect2(721,655,294,524)]
	var hips=[Vector2(425,128),Vector2(883,140)]
	var knees=[Vector2(418,560),Vector2(878,558)]
	var lower_knees=[Vector2(422,699),Vector2(855,697)]
	var ankles=[Vector2(402,1140),Vector2(867,1140)]
	for side: int in 2:
		var upper_axis: Vector2=(knees[side]-hips[side])*pants_scale
		var lower_axis: Vector2=(ankles[side]-lower_knees[side])*pants_scale
		var thigh=_bone(pelvis,"RearThigh" if side==0 else "FrontThigh",Vector2(-3.84,-0.128) if side==0 else Vector2(3.84,0.192),upper_axis.length())
		thigh.z_index=-2 if side==0 else 1
		var shin=_bone(thigh,"Shin",Vector2(0,upper_axis.length()),lower_axis.length())
		var foot=_bone(shin,"Boot",Vector2(0,lower_axis.length()),8.0)
		var upper_angle:=upper_axis.angle()-PI*0.5
		var lower_angle:=lower_axis.angle()-PI*0.5
		var upper_sprite=_part(thigh,PANTS,upper_rects[side],hips[side],pants_scale)
		upper_sprite.rotation=-upper_angle
		var lower_sprite=_part(shin,PANTS,lower_rects[side],lower_knees[side],pants_scale)
		lower_sprite.rotation=-lower_angle
		# Local sprite origins rotate with the corrective art-axis transform.
		upper_sprite.position=upper_sprite.position.rotated(-upper_angle)
		lower_sprite.position=lower_sprite.position.rotated(-lower_angle)
		var rest_tilt:=0.20 if side==0 else -0.055
		thigh.rotation=rest_tilt
		shin.rotation=0.0
		foot.rotation=-rest_tilt
		var fade:=Shader.new()
		fade.code="shader_type canvas_item; uniform float end_y; void fragment(){vec4 c=texture(TEXTURE,UV); c.a*=1.0-smoothstep(end_y-0.060,end_y,UV.y); COLOR=c;}"
		var material:=ShaderMaterial.new()
		material.shader=fade
		material.set_shader_parameter("end_y",605.0/1254.0 if side==0 else 603.0/1254.0)
		upper_sprite.material=material
		_boot_art(foot,side)
		thighs.append(thigh)
		shins.append(shin)
		feet.append(foot)
		rest_angles.append(Vector2(rest_tilt,rest_tilt))
		rest_feet.append(to_local(foot.global_position))

func _bone(parent: Node2D,label: String,point: Vector2,length: float) -> Bone2D:
	var node:=Bone2D.new()
	node.name=label
	node.position=point
	node.set_autocalculate_length_and_angle(false)
	node.length=length
	node.bone_angle=PI*0.5
	parent.add_child(node)
	node.rest=node.transform
	return node

func _part(parent: Bone2D,texture: Texture2D,rect: Rect2,pivot: Vector2,size: float) -> Sprite2D:
	var sprite:=Sprite2D.new()
	var atlas:=AtlasTexture.new()
	atlas.atlas=texture
	atlas.region=rect
	atlas.filter_clip=true
	sprite.texture=atlas
	sprite.centered=false
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position=-(pivot-rect.position)*size
	sprite.scale=Vector2.ONE*size
	parent.add_child(sprite)
	sprites.append(sprite)
	return sprite

func _body_art(parent: Bone2D) -> void:
	# A contour excludes the two boots sharing this sheet, without touching the
	# original raster or cropping the backpack's hanging strap.
	var points:=PackedVector2Array([Vector2(444,4),Vector2(1034,4),Vector2(1034,750),Vector2(930,750),Vector2(930,799),Vector2(500,799),Vector2(500,750),Vector2(444,750)])
	var shape:=Polygon2D.new()
	shape.texture=UPPER
	shape.uv=points
	var geometry:=PackedVector2Array()
	for point in points:
		geometry.append((point-Vector2(808,712))*0.064)
	shape.polygon=geometry
	shape.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(shape)

func animate(delta: float,moved: Vector2,depth: float,reduced: bool) -> void:
	if pelvis==null:
		return
	var facing:=signf(scale.x)
	if facing!=_last_facing:
		# Settle the silhouette briefly at the facing swap, without squeezing it.
		walk_weight=minf(walk_weight,0.25)
		_last_facing=facing
	var moving:=moved.length()/maxf(delta*depth,0.0001)>2.0 and not reduced
	walk_weight=move_toward(walk_weight,1.0 if moving else 0.0,delta*(5.0 if moving else 4.5))
	if moving:
		phase=fmod(phase+moved.length()/maxf(STRIDE*depth,0.001),1.0)
	elif walk_weight>0.0:
		phase=fmod(phase+delta*1.1,1.0)
	var targets: Array[Vector2]=[]
	var drop:=0.0
	for side: int in 2:
		var cycle:=fmod(phase+float(side)*0.5,1.0)
		stance[side]=cycle<DUTY or walk_weight<0.01
		var x:=0.0
		var lift:=0.0
		if cycle<DUTY:
			x=lerpf(13.0,-13.0,cycle/DUTY)
		else:
			var u:=(cycle-DUTY)/(1.0-DUTY)
			x=lerpf(-13.0,13.0,smoothstep(0.0,1.0,u))
			lift=sin(PI*u)*5.0
		var target:=Vector2(thighs[side].position.x+x,rest_feet[side].y-lift)
		target=rest_feet[side].lerp(target,walk_weight)
		targets.append(target)
		if stance[side]:
			var hip:=REST_PELVIS+thighs[side].position
			var length: float=thighs[side].length+shins[side].length-0.05
			var vertical:=sqrt(maxf(1.0,length*length-pow(target.x-hip.x,2)))
			drop=maxf(drop,target.y-hip.y-vertical)
	pelvis.position=REST_PELVIS+Vector2(0,minf(drop,2.8)*walk_weight)
	# Keep face, camera, sweater and pack together; never bend or spin the core.
	torso.rotation=0.0
	for side: int in 2:
		if walk_weight<=0.00001:
			thighs[side].rotation=rest_angles[side].x
			shins[side].rotation=0.0
			feet[side].rotation=-rest_angles[side].y
			continue
		var hip:=pelvis.position+thighs[side].position
		var reach:=targets[side]-hip
		var a: float=thighs[side].length
		var b: float=shins[side].length
		var distance:=clampf(reach.length(),0.1,a+b-0.005)
		var bend:=acos(clampf((a*a+distance*distance-b*b)/(2.0*a*distance),-1.0,1.0))
		var knee:=hip+reach.normalized().rotated(-bend)*a
		var upper_angle:=(knee-hip).angle()-PI*0.5
		var lower_angle:=(targets[side]-knee).angle()-PI*0.5
		thighs[side].rotation=lerp_angle(rest_angles[side].x,upper_angle,walk_weight)
		shins[side].rotation=lerp_angle(0.0,lower_angle-upper_angle,walk_weight)
		feet[side].rotation=-thighs[side].rotation-shins[side].rotation

func reset_motion() -> void:
	walk_weight=0.0
	phase=0.30
	animate(0.0,Vector2.ZERO,1.0,true)

func _boot_art(foot: Bone2D,side: int) -> void:
	if side==0:
		_part(foot,UPPER,Rect2(300,751,170,234),Vector2(409,790),0.056)
	else:
		_part(foot,UPPER,Rect2(937,775,314,212),Vector2(1012,814),0.064)
