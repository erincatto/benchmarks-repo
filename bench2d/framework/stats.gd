extends RefCounted

## Percentiles and the run fingerprint.
##
## The fingerprint exists because Godot silently falls back to its default physics server
## when `physics/{2d,3d}/physics_engine` names an engine it cannot find — no error, no
## warning. Two engines reporting the same fingerprint did not both run.


## Nearest-rank percentile over an already-sorted array.
static func percentile(sorted_samples: PackedFloat64Array, q: float) -> float:
	if sorted_samples.is_empty():
		return 0.0
	var idx := int(ceil(q * sorted_samples.size())) - 1
	return sorted_samples[clampi(idx, 0, sorted_samples.size() - 1)]


static func mean(samples: PackedFloat64Array) -> float:
	if samples.is_empty():
		return 0.0
	var total := 0.0
	for s in samples:
		total += s
	return total / samples.size()


static func stddev(samples: PackedFloat64Array, m: float) -> float:
	if samples.size() < 2:
		return 0.0
	var acc := 0.0
	for s in samples:
		acc += (s - m) * (s - m)
	return sqrt(acc / (samples.size() - 1))


static func summarize(samples: PackedFloat64Array) -> Dictionary:
	var sorted_samples := samples.duplicate()
	sorted_samples.sort()
	var m := mean(sorted_samples)
	return {
		"count": sorted_samples.size(),
		"mean_ms": m,
		"stddev_ms": stddev(sorted_samples, m),
		"min_ms": sorted_samples[0] if not sorted_samples.is_empty() else 0.0,
		"p50_ms": percentile(sorted_samples, 0.50),
		"p95_ms": percentile(sorted_samples, 0.95),
		"p99_ms": percentile(sorted_samples, 0.99),
		"max_ms": sorted_samples[-1] if not sorted_samples.is_empty() else 0.0,
	}


## Quantized so that a solver whose last bits differ between repeats still fingerprints the
## same, while genuinely different engines — which diverge far faster than this — do not.
const FINGERPRINT_QUANTUM := 0.01


static func fingerprint(bodies: Array[Node]) -> String:
	# 32-bit FNV-1a. The 64-bit variant's constants exceed GDScript's signed int range, and
	# 32 bits is ample to tell three engines apart.
	var hash_value := 2166136261
	for body in bodies:
		if not is_instance_valid(body):
			continue
		var components: Array[float] = []
		if body is Node2D:
			var p2: Vector2 = (body as Node2D).global_position
			components = [p2.x, p2.y, (body as Node2D).global_rotation]
		elif body is Node3D:
			var p3: Vector3 = (body as Node3D).global_position
			components = [p3.x, p3.y, p3.z]
		for c in components:
			# Non-finite values collapse to a sentinel so a NaN-producing engine still
			# fingerprints deterministically instead of hashing garbage.
			var q := 0x7fffffff if not is_finite(c) else int(round(c / FINGERPRINT_QUANTUM))
			for byte_index in 8:
				hash_value ^= (q >> (byte_index * 8)) & 0xff
				# Masked every round, so the product never leaves signed-64 range and the
				# result does not depend on overflow behaviour.
				hash_value = (hash_value * 16777619) & 0xffffffff
	return "%08x" % hash_value
