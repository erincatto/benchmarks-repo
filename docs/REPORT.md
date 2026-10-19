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
## 3D (lower is better)

![3d step time](chart_3d.png)

![3d relative](chart_3d_rel.png)

### `pyramid` (3d)

| Rapier3D | Jolt Physics |
|---|---|
| ![Rapier3D](shots/3d_pyramid_Rapier3D.png) | ![Jolt Physics](shots/3d_pyramid_Jolt_Physics.png) |

| engine | step p50 | step p99 | vs Rapier3D |
|---|---:|---:|---:|
| **Rapier3D** | **24.90 ms** | 34.05 ms | — |
| Box3D Physics | 28.18 ms | 46.73 ms | 1.13x |
| Jolt Physics | 30.09 ms | 38.79 ms | 1.21x |
| GodotPhysics3D | 40.91 ms | 129.65 ms | 1.64x |

### `mixed_pile` (3d)

| Rapier3D | Jolt Physics |
|---|---|
| ![Rapier3D](shots/3d_mixed_pile_Rapier3D.png) | ![Jolt Physics](shots/3d_mixed_pile_Jolt_Physics.png) |

| engine | step p50 | step p99 | vs Rapier3D |
|---|---:|---:|---:|
| **Rapier3D** | **11.68 ms** | 19.98 ms | — |
| Jolt Physics | 13.31 ms | 70.03 ms | 1.14x |
| Box3D Physics | 14.13 ms | 18.11 ms | 1.21x |
| GodotPhysics3D | 81.32 ms | 135.91 ms | 6.96x |

### `joint_grid` (3d)

| Rapier3D |
|---|
| ![Rapier3D](shots/3d_joint_grid_Rapier3D.png) |

| engine | step p50 | step p99 | vs Rapier3D |
|---|---:|---:|---:|
| Jolt Physics | failed | — | — |
| **Rapier3D** | **11.55 ms** | 43.15 ms | — |
| Box3D Physics | 11.75 ms | 20.35 ms | 1.02x |
| GodotPhysics3D | 26.21 ms | 47.85 ms | 2.27x |

| engine | `displacement_max` |
|---|---|
| Box3D Physics | — |
| GodotPhysics3D | 40.65 |
| Rapier3D | 25.58 |

### `smash` (3d)

| Rapier3D | Jolt Physics |
|---|---|
| ![Rapier3D](shots/3d_smash_Rapier3D.png) | ![Jolt Physics](shots/3d_smash_Jolt_Physics.png) |

| engine | step p50 | step p99 | vs Rapier3D |
|---|---:|---:|---:|
| **Jolt Physics** | **12.16 ms** | 33.86 ms | 0.54x |
| Box3D Physics | 20.45 ms | 36.94 ms | 0.90x |
| Rapier3D | 22.69 ms | 54.84 ms | — |
| GodotPhysics3D | 93.62 ms | 128.10 ms | 4.13x |

| engine | `spread` |
|---|---|
| Box3D Physics | 422.2 |
| GodotPhysics3D | 140.6 |
| Jolt Physics | 280.3 |
| Rapier3D | 189.3 |

### `query_storm` (3d)

| Rapier3D | Jolt Physics |
|---|---|
| ![Rapier3D](shots/3d_query_storm_Rapier3D.png) | ![Jolt Physics](shots/3d_query_storm_Jolt_Physics.png) |

| engine | step p50 | step p99 | vs Rapier3D |
|---|---:|---:|---:|
| **Rapier3D** | **7.11 ms** | 10.48 ms | — |
| Box3D Physics | 7.29 ms | 13.15 ms | 1.02x |
| Jolt Physics | 22.97 ms | 38.79 ms | 3.23x |
| GodotPhysics3D | 62.21 ms | 89.82 ms | 8.75x |

| engine | `hits` | `queries` |
|---|---|---|
| Box3D Physics | 215900 | 269250 |
| GodotPhysics3D | 215893 | 269250 |
| Jolt Physics | 215893 | 269250 |
| Rapier3D | 215792 | 269250 |

### `drop` (3d)

| engine | step p50 | step p99 | vs Rapier3D |
|---|---:|---:|---:|
| GodotPhysics3D | failed | — | — |
| **Box3D Physics** | **12.28 ms** | 15.15 ms | 0.90x |
| Rapier3D | 13.69 ms | 20.35 ms | — |
| Jolt Physics | 21.80 ms | 53.43 ms | 1.59x |
