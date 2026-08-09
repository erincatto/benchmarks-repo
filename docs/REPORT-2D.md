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
| **Rapier2D** | **19.47 ms** | 38.84 ms | — |
| Box2D | 24.06 ms | 66.90 ms | 1.24x |
| GodotPhysics2D | 151.83 ms | 242.54 ms | 7.80x |

### `mixed_pile` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_mixed_pile_Rapier2D.png) | ![Box2D](shots/2d_mixed_pile_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **5.91 ms** | 9.69 ms | 0.67x |
| Rapier2D | 8.77 ms | 12.54 ms | — |
| GodotPhysics2D | 64.78 ms | 149.32 ms | 7.38x |

### `joint_grid` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_joint_grid_Rapier2D.png) | ![Box2D](shots/2d_joint_grid_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| GodotPhysics2D | failed | — | — |
| **Box2D** | **3.83 ms** | 4.93 ms | 0.48x |
| Rapier2D | 7.99 ms | 11.65 ms | — |

| engine | `displacement_max` |
|---|---|
| Box2D | inf |
| Rapier2D | 220.7 |

### `smash` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_smash_Rapier2D.png) | ![Box2D](shots/2d_smash_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **11.52 ms** | 27.05 ms | 0.93x |
| Rapier2D | 12.42 ms | 21.36 ms | — |
| GodotPhysics2D | 50.63 ms | 64.15 ms | 4.08x |

| engine | `spread` |
|---|---|
| Box2D | 1.427e+04 |
| GodotPhysics2D | 1.484e+04 |
| Rapier2D | 3449 |

### `query_storm` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_query_storm_Rapier2D.png) | ![Box2D](shots/2d_query_storm_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **4.28 ms** | 16.66 ms | 0.60x |
| Rapier2D | 7.11 ms | 19.76 ms | — |
| GodotPhysics2D | 63.39 ms | 89.14 ms | 8.91x |

| engine | `hits` | `queries` |
|---|---|---|
| Box2D | 280158 | 323100 |
| GodotPhysics2D | 280132 | 323100 |
| Rapier2D | 258360 | 323100 |

### `drop` (2d)

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Rapier2D** | **17.81 ms** | 28.86 ms | — |
| Box2D | 21.10 ms | 41.18 ms | 1.19x |
| GodotPhysics2D | 117.37 ms | 180.69 ms | 6.59x |
