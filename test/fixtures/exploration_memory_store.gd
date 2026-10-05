extends "res://autoload/save_store.gd"
# 生产 SaveStore 的探索 API，只把文件提交换成内存：用来注入写入失败，不碰真实存档。

var fail_commits := false
# >= 0 时：再成功这么多次后开始失败（模拟“提交成功、随后的空闲记录没写上就断电”）
var fail_after := -1
var commits := 0


func _init() -> void:
	_data = _default_data()


func _commit_candidate(candidate: Dictionary) -> bool:
	if fail_commits:
		return false
	if fail_after == 0:
		return false
	if fail_after > 0:
		fail_after -= 1
	commits += 1
	_data = candidate
	return true
