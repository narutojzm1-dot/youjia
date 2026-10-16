#!/usr/bin/env python3
"""#749 溪流候选：把有损 MP4 的相邻帧差与原 PNG 序列（同一 scale 无损缩放）逐帧对照（仍只是候选，不改生产）。

Agent-ID: GROK-BUILD
用途：区分 MP4 里的相邻帧差峰是编码（关键帧刷新）造成，还是渲染本身变化。
- ref：Movie Maker 原 PNG 序列经 ffmpeg 同一 scale 过滤缩到 MP4 尺寸，rgb24 无损。
- mp4：被检 MP4 解码为 rgb24。
- static：在 ref 全 1200 帧里从不变化的像素（水面以外 + 保护区）。
输出每个 MP4 关键帧位置的前后差、ref 同位差、static 区差，以及全片中位/最大。

  python3 verify_mp4_vs_png.py /tmp/mv749full stream_flow_realtime_30fps_40s.mp4 [--json out.json] [--samples DIR --at 249,250]
"""
import argparse, json, subprocess, sys
import numpy as np


def frames(cmd, w, h):
    fs = w * h * 3
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    while True:
        b = p.stdout.read(fs)
        if len(b) < fs:
            break
        yield np.frombuffer(b, np.uint8).reshape(h, w, 3).astype(np.int16)
    p.wait()


def probe(mp4):
    o = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v", "-show_entries", "stream=width,height",
                        "-of", "csv=p=0", mp4], capture_output=True, text=True, check=True).stdout.strip().split(",")
    kf = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v", "-show_entries", "frame=key_frame",
                         "-of", "csv=p=0", mp4], capture_output=True, text=True, check=True).stdout.split()
    return int(o[0]), int(o[1]), [i for i, k in enumerate(kf) if k.strip().startswith("1")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("frames_dir"); ap.add_argument("mp4")
    ap.add_argument("--json"); ap.add_argument("--samples"); ap.add_argument("--at", default="")
    a = ap.parse_args()
    w, h, keys = probe(a.mp4)
    ref_cmd = ["ffmpeg", "-v", "error", "-framerate", "30", "-i", a.frames_dir + "/f%08d.png",
               "-vf", f"scale={w}:{h}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    mp_cmd = ["ffmpeg", "-v", "error", "-i", a.mp4, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    want = set(int(x) for x in a.at.split(",") if x)
    look = set(want)
    for k in keys:
        if k > 0:
            look |= {k - 1, k}
    adj_r, adj_m, keep, static, pr, pm = [], [], {}, None, None, None
    for i, (r, m) in enumerate(zip(frames(ref_cmd, w, h), frames(mp_cmd, w, h))):
        if pr is not None:
            adj_r.append(float(np.abs(r - pr).mean())); adj_m.append(float(np.abs(m - pm).mean()))
            ch = np.any(r != pr, axis=2)
            static = ~ch if static is None else (static & ~ch)
        if i in look:
            keep[i] = (r.copy(), m.copy())
        pr, pm = r, m
    adj_r, adj_m = np.array(adj_r), np.array(adj_m)
    at_keys = []
    for k in keys:
        if k == 0 or k - 1 not in keep:
            continue
        dr = np.abs(keep[k][0] - keep[k - 1][0]); dm = np.abs(keep[k][1] - keep[k - 1][1])
        at_keys.append({"from": k - 1, "to": k, "mp4_adj": round(float(adj_m[k - 1]), 6), "ref_adj": round(float(adj_r[k - 1]), 6),
                        "mp4_static_mean": round(float(dm[static].mean()), 6), "mp4_static_max": int(dm[static].max()),
                        "mp4_static_px_changed": int(np.any(dm > 0, axis=2)[static].sum()),
                        "ref_static_max": int(dr[static].max())})
    out = {"mp4": a.mp4, "size": [w, h], "frames": int(len(adj_m) + 1), "keyframes": keys, "static_px": int(static.sum()),
           "mp4_adj_median": round(float(np.median(adj_m)), 6), "mp4_adj_max": round(float(adj_m.max()), 6),
           "mp4_adj_argmax": [int(adj_m.argmax()), int(adj_m.argmax()) + 1],
           "ref_adj_median": round(float(np.median(adj_r)), 6), "ref_adj_max": round(float(adj_r.max()), 6),
           "ref_adj_argmax": [int(adj_r.argmax()), int(adj_r.argmax()) + 1], "at_keyframes": at_keys}
    print("MP4_VS_PNG " + json.dumps(out, ensure_ascii=False))
    if a.json:
        json.dump(out, open(a.json, "w"), ensure_ascii=False, indent=1)
    if a.samples and want:
        from PIL import Image
        for i in sorted(want):
            if i in keep:
                Image.fromarray(keep[i][0].astype(np.uint8)).save(f"{a.samples}/ref_{i:04d}.png")
                Image.fromarray(keep[i][1].astype(np.uint8)).save(f"{a.samples}/mp4_{i:04d}.png")


if __name__ == "__main__":
    sys.exit(main())
