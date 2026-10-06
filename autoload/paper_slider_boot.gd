extends Node

## REQ-20261006-040：暂停页音量滑条换成暖纸样式。
## 和 ManusFontTheme 一样在节点进树时套样式，不改 `scripts/main.gd`
## （#382 输入路由、#459 焦点路径都在改那个文件）。样式与边界见
## `scripts/ui/paper_slider_style.gd`；只改外观，不改取值、尺寸、命中或焦点。


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is HSlider:
		PaperSliderStyle.apply(node)
