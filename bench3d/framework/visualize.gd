extends Node

## Renders every collider in a case, batched into MultiMeshes so 4000 bodies cost a handful
## of draw calls instead of 4000 nodes. Grouping is by shape class plus quantized dimensions,
## because cases build a fresh shape per body and keying on the resource would batch nothing.

const CIRCLE_SEGMENTS := 16
const SIZE_QUANTUM := 0.5
const STATIC_COLOR := Color(0.55, 0.58, 0.64, 0.30)

## Cases add nodes here when drawing them would hide the scene — the tumbler drum being the
## obvious one, since you want to watch what is inside it.
const NO_DRAW := "bench_no_draw"

var _dim := "2d"
var _enabled := true
var _groups: Array = []
var _tinted := 0


func build(root: Node, dim: String) -> void:
	_dim = dim
	var buckets: Dictionary = {}
	_collect(root, buckets)
	for key in buckets:
		_make_group(key, buckets[key])
	_update_transforms()


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	for group in _groups:
		group["instance"].visible = enabled


func _process(_delta: float) -> void:
	if _enabled:
		_update_transforms()


func _collect(node: Node, buckets: Dictionary) -> void:
	for child in node.get_children():
		var shape: Resource = null
		var dynamic := false
		if child is CollisionShape2D:
			shape = (child as CollisionShape2D).shape
			dynamic = child.get_parent() is RigidBody2D
		elif child is CollisionShape3D:
			shape = (child as CollisionShape3D).shape
			dynamic = child.get_parent() is RigidBody3D
		if shape != null and not _hidden(child):
			var key := "%s|%s|%s" % [shape.get_class(), _shape_key(shape), dynamic]
			if not buckets.has(key):
				buckets[key] = []
			buckets[key].append(child)
		_collect(child, buckets)


func _hidden(collider: Node) -> bool:
	var node := collider
	while node != null:
		if node.is_in_group(NO_DRAW):
			return true
		node = node.get_parent()
	return false


func _shape_key(shape: Resource) -> String:
	var q := func(v: float) -> float: return snappedf(v, SIZE_QUANTUM)
	if shape is RectangleShape2D:
		var s := (shape as RectangleShape2D).size
		return "%.2f,%.2f" % [q.call(s.x), q.call(s.y)]
	if shape is CircleShape2D:
		return "%.2f" % q.call((shape as CircleShape2D).radius)
	if shape is CapsuleShape2D:
		var c := shape as CapsuleShape2D
		return "%.2f,%.2f" % [q.call(c.radius), q.call(c.height)]
	if shape is BoxShape3D:
		var b := (shape as BoxShape3D).size
		return "%.2f,%.2f,%.2f" % [q.call(b.x), q.call(b.y), q.call(b.z)]
	if shape is SphereShape3D:
		return "%.2f" % q.call((shape as SphereShape3D).radius)
	if shape is CapsuleShape3D:
		var c3 := shape as CapsuleShape3D
		return "%.2f,%.2f" % [q.call(c3.radius), q.call(c3.height)]
	return str(shape.get_instance_id())


## Golden-ratio hue walk at low saturation: every body gets its own muted colour, and
## neighbours never land on the same hue.
func _next_tint() -> Color:
	_tinted += 1
	var hue := fmod(_tinted * 0.6180339887, 1.0)
	return Color.from_hsv(hue, 0.38, 0.82)


func _make_group(key: String, colliders: Array) -> void:
	var first: Resource = (
		(colliders[0] as CollisionShape2D).shape
		if colliders[0] is CollisionShape2D
		else (colliders[0] as CollisionShape3D).shape
	)
	var mesh := _mesh_for(first)
	if mesh == null:
		return
	var dynamic := key.ends_with("|true")

	var multimesh := MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_2D if _dim == "2d" else MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = colliders.size()
	for i in colliders.size():
		multimesh.set_instance_color(i, _next_tint() if dynamic else STATIC_COLOR)

	var instance: Node
	if _dim == "2d":
		var mmi := MultiMeshInstance2D.new()
		mmi.multimesh = multimesh
		instance = mmi
	else:
		var mmi3 := MultiMeshInstance3D.new()
		mmi3.multimesh = multimesh
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		if not dynamic:
			# Bin walls and floors are large enough to hide the whole scene behind them.
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.no_depth_test = false
			material.albedo_color.a = 0.10
		mmi3.material_override = material
		instance = mmi3
	add_child(instance)
	_groups.append({"instance": instance, "colliders": colliders})


func _update_transforms() -> void:
	for group in _groups:
		var multimesh: MultiMesh = group["instance"].multimesh
		var colliders: Array = group["colliders"]
		for i in colliders.size():
			var collider: Node = colliders[i]
			if not is_instance_valid(collider):
				# Cases that free bodies mid-run would otherwise leave the last transform
				# frozen in place; a zero-scale instance disappears instead.
				if _dim == "2d":
					multimesh.set_instance_transform_2d(i, Transform2D().scaled(Vector2.ZERO))
				else:
					multimesh.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))
				continue
			if _dim == "2d":
				multimesh.set_instance_transform_2d(i, (collider as CollisionShape2D).global_transform)
			else:
				multimesh.set_instance_transform(i, (collider as CollisionShape3D).global_transform)


func _mesh_for(shape: Resource) -> Mesh:
	if shape is BoxShape3D:
		var box := BoxMesh.new()
		box.size = (shape as BoxShape3D).size
		return box
	if shape is SphereShape3D:
		var sphere := SphereMesh.new()
		sphere.radius = (shape as SphereShape3D).radius
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 12
		sphere.rings = 6
		return sphere
	if shape is CapsuleShape3D:
		var cap := CapsuleMesh.new()
		cap.radius = (shape as CapsuleShape3D).radius
		cap.height = (shape as CapsuleShape3D).height
		cap.radial_segments = 10
		cap.rings = 4
		return cap
	if shape is Shape3D:
		return (shape as Shape3D).get_debug_mesh()
	var points := _polygon_for(shape)
	if points.size() < 3:
		return null
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		return null
	var vertices := PackedVector3Array()
	vertices.resize(points.size())
	for i in points.size():
		vertices[i] = Vector3(points[i].x, points[i].y, 0.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _polygon_for(shape: Resource) -> PackedVector2Array:
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size * 0.5
		return PackedVector2Array(
			[
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
			]
		)
	if shape is CircleShape2D:
		return _arc(Vector2.ZERO, (shape as CircleShape2D).radius, 0.0, TAU, CIRCLE_SEGMENTS)
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		var offset := maxf(capsule.height * 0.5 - capsule.radius, 0.0)
		var points := _arc(Vector2(0, -offset), capsule.radius, PI, TAU, CIRCLE_SEGMENTS / 2)
		points.append_array(_arc(Vector2(0, offset), capsule.radius, 0.0, PI, CIRCLE_SEGMENTS / 2))
		return points
	if shape is ConvexPolygonShape2D:
		return (shape as ConvexPolygonShape2D).points
	return PackedVector2Array()


func _arc(centre: Vector2, radius: float, from: float, to: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		var angle := from + (to - from) * i / float(segments)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return points
