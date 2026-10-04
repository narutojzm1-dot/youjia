extends Node
var main
var callback: JavaScriptObject
func _ready():
 main=load('res://scenes/main.tscn').instantiate()
 add_child(main)
 await get_tree().process_frame
 await get_tree().process_frame
 main._start_holiday()
 main._process(0.0)
 main.set_process(false)
 callback=JavaScriptBridge.create_callback(_step)
 JavaScriptBridge.get_interface('window').boundaryStep=callback
 JavaScriptBridge.eval('window.boundaryReady=true')
func _step(args:Array):
 var mode=str(args[0]);var phase=str(args[1])
 get_node('/root/TuningStore').set_value('ui.reduced_motion',mode=='reduced',false)
 var world=main._world
 world.request_pointer_action(Vector2(865,478))
 if phase=='late':world.tick(1.0,Vector2.ZERO)
 if phase=='expired':world.tick(1.3,Vector2.ZERO)
 world.queue_redraw()
 var point=main.get_viewport().get_canvas_transform()*Vector2(865,478)
 JavaScriptBridge.eval('window.boundaryState='+JSON.stringify({'x':point.x,'y':point.y,'remaining':world._rejected_seconds,'mode':mode,'phase':phase}))
