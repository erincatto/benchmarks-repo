extends Node

## Runs one case on screen with a framed camera and a live HUD, using the same case scripts
## the headless runner uses.
##
## Timings here are not comparable to the report: this window renders and runs unbounded.

const Visualize := preload("res://framework/visualize.gd")
const Stats := preload("res://framework/stats.gd")

const WINDOW := 180
const FRAME_MARGIN := 1.25

var case_name := "pyramid"
var debug_draw := true
## When set, the viewer saves a PNG and quits — once the scene has settled, or at `shot_tick`
## if it never does. Cases like the tumbler never settle, so the cap is what stops them.
var shot_path := ""
var shot_tick := 600
## Steady-state cases never settle and their frames are expensive; tick 600 looks identical
## to tick 200, so a real-time cap stops them without losing anything.
var shot_seconds := 7.0
## Comparison shots must land on the same simulated tick for every engine, or the images show
## different moments and nothing can be read from them. Settling and the wall clock are both
## frame-rate dependent — a fast-rendering engine settles before a slow one reaches the cap —
## so `--shot-exact` disables both and stops precisely at `shot_tick`.
var shot_exact := false
## Ticks to simulate before stopping, so a case does not run until you close the window.
## Physics stops but the scene stays on screen, with the final metrics still on the HUD.
## 0 runs indefinitely.
var max_ticks := 1800

## Wall-clock cut for recording. Ticks are useless there: a slow engine takes far longer to
## reach the same tick, so clips would differ in length. 0 disables.
var max_seconds := 0.0

var _case: RefCounted
var _dim := "2d"
var _tick := 0
var _paused := false
var _finished := false
var _calm := 0
var _started_usec := 0
var _samples := PackedFloat64Array()
var _last_usec := 0
var _hud: Label
var _camera_2d: Camera2D
var _camera_3d: Camera3D
var _renderer: Node


func _ready() -> void:
	_dim = str(ProjectSettings.get_setting("application/config/bench_dim", "2d"))

	var case_script := load("res://cases/%s.gd" % case_name) as GDScript
	if case_script == null:
		_fail("case '%s' failed to load" % case_name)
		return
	_case = case_script.new()
	_case.rng_seed(hash(case_name))
	_case.build(self)

	_renderer = Visualize.new()
	add_child(_renderer)
	_renderer.build(self, _dim)
	_renderer.set_enabled(debug_draw)
	_build_hud()
	_build_title()
	_frame_camera()
	_last_usec = Time.get_ticks_usec()
	_started_usec = _last_usec


func _physics_process(_delta: float) -> void:
	if _case == null or _paused or _finished:
		return
	var over_time := (
		max_seconds > 0.0
		and (Time.get_ticks_usec() - _started_usec) / 1_000_000.0 >= max_seconds
	)
	if (max_ticks > 0 and _tick >= max_ticks) or over_time:
		_finished = true
		_update_hud()
		case_finished.emit(case_name)
		return
	var now := Time.get_ticks_usec()
	_samples.append((now - _last_usec) / 1000.0)
	if _samples.size() > WINDOW:
		_samples = _samples.slice(_samples.size() - WINDOW)
	_last_usec = now

	_case.step(_tick, self)
	_tick += 1
	if _tick % 10 == 0:
		_update_hud()
	if shot_path == "":
		return
	if shot_exact:
		if _tick >= shot_tick:
			_take_shot()
		return
	if _tick >= shot_tick or _settled() or _shot_overdue():
		_take_shot()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://main.tscn")
			KEY_SPACE:
				_paused = not _paused
				_last_usec = Time.get_ticks_usec()
			KEY_R:
				get_tree().reload_current_scene()
			KEY_D:
				# Toggling in place, so the frame-time change from drawing a shape per
				# collider is visible on the HUD immediately.
				debug_draw = not debug_draw
				_renderer.set_enabled(debug_draw)
				_samples.clear()
				_last_usec = Time.get_ticks_usec()
				_update_hud()
	# Wheel zoom, so a case that frames badly is still inspectable.
	if event is InputEventMouseButton and _camera_2d != null:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera_2d.zoom *= 1.1
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera_2d.zoom /= 1.1


## Frames on the bodies the case created, expanded by their own extents so large shapes are
## not clipped, and fitted to the viewport rather than to a fixed distance.
func _frame_camera() -> void:
	var bodies: Array[Node] = _case.bodies
	if bodies.is_empty():
		return

	if _dim == "2d":
		var min_p := Vector2.INF
		var max_p := -Vector2.INF
		for b in bodies:
			if b is Node2D:
				var p := (b as Node2D).global_position
				min_p = min_p.min(p)
				max_p = max_p.max(p)
		var centre := (min_p + max_p) * 0.5
		var extent := (max_p - min_p) + Vector2.ONE * _typical_size() * 4.0
		var view := get_viewport().get_visible_rect().size
		var zoom := minf(view.x / maxf(extent.x, 1.0), view.y / maxf(extent.y, 1.0)) / FRAME_MARGIN
		_camera_2d = Camera2D.new()
		_camera_2d.position = centre
		_camera_2d.zoom = Vector2(zoom, zoom)
		add_child(_camera_2d)
		_camera_2d.make_current()
		return

	var min3 := Vector3.INF
	var max3 := -Vector3.INF
	for b in bodies:
		if b is Node3D:
			var p := (b as Node3D).global_position
			min3 = min3.min(p)
			max3 = max3.max(p)
	var pad := _typical_size() * 2.0
	min3 -= Vector3.ONE * pad
	max3 += Vector3.ONE * pad
	var centre3 := (min3 + max3) * 0.5
	var radius := maxf((max3 - min3).length() * 0.5, 1.0)

	_camera_3d = Camera3D.new()
	_camera_3d.far = radius * 20.0
	# Fit the bounding sphere to the vertical field of view.
	var distance := radius / tan(deg_to_rad(_camera_3d.fov) * 0.5) * FRAME_MARGIN
	var direction := Vector3(0.7, 0.45, 1.0).normalized()
	add_child(_camera_3d)
	_camera_3d.look_at_from_position(centre3 + direction * distance, centre3, Vector3.UP)
	_camera_3d.current = true

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-35), 0)
	light.light_energy = 1.1
	add_child(light)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.66)
	env.ambient_light_energy = 0.55
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


