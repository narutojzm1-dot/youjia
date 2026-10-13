extends "res://test/pond_growth_director_suite.gd"
## Bounded reproduction for ordinary idle encounter/save ownership between jobs.
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	store = root.get_node("SaveStore")
	for test_seed in range(8):
		print("SCHEDULER_SEED ", test_seed)
		await check_autonomous_work(test_seed)
	print("SCHEDULER_DIAGNOSTIC checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
