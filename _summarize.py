"""One-line console summary for a finished run."""
import json
import sys

d = json.load(open(sys.argv[1]))
cpu = d.get("cpu", {})
cores, rss = cpu.get("cores_used"), cpu.get("peak_rss_mb")
gmem = d.get("godot_memory_mb", {}).get("static_mb")
print(
    f"p50={d['step_ms']['p50_ms']:.2f}ms"
    f" p99={d['step_ms']['p99_ms']:.2f}ms"
    + (f" cores={cores:.2f}" if cores else "")
    + (f" rss={rss:.0f}MB" if rss else "")
    + (f" gdmem={gmem:.0f}MB" if gmem else "")
    + f" fp={d['fingerprint']}"
)
