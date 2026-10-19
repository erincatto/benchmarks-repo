# Godot physics engine benchmark

Godot 4.7.2-stable (official) · 300 timed steps · 60 Hz · single run · lower is better.

## 2D (lower is better)

![2d step time](chart_2d.png)

![2d relative](chart_2d_rel.png)

### `pyramid` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_pyramid_Rapier2D.png) | ![Box2D](shots/2d_pyramid_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **11.56 ms** | 12.96 ms | 0.29x |
| Rapier2D | 40.09 ms | 59.26 ms | — |

### `mixed_pile` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_mixed_pile_Rapier2D.png) | ![Box2D](shots/2d_mixed_pile_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **5.53 ms** | 7.69 ms | 0.35x |
| Rapier2D | 15.87 ms | 21.18 ms | — |

### `joint_grid` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_joint_grid_Rapier2D.png) | ![Box2D](shots/2d_joint_grid_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **4.71 ms** | 7.26 ms | 0.41x |
| Rapier2D | 11.41 ms | 16.31 ms | — |

| engine | `displacement_max` |
|---|---|
| Box2D | 16.51 |
| Rapier2D | 18.59 |

### `smash` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_smash_Rapier2D.png) | ![Box2D](shots/2d_smash_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **5.34 ms** | 7.09 ms | 0.34x |
| Rapier2D | 15.71 ms | 21.52 ms | — |

| engine | `spread` |
|---|---|
| Box2D | 3369 |
| Rapier2D | 6391 |

### `query_storm` (2d)

| Rapier2D | Box2D |
|---|---|
| ![Rapier2D](shots/2d_query_storm_Rapier2D.png) | ![Box2D](shots/2d_query_storm_Box2D.png) |

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **3.35 ms** | 5.21 ms | 0.14x |
| Rapier2D | 23.60 ms | 33.05 ms | — |

| engine | `hits` | `queries` |
|---|---|---|
| Box2D | 280563 | 323100 |
| Rapier2D | 223023 | 323100 |

### `drop` (2d)

| engine | step p50 | step p99 | vs Rapier2D |
|---|---:|---:|---:|
| **Box2D** | **9.43 ms** | 11.52 ms | 0.62x |
| Rapier2D | 15.33 ms | 19.96 ms | — |
