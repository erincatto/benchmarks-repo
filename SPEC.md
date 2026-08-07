# Benchmark method

What each case isolates, how timing is measured, and the caveats that qualify every number here.

---

## 1. Harness

### 1.1 Layout

```
benchmarks/
  framework/          shared by both projects via symlink
    bench_main.gd     headless entry point: one case, one run, one JSON file
    bench_case.gd     case base class + terse body/shape builders
    stats.gd          percentiles + fingerprint
    launcher.gd       menu: pick engine and case, run it on screen
    viewer.gd         runs a case with a framed camera and live HUD
    visualize.gd      MultiMesh renderer for collision shapes
  bench2d/            Godot project — Rapier2D, Box2D, GodotPhysics2D
    main.tscn         launcher (main scene)
    bench.tscn        headless runner, named explicitly by run_bench.sh
    cases/*.gd
    addons/godot-rapier2d, addons/godot-box2d-v3
  bench3d/            Godot project — Rapier3D, Jolt Physics, GodotPhysics3D
  run_bench.sh        driver
  make_report.py      aggregation → docs/REPORT.md
  docs/               generated report, per-case screenshots, chart
```

Two projects rather than one because the Rapier 2D and 3D builds are separate libraries of
the same crate; keeping them apart avoids any question of both registering into one project.

### 1.2 Why the tracks differ

Jolt is 3D-only and Box2D is 2D-only, so there is no single three-way comparison. Each track
compares Rapier against the strongest available competitor plus the built-in Godot server as
a common reference point.

### 1.3 Cases

Fourteen per dimension, mirroring the categories the established suites cover (Box2D v3's
samples, Rapier's testbed stress scenes, Jolt's performance tests), chosen so that a win in
one does not imply a win in another. Body counts below are 2D; 3D is comparable.

**Solver and stacking**

| case | bodies | what it isolates |
|---|---:|---|
| `pyramid` | 3600 | constraint solver on one large stack, boxes placed exactly touching so it starts from resting contact. Box-box only — the pair every engine special-cases. |
| `many_pyramids` | 3780 | the same work split across 36 islands. Read against `pyramid`, it separates parallel island scaling from per-constraint cost. |
| `stack_stability` | 3320 | **how high a stack survives.** Towers ramp 20→400 boxes; `tallest_stable` is the tallest still standing. Quality, not speed. |

**Narrow phase**

| case | bodies | what it isolates |
|---|---:|---|
| `mixed_pile` | 4000 | every shape pair the engines share, including a real convex polygon that defeats box and circle fast paths. |
| `compound` | 2500 | multi-shape bodies: 7500 broad-phase proxies over 2500 islands, so "body" and "collider" stop being interchangeable. |

**Constraints**

| case | bodies | what it isolates |
|---|---:|---|
| `joint_grid` | 1024 | a wide, *cyclic* joint lattice (~2000 joints). Contact solving barely runs. `displacement_max` catches joints that silently failed to bind. |
| `joint_chains` | 1500 | narrow and *deep* — 60 chains 25 constraints long, the hard shape for an iterative solver. `stretch_max` exposes a fast-but-soft solver. |

**Agitation and impact**

| case | bodies | what it isolates |
|---|---:|---|
| `tumbler` | 3000 | a rotating kinematic drum. Nothing settles, contacts turn over completely, and a kinematic body meets thousands of dynamic ones. |
| `smash` | 2401 | a heavy fast projectile into a wall of boxes: thousands of simultaneous high-energy contacts in one frame. `spread` and `non_finite` keep "damped it away" from reading as speed. |

**Everything that is not the solver**

