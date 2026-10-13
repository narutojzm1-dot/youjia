extends SceneTree
const ROOT := "res://art/concepts/lead_flower642_20261010/"
func tex(path: String) -> ImageTexture:
	return ImageTexture.create_from_image(Image.load_from_file(path))
func sprite(parent: Node, texture: Texture2D, at: Vector2, size: Vector2) -> Sprite2D:
	var node := Sprite2D.new()
	node.centered = false
	node.texture = texture
	node.position = at
	node.scale = size / Vector2(texture.get_size())
	parent.add_child(node)
	return node
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var sun := tex("res://assets/holiday/environment/yard_sunny.png")
	var over := tex("res://assets/holiday/environment/yard_overcast_aligned.png")
	var atlas := tex(ROOT+"yard_flower_groups_v1.png")
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec2 dimensions;
uniform float weather;
uniform sampler2D sunny;
uniform sampler2D cloudy;
uniform vec4 crop;
uniform int area;
float ellipse(vec2 p, vec2 center, vec2 radius){return 1.0-smoothstep(.92,1.05,length((p-center)/radius));}
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 vec2 p=UV*dimensions;
 vec2 edge=min(UV,vec2(1.0)-UV)*dimensions;
 float a=smoothstep(0.0,3.0,min(edge.x,edge.y));
 float shape=1.0;
 if(area==0){
  shape=max(ellipse(p,vec2(105,95),vec2(122,75)),max(ellipse(p,vec2(65,190),vec2(88,110)),ellipse(p,vec2(205,210),vec2(68,70))));
  float rocks=max(ellipse(p,vec2(87,301),vec2(44,40)),max(ellipse(p,vec2(166,266),vec2(27,48)),ellipse(p,vec2(236,204),vec2(25,43))));
  shape*=1.0-rocks;
 }else if(area==1){shape=ellipse(p,vec2(60,32),vec2(64,48));}
 else{shape=ellipse(p,vec2(85,53),vec2(105,73))*(1.0-ellipse(p,vec2(67,126),vec2(46,45)));}
 COLOR=vec4(c.rgb,a*shape);
}
"""
	for index in 4:
		var holder := Node2D.new()
		holder.position=Vector2((index%2)*960,(index/2)*540)
		holder.scale=Vector2(.5,.5)
		root.add_child(holder)
		sprite(holder,over if index==3 else sun,Vector2.ZERO,Vector2(1920,1080))
		if index==0: continue
		for entry in [["left",Rect2(0,590,270,340)],["door",Rect2(250,590,120,115)],["pond",Rect2(550,795,190,150)]]:
			var rect: Rect2=entry[1]
			var node := sprite(holder,tex(ROOT+entry[0]+("_clear_patch_overcast_v1.png" if index==3 else "_clear_patch_v1.png")),rect.position,rect.size)
			var mat := ShaderMaterial.new()
			mat.shader=shader
			mat.set_shader_parameter("dimensions",rect.size)
			mat.set_shader_parameter("area",["left","door","pond"].find(entry[0]))
			mat.set_shader_parameter("crop",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
			mat.set_shader_parameter("sunny",sun)
			mat.set_shader_parameter("cloudy",over)
			mat.set_shader_parameter("weather",0.0)
			node.material=mat
		if index==2:
			for entry in [[Rect2(0,0,750,768),Vector2(0,600),Vector2(245,250)],[Rect2(750,0,650,768),Vector2(275,575),Vector2(90,90)],[Rect2(1400,0,648,768),Vector2(615,780),Vector2(105,130)]]:
				var part:=AtlasTexture.new()
				part.atlas=atlas
				part.region=entry[0]
				sprite(holder,part,entry[1],entry[2])
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(OS.get_environment("TEMP").path_join("youjia-flower642-contact.jpg"),.95)
	print("FLOWER642_PREVIEW_CAPTURED")
	quit()
