#!/usr/bin/env python3
"""#749 启动帧核对（Agent-ID: GROK-BUILD）：读 run_case.sh 的一个或多个录制目录，逐帧对照
第 1 圈第 k 帧 vs 第 2 圈第 k+240 帧的像素差，与 DELTA_LOG 里的 delta / phase 并排输出。只读 /tmp，不改仓库。
用法：python3 analyze_startup.py /tmp/startup749/A_default [/tmp/startup749/B_jitterfix0 ...]
"""
import glob, json, math, os, sys
import numpy as np
from PIL import Image

FPS = 30
PERIOD = 8 * FPS
TAU = 2 * math.pi


def load(p):
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)


def case(d, first_n=30):
    rows = {}
    cfg = None
    for line in open(os.path.join(d, "log.txt"), encoding="utf-8", errors="replace"):
        if line.startswith("DELTA_LOG_CFG "):
            cfg = json.loads(line.split(" ", 1)[1])
        elif line.startswith("DELTA_LOG "):
            r = json.loads(line.split(" ", 1)[1])
            rows[r["frame"]] = r
    files = sorted(glob.glob(os.path.join(d, "frames", "*.png")))
    n = len(files)
    cum = 0.0
    per = []
    first_cycle_max = 0
    differing = []
    for k in range(min(first_n, n - PERIOD)):
        r, r2 = rows[k], rows[k + PERIOD]
        a, b = load(files[k]), load(files[k + PERIOD])
        dd = np.abs(a - b).max(axis=2)
        mx, px = int(dd.max()), int((dd > 0).sum())
        first_cycle_max = max(first_cycle_max, mx)
        if mx:
            differing.append(k)
        dphase = (r2["phase"] - r["phase"] + math.pi) % TAU - math.pi  # 同位帧 phase 差（弧度，按圈取模）
        per.append({"frame": k, "delta": round(r["delta"], 9), "delta_x60": round(r["delta"] * 60, 4),
                    "phase": r["phase"], "phase_plus240": r2["phase"],
                    "phase_diff_rad": float("%.3e" % dphase),
                    "time_lag_vs_cycle2_ms": round(dphase / (TAU / 8) * 1000, 4),
                    "physics_frames": r["physics_frames"],
                    "px_max_diff_vs_k240": mx, "px_changed_vs_k240": px})
    deltas = [rows[k]["delta"] for k in sorted(rows)]
    nonuniform = [k for k, v in enumerate(deltas) if abs(v - 1 / FPS) > 1e-9]
    drift = sum(deltas[:n]) - n / FPS
    return {"dir": d, "cfg": cfg, "frames": n, "logged": len(rows),
            "nonuniform_delta_frames": nonuniform,
            "total_time_drift_s": round(drift, 9),
            "first_cycle_max_diff": first_cycle_max, "first_cycle_frames_differing": differing,
            "per_frame": per}


if __name__ == "__main__":
    out = [case(d) for d in sys.argv[1:]]
    for c in out:
        print("STARTUP_CASE " + json.dumps({k: v for k, v in c.items() if k != "per_frame"}, ensure_ascii=False))
        for p in c["per_frame"][:8]:
            print("   ", json.dumps(p))
    json.dump(out, open(os.environ.get("STARTUP_JSON", "/tmp/startup749/startup_cases.json"), "w"), indent=1)