## Median-ish body extent, used to pad the framing so bodies at the edge are not half cut.
func _typical_size() -> float:
	for b in _case.bodies:
		for child in b.get_children():
			if child is CollisionShape2D and (child as CollisionShape2D).shape != null:
				return (child as CollisionShape2D).shape.get_rect().size.length()
			if child is CollisionShape3D and (child as CollisionShape3D).shape != null:
				return (child as CollisionShape3D).shape.get_debug_mesh().get_aabb().size.length()
	return 1.0


signal case_finished(name: String)


## Large engine + case caption, legible in a screen recording where the corner HUD is not.
func _build_title() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position = Vector2(0, 18)
	layer.add_child(box)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "%s  —  %s" % [
		str(ProjectSettings.get_setting("physics/%s/physics_engine" % _dim, "DEFAULT")),
		case_name.capitalize(),
	]
	box.add_child(label)
	await get_tree().process_frame
	box.position = Vector2((get_viewport().get_visible_rect().size.x - box.size.x) * 0.5, 18)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	layer.add_child(panel)
	_hud = Label.new()
	_hud.add_theme_constant_override("line_spacing", 2)
	panel.add_child(_hud)
	_update_hud()


func _update_hud() -> void:
	if _hud == null:
		return
	var engine_setting := str(
		ProjectSettings.get_setting("physics/%s/physics_engine" % _dim, "DEFAULT")
	)
	var sorted := _samples.duplicate()
	sorted.sort()
	var lines := [
		"engine   %s" % engine_setting,
		"case     %s" % case_name,
		"bodies   %d" % _case.bodies.size(),
		"tick     %d / %s%s" % [_tick, max_ticks if max_ticks > 0 else "\u221e", _state_suffix()],
	]
	if not shot_exact:
		lines.append(
			"frame    p50 %.2f ms   p99 %.2f ms"
			% [Stats.percentile(sorted, 0.5), Stats.percentile(sorted, 0.99)]
		)
		lines.append("fps      %d" % Engine.get_frames_per_second())
	var extra: Dictionary = _case.extra_metrics()
	for key in extra:
		var value = extra[key]
		lines.append("%s %s" % [key.rpad(14), _short(value)])
	lines.append("")
	lines.append(
		"[esc] menu  [space] pause  [r] restart  [d] debug draw: %s"
		% ("on" if debug_draw else "off")
	)
	_hud.text = "\n".join(lines)


func _shot_overdue() -> bool:
	return (Time.get_ticks_usec() - _started_usec) / 1_000_000.0 > shot_seconds


## Settled means the mean speed has stayed under a fraction of a body-width per second for
## three consecutive samples. Sampling rather than checking every tick keeps the cost off the
## timed path, and requiring three in a row avoids firing on a momentary lull mid-collapse.
func _settled() -> bool:
	if _tick < 90 or _tick % 15 != 0:
		return false
	var total := 0.0
	var count := 0
	for b in _case.bodies:
		if not is_instance_valid(b):
			continue
		if b is RigidBody2D:
			total += (b as RigidBody2D).linear_velocity.length()
			count += 1
		elif b is RigidBody3D:
			total += (b as RigidBody3D).linear_velocity.length()
			count += 1
	if count == 0:
		return false
	if total / count < _typical_size() * 0.15:
		_calm += 1
	else:
		_calm = 0
	return _calm >= 3


## GDScript's % has no %g, so compact float formatting is done by hand.
func _short(value) -> String:
	if value is float:
		return "%.3f" % value if absf(value) < 1000.0 else "%.0f" % value
	return str(value)


func _state_suffix() -> String:
	if _finished:
		return "  (finished)"
	return "  (paused)" if _paused else ""


func _fail(message: String) -> void:
	push_error("viewer: " + message)
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "%s\n\n[esc] menu" % message
	label.position = Vector2(20, 20)
	layer.add_child(label)


func _take_shot() -> void:
	# The viewport texture is only valid once the frame has actually been drawn.
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(shot_path)
	if error != OK:
		push_error("viewer: could not write %s (%d)" % [shot_path, error])
		get_tree().quit(5)
		return
	# Same reason as the runner: the PNG is written, so skip tearing down the world.
	OS.kill(OS.get_process_id())
	get_tree().quit(0)
