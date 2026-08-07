extends "res://framework/bench_case.gd"

## Narrow-phase breadth: 5,000 bodies across every shape pair the three engines share,
## including a real convex polygon that defeats box and circle fast paths. `pyramid` only
## ever exercises box-box; this is where generic convex support functions diverge.

const COUNT := 5000
const HALF := 1400.0


func build(root: Node) -> void:
	_bin(root, HALF, 3000.0)
	var spots := grid_2d(COUNT, Vector2(30, 30), 88, Vector2(-1305, 930), 0.05)
	for i in COUNT:
		body(root, spots[i], _shape(i % 4)).rotation = rand_range(-PI, PI)


func _shape(kind: int) -> Shape2D:
	match kind:
		0: return rect(Vector2(rand_range(14, 26), rand_range(14, 26)))
		1: return circle(rand_range(7, 13))
		2: return capsule(rand_range(6, 10), rand_range(22, 34))
		_: return ngon(rand_range(10, 16), 5)


func _bin(root: Node, half: float, height: float) -> void:
	fixed(root, Vector2(0, 960), rect(Vector2(half * 2.0, 40)))
	fixed(root, Vector2(-half, 0), rect(Vector2(40, height)))
	fixed(root, Vector2(half, 0), rect(Vector2(40, height)))


func settle_ticks() -> int:
	return 90