| case | bodies | what it isolates |
|---|---:|---|
| `query_storm` | 1000 dyn + 4000 static | the acceleration structure: 900 ray/shape/point queries per tick. An engine can win `pyramid` and lose here. |
| `ccd_bullets` | 1000 | continuous collision detection; `tunnelled` reports the failure CCD exists to prevent. |
| `contact_heavy` | 3000 | contact *reporting*, separate from solving: `contact_monitor` on with real signal handlers. This is the path §2 optimizes. |
| `spawn_despawn` | 2120 | body lifecycle — allocation, RID bookkeeping, broad-phase insert/remove — with `free()` so the cost lands inside the timed tick. |
| `sleep_settle` | 4000 | the sleep heuristic, the one case with sleeping **on**. `asleep` guards against a fast time that only means the run never settled. |

Each case seeds its RNG from its own name, so every engine simulates a bit-identical world.
Pile cases place bodies on a jittered lattice rather than at uniform random, because randomly
scattered bodies start deeply interpenetrating and the opening ticks then measure untangling
a soup — pathological, and not what any case is meant to isolate.

#### 1.3.1 Quality metrics

`stack_stability`, `joint_chains` and `smash` report correctness alongside time, because for
those the interesting failure is silent: a solver can be fast *because* it is sloppy.

| metric | case | meaning |
|---|---|---|
| `tallest_stable` | `stack_stability` | boxes in the tallest tower still standing |
| `drift_max` | `stack_stability` | furthest a box slid horizontally from where it was placed |
| `sink_max` | `stack_stability` | deepest a box sank below where it was placed (interpenetration) |
| `toppled` | `stack_stability` | boxes tilted past 20° |
| `stretch_max` | `joint_chains` | worst link separation as a fraction of rest length |
| `spread` / `non_finite` | `smash` | how far debris travelled; count of bodies that diverged |
| `tunnelled` | `ccd_bullets` | bullets that passed through a wall they should have hit |
| `asleep` | `sleep_settle` | bodies asleep at the end of the run |

### 1.4 Metric

**`step_ms`: wall time between consecutive physics ticks**, reported as median-of-repeats of
each run's p50, with p99 alongside.

Runs are `--headless --fixed-fps 60` with `max_physics_steps_per_frame=1`. Headless does no
rendering and `--fixed-fps` decouples the loop from real time, so the loop runs flat out at
exactly one physics tick per iteration. `step_ms` is therefore the physics step plus a small
constant of engine overhead — and critically it is measured the same way for every engine.

Godot's own `TIME_PHYSICS_PROCESS` monitor is recorded as `physics_monitor_ms` but is **not**
the headline: it refreshes per rendered frame, so headless runs see it read 0 on some ticks
and double on others. It is a trend cross-check, not a ranking input.

Across repeats the report takes the **median**, so one repeat disturbed by other load on the
machine does not move the headline.

### 1.5 Isolation

One process per (engine, case, repeat). A previous run cannot leave a warm allocator, a
populated broad-phase or a grown island behind to flatter the next, and a crash costs one
data point rather than the sweep.

### 1.6 Engine selection, and the trap it hides

Godot reads `physics/{2d,3d}/physics_engine` once at startup and offers no CLI flag, so the
driver writes an `override.cfg` before each launch.

**When that setting names an engine Godot cannot find, it falls back to the default server
silently — no error, no warning.** A sweep can therefore produce a complete, plausible table
in which "Box2D" is really Godot Physics measured twice. This was not hypothetical: the first
three-way run of this harness returned one identical fingerprint for all three engines,
because a never-opened project has no `.godot/extension_list.cfg` and so loads no
GDExtension at all.

Two independent guards:

- **Pre-flight.** Registered engines appear in the `physics_engine` setting's property hint.
  The driver reads the hint and refuses to start if a requested engine is absent.
- **Fingerprint.** Each run hashes the final quantized pose of every body (32-bit FNV-1a,
  0.01 quantum). Different engines diverge long before that quantum, so within a case each
  engine must produce a *distinct* fingerprint. `make_report.py` flags any collision as
  invalid, and also flags an engine whose own repeats disagree.

