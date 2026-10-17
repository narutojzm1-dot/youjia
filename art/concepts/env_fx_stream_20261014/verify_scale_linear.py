#!/usr/bin/env python3
"""#749 溪流裁切 demo：Painting 与子层都按线性过滤时，多缩放 × 多相位 × 子像素偏移的边界对照。

Agent-ID: GROK-BUILD
仍只是候选，不改生产文件。只写到 --out 目录。

对照目的（回应 CODEX-LEAD 对 435cc826 的审查）：
  A) 当前默认（base_sample_linear=true）对独立 LINEAR Painting：
     R=减少动态原画；S0=strength0；C(phase)=裁切 demo 默认线性底图。
     判定：S0==R；非水面/矩形外/保护区/矩形边±3 的 C vs R 差 0；
     0 vs TAU 一致；半圈水面有变化；sequence 暂停/减少动态。
     不再把默认 C 与整幅 nearest 预览 F 的水面差当作通过门。
  B) 历史/受控 legacy（同底图 nearest）：
     C_near=--base-nearest；F=整幅 stream_flow_preview（base_tex nearest）。
     硬门只在 scale=1.0 且整数偏移（历史 1:1 对照条件）；其他变换只汇报，
     因为整幅预览 Sprite 仍 nearest，而裁切 demo Painting/子层是 LINEAR，
     分数缩放下的差来自 Sprite 过滤，不是 base_sample_linear 判据。

每个 (scale, offset) 另报：
  NZ = strength 1e-4 + --base-nearest（纹素中心底图 vs 线性 Painting）
  NL = strength 1e-4 默认线性底图（连续 UV vs 线性 Painting）

用法（仓库根，需显示器或 xvfb-run）：
  GODOT=/path/to/godot xvfb-run -a -s "-screen 0 1800x1000x24" \\
    python3 art/concepts/env_fx_stream_20261014/verify_scale_linear.py --out /tmp/scale749
"""
import argparse
import math
import os
import subprocess
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, "godot_preview")
TEX = os.path.join(PROJ, "textures")
X, Y, W, H = 191, 543, 183, 302
VW, VH = 1672, 941
PHASES = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2, math.tau]
SCALES = [0.5, 0.75, 1.0, 1.5, 2.0]
SUBPIX = [(0.0, 0.0), (0.37, 0.61)]
EPS = 1e-3
CROP = "res://stream_flow_crop_demo.tscn"
FULL = "res://stream_flow_preview.tscn"


def run(godot, scene, *extra, timeout=120):
    cmd = [godot, "--rendering-driver", "opengl3", "--path", PROJ, "--resolution", f"{VW}x{VH}",
           scene, "--", *extra]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)


def dump(godot, scene, out, *extra):
    r = run(godot, scene, "--dump-frame", out, *extra)
    if r.returncode != 0 or not os.path.exists(out):
        raise RuntimeError(f"dump failed {scene} {extra}: {r.stderr[-400:]}")
    return np.array(Image.open(out).convert("RGB")).astype(int)


def load_mask(name, ch=None):
    a = np.array(Image.open(os.path.join(TEX, name)))
    if a.ndim == 3:
        a = a[..., ch] if ch is not None else a[..., :3].sum(axis=2)
    return a > 0


def texel_sets(s, ox, oy):
    """屏幕像素中心 -> Painting 纹素；返回 (lo,hi) 两组索引，lo!=hi 处为落在纹素边界上的不确定像素。"""
    xs = (np.arange(VW) + 0.5 - ox) / s
    ys = (np.arange(VH) + 0.5 - oy) / s
    return [(np.floor(v - EPS).astype(int), np.floor(v + EPS).astype(int)) for v in (xs, ys)]


def classify(mask, sets, outside_value):
    """mask[ty,tx] 映射到屏幕；返回 (all_true, any_true)。纹素超出画布时取 outside_value。"""
    (xl, xh), (yl, yh) = sets
    mh, mw = mask.shape
    res = []
    for xi in (xl, xh):
        for yi in (yl, yh):
            vx = (xi >= 0) & (xi < mw)
            vy = (yi >= 0) & (yi < mh)
            m = mask[np.clip(yi, 0, mh - 1)][:, np.clip(xi, 0, mw - 1)]
            valid = vy[:, None] & vx[None, :]
            res.append(np.where(valid, m, outside_value))
    st = np.stack(res)
    return st.all(axis=0), st.any(axis=0)


