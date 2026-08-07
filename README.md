# Godot physics engine benchmarks

Compares Godot physics extensions on the same scenes, in the same engine build, measured the
same way.

| track | engines |
|---|---|
| **2D** | [Rapier](https://github.com/appsinacup/godot-rapier-physics) · [Box2D v3](https://github.com/Pizzaandy/godot-box2d-v3) |
| **3D** | [Rapier](https://github.com/appsinacup/godot-rapier-physics) · Jolt Physics (built into Godot 4.4+) |

Jolt is 3D-only and Box2D is 2D-only, so there is no single three-way comparison.

**[→ Results](docs/REPORT.md)** · **[→ Method and caveats](SPEC.md)**

## Run it

Addons are committed, so a clone is all you need.

```bash
./run_bench.sh                      # both tracks, writes docs/REPORT.md
./run_bench.sh --dim 2d --cases pyramid
./capture_shots.sh                  # per-engine screenshots at an identical tick
python3 make_pdf.py                 # shareable PDF + self-contained HTML
```

`--with-godot` adds Godot's built-in server as a reference column. It is an order of
magnitude slower at these body counts, which is why it is not in the default path.

## Watch a case

Open `bench2d/` or `bench3d/` in Godot and press play. Pick engine and case from the menu;
switching engine restarts, because Godot reads `physics/{2d,3d}/physics_engine` once at
startup. In the viewer: `esc` menu, `space` pause, `r` restart, `d` toggle shape drawing.

## Cases

| case | 2D bodies | measures |
|---|---:|---|
| `pyramid` | 10,000 | solver throughput, box-box |
| `mixed_pile` | 5,000 | narrow phase: circle, capsule, convex polygon |
| `joint_grid` | 5,000 / ~9,950 joints | constraints |
| `smash` | 5,000 | high-energy impact |
| `query_storm` | 10,000 + 900 queries/tick | acceleration structure |

## Two things to know before quoting a number

**Godot falls back to its default physics server silently** when the configured engine is
missing — no error, no warning, and the resulting table looks perfectly normal. Two guards
run every sweep: a pre-flight check that the requested engines actually registered, and a
per-run fingerprint of the final body poses that must differ between engines. A collision
means one of them was the fallback.

**Timing is CPU time.** A busy machine inflates every figure. `run_bench.sh` records the load
average into `results/environment.json`; if it is a significant fraction of your core count,
the ratios still hold but the milliseconds are not comparable to a run on an idle machine.

## Adding platforms

Only macOS arm64 binaries are committed. For other platforms, drop the matching libraries
into `bench2d/addons/*/bin/` and `bench3d/addons/*/bin/` and extend the `.gdextension` files.
Rapier releases cover every platform; Box2D v3 builds from source with SCons.

## Layout

```
bench2d/  bench3d/    Godot projects: cases/, framework/, addons/
run_bench.sh          sweep driver
capture_shots.sh      per-engine screenshots at a fixed tick
make_report.py        results/ -> docs/REPORT.md + charts
make_pdf.py           REPORT.md -> PDF + self-contained HTML
```

Framework scripts are duplicated in `bench2d/framework/` and `bench3d/framework/` rather than
symlinked, because a git symlink checks out as a text file on Windows. Keep them in sync.
