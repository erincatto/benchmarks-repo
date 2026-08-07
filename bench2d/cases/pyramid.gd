extends "res://framework/bench_case.gd"

## Solver throughput on one large, well-conditioned stack: 10,000 boxes, placed exactly
## touching so the solver starts from resting contact rather than from a settling drop.
## Box-box only — the pair every engine special-cases — so this is as close to a pure
## constraint-solver measurement as the suite gets.

const COUNT := 10000
const BOX := 20.0


func build(root: Node) -> void:
	var base := int(ceil((sqrt(8.0 * COUNT + 1.0) - 1.0) * 0.5))
	fixed(root, Vector2(0, 20), rect(Vector2(base * BOX * 2.0, 40)))
	var placed := 0
	var level := 0
	while placed < COUNT:
		var width := mini(base - level, COUNT - placed)
		var x := -0.5 * (width - 1) * BOX
		for i in width:
			body(root, Vector2(x + i * BOX, -BOX * (0.5 + level)), rect(Vector2(BOX, BOX)))
		placed += width
		level += 1
