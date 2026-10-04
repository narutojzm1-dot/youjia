extends RefCounted
# 方向输入聚合：键盘左右、每根触摸手指各算一个来源。
# 同时按住多个来源时以最近按下的为准；松开、触摸取消或失焦都会移除来源，避免粘键。

## 按下顺序：[{source, dir}]，越靠后越新
var _held: Array[Dictionary] = []


func press(source: String, dir: int) -> void:
	release(source)
	if dir != 0:
		_held.append({"source": source, "dir": signi(dir)})


func release(source: String) -> void:
	for index in range(_held.size() - 1, -1, -1):
		if _held[index]["source"] == source:
			_held.remove_at(index)


func clear() -> void:
	_held.clear()


func direction() -> int:
	if _held.is_empty():
		return 0
	return int(_held[-1]["dir"])


func held_count() -> int:
	return _held.size()
