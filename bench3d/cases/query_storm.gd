extends "res://framework/bench_case.gd"

## Queries against a populated 3D broad-phase: 8,000 static and 2,000 moving bodies, hit every
## tick with a fixed mix of rays, shape casts and point queries whose origins sweep the
## volume deterministically. This measures the acceleration structure rather than the solver,
## so an engine can win `pyramid` and lose here.

const STATICS := 8000
const MOVERS := 2000
const FIELD := 60.0
const RAYS := 500
const CASTS := 100
const POINTS := 150

var _queries := 0
var _hits := 0
var _cast: PhysicsShapeQueryParameters3D
var _ray := PhysicsRayQueryParameters3D.new()
var _point := PhysicsPointQueryParameters3D.new()


func build(root: Node) -> void:
	for i in STATICS:
		fixed3(root, _scatter(), box3(Vector3(rand_range(0.8, 2.4), rand_range(0.8, 2.4), rand_range(0.8, 2.4)))).rotation = Vector3(
			rand_range(-PI, PI), rand_range(-PI, PI), rand_range(-PI, PI)
		)
	for i in MOVERS:
		var b := body3(root, _scatter(), sphere3(rand_range(0.3, 0.8)))
		b.gravity_scale = 0.0
		b.linear_velocity = Vector3(rand_range(-2, 2), rand_range(-2, 2), rand_range(-2, 2))

	_cast = PhysicsShapeQueryParameters3D.new()
	_cast.shape = sphere3(0.8)
	_cast.collide_with_areas = false


func step(tick: int, root: Node) -> void:
	var space := root.get_viewport().world_3d.direct_space_state
	var phase := tick * 0.017
	for i in RAYS:
		var a := phase + TAU * i / RAYS
		var h := sin(phase * 0.7 + i) * FIELD * 0.5
		_ray.from = Vector3(cos(a) * FIELD, h, sin(a) * FIELD)
		_ray.to = -_ray.from
		_count(not space.intersect_ray(_ray).is_empty())
	for i in CASTS:
		var a := phase * 1.7 + TAU * i / CASTS
		var origin := Vector3(cos(a) * FIELD, sin(a) * FIELD * 0.4, sin(a) * FIELD)
		_cast.transform = Transform3D(Basis(), origin)
		_cast.motion = -origin * 2.0
		var hit := space.cast_motion(_cast)
		_count(not hit.is_empty() and hit[0] < 1.0)
	for i in POINTS:
		var a := phase * 2.3 + TAU * i / POINTS
		_point.position = Vector3(cos(a) * FIELD * 0.6, sin(a * 1.3) * FIELD * 0.4, sin(a) * FIELD * 0.6)
		_count(not space.intersect_point(_point, 8).is_empty())


func _scatter() -> Vector3:
	return Vector3(rand_range(-FIELD, FIELD), rand_range(-FIELD, FIELD), rand_range(-FIELD, FIELD))


func _count(hit: bool) -> void:
	_queries += 1
	if hit:
		_hits += 1


func work_units() -> int:
	return _queries


func extra_metrics() -> Dictionary:
	# A wildly different hit count means an engine is not finding the same geometry, which
	# invalidates the timing comparison rather than just being a curiosity.
	return {"queries": _queries, "hits": _hits}
