extends "res://framework/bench_case.gd"

## Narrow-phase breadth: 5,000 bodies across boxes, spheres, capsules and a real convex hull
## that defeats shape-specific fast paths. `pyramid` only exercises box-box; convex-convex in
## 3D falls back to GJK/EPA or an SAT variant depending on the engine, and that is where
## implementations diverge most.

const COUNT := 5000
const HALF := 16.0


func build(root: Node) -> void:
	_bin(root, HALF, 60.0)
	var spots := grid_3d(COUNT, Vector3(1.0, 1.0, 1.0), 28, 28, Vector3(-13.5, 0.6, -13.5), 0.05)
	for i in COUNT:
		body3(root, spots[i], _shape(i % 4)).rotation = Vector3(
			rand_range(-PI, PI), rand_range(-PI, PI), rand_range(-PI, PI)
		)


func _shape(kind: int) -> Shape3D:
	match kind:
		0: return box3(Vector3(rand_range(0.5, 0.9), rand_range(0.5, 0.9), rand_range(0.5, 0.9)))
		1: return sphere3(rand_range(0.25, 0.45))
		2: return capsule3(rand_range(0.2, 0.32), rand_range(0.9, 1.4))
		_: return hull3(rand_range(0.35, 0.55))


func _bin(root: Node, half: float, height: float) -> void:
	fixed3(root, Vector3(0, -0.5, 0), box3(Vector3(half * 2, 1, half * 2)))
	for s in [-1.0, 1.0]:
		fixed3(root, Vector3(s * half, height * 0.5, 0), box3(Vector3(1, height, half * 2)))
		fixed3(root, Vector3(0, height * 0.5, s * half), box3(Vector3(half * 2, height, 1)))


func settle_ticks() -> int:
	return 90