The report states explicitly when neither guard fired.

### 1.7 Running

```bash
cd benchmarks
./run_bench.sh                       # full sweep: both tracks, 900 steps, 3 repeats
./run_bench.sh --dim 2d --repeats 1  # quick
```

A fresh checkout needs each project imported once; `run_bench.sh` does this automatically
when `.godot/extension_list.cfg` is missing. The first import on a fresh project can abort
after writing that file, which is why it imports twice.

---

## 2. Build configuration of the engines compared

| engine | build |
|---|---|
| Rapier 2D/3D | `cargo build --release`, features `single-dim{2,3},serde-serialize,parallel,register-docs,api-4-7`; `lto="fat"`, `codegen-units=1`. Rapier at dimforge master `b369e9d7`. |
| Box2D v3 | `Pizzaandy/godot-box2d-v3` at `a2961e3`, unmodified, `scons target=template_release arch=arm64`. |
| Jolt | Built into Godot 4.7 stable. |
| Godot Physics 2D/3D | Built into Godot 4.7 stable. |

Host: Godot 4.7.stable.official, macOS arm64.

### Caveats that belong next to any published number

- **Threading differs by engine and is not normalized.** Rapier is built with `parallel`
  (its shipping configuration); Godot Physics 2D is single-threaded; Jolt and Box2D v3 run in
  whatever configuration they default to here. The comparison is therefore *shipping config
  vs shipping config*, which is what a user gets — not a like-for-like single-threaded
  measurement. A serial-Rapier variant would be needed to separate algorithmic wins from
  parallelism, and has not been run.
- **Box2D v3 is dormant.** Last commit 2025-05-14; its only release predates Godot 4.7. It is
  built against its own pinned godot-cpp 4.3 and loaded into 4.7 through GDExtension forward
  compatibility. Building it against godot-cpp master was attempted and abandoned: it needs
  two API ports, one of them semantic (Godot 4.7 added a direction parameter to one-way
  collision), and implementing that would mean modifying the competitor rather than measuring
  it. No benchmark case uses one-way collision.
- **The profiling build is not the benchmarked build.** `profiling` adds `Instant::now()`
  instrumentation, so the headline Rapier numbers come from a build without it; the
  `rapier/*` phase breakdown requires a separate run.
- Single host, single OS, single CPU architecture. Nothing here predicts relative performance
  on x86_64, mobile, or web.

---

## 3. Repository layout

Feasible, and comfortably inside GitHub's limits. Measured payload:

| component | per platform | notes |
|---|---:|---|
| godot-rapier2d | ~8.3 MB | macOS dylib measured; Linux/Windows are comparable |
| godot-rapier3d | ~9.0 MB | |
| godot-box2d-v3 | ~0.6 MB | |
| cases, framework, projects | <1 MB | text |

Three desktop platforms (macOS, Linux x86_64, Windows x86_64) for all three addons comes to
roughly **55 MB** — under the 100 MB mark, and no single file is anywhere near GitHub's
100 MB per-file hard limit. Shipping *every* platform Rapier releases (Android, iOS, web,
ARM variants) is what pushes it up: the official all-platform zips are 40–47 MB each for 2D
and 3D separately, so an everything-included repo lands near 100 MB. That still clones, but
it is the point where trimming to desktop-only is the better trade.

Jolt and Godot Physics need nothing shipped — both are built into Godot 4.4+.

What a standalone repo needs beyond a copy of `benchmarks/`:

- `bench2d/addons/` and `bench3d/addons/` committed rather than built, with a
  `.gdextension` per addon listing the platforms actually shipped;
- `.godot/extension_list.cfg` **not** committed (it is generated) — `run_bench.sh` already
  imports on first run, which is what creates it;
- a note that Rapier's own addon is a release build with `parallel`, since that is what the
  numbers describe.

Not created here: making a new public repository is a call for the maintainer, not something
this harness should do on its own.
