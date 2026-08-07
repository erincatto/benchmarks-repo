extends "res://framework/bench_case.gd"

## 8,000 boxes dropped into a walled pit: they fall, collide and pile deep, so the measurement is
## dominated by an active contact-heavy pile rather than a settled one. Mirrors the drop test
## godot-box3d publishes. Sized to sit near a 60 FPS budget.
## Set BENCH_DROP_COUNT to sweep the body count.

const BOX := 1.0
const GAP := 1.15
const PIT := 9.2


func build(root: Node) -> void:
	var count := int(OS.get_environment("BENCH_DROP_COUNT"))
	if count <= 0:
		count = 8000
	fixed3(root, Vector3(0, -0.5, 0), box3(Vector3(PIT * 2.0 + 8, 1, PIT * 2.0 + 8)))
	# Walls keep the pile from spreading into a cheap flat layer.
	for s in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var thick := Vector3(1, 80, PIT * 2.0) if s.x != 0 else Vector3(PIT * 2.0, 80, 1)
		fixed3(root, s * (PIT + 0.5) + Vector3(0, 40, 0), box3(thick))
	# Columns of boxes stacked above the pit, so they land into a deep heap.
	var per_side := int(floor(PIT * 2.0 / GAP))
	var origin := -0.5 * (per_side - 1) * GAP
	var placed := 0
	var layer := 0
	while placed < count:
		for ix in per_side:
			for iz in per_side:
				if placed >= count:
					return
				var b := body3(root, Vector3(origin + ix * GAP, 1.0 + layer * GAP, origin + iz * GAP),
					box3(Vector3.ONE * BOX))
				if OS.get_environment("BENCH_DROP_CCD") == "1":
					b.continuous_cd = true
				placed += 1
		layer += 1
