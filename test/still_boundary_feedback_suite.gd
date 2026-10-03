extends SceneTree

## Headless: BoundaryFeedback.pose still vs animated alpha contract (REQ-024).

func _init() -> void:
	var failed := 0
	failed += _expect_eq(BoundaryFeedback.pose(1.2, true)["alpha"], 0.80, "still full remaining")
	failed += _expect_eq(BoundaryFeedback.pose(0.20, true)["alpha"], 0.80, "still late remaining")
	failed += _expect_eq(BoundaryFeedback.pose(0.0, true)["alpha"], 0.0, "still ended")
	failed += _expect_eq(BoundaryFeedback.pose(1.2, false)["alpha"], 0.80, "motion full remaining")
	failed += _expect_near(BoundaryFeedback.pose(0.175, false)["alpha"], 0.40, 0.001, "motion mid fade")
	failed += _expect_eq(BoundaryFeedback.pose(0.0, false)["alpha"], 0.0, "motion ended")
	failed += _expect_eq(BoundaryFeedback.pose(0.5, true)["radius"], 12.0, "radius still")
	if failed == 0:
		print("STILL BOUNDARY FEEDBACK PASS 7")
		quit(0)
	else:
		print("STILL BOUNDARY FEEDBACK FAIL ", failed)
		quit(1)

func _expect_eq(got, want, label: String) -> int:
	if got != want:
		print("FAIL ", label, " got=", got, " want=", want)
		return 1
	return 0

func _expect_near(got: float, want: float, eps: float, label: String) -> int:
	if absf(got - want) > eps:
		print("FAIL ", label, " got=", got, " want=", want)
		return 1
	return 0
