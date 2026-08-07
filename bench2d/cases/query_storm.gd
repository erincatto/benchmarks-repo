extends "res://framework/bench_case.gd"

## Queries against a populated broad-phase: 8,000 static and 2,000 moving bodies, hit every
## tick with a fixed mix of rays, shape casts and point queries whose origins sweep the field
## deterministically. This measures the acceleration structure rather than the solver, so an
## engine can win `pyramid` and lose here.

const STATICS := 8000
const MOVERS := 2000
const FIELD := 3000.0
const RAYS := 600
const CASTS := 120
const POINTS := 180

var _queries := 0
var _hits := 0
var _overlay: QueryOverlay
var _cast: PhysicsShapeQueryParameters2D
var _ray := PhysicsRayQueryParameters2D.new()
var _point := PhysicsPointQueryParameters2D.new()


func build(root: Node) -> void:
	for i in STATICS:
		fixed(
			root,
			Vector2(rand_range(-FIELD, FIELD), rand_range(-FIELD, FIELD)),
			rect(Vector2(rand_range(20, 60), rand_range(20, 60)))
		).rotation = rand_range(-PI, PI)
	for i in MOVERS:
		var b := body(
			root, Vector2(rand_range(-FIELD, FIELD), rand_range(-FIELD, FIELD)), circle(rand_range(10, 24))
		)
		b.gravity_scale = 0.0
		b.linear_velocity = Vector2(rand_range(-60, 60), rand_range(-60, 60))

	_cast = PhysicsShapeQueryParameters2D.new()
	_cast.shape = circle(24)
	_cast.collide_with_areas = false
	# Shows where the queries actually go. `_draw` never runs headless, so the timed runs
	# are untouched; this only costs anything in the viewer.
	_overlay = QueryOverlay.new()
	root.add_child(_overlay)


func step(tick: int, root: Node) -> void:
	var space := root.get_viewport().world_2d.direct_space_state
	var phase := tick * 0.017
	for i in RAYS:
		var a := phase + TAU * i / RAYS
		_ray.from = Vector2(cos(a), sin(a)) * FIELD
		_ray.to = -_ray.from
		_count(not space.intersect_ray(_ray).is_empty())
	for i in CASTS:
		var a := phase * 1.7 + TAU * i / CASTS
		var origin := Vector2(cos(a), sin(a)) * FIELD
		_cast.transform = Transform2D(0.0, origin)
		_cast.motion = -origin * 2.0
		var hit := space.cast_motion(_cast)
		_count(not hit.is_empty() and hit[0] < 1.0)
	for i in POINTS:
		var a := phase * 2.3 + TAU * i / POINTS
		_point.position = Vector2(cos(a), sin(a)) * FIELD * 0.6
		_count(not space.intersect_point(_point, 8).is_empty())
	_update_overlay(phase)


## Every Nth query, so the overlay reads as a sweeping fan instead of a solid disc.
func _update_overlay(phase: float) -> void:
	if _overlay == null:
		return
	var rays := PackedVector2Array()
	for i in range(0, RAYS, 12):
		var a := phase + TAU * i / RAYS
		var from := Vector2(cos(a), sin(a)) * FIELD
		rays.append(from)
		rays.append(-from)
	var casts := PackedVector2Array()
	for i in range(0, CASTS, 4):
		var a := phase * 1.7 + TAU * i / CASTS
		casts.append(Vector2(cos(a), sin(a)) * FIELD)
	var points := PackedVector2Array()
	for i in range(0, POINTS, 3):
		var a := phase * 2.3 + TAU * i / POINTS
		points.append(Vector2(cos(a), sin(a)) * FIELD * 0.6)
	_overlay.rays = rays
	_overlay.casts = casts
	_overlay.points = points
	_overlay.queue_redraw()


class QueryOverlay:
	extends Node2D

	var rays := PackedVector2Array()
	var casts := PackedVector2Array()
	var points := PackedVector2Array()

	func _ready() -> void:
		z_index = 100

	func _draw() -> void:
		for i in range(0, rays.size() - 1, 2):
			draw_line(rays[i], rays[i + 1], Color(1.0, 0.55, 0.15, 0.22), 2.0)
		for c in casts:
			draw_circle(c, 24.0, Color(0.35, 0.9, 1.0, 0.30))
			draw_line(c, -c, Color(0.35, 0.9, 1.0, 0.12), 3.0)
		for pt in points:
			draw_circle(pt, 10.0, Color(0.6, 1.0, 0.4, 0.55))


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
