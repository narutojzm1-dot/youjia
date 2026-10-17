#!/usr/bin/env python3
"""#749 隔离 Web 完整 10×5 缩放/子像素矩阵判定（离线逐 PNG 复核 + 身份/完整性互证）。

Agent-ID: GROK-BUILD
仍只是候选工具，只读 --uploads 目录、只写 --out。

输入：浏览器日志里恰好一条 WEBMATRIX 摘要；页面上传的 webmatrix_result.json；服务器 uploads.jsonl 与各 PNG；
run_identity.json（导出前写入 PCK 的 build_id、PCK SHA256、浏览器版本等）。
判据（与 ../verify_scale_linear.py (A) 同一矩阵与硬门）：
  每组变换（缩放 0.5/0.75/1.0/1.5/2.0 × 偏移 居中整数 / +0.37,+0.61）：
    S0（strength 0）vs R（减少动态原画）整帧 0；NL / NZ（strength 1e-4，线性 / nearest 底图）非水面 0；
    phase 0 vs TAU 整帧 0；半圈整帧有变化；×1.0 整数偏移时 R 与原画 PNG 逐像素 0。
  每个相位 C vs R：非水面、保护区、裁切矩形外、矩形边框 ±3 最大通道差 0。
  保护区 / 非水面沿用既有线性采样 ±1 纹素边界：像素中心映射点的平局四角（lo/hi）任一在水面纹素切比雪夫 1 以内，
  属 LINEAR 渗色带，不进 0 差硬门（另报不排除的 strict 值与旧 floor(l)±1 规则值，仅供参考）。全部用无损 PNG，不用有损视频。
用法：python3 web_matrix_verdict.py --log LOG --uploads DIR --identity run_identity.json --out verdict.json [--desktop-dir DIR]
退出码 0 = 顶层通过。
"""
import argparse
import hashlib
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import verify_scale_linear as vsl  # noqa: E402

MARK = "WEBMATRIX "
PHASES = ["0.0000", "1.5708", "3.1416", "4.7124", "6.2832"]


def extract(text):
    dec = json.JSONDecoder()
    found, pos = [], 0
    while True:
        i = text.find(MARK + "{", pos)
        if i < 0:
            return found
        obj, end = dec.raw_decode(text, i + len(MARK))
        found.append(obj)
        pos = end


def sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def load(path):
    return np.array(Image.open(path).convert("RGB")).astype(int)


def dilate(m):
    """3×3（切比雪夫 1 纹素）膨胀，不回绕边缘。"""
    p = np.pad(m, 1)
    d = np.zeros_like(m)
    h, w = m.shape
    for dy in (0, 1, 2):
        for dx in (0, 1, 2):
            d |= p[dy:dy + h, dx:dx + w]
    return d


def floor_rule_near(near_w, s, ox, oy):
    """旧 ?probe=1 的 floor(l)±1 规则（只看像素中心所在纹素，不看平局另一侧），仅作对照。"""
    tx = np.floor((np.arange(vsl.VW) + 0.5 - ox) / s).astype(int)
    ty = np.floor((np.arange(vsl.VH) + 0.5 - oy) / s).astype(int)
    h, w = near_w.shape
    vx = (tx >= 0) & (tx < w)
    vy = (ty >= 0) & (ty < h)
    m = near_w[np.clip(ty, 0, h - 1)][:, np.clip(tx, 0, w - 1)]
    return m & vy[:, None] & vx[None, :]


