class_name WebHiDpi
extends RefCounted

## REQ-20261005-026：网页高清屏（devicePixelRatio > 1）时，界面仍按 CSS 像素排版。
##
## Godot Web 默认按物理像素建画布（hidpi 开），而本项目 `window/stretch/mode`
## 是 disabled，于是手机、Retina 和 125%～175% 缩放的 Windows 上：
## - 15px 目标提示、14px 天数、16px 通知都只剩 1/DPR 大；
## - 390×844 的竖屏手机物理宽度 ≥ 700，被 `Main._layout()` 当成桌面横排。
## 这里用窗口 `content_scale_factor` 把逻辑尺寸还原成 CSS 像素：布局、字号、
## 镜头取景和 DPR=1 时完全一致；画面仍按物理分辨率渲染，字体按倍率超采样，不会变糊。
## 原生桌面不动（`screen_scale()` 只在 Web 读浏览器倍率）。

## 浏览器倍率异常大时的上限，防止逻辑尺寸被压得过小。
const MAX_FACTOR := 4.0

## 仅供测试：> 0 时代替浏览器倍率。
static var override_scale := -1.0


static func factor_for(screen_scale: float) -> float:
	if is_nan(screen_scale) or is_inf(screen_scale) or screen_scale <= 1.0:
		return 1.0
	return minf(screen_scale, MAX_FACTOR)


static func screen_scale() -> float:
	if override_scale > 0.0:
		return override_scale
	if not OS.has_feature("web"):
		return 1.0
	return DisplayServer.screen_get_scale()


## 返回本次是否改了窗口倍率。
static func apply(window: Window, scale: float) -> bool:
	if window == null:
		return false
	var factor := factor_for(scale)
	if is_equal_approx(window.content_scale_factor, factor):
		return false
	window.content_scale_factor = factor
	return true
