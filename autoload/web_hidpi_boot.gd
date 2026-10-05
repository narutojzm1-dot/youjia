extends Node

## REQ-20261005-026：网页高清屏按 CSS 像素排版。
## 作为最先加载的一批节点，在主场景首次布局前定好根窗口倍率；
## 浏览器缩放、拖到另一块屏会改 devicePixelRatio 并伴随一次画布尺寸变化，届时重读。
## 规则和说明见 `scripts/ui/web_hidpi.gd`。


func _ready() -> void:
	_apply()
	get_tree().root.size_changed.connect(_on_root_size_changed)


func _on_root_size_changed() -> void:
	call_deferred("_apply")


func _apply() -> void:
	WebHiDpi.apply(get_tree().root, WebHiDpi.screen_scale())