def mx(d, m):
    return int(d[m].max(initial=0)) if m.any() else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True)
    ap.add_argument("--uploads", required=True)
    ap.add_argument("--identity", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--desktop-dir", default="")
    a = ap.parse_args()
    ident = json.load(open(a.identity))
    fails = []
    with open(a.log, encoding="utf-8", errors="replace") as f:
        lines = extract(f.read())
    if len(lines) != 1:
        fails.append(f"expected exactly 1 WEBMATRIX line, got {len(lines)}")
    summ = lines[0] if lines else {}
    if summ.get("build_id") != ident["build_id"]:
        fails.append("console build_id != exported build_id")
    if summ.get("ok") is not True:
        fails.append(f"console ok is {summ.get('ok')!r}")
    res_path = os.path.join(a.uploads, "webmatrix_result.json")
    res = json.load(open(res_path))
    if sha(res_path) != summ.get("result_sha256"):
        fails.append("uploaded result JSON sha256 != console summary result_sha256")
    if res.get("build_id") != ident["build_id"] or res.get("web") is not True:
        fails.append("result JSON build_id/web mismatch")
    # 上传完整性：服务器 jsonl、磁盘文件、页面自报 SHA 三方一致。
    jl = {}
    for ln in open(os.path.join(a.uploads, "uploads.jsonl")):
        r = json.loads(ln)
        jl[r["name"]] = r
    manifest = []
    for f in res["files"]:
        p = os.path.join(a.uploads, f["name"])
        on_disk = sha(p) if os.path.exists(p) else None
        good = f["status"] == 200 and on_disk == f["sha256"] == jl.get(f["name"], {}).get("sha256") \
            and jl[f["name"]].get("build_id") == ident["build_id"]
        if not good:
            fails.append(f"upload integrity {f['name']}")
        manifest.append({"name": f["name"], "sha256": on_disk, "bytes": os.path.getsize(p) if on_disk else None})
    if len([m for m in manifest if m["name"].endswith(".png")]) != 90:
        fails.append("expected 90 PNG uploads (10 transforms × (R,S0,NL,NZ + 5 phases))")

    base = load(os.path.join(vsl.TEX, "near_path_base.png"))
    water = vsl.load_mask("flow_map.png", 3) | vsl.load_mask("secondary_weight.png")
    near_w = dilate(water)
    prot = vsl.load_mask("mask_protect.png", 0)
    X, Y, W, H = vsl.X, vsl.Y, vsl.W, vsl.H
    rect = np.zeros(water.shape, bool)
    rect[Y:Y + H, X:X + W] = True
    band = np.zeros(water.shape, bool)
    band[Y - 3:Y + H + 3, X - 3:X + W + 3] = True
    band[Y + 3:Y + H - 3, X + 3:X + W - 3] = False
    browser_combo = {(c["tag"], c["phase"]): c for c in res["combos"]}
    browser_tr = {t["tag"]: t for t in res["transforms"]}
    transforms, combos = [], []
    agree = True
    for s in vsl.SCALES:
        for frac in vsl.SUBPIX:
            tag = f"s{s}_o{frac[0]}"
            ox, oy = vsl.offset_for(s, frac)
            bt = browser_tr[tag]
            if abs(bt["offset"][0] - ox) > 1e-4 or abs(bt["offset"][1] - oy) > 1e-4:
                fails.append(f"{tag} offset mismatch {bt['offset']} vs {(ox, oy)}")
            sets = vsl.texel_sets(s, ox, oy)
            _, w_any = vsl.classify(water, sets, False)
            _, nw_any = vsl.classify(near_w, sets, False)
            p_all, _ = vsl.classify(prot, sets, False)
            _, r_any = vsl.classify(rect, sets, False)
            b_all, _ = vsl.classify(band, sets, False)
            nonwater_strict = ~w_any
            nonwater = ~w_any & ~nw_any
            protect = p_all & ~nw_any
            outside = ~r_any
            nonwater_floor = ~w_any & ~floor_rule_near(near_w, s, ox, oy)
            P = lambda k: load(os.path.join(a.uploads, f"{k}_{tag}.png"))  # noqa: E731
            R, S0, NL, NZ = P("R"), P("S0"), P("NL"), P("NZ")
            C = {pt: load(os.path.join(a.uploads, f"C_{tag}_{pt}.png")) for pt in PHASES}
            dm = lambda A, B: np.abs(A - B).max(axis=2)  # noqa: E731
            t = {"tag": tag, "scale": s, "subpix": list(frac), "offset": [ox, oy],
                 "S0_vs_R_full_max": int(dm(S0, R).max()),
                 "NL_nonwater_max": mx(dm(NL, R), nonwater), "NZ_nonwater_max": mx(dm(NZ, R), nonwater),
                 "NL_nonwater_strict_max": mx(dm(NL, R), nonwater_strict),
                 "NZ_nonwater_strict_max": mx(dm(NZ, R), nonwater_strict),
                 "NL_nonwater_floor_rule_max": mx(dm(NL, R), nonwater_floor),
                 "NZ_nonwater_floor_rule_max": mx(dm(NZ, R), nonwater_floor),
                 "phase0_vs_tau_full_max": int(dm(C["0.0000"], C["6.2832"]).max()),
                 "half_cycle_changed_px": int((dm(C["0.0000"], C["3.1416"]) > 0).sum()),
                 "nonwater_px_gated": int(nonwater.sum()), "nonwater_px_strict": int(nonwater_strict.sum()),
                 "protect_px_gated": int(protect.sum()), "protect_px_strict": int(p_all.sum())}
            t_ok = (t["S0_vs_R_full_max"] == 0 and t["NL_nonwater_max"] == 0 and t["NZ_nonwater_max"] == 0
                    and t["phase0_vs_tau_full_max"] == 0 and t["half_cycle_changed_px"] > 0)
            if s == 1.0 and frac == (0.0, 0.0):
                ref = np.zeros_like(R)
                bx, by = int(ox), int(oy)
                ys0, ys1 = max(0, by), min(vsl.VH, by + base.shape[0])
                xs0, xs1 = max(0, bx), min(vsl.VW, bx + base.shape[1])
                ref[ys0:ys1, xs0:xs1] = base[ys0 - by:ys1 - by, xs0 - bx:xs1 - bx]
                t["R_vs_original_png_max"] = int(np.abs(R - ref).max())
                t_ok = t_ok and t["R_vs_original_png_max"] == 0
            t["ok"] = t_ok
            if bool(bt["ok"]) != t_ok:
                agree = False
            transforms.append(t)
            for pt in PHASES:
                d = dm(C[pt], R)
                c = {"tag": tag, "phase": pt, "png": f"C_{tag}_{pt}.png",
                     "sha256": sha(os.path.join(a.uploads, f"C_{tag}_{pt}.png")),
                     "nonwater_max": mx(d, nonwater), "protect_max": mx(d, protect),
                     "outside_rect_max": mx(d, outside), "rect_border3_max": mx(d, b_all),
                     "nonwater_strict_max": mx(d, nonwater_strict), "protect_strict_max": mx(d, p_all),
                     "nonwater_floor_rule_max": mx(d, nonwater_floor),
                     "water_changed_vs_R_px": int((d > 0).sum())}
                c_ok = (c["nonwater_max"] == 0 and c["protect_max"] == 0 and c["outside_rect_max"] == 0
                        and c["rect_border3_max"] == 0 and t_ok)
                c["transform_ok"] = t_ok
                c["ok"] = c_ok
                bc = browser_combo[(tag, pt)]
                c["browser_ok"] = bc["ok"]
                c["browser_sha256_match"] = bc["sha256"] == c["sha256"]
                if bc["ok"] != c_ok or not c["browser_sha256_match"]:
                    agree = False
                if a.desktop_dir:
                    dp = os.path.join(a.desktop_dir, c["png"])
                    if os.path.exists(dp):
                        dd = dm(load(dp), C[pt])
                        c["web_vs_llvmpipe_max"] = int(dd.max())
                        c["web_vs_llvmpipe_px"] = int((dd > 0).sum())
                combos.append(c)
    n_ok = sum(c["ok"] for c in combos)
    if not agree:
        fails.append("offline verdict disagrees with in-browser verdict or SHA")
    if n_ok != 50 or len(combos) != 50:
        fails.append(f"matrix {n_ok}/50 ok")
    out = {"ok": not fails, "n_combos": len(combos), "n_ok": n_ok, "fails": fails,
           "browser_offline_agree": agree, "identity": ident,
           "browser": {k: res.get(k) for k in ("renderer", "vendor", "api", "browser_env", "window", "viewport", "engine")},
           "browser_summary": summ, "transforms": transforms, "combos": combos, "files": manifest}
    with open(a.out, "w") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    for t in transforms:
        print(f"[{t['tag']}] S0 {t['S0_vs_R_full_max']} NL/NZ nonwater {t['NL_nonwater_max']}/{t['NZ_nonwater_max']} "
              f"(strict {t['NL_nonwater_strict_max']}/{t['NZ_nonwater_strict_max']}, floor-rule {t['NL_nonwater_floor_rule_max']}/{t['NZ_nonwater_floor_rule_max']}) 0vsTAU {t['phase0_vs_tau_full_max']} "
              f"half {t['half_cycle_changed_px']} {'R-vs-PNG ' + str(t['R_vs_original_png_max']) if 'R_vs_original_png_max' in t else ''} "
              f"{'OK' if t['ok'] else 'FAIL'}")
        for c in [c for c in combos if c["tag"] == t["tag"]]:
            extra = f" web-vs-llvmpipe max {c['web_vs_llvmpipe_max']} ({c['web_vs_llvmpipe_px']} px)" if "web_vs_llvmpipe_max" in c else ""
            print(f"  phase {c['phase']}: nonwater {c['nonwater_max']} protect {c['protect_max']} outside {c['outside_rect_max']} "
                  f"border±3 {c['rect_border3_max']} (strict nonwater/protect {c['nonwater_strict_max']}/{c['protect_strict_max']}) "
                  f"water-changed {c['water_changed_vs_R_px']} {'OK' if c['ok'] else 'FAIL'}{extra}")
    print(f"WEBMATRIX verdict: {'PASS' if out['ok'] else 'FAIL'} {n_ok}/{len(combos)} ok; browser/offline agree={agree}; "
          f"fails={fails}", file=sys.stderr)
    return 0 if out["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
