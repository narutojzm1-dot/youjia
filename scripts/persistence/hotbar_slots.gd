extends RefCounted
## Saved references only. Never owns inventory, quantities or held state.
const COUNT := 5
const KINDS := ["small", "medium", "odd", "grass", "millet", "wheat", "corn"]

static func clean(raw: Variant) -> Array:
	var slots: Array = []
	var seen := {}
	for index in COUNT:
		var kind: Variant = raw[index] if raw is Array and index < raw.size() else ""
		if not kind is String or kind not in KINDS or seen.has(kind): kind = ""
		if kind != "": seen[kind] = true
		slots.append(kind)
	return slots
