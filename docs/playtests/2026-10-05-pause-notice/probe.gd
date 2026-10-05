extends SceneTree
var main
var events := []
func _initialize():
	call_deferred("run")
func snap(stage):
	var row = {"stage":stage,"pause":main._pause_screen.visible,"notice_visible":main._notice.visible,"notice_time":main._notice_time,"screen":main._screen}
	events.append(row)
	print(JSON.stringify(row))
func run():
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await root.get_node("SaveStore").flush_pending()
	main._start_holiday(false)
	await process_frame
	await process_frame
	main._show_notice_key("notice.new_day.a")
	snap("notice-before-pause")
	main._toggle_pause()
	snap("same-call-after-pause")
	await process_frame
	snap("next-frame-paused")
	main._show_notice_key("notice.new_day.a")
	snap("late-callback-while-paused")
	await process_frame
	snap("late-callback-next-frame")
	main._process(4.0)
	snap("controlled-four-second-pause")
	main._toggle_pause()
	await process_frame
	snap("resume-after-four-second-pause")
	main.queue_free()
	await process_frame
	quit()
