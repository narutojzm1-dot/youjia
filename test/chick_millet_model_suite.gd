extends SceneTree
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Residents := preload("res://scripts/game/world_residents.gd")
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func _initialize() -> void:
	var root_data := {"yard_inventory": {"schema": 2, "revision": 7, "fish": {"small": 2}, "grass": 3, "held": "", "ground": [{"id": 1, "kind": "grass", "x": 400.0, "y": 500.0}], "next_food_id": 2}, "keepsakes": {"old": 4}}
	var old := root_data.duplicate(true)
	var view := Inventory.read(root_data)
	check(view.schema == 3 and view.millet == 0 and view.fish.small == 2 and view.grass == 3 and view.ground.size() == 1, "schema2 migrates without losing any location")
	check(root_data == old, "migration view does not mutate source")
	var scoop := Inventory.transition(root_data, 7, "scoop", "millet")
	check(scoop.has("candidate") and scoop.candidate.yard_inventory.held == "millet", "one handful from grain tin")
	root_data = scoop.candidate
	check(Inventory.transition(root_data, 7, "scoop", "millet").get("error") == "BASKET_CHANGED", "replay cannot mint another handful")
	check(Inventory.transition(root_data, 8, "scoop", "millet").get("error") == "BASKET_HAND_OCCUPIED", "occupied hand cannot scoop")
	check(Inventory.transition(root_data, 8, "catch", "millet").get("error") == "BASKET_INVALID", "millet is not a fish catch")
	root_data = Inventory.transition(root_data, 8, "return", "millet").candidate
	check(root_data.yard_inventory.millet == 1 and root_data.yard_inventory.held == "", "handful stored once")
	root_data = Inventory.transition(root_data, 9, "withdraw", "millet").candidate
	check(root_data.yard_inventory.millet == 0 and root_data.yard_inventory.held == "millet", "basket to hand conserves grain")
	root_data = Inventory.transition(root_data, 10, "drop", "millet", {"x": 450.0, "y": 510.0}).candidate
	check(root_data.yard_inventory.held == "" and root_data.yard_inventory.ground.size() == 2, "drop creates one visible ground portion")
	root_data = Inventory.transition(root_data, 11, "pickup", "millet", {"id": 2}).candidate
	check(root_data.yard_inventory.held == "millet" and root_data.yard_inventory.ground.size() == 1, "pickup removes only millet, preserves older grass")
	root_data = Inventory.transition(root_data, 12, "drop", "millet", {"x": 450.0, "y": 510.0}).candidate
	root_data = Inventory.transition(root_data, 13, "eat", "millet", {"id": 3}).candidate
	check(root_data.yard_inventory.ground.size() == 1 and root_data.yard_inventory.fish.small == 2 and root_data.keepsakes.old == 4, "consume preserves all other items and root fields")
	check(Inventory.transition(root_data, 14, "eat", "millet", {"id": 3}).get("error") == "BASKET_EMPTY", "second consumer cannot eat same portion")
	var bad := old.duplicate(true)
	bad.yard_inventory.held = "millet"
	check(Inventory.read(bad).is_empty(), "schema2 cannot smuggle a future hand kind")
	bad = root_data.duplicate(true)
	bad.yard_inventory.millet = -1
	check(Inventory.read(bad).is_empty(), "negative grain blocked")
	bad = root_data.duplicate(true)
	bad.yard_inventory.schema = 4
	check(Inventory.read(bad).is_empty(), "future inventory untouched")
	var residents := {"schema": 2, "revision": 4, "beibei": {"stage": "grown", "adopted_clock": {"day": 1, "elapsed": 0.0}}, "turtle": {"stage": "pond", "found_trip": "trip-2"}}
	root_data.world_residents = residents.duplicate(true)
	root_data.holiday_day = 5
	root_data.holiday_day_elapsed = 50.0
	var migrated := Residents.read(root_data)
	check(migrated.schema == 3 and migrated.chicken.stage == "unmet" and migrated.turtle.stage == "pond" and migrated.beibei.stage == "grown", "chicken migration preserves dog and turtle")
	check(root_data.world_residents == residents, "resident migration is a nonmutating view")
	root_data = Residents.transition(root_data, 4, "settle_chick").candidate
	check(root_data.world_residents.chicken.stage == "chick" and root_data.world_residents.chicken.settled_clock.day == 5, "chick introduced once at authoritative game time")
	check(Residents.transition(root_data, 5, "settle_chick").get("error") == "RESIDENT_ALREADY_HOME", "cannot reset chick age by introduction replay")
	check(Residents.transition(root_data, 5, "grow_chicken").get("error") == "RESIDENT_NOT_READY", "no premature growth")
	root_data.holiday_day = 8
	root_data.holiday_day_elapsed = 49.9
	check(Residents.transition(root_data, 5, "grow_chicken").get("error") == "RESIDENT_NOT_READY", "one tenth second early remains a chick")
	root_data.holiday_day_elapsed = 50.0
	root_data = Residents.transition(root_data, 5, "grow_chicken").candidate
	check(root_data.world_residents.chicken.stage == "hen" and root_data.world_residents.chicken.settled_clock.day == 5, "three complete game days grow the same chicken")
	check(root_data.world_residents.beibei.stage == "grown" and root_data.world_residents.turtle.stage == "pond", "growth cannot overwrite other residents")
	check(Residents.read(JSON.parse_string(JSON.stringify(root_data))).chicken.stage == "hen", "JSON reopen retains hen")
	check(Residents.transition(root_data, 6, "grow_chicken").get("error") == "RESIDENT_NOT_CHICK", "no duplicate growth")
	bad = root_data.duplicate(true)
	bad.world_residents.chicken.settled_clock = null
	check(Residents.read(bad).is_empty(), "grown chicken without provenance blocked")
	bad = root_data.duplicate(true)
	bad.world_residents.schema = 4
	check(Residents.read(bad).is_empty(), "future residents are not reset")
	print("CHICK_MILLET_MODEL checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
