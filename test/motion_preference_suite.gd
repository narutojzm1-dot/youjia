extends SceneTree
var checks := 0
var failures: Array[String] = []
func check(ok: bool, why: String):
	checks += 1
	if not ok: failures.append(why); push_error(why)
func _initialize(): call_deferred("run")
func run():
	var store = root.get_node("TuningStore")
	var adapter = root.get_node("MotionPreference")
	store.set_value("ui.reduced_motion",false,false)
	for bad in [[],[1],["true"],[true,false],[null]]:
		adapter._receive(bad)
		check(not store.get_value("ui.reduced_motion"),"invalid wire value ignored: "+str(bad))
	adapter._receive([true])
	check(store.get_value("ui.reduced_motion"),"strict bool reaches LIVE store")
	adapter._receive([false])
	check(not store.get_value("ui.reduced_motion"),"normal returns without persistence")
	check(adapter._binding==null,"native fallback creates no JS binding")
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world);world.setup()
	var snapshot := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(not snapshot.is_empty(),"real yard capture for actual presentation")
	var original := snapshot.duplicate(true)
	var arrival = load("res://scripts/ui/photo_arrival.gd").new()
	root.add_child(arrival)
	var completions := [0]
	arrival.tucked_away.connect(func(): completions[0]+=1)
	check(arrival.play(snapshot,false),"normal presentation starts")
	await create_timer(0.25).timeout
	var before: float = arrival._tween.get_total_elapsed_time()
	var started := Time.get_ticks_msec()
	store.set_value("ui.reduced_motion",true,false)
	check(arrival.visible and arrival._card.modulate.a==1 and arrival._motion_static,"live preference makes current card fully static")
	var saved: Dictionary = arrival._snapshot.duplicate(true)
	store.set_value("ui.reduced_motion",false,false)
	await create_timer(0.10).timeout
	check(arrival._card.modulate.a==1 and arrival._motion_static,"reduce off never restarts fade")
	store.set_value("ui.reduced_motion",true,false)
	check(arrival._snapshot==saved and snapshot==original,"toggle preserves frozen photo and caller data")
	await arrival.tucked_away
	await process_frame
	var remaining := float(Time.get_ticks_msec()-started)/1000.0
	check(absf(remaining-(1.58-before))<0.18,"deadline retained instead of new full duration")
	check(completions[0]==1 and not arrival.visible,"finishes once")
	check(arrival.play(snapshot,true),"initial reduced presentation starts")
	store.set_value("ui.reduced_motion",false,false)
	check(arrival._card.modulate.a==1 and arrival._motion_static,"initial reduced never fades when preference turns off")
	arrival.dismiss()
	store.set_value("ui.reduced_motion",true,false)
	check(not arrival.visible and arrival._snapshot.is_empty(),"dismissed photo never resurrects")
	arrival.free();world.free()
	store.set_value("ui.reduced_motion",false,false)
	print("MOTION PREFERENCE NATIVE ","PASS" if failures.is_empty() else "FAIL"," ",checks)
	quit(0 if failures.is_empty() else 1)