def offset_for(s, frac):
    # 让裁切矩形中心落在视口中心附近，整数部分取整，再加子像素小数。
    cx, cy = X + W / 2, Y + H / 2
    return math.floor(VW / 2 - cx * s) + frac[0], math.floor(VH / 2 - cy * s) + frac[1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--tolerance", type=int, default=1)
    a = ap.parse_args()
    godot = os.environ.get("GODOT", "godot")
    os.makedirs(a.out, exist_ok=True)
    base = np.array(Image.open(os.path.join(TEX, "near_path_base.png")).convert("RGB")).astype(int)
    water = load_mask("flow_map.png", 3) | load_mask("secondary_weight.png")
    prot = load_mask("mask_protect.png", 0)
    rect = np.zeros(water.shape, bool)
    rect[Y:Y + H, X:X + W] = True
    band = np.zeros(water.shape, bool)
    band[Y - 3:Y + H + 3, X - 3:X + W + 3] = True
    band[Y + 3:Y + H - 3, X + 3:X + W - 3] = False
    ok = True
    print("renderer: Godot 4.7.2 GL Compatibility / OpenGL3 via Mesa llvmpipe (software, Xvfb). Not RTX/Web/phone/frame-time.")
    print("gates: (A) default linear base vs LINEAR Painting; (B) legacy nearest crop vs full nearest preview.")
    for s in SCALES:
        for frac in SUBPIX:
            ox, oy = offset_for(s, frac)
            xf = ["--scale", repr(s), "--offset", repr(ox), repr(oy)]
            tag = f"s{s}_o{frac[0]}"
            sets = texel_sets(s, ox, oy)
            w_all, w_any = classify(water, sets, False)
            (xl, xh), (yl, yh) = sets
            tie = (xl != xh)[None, :] | (yl != yh)[:, None]
            w_cmp = w_all & ~tie
            w_tie = w_all & tie
            land = ~w_any
            nb = np.zeros_like(land)
            nb[1:, :] |= land[:-1, :]
            nb[:-1, :] |= land[1:, :]
            nb[:, 1:] |= land[:, :-1]
            nb[:, :-1] |= land[:, 1:]
            w_edge = w_all & nb
            nonwater = ~w_any
            p_all, _ = classify(prot, sets, False)
            _, r_any = classify(rect, sets, False)
            outside = ~r_any
            b_all, _ = classify(band, sets, False)
            R = dump(godot, CROP, os.path.join(a.out, f"R_{tag}.png"), "--phase", "0", "--reduced", *xf)
            S0 = dump(godot, CROP, os.path.join(a.out, f"S0_{tag}.png"), "--phase", "0", "--strength", "0", *xf)
            NZ = dump(godot, CROP, os.path.join(a.out, f"NZ_{tag}.png"), "--phase", "0", "--strength", "0.0001",
                      "--base-nearest", *xf)
            NL = dump(godot, CROP, os.path.join(a.out, f"NL_{tag}.png"), "--phase", "0", "--strength", "0.0001", *xf)
            s0d = int(np.abs(S0 - R).max())
            line_ok = s0d == 0
            extra = ""
            if s == 1.0 and frac == (0.0, 0.0):
                bx, by = int(ox), int(oy)
                ref = np.zeros_like(R)
                ys0, ys1 = max(0, by), min(VH, by + base.shape[0])
                xs0, xs1 = max(0, bx), min(VW, bx + base.shape[1])
                ref[ys0:ys1, xs0:xs1] = base[ys0 - by:ys1 - by, xs0 - bx:xs1 - bx]
                rd = int(np.abs(R - ref).max())
                extra = f" R-vs-PNG max {rd}"
                line_ok = line_ok and rd == 0
            nz = np.abs(NZ - R).max(axis=2)
            nl = np.abs(NL - R).max(axis=2)
            st = lambda d, m: f"max {int(d[m].max(initial=0))} mean {float(d[m].mean()) if m.any() else 0:.2f}"
            print(f"[{tag}] offset=({ox},{oy}) water px {int(w_all.sum())} (nearest-tie {int(w_tie.sum())}, "
                  f"water/land-ambiguous {int((w_any & ~w_all).sum())}, water-edge {int(w_edge.sum())}); "
                  f"strength0 vs R max {s0d};{extra}")
            print(f"  base sampling vs linear Painting @strength1e-4: --base-nearest water {st(nz, w_all)}, "
                  f"water-edge {st(nz, w_edge)}; default-linear water {st(nl, w_all)}, water-edge {st(nl, w_edge)}; "
                  f"nonwater max {int(nz[nonwater].max())}/{int(nl[nonwater].max())}")
            ok = ok and line_ok and int(nz[nonwater].max()) == 0 and int(nl[nonwater].max()) == 0
            crops = {}
            for ph in PHASES:
                pt = f"{ph:.4f}"
                C = dump(godot, CROP, os.path.join(a.out, f"C_{tag}_{pt}.png"), "--phase", repr(ph), *xf)
                C_near = dump(godot, CROP, os.path.join(a.out, f"Cnear_{tag}_{pt}.png"),
                              "--phase", repr(ph), "--base-nearest", *xf)
                F = dump(godot, FULL, os.path.join(a.out, f"F_{tag}_{pt}.png"), "--phase", repr(ph), *xf)
                crops[ph] = C
                dcr = np.abs(C - R).max(axis=2)
                dcf_legacy = np.abs(C_near - F).max(axis=2)
                # A) default linear vs LINEAR Painting boundaries
                nw = int(dcr[nonwater].max())
                outm = int(dcr[outside].max())
                prm = int(dcr[p_all].max()) if p_all.any() else 0
                bdm = int(dcr[b_all].max()) if b_all.any() else 0
                water_changed = int((dcr[w_cmp] > 0).sum()) if w_cmp.any() else 0
                a_ok = nw == 0 and outm == 0 and prm == 0 and bdm == 0
                # B) legacy nearest crop vs full nearest
                wa = int(dcf_legacy[w_cmp].max(initial=0))
                wn = int((dcf_legacy[w_cmp] > 0).sum())
                ta = int(dcf_legacy[w_tie].max(initial=0))
                tn = int((dcf_legacy[w_tie] > 0).sum())
                legacy_gate = (s == 1.0 and frac == (0.0, 0.0))
                b_ok = wa <= a.tolerance
                if legacy_gate:
                    good = a_ok and b_ok
                    b_label = 'OK' if b_ok else 'FAIL'
                else:
                    good = a_ok
                    b_label = ('OK' if b_ok else 'INFO-diff') + ' (report-only; not 1:1 integer)'
                ok = ok and good
                print(f"  phase {pt}: (A) default-linear vs Painting: nonwater max {nw}; outside-rect max {outm}; "
                      f"protect max {prm}; rect-border±3 max {bdm}; water-changed-vs-R {water_changed} px "
                      f"{'OK' if a_ok else 'FAIL'}")
                print(f"           (B) legacy nearest C-vs-F water max {wa} ({wn}/{int(w_cmp.sum())} px) "
                      f"[tie px differ {tn}, max {ta}] {b_label}")
            loop = int(np.abs(crops[PHASES[0]] - crops[PHASES[-1]]).max())
            half = int((np.abs(crops[PHASES[0]] - crops[PHASES[2]]).max(axis=2) > 0).sum())
            print(f"  loop 0 vs TAU max {loop}; half-cycle changed px {half}")
            ok = ok and loop == 0 and half > 0
    # 连续暂停 / 减少动态切换（真实帧，P/R 键路径）
    seq_dir = os.path.join(a.out, "seq")
    os.makedirs(seq_dir, exist_ok=True)
    r = run(godot, CROP, "--sequence-check", seq_dir, timeout=180)
    for line in r.stdout.splitlines():
        if line.startswith("seq ") or line.startswith("sequence-check"):
            print("  " + line)
    seq_ok = r.returncode == 0
    img = {n: np.array(Image.open(os.path.join(seq_dir, f"seq_{n}.png")).convert("RGB")).astype(int)
           for n in ["1_paused_a", "2_paused_b", "3_paused_reduced", "4_paused_restored", "5_running_reduced"]}
    base_c = np.zeros_like(img["1_paused_a"])
    base_c[:base.shape[0], :base.shape[1]] = base
    d12 = int(np.abs(img["1_paused_a"] - img["2_paused_b"]).max())
    d14 = int(np.abs(img["1_paused_a"] - img["4_paused_restored"]).max())
    d3b = int(np.abs(img["3_paused_reduced"] - base_c).max())
    d5b = int(np.abs(img["5_running_reduced"] - base_c).max())
    d1b = int((np.abs(img["1_paused_a"] - base_c).max(axis=2) > 0).sum())
    print(f"  sequence frames: paused a vs b max {d12}; paused vs restored max {d14}; "
          f"paused-reduced vs PNG max {d3b}; running-reduced vs PNG max {d5b}; paused frame water changed px {d1b}")
    seq_ok = seq_ok and d12 == 0 and d14 == 0 and d3b == 0 and d5b == 0 and d1b > 0
    print("  sequence", "OK" if seq_ok else "FAIL")
    ok = ok and seq_ok
    print("RESULT", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
