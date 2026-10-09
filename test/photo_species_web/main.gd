extends Node
func _ready():
 var store=get_node('/root/SaveStore');store._data=store._default_data()
 var main=load('res://scenes/main.tscn').instantiate();add_child(main)
 await get_tree().process_frame
 await get_tree().process_frame
 main.set_process(false);await main._start_holiday()
 var w=main._world;w.set_process(false)
 w.actor_named('sheep_a').position=Vector2(230,420)
 w.actor_named('sheep_b').position=Vector2(340,450)
 var photo=PhotoMoment.capture(w,ExpressionCatalog.find_rule('sheep_pet_gentle'))
 main.hide()
 var layer=CanvasLayer.new();add_child(layer)
 var control=Control.new();control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(control)
 var row=HBoxContainer.new();row.position=Vector2(10,80);control.add_child(row)
 for before in [true,false]:
  var moment=photo.duplicate(true)
  if before:moment.focus=[630,470];moment.span=220
  var card=PhotoMoment.new();card.custom_minimum_size=Vector2(280,280);card.setup(moment);row.add_child(card)
 var label=Label.new();label.text='Controlled production snapshot: old fallback (left), species frame (right)';label.position=Vector2(10,15);control.add_child(label)
 JavaScriptBridge.eval('window.speciesReady='+JSON.stringify({'controlled':true,'focus':photo.focus,'span':photo.span})+';',true)
