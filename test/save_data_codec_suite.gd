extends SceneTree
const Codec = preload("res://scripts/persistence/save_data_codec.gd")
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func run() -> void:
	var key := "goose_llama_shared_space_after_player_lead"
	var source := {"version":5, "locale":"en", "holiday_day":17, "holiday_day_elapsed":42.5,
		"plant_state":2, "plant_day_planted":15, "plant_watered_day":16,
		"first_fish_caught":true, "tutorial_version":1,
		"album":["legacy-unknown", "legacy-unknown", ""],
		"photo_moments":{}, "animal_relationship_memory":{key:true, "future":7},
		"future_extension":{"keep":[1,2,3]}}
	var before := source.duplicate(true)
	var data := Codec.project(source)
	check(data.holiday_day==17 and data.holiday_day_elapsed==42.5, "holiday progress survives projection")
	check(data.plant_state==2 and data.plant_day_planted==15 and data.plant_watered_day==16, "plant history survives projection")
	check(data.first_fish_caught and data.locale=="en" and data.tutorial_version==1, "existing completion and locale survive")
	check(data.album==["legacy-unknown"], "unknown historical album IDs remain while duplicates collapse")
	check(data.animal_relationship_memory=={key:true}, "existing relationship memory survives")
	check(source==before, "projection never mutates source, including unknown extensions")
	data.album.append("new")
	data.animal_relationship_memory[key]=false
	check(source==before, "projected mutable fields cannot mutate preserved source")
	var first := Codec.defaults()
	first.album.append("new")
	first.photo_moments["new"]={}
	check(Codec.defaults().album.is_empty() and Codec.defaults().photo_moments.is_empty(), "fresh worlds never share containers")
	var bounded := Codec.project({"holiday_day":-2, "holiday_day_elapsed":-5, "plant_state":99, "plant_day_planted":-1, "locale":"xx", "album":"not-array"})
	check(bounded.holiday_day==1 and bounded.holiday_day_elapsed==0 and bounded.plant_state==3 and bounded.plant_day_planted==0, "existing bounds unchanged")
	check(bounded.locale=="zh-CN" and bounded.album.is_empty(), "legacy defaults remain compatible")
	check(Codec.project({})==Codec.defaults(), "missing legacy fields retain defaults")
	check(Codec.clean_moments({"orphan":{"rule_id":"orphan"}},[]).is_empty(), "orphan snapshot cannot enter projected album")
	# A real production snapshot exercises nested photo containers, not a fake stub.
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	var photo_id := "llama_fed_gentle"
	var photo: Dictionary = PhotoMoment.capture(world, ExpressionCatalog.find_rule(photo_id))
	check(not photo.is_empty(), "production capture supplies a valid snapshot fixture")
	var photo_source := {"album":[photo_id], "photo_moments":{photo_id:photo}}
	var photo_before := photo_source.duplicate(true)
	var projected := Codec.project(photo_source)
	check(projected.photo_moments.has(photo_id), "valid captured photo survives business projection")
	if projected.photo_moments.has(photo_id):
		projected.photo_moments[photo_id].background.transform[0]=123.0
		projected.photo_moments[photo_id].items[0].transform[0]=123.0
		check(photo_source==photo_before, "nested projected photo transforms do not alias original snapshot")
	world.free()
	var store := root.get_node("SaveStore")
	check(store._default_data()==Codec.defaults(), "production SaveStore delegates defaults")
	print("SAVE_DATA_CODEC ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
