extends Node

## Runs one case, once, then writes a JSON result and quits. One case per process, so an
## earlier run cannot leave a warm allocator or grown island behind to flatter the next.
##
## `step_ms` is wall time between physics ticks. Under `--headless --fixed-fps 60` with
## `max_physics_steps_per_frame=1` nothing renders and there is exactly one tick per main-loop
## iteration, so it is the physics step plus a small constant, measured the same way for every
## engine — which Godot's own per-frame monitors are not.
##
##   godot --headless --fixed-fps 60 --path <project> bench.tscn -- \
##       --case=pyramid --steps=900 --warmup=120 --out=result.json --engine-label=Rapier2D

const Stats := preload("res://framework/stats.gd")

const DEFAULT_STEPS := 900
const DEFAULT_WARMUP := 120

var _case: RefCounted
var _case_name := ""
var _engine_label := ""
var _out_path := ""
var _steps := DEFAULT_STEPS
var _warmup := DEFAULT_WARMUP

var _tick := 0
var _physics_ms := PackedFloat64Array()
var _step_ms := PackedFloat64Array()
var _last_tick_usec := 0
var _run_start_usec := 0
var _custom_monitor_totals: Dictionary = {}
var _custom_monitor_samples := 0


func _ready() -> void:
	var args := _parse_args()
	_case_name = args.get("case", "")
	_engine_label = args.get("engine-label", "unknown")
	_out_path = args.get("out", "")
	_steps = int(args.get("steps", DEFAULT_STEPS))
	_warmup = int(args.get("warmup", DEFAULT_WARMUP))

	if _case_name.is_empty() or _out_path.is_empty():
		push_error("bench: --case and --out are required")
		get_tree().quit(2)
		return

	var case_path := "res://cases/%s.gd" % _case_name
	if not ResourceLoader.exists(case_path):
		push_error("bench: no such case '%s' (%s)" % [_case_name, case_path])
		get_tree().quit(2)
		return

	# A case that fails to parse loads as null, and without this the runner would spend the
	# whole run calling `step` on nothing, emitting one error per tick and never writing a
	# result — which reads from the outside like the engine being pathologically slow rather
	# than like a broken case.
	var case_script := load(case_path) as GDScript
	_case = case_script.new() if case_script != null else null
	if _case == null:
		push_error("bench: case '%s' failed to load — see parse errors above" % _case_name)
		get_tree().quit(4)
		return

	# Same seed for every engine, so all three simulate a bit-identical starting world.
	_case.rng_seed(hash(_case_name))
	_case.build(self)

	# A pile case is still falling long after the default warmup, so it declares its own.
	_warmup = maxi(_warmup, _case.settle_ticks())

	_physics_ms.resize(_steps)
	_step_ms.resize(_steps)
	_last_tick_usec = Time.get_ticks_usec()


func _physics_process(_delta: float) -> void:
	# quit() takes effect at the end of the frame, so a failed load still reaches here once.
	if _case == null:
		return
	var now := Time.get_ticks_usec()
	var frame_usec := now - _last_tick_usec
	_last_tick_usec = now

	if _tick == _warmup:
		_run_start_usec = now

	if _tick >= _warmup:
		var sample_index := _tick - _warmup
		if sample_index < _steps:
			_step_ms[sample_index] = frame_usec / 1000.0
			# Secondary and deliberately not the headline: this monitor is only refreshed
			# per rendered frame, so headless runs see it read 0 on some ticks and double on
			# others. Kept for cross-checking the trend, not for ranking engines.
			_physics_ms[sample_index] = (
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			)
			_accumulate_custom_monitors()
		if sample_index >= _steps - 1:
			_finish(now)
			return

	_case.step(_tick, self)
	_tick += 1


## Rapier publishes its internal phase timings as custom monitors under `rapier/*` when built
## with the `profiling` feature. Recorded when present so a regression can be attributed to a
## phase rather than just to the total; absent for the other engines, which is expected.
func _accumulate_custom_monitors() -> void:
	for monitor_name in Performance.get_custom_monitor_names():
		var key := String(monitor_name)
		var value: float = Performance.get_custom_monitor(monitor_name)
		_custom_monitor_totals[key] = _custom_monitor_totals.get(key, 0.0) + value
	_custom_monitor_samples += 1


func _finish(now_usec: int) -> void:
	var wall_s := (now_usec - _run_start_usec) / 1_000_000.0
	var monitor_means: Dictionary = {}
	if _custom_monitor_samples > 0:
		for key in _custom_monitor_totals:
			monitor_means[key] = _custom_monitor_totals[key] / _custom_monitor_samples

	var bodies: Array[Node] = _case.bodies
	var result := {
		"case": _case_name,
		"engine_label": _engine_label,
		"engine_setting_2d": ProjectSettings.get_setting("physics/2d/physics_engine", ""),
		"engine_setting_3d": ProjectSettings.get_setting("physics/3d/physics_engine", ""),
		"godot_version": Engine.get_version_info()["string"],
		"steps": _steps,
		"warmup": _warmup,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"body_count": bodies.size(),
		"work_units": _case.work_units(),
		"extra_metrics": _case.extra_metrics(),
		"fingerprint": Stats.fingerprint(bodies),
		"wall_total_s": wall_s,
		"wall_per_step_ms": (wall_s * 1000.0) / _steps if _steps > 0 else 0.0,
		"step_ms": Stats.summarize(_step_ms),
		"physics_monitor_ms": Stats.summarize(_physics_ms),
		# Godot's own allocator only: a GDExtension engine allocating through its own
		# allocator is invisible here, which is exactly what `cpu.peak_rss_mb` catches.
		"godot_memory_mb": {
			"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			"static_max_mb": Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0,
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		},
		"custom_monitors": monitor_means,
	}

	var file := FileAccess.open(_out_path, FileAccess.WRITE)
	if file == null:
		push_error("bench: cannot write %s (%s)" % [_out_path, FileAccess.get_open_error()])
		get_tree().quit(3)
		return
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	# The result is on disk, so the only thing left is Godot freeing 10k bodies and the
	# physics world one RID at a time — several seconds per run that measure nothing. Exit
	# without it. Safe specifically because the file is closed and flushed above.
	OS.kill(OS.get_process_id())
	get_tree().quit(0)


func _parse_args() -> Dictionary:
	var parsed: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq == -1:
			parsed[body] = "true"
		else:
			parsed[body.left(eq)] = body.substr(eq + 1)
	return parsed
