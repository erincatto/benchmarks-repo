extends "res://framework/bench_case.gd"

## Solver throughput on one large, well-conditioned stack: 3795 boxes in a 22-level stepped
## pyramid, placed exactly touching so the solver starts from resting contact. Box-box only —
## the pair every engine special-cases — so this is as close to a pure constraint-solver
## measurement as the suite gets.

const LEVELS := 22
const BOX := 1.0


func build(root: Node) -> void:
	fixed3(root, Vector3(0, -0.5, 0), box3(Vector3(400, 1, 400)))
	for level in LEVELS:
		var side := LEVELS - level
		var y := BOX * (0.5 + level)
		var origin := -0.5 * (side - 1) * BOX
		for ix in side:
			for iz in side:
				body3(root, Vector3(origin + ix * BOX, y, origin + iz * BOX), box3(Vector3.ONE * BOX))
