extends "res://test/exploration_return_adapter/return_adapter.gd"
# 首条画卷体验研究（#201）：在 #200 回院适配器上研究三段体验——
#   停下看景：在只看不带的停留点停下，观察态收景，不调用核心、不计任何进度；
#   空手中途返回：停下看了可带的东西但不带，随时回院，院内说明「空手回来」而不是「已收好」；
#   带一个占位物中途返回：停下后自己选择带上（也可放回），不必走回起点就能回院。
# 占位物来自 #176 夹具（formal.find.reed），只是测试夹具，不是已批准的正式物品；
# 保存结果仍只由假宿主决定，不证明耐久保存、强退恢复或真实宿主接入。

const ExperienceScroll := preload("res://test/exploration_first_experience/experience_scroll.gd")

## 空手往返的院内文字：没有东西要收，只说这趟散步记没记下；同样只有核心确认提交后才说「已记下」
const TEXT_EMPTY_SAVING := "空手回来了，正在记下这趟散步…可以先在院子里走走"
const TEXT_EMPTY_UNKNOWN := "还在确认这趟散步有没有记下，可以先在院子里走走"
const TEXT_EMPTY_FAILED := "这趟散步没能记下，可以再试一次"
const TEXT_EMPTY_SAVED := "空手回来了，这趟散步已记下"

## 停留点 → 在这里带上的东西；用来支持「放回」，也让底部按钮显示放回
var _found_at := {}
var _saved_empty := false


func _init() -> void:
	scroll_script = ExperienceScroll


func _connect_scroll(target: AdaptedScroll, generation: int) -> void:
	super(target, generation)
	## scroll 按父类声明为 AdaptedScroll，研究画卷新增的信号与方法走无类型引用
	var research = target
	research.pick_toggled.connect(_on_pick_toggled.bind(generation))
	research.observe_ended.connect(_on_observe_ended.bind(generation))


func set_out() -> Dictionary:
	var result := super()
	if result.ok:
		_found_at.clear()
	return result


## 停下看：只走到对应核心停留点并读出可带的东西，不自动带上；未映射的停留点只看
func _on_observe_requested(stop_id: String, generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		_log("stale_observe_ignored")
		return
	if not stop_map.has(stop_id):
		_research().enter_observe(stop_id, "", "")
		scroll.show_note("停下来看看这一处")
		_log("observe_only:%s" % stop_id)
		return
	var target: String = stop_map[stop_id]
	var view: Dictionary = host.session.get_view()
	if view.get("current_stop", "") != target:
		var moved: Dictionary = host.session.visit(target)
		if not moved.ok:
			scroll.show_note("从这里还走不到那儿（%s）" % moved.get("error", ""))
			_log("visit_rejected:%s" % moved.get("error", ""))
			return
		host.persist()
		view = host.session.get_view()
	_research().enter_observe(stop_id, view.get("offer", ""), _carried_from(stop_id))
	scroll.show_note("这里有一样可以带走的东西，带不带都行" if not String(view.get("offer", "")).is_empty() else "停下来看看这一处")
	_log("observe:%s" % target)


## 带上 / 放回：由玩家在观察态里选择，经核心 take / release，成功后才改按钮
func _on_pick_toggled(stop_id: String, generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		_log("stale_pick_ignored")
		return
	var carried := _carried_from(stop_id)
	if not carried.is_empty():
		var released: Dictionary = host.session.release(carried)
		if released.ok:
			host.persist()
			_found_at.erase(stop_id)
			scroll.show_note("放回去了")
			_log("release:%s" % carried)
		else:
			_log("release_rejected:%s" % released.get("error", ""))
	else:
		var offer: String = host.session.get_view().get("offer", "")
		var taken: Dictionary = host.session.take(offer) if not offer.is_empty() else {"ok": false, "error": "not_offered"}
		if taken.ok:
			host.persist()
			_found_at[stop_id] = offer
			scroll.show_note("带上了（占位：%s）" % offer)
			_log("take:%s" % offer)
		else:
			scroll.show_note("带不下了（%s）" % taken.get("error", ""))
			_log("take_rejected:%s" % taken.get("error", ""))
	_research().update_choice(host.session.get_view().get("offer", ""), _carried_from(stop_id))


func _on_observe_ended(stop_id: String, generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		return
	_log("observe_end:%s" % stop_id)


func status_text() -> String:
	var text := super()
	var state := core_state()
	var empty := false
	if state == C.STATE_PENDING or state == C.STATE_FAILURE:
		empty = int(host.session.get_view().get("proposal_items", -1)) == 0
	elif state == C.STATE_IDLE:
		empty = _saved_empty
	if not empty:
		return text
	var replace := {TEXT_SAVING: TEXT_EMPTY_SAVING, TEXT_UNKNOWN: TEXT_EMPTY_UNKNOWN, TEXT_FAILED: TEXT_EMPTY_FAILED, TEXT_SAVED: TEXT_EMPTY_SAVED}
	for key: String in replace:
		if text.ends_with(key):
			return text.trim_suffix(key) + replace[key]
	return text


func _settle_committed() -> void:
	if core_state() == C.STATE_COMMITTED:
		_saved_empty = int(host.session.get_view().get("proposal_items", -1)) == 0
	super()


func _research():
	return scroll


func _carried_from(stop_id: String) -> String:
	var find: String = _found_at.get(stop_id, "")
	if find.is_empty() or not (host.session.get_view().get("carried", []) as Array).has(find):
		return ""
	return find
