extends "res://framework/bench_case.gd"

## 8,000 boxes dropped into a walled pit: they fall, collide and pile deep, so the measurement is
## dominated by an active contact-heavy pile rather than a settled one.
## Sized to sit near a 60 FPS budget. Timings vary noticeably run to run: the falling
## phase dominates and small packing differences change it, so treat the median as
## indicative rather than tuned.
## Set BENCH_DROP_COUNT to sweep the body count.

const BOX := 20.0
const GAP := 22.0
const COLS := 120



func build(root: Node) -> void:
	var count := int(OS.get_environment("BENCH_DROP_COUNT"))
	if count <= 0:
		count = 8000
	var cols := int(OS.get_environment("BENCH_DROP_COLS")) if OS.get_environment("BENCH_DROP_COLS") != "" else COLS
	var half := 0.5 * cols * GAP
	fixed(root, Vector2(0, 20), rect(Vector2(cols * GAP + 80, 40)))
	fixed(root, Vector2(-half - 20, -600), rect(Vector2(40, 1400)))
	fixed(root, Vector2(half + 20, -600), rect(Vector2(40, 1400)))
	var origin := -0.5 * (cols - 1) * GAP
	var placed := 0
	var row := 0
	while placed < count:
		for col in cols:
			if placed >= count:
				return
			body(root, Vector2(origin + col * GAP, -40.0 - row * GAP), rect(Vector2(BOX, BOX)))
			placed += 1
		row += 1
