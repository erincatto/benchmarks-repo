extends "res://framework/bench_case.gd"

## A heavy fast projectile into a 100x50 wall of 5,000 boxes, placed exactly touching. Impact
## rather than steady state: one frame goes from a quiet island to thousands of simultaneous
## high-energy contacts, and the shock front then propagates. Impulse magnitudes here are far
## outside what the other cases produce, which is where an unstable solver either explodes or
## quietly absorbs energy it should have transferred.
##
## spread tells damping-it-away apart from resolving it; non_finite catches divergence.

const COLUMNS := 100
const ROWS := 50
const BOX := 20.0

var _centre := Vector2.ZERO


func build(root: Node) -> void:
	fixed(root, Vector2(0, 20), rect(Vector2(8000, 40)))
	var origin := -0.5 * (COLUMNS - 1) * BOX
	var sum := Vector2.ZERO
	for col in COLUMNS:
		for row in ROWS:
			var at := Vector2(origin + col * BOX, -BOX * (0.5 + row))
			body(root, at, rect(Vector2(BOX, BOX)))
			sum += at
	_centre = sum / bodies.size()

	var shot := body(root, Vector2(origin - 900, -ROWS * BOX * 0.5), circle(40))
	shot.mass = 800.0
	shot.gravity_scale = 0.0
	shot.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	shot.linear_velocity = Vector2(4000, 0)


func extra_metrics() -> Dictionary:
	var spread := 0.0
	var non_finite := 0
	for b in bodies:
		var p := (b as Node2D).position
		if is_finite(p.x) and is_finite(p.y):
			spread = maxf(spread, p.distance_to(_centre))
		else:
			non_finite += 1
	return {"spread": spread, "non_finite": non_finite}


func settle_ticks() -> int:
	return 90
