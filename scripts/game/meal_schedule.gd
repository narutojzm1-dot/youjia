extends RefCounted
## Producer first playable recipes, using already obtainable basket foods.
## Wheat needs the future mill; unusual fish is not assumed edible.
const RECIPES := {
	"millet": {"id": "millet_porridge", "ingredients": {"millet": 1}},
	"small": {"id": "small_fish_soup", "ingredients": {"small": 1}},
	"medium": {"id": "fish_soup", "ingredients": {"medium": 1}},
}
const Daylight := preload("res://scripts/game/world_daylight.gd")
const IDLE_SECONDS := 8.0
const COOK_SECONDS := 8.0

static func meal_at(fraction: float) -> String:
	var hour := Daylight.hour(fraction)
	if hour >= 7.0 and hour < 10.0: return "breakfast"
	if hour >= 12.0 and hour < 15.0: return "lunch"
	if hour >= 18.0 and hour < 21.0: return "dinner"
	return ""
