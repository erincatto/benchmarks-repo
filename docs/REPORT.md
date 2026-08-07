# Godot physics engine benchmark

Godot 4.7-stable (official) · 240 timed steps · 60 Hz · single run · lower is better.

## 2D (lower is better)

![2d step time](chart_2d.png)

![2d relative](chart_2d_rel.png)

### `drop` (2d)

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Rapier2D** | **20.85 ms** | 33.23 ms | — |
| Box2D | 25.61 ms | 48.95 ms | 1.23x |
