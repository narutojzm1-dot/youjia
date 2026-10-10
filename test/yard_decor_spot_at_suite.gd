extends SceneTree
const Decor := preload("res://scripts/inventory/yard_decor.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func run() -> void:
	var decor := Decor.empty()
	decor.places["pond_path"] = {"find_id": "pine_cone", "dx": 0, "dy": 0}
	var at: Vector2 = Decor.position_for("pond_path", decor.places.pond_path)
	check(Decor.spot_at(decor, at) == "pond_path", "centre hits the placed pine cone")
	check(Decor.spot_at(decor, at + Vector2(40, 0)).is_empty(), "a miss does not recall a neighbour")
	check(Decor.spot_at(decor, Vector2(NAN, 0)).is_empty(), "non-finite point is not a hit")
	decor.places.erase("pond_path")
	check(Decor.spot_at(decor, at).is_empty(), "removed placement is no longer pickable")
	print("YARD_DECOR_SPOT_AT checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
