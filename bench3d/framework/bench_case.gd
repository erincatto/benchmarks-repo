extends RefCounted

## Base class for a benchmark scenario.
##
## `build` populates the world once, before timing starts. `step` runs inside every timed
## tick and is where query- and spawn-driven cases do their work; pure solver cases leave it
## empty so their timings describe the solver alone.
##
## The `body`/`fixed` helpers exist so a case reads as the scene it describes rather than as
## node-and-collider plumbing. They create the body, attach the shape, parent it and record
## it, then hand it back for any per-case tweaks.

## Bodies created by `build`, in creation order. Used for the run fingerprint, so the order
## must be stable across engines or fingerprints will not be comparable.
var bodies: Array[Node] = []

var _rng := RandomNumberGenerator.new()


## Seeded per case so every engine gets a bit-identical world to simulate.
func rng_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func rand_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


# --- 2D construction ---------------------------------------------------------------------

func rect(size: Vector2) -> RectangleShape2D:
	var s := RectangleShape2D.new()
	s.size = size
	return s


func circle(radius: float) -> CircleShape2D:
	var s := CircleShape2D.new()
	s.radius = radius
	return s


func capsule(radius: float, height: float) -> CapsuleShape2D:
	var s := CapsuleShape2D.new()
	s.radius = radius
	s.height = height
	return s


func ngon(radius: float, sides: int) -> ConvexPolygonShape2D:
	var points := PackedVector2Array()
	for i in sides:
		var a := TAU * i / sides
		points.append(Vector2(cos(a), sin(a)) * radius)
	var s := ConvexPolygonShape2D.new()
	s.points = points
	return s


## Sleeping is off by default: every case but `sleep_settle` wants the solver measured
## rather than the sleep heuristic.
func body(root: Node, at: Vector2, shape: Shape2D) -> RigidBody2D:
	var b := RigidBody2D.new()
	b.can_sleep = false
	b.position = at
	_attach(b, shape)
	root.add_child(b)
	bodies.append(b)
	return b


func fixed(root: Node, at: Vector2, shape: Shape2D) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.position = at
	_attach(b, shape)
	root.add_child(b)
	return b


# --- 3D construction ---------------------------------------------------------------------

func box3(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


func sphere3(radius: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = radius
	return s


func capsule3(radius: float, height: float) -> CapsuleShape3D:
	var s := CapsuleShape3D.new()
	s.radius = radius
	s.height = height
	return s


func hull3(radius: float) -> ConvexPolygonShape3D:
	var s := ConvexPolygonShape3D.new()
	s.points = PackedVector3Array(
		[
			Vector3(radius, 0, 0),
			Vector3(-radius, 0, 0),
			Vector3(0, radius, 0),
			Vector3(0, -radius, 0),
			Vector3(0, 0, radius),
			Vector3(0, 0, -radius),
		]
	)
	return s


func body3(root: Node, at: Vector3, shape: Shape3D) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.can_sleep = false
	b.position = at
	_attach3(b, shape)
	root.add_child(b)
	bodies.append(b)
	return b


func fixed3(root: Node, at: Vector3, shape: Shape3D) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.position = at
	_attach3(b, shape)
	root.add_child(b)
	return b


func _attach(node: Node, shape: Shape2D) -> void:
	var c := CollisionShape2D.new()
	c.shape = shape
	node.add_child(c)


func _attach3(node: Node, shape: Shape3D) -> void:
	var c := CollisionShape3D.new()
	c.shape = shape
	node.add_child(c)


# --- placement ---------------------------------------------------------------------------

## Lattice placement for the pile cases, jittered by up to `jitter` of a cell.
##
## Deliberately not uniform random. Scattering N bodies independently makes a large fraction
## start deeply interpenetrating, and the opening ticks then measure how an engine untangles
## a soup — pathological (seconds per tick for some engines) and not what any case is meant
## to isolate. A jittered lattice starts everything separated while staying irregular enough
## that the pile is not a crystal.
func grid_2d(count: int, cell: Vector2, columns: int, origin: Vector2, jitter := 0.2) -> Array:
	var out: Array = []
	for i in count:
		out.append(
			origin
			+ Vector2((i % columns) * cell.x, -(i / columns) * cell.y)
			+ Vector2(_rng.randf_range(-jitter, jitter) * cell.x, _rng.randf_range(-jitter, jitter) * cell.y)
		)
	return out


func grid_3d(count: int, cell: Vector3, columns: int, depth: int, origin: Vector3, jitter := 0.2) -> Array:
	var out: Array = []
	var per_layer := columns * depth
	for i in count:
		var within := i % per_layer
		out.append(
			origin
			+ Vector3((within % columns) * cell.x, (i / per_layer) * cell.y, (within / columns) * cell.z)
			+ Vector3(
				_rng.randf_range(-jitter, jitter) * cell.x,
				_rng.randf_range(-jitter, jitter) * cell.y,
				_rng.randf_range(-jitter, jitter) * cell.z
			)
		)
	return out


# --- reporting ---------------------------------------------------------------------------

func build(_root: Node) -> void:
	pass


func step(_tick: int, _root: Node) -> void:
	pass


## Extra warmup this case needs before timing means anything, in ticks.
##
## Cases split in two. Steady-state ones (tumbler, ccd_bullets, query_storm) never settle by
## design, so any window is valid and they return 0. Pile ones start as a lattice in the air:
## until it lands, the step is measuring near-empty free-fall, and a timed window that starts
## too early is a blend of that and the settled pile — which flatters whichever engine drops
## bodies fastest. Those cases return the ticks their pile needs to come to rest.
func settle_ticks() -> int:
	return 0


## Work counter for cases whose cost is driven by something other than body count. Reported
## alongside timings so a case that silently did nothing looks idle rather than fast.
func work_units() -> int:
	return 0


## Case-specific numbers that qualify the timing — tunnelled bullets, contacts reported,
## stack drift. A time is only comparable between engines when these agree.
func extra_metrics() -> Dictionary:
	return {}
