extends SceneTree
var failures:Array=[]
var checks:=0
func _initialize():
 for device in [0,16]:
  for code in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
   for physical in [false,true]:
    var e:=InputEventKey.new()
    e.device=device;e.keycode=code;e.physical_keycode=code if physical else 0;e.pressed=true
    checks+=1
    if not e.is_action_pressed("ui_accept"):
     failures.append("device%s key%s physical%s"%[device,code,physical])
 print("[portable-accept-tests] ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
