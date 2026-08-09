# Godot physics engine benchmark

Godot 4.7-stable (official) · 300 timed steps · 60 Hz · single run · lower is better.

## 2D (lower is better)

![2d step time](chart_2d.png)

![2d relative](chart_2d_rel.png)

### `pyramid` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_pyramid_Rapier2D.png) | ![Box2D](shots/2d_pyramid_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Rapier2D** | **19.00 ms** | 25.80 ms | — |
| Box2D | 20.08 ms | 39.74 ms | 1.06x |
