extends Node2D
## Read-only world projection. Only the confirmed ledger can create a stone.
## Eight named arcs are render addresses, not an approved recipe/AP cost.
const Edging := preload("res://scripts/game/pond_edging.gd")
const IDS := ["rim_00", "rim_01", "rim_02", "rim_03", "rim_04", "rim_05", "rim_06", "rim_07"]
var visuals: Dictionary = {}
var confirmed: Dictionary = {}
var _store: Node

func _init(store: Node = null) -> void:
	_store = store
	name = "PondEdging"

func _ready() -> void:
	if _store == null: _store = get_node("/root/SaveStore")
	_store.commit_confirmed.connect(_on_confirmed)
	refresh()

func _exit_tree() -> void:
	if is_instance_valid(_store) and _store.commit_confirmed.is_connected(_on_confirmed):
		_store.commit_confirmed.disconnect(_on_confirmed)

func _on_confirmed(_operation: String, kind: String) -> void:
	if kind == "growth": refresh()

func refresh() -> bool:
	return sync(_store.get_pond_edging())

static func points(section: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var index := IDS.find(section)
	if index < 0: return result
	# Painted-bank coordinates deliberately differ from the smaller collision ellipse.
	# Small groups follow the painted rim; three visible pieces are an art
	# composition, not a material count. Future costs remain explicit inputs.
	for offset in [-15.0, 0.0, 15.0]:
		var angle := deg_to_rad(index * 45.0 + offset)
		result.append(Vector2(755.0, 615.0) + Vector2(cos(angle) * 245.0, sin(angle) * 73.0))
	return result

func sync(value: Dictionary) -> bool:
	# Unknown/future/corrupt data must not erase the last confirmed display.
	var valid := Edging.read({"holiday_day":2147483647, Edging.FIELD:value})
	if valid.is_empty(): return false
	if valid == confirmed: return true
	for section: String in visuals.keys():
		if not valid.sections.has(section):
			for prop: Node2D in visuals[section]:
				prop.hide()
				prop.queue_free()
			visuals.erase(section)
	for section: String in IDS:
		if not valid.sections.has(section) or visuals.has(section): continue
		var group: Array[Node2D] = []
		for point: Vector2 in points(section):
			var prop := YardPropVisual.new()
			prop.configure("keepsake", {"find_id":ExplorationRoutes.FIND_STONE})
			prop.position = point
			prop.scale = Vector2.ONE * YardGround.depth_at(point.y) * 1.15
			prop.z_as_relative = false
			prop.z_index = roundi(point.y)
			add_child(prop)
			group.append(prop)
		visuals[section] = group
	confirmed = valid.duplicate(true)
	return true
