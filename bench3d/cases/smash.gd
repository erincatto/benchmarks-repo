extends "res://framework/bench_case.gd"

## A heavy fast projectile into a 25x25x8 wall of 5,000 boxes, placed exactly touching. Impact
## rather than steady state: one frame goes from a quiet island to thousands of simultaneous
## high-energy contacts. Impulse magnitudes here are far outside what the other cases
## produce, which is where an unstable solver either explodes or quietly absorbs energy.
##
## spread tells damping-it-away apart from resolving it; non_finite catches divergence.

const COLUMNS := 25
const ROWS := 25
const DEPTH := 8
const BOX := 1.0

var _centre := Vector3.ZERO


func build(root: Node) -> void:
	fixed3(root, Vector3(0, -0.5, 0), box3(Vector3(400, 1, 400)))
	var ox := -0.5 * (COLUMNS - 1) * BOX
	var oz := -0.5 * (DEPTH - 1) * BOX
	var sum := Vector3.ZERO
	for col in COLUMNS:
		for row in ROWS:
			for layer in DEPTH:
				var at := Vector3(ox + col * BOX, BOX * (0.5 + row), oz + layer * BOX)
				body3(root, at, box3(Vector3.ONE * BOX))
				sum += at
	_centre = sum / bodies.size()

	var shot := body3(root, Vector3(ox - 30, ROWS * BOX * 0.5, 0), sphere3(1.6))
	shot.mass = 800.0
	shot.gravity_scale = 0.0
	shot.continuous_cd = true
	shot.linear_velocity = Vector3(120, 0, 0)


func extra_metrics() -> Dictionary:
	var spread := 0.0
	var non_finite := 0
	for b in bodies:
		var p := (b as Node3D).position
		if is_finite(p.x) and is_finite(p.y) and is_finite(p.z):
			spread = maxf(spread, p.distance_to(_centre))
		else:
			non_finite += 1
	return {"spread": spread, "non_finite": non_finite}


func settle_ticks() -> int:
	return 90
