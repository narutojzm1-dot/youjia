extends Node2D
## Left: existing geometry is updated. Right: equivalent geometry is rebuilt.
## Same six vertices, different triangulation. Compare complete viewport halves.
var updated: Node2D
var reference: Node2D
var frames := 0
var before := PackedVector2Array([
    Vector2(0, 0), Vector2(60, 0), Vector2(60, 40),
    Vector2(42, 40), Vector2(42, 12), Vector2(0, 12)])
var after := PackedVector2Array([
    Vector2(0, 0), Vector2(18, 0), Vector2(18, 28),
    Vector2(60, 28), Vector2(60, 40), Vector2(0, 40)])


func _create(offset: float, points: PackedVector2Array) -> Node2D:
    var group := Node2D.new()
    group.position.x = offset
    add_child(group)
    for i in 29:
        var polygon := Polygon2D.new()
        polygon.polygon = points
        polygon.position = Vector2(30 + (i % 4) * 85, 30 + (i / 4) * 65)
        polygon.color = Color(0.3, 0.5, 0.7)
        group.add_child(polygon)
    return group


func _ready() -> void:
    updated = _create(0, before)
    reference = _create(400, before)
    print("index-repro initial")


func _process(_delta: float) -> void:
    frames += 1
    if frames == 80:
        updated.visible = false
        print("index-repro hidden")
    elif frames == 110:
        updated.visible = true
        print("index-repro shown")
    elif frames == 160:
        for child in updated.get_children():
            child.polygon = after
        reference.queue_free()
        reference = _create(400, after)
        print("index-repro changed triangulation / rebuilt reference")
    elif frames == 200:
        print("index-repro ready for comparison")
        if OS.has_feature("web"):
            JavaScriptBridge.eval("window.__minimalDone=true")
