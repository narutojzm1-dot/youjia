#!/usr/bin/env python3
"""Reproducible generator for lake/creek mist isolation candidate (#749).

Two hand-painted mist layers (derived from approved mist_candidate.png) +
multi-scale continuous alpha/micro-deform modulation + soft spatial envelope.
Foreground path / cottage / bridge / paper rim stay pixel-stable across frames.

Aligned with godot_preview/mist_density.gdshader defaults.
# 2026-10-14 加强运动：整数谐波聚散 + 可见漂移/抬升。phase 与 phase+2π 相同。
# 手绘层本身横向几乎均匀，平移必须带动调制波；覆盖度只乘一次，避免运动被平方吃掉。
"""
from __future__ import annotations

import argparse
import os
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# Defaults mirrored by mist_density.gdshader / mist_density_preview.tscn
BASE_SIZE = (1672, 941)
# 雾带重心放到湖面与溪水上方。手绘层是横向均匀的竖向渐变，落点由原点决定。
# 远层在 phase=π（抬升最大）时，密度峰值落在湖面 y≈430，而不是近岸草地。
# 近层密度峰值落在前景溪床。草地靠包络挖空，运动幅度不减弱。
FAR_ORIGIN = (40, 70)
NEAR_ORIGIN = (20, 380)
FAR_SCALE = 1.0  # layers already pre-scaled into mist_far/near pngs
NEAR_SCALE = 1.0
# 调制分母（层像素）。波长 = 2π * 分母；一圈平移一个大团波长。
FAR_MOD_XX = 230.0
FAR_MOD_YY = 160.0
FAR_MOD_FINE = 92.0
NEAR_MOD_XX = 145.0
NEAR_MOD_YY = 110.0
NEAR_MOD_FINE = 60.0
# 水平漂移（像素，sin(phase)）。带动层空间里的浓淡波，不是空移一块均匀色带。
FAR_DRIFT_PX = 150.0
NEAR_DRIFT_PX = -120.0
# 垂直抬升（像素）。(1-cos(phase))/2：起点贴谷底，中点抬到最高，一圈回到起点。
FAR_LIFT_PX = 48.0
NEAR_LIFT_PX = 62.0
# 微形变幅度（像素）。空间周期须与 shader 常量一致。
FAR_DEFORM = 22.0
NEAR_DEFORM = 30.0
DEFORM_X_PERIOD = 160.0
DEFORM_Y_PERIOD = 300.0
# 近层相位错开，避免两层同步呼吸
NEAR_PHASE = 2.1
# 远层相对强度
FAR_STRENGTH = 0.90
# 单层覆盖上限，峰值是乳白色雾团，不是铺满的死白
CA_CAP = 170.0
# 旧谷地整条软带的模糊半径。水面包络改用 WATER_BLUR / EDGE_BLUR，这个值留着对照。
BLUR_RADIUS = 26
# 只在这两扇窗里认水面。窗外的蓝灰是远山和松林，不能收成雾。
LAKE_WINDOW = (590, 408, 870, 476)
CREEK_WINDOW = (155, 530, 390, 870)
# 膨胀之后还允许留雾的范围。比检测窗宽一圈，仍然不进中央草地。
LAKE_ALLOW = (545, 372, 905, 484)
CREEK_ALLOW = (120, 520, 390, 890)
LAKE_LOFT_PX = (16, 34)
# 溪水细脊，只补蓝水检测的断口，半宽很小，膨胀后才形成贴水面的雾。
CREEK_CENTERLINE = (
    (318, 548),
    (286, 590),
    (262, 635),
    (248, 680),
    (232, 730),
    (236, 780),
    (218, 825),
    (206, 870),
)
CREEK_SPINE_RADIUS = 8
# 水面外扩。太大就会盖住河岸草地。
WATER_DILATE = 14
LOFT_DILATE = 8
# 中央与右侧草坪。溪水在这条线左侧，湖面在这条线上方。
MEADOW_BOX = (430, 508, 1672, 941)
# Hard protect ellipses / polygons (black = protect) before the last soft blur
PATH_ELLIPSE = (400, 780, 1150, 970)  # 近景小路
COTTAGE_BOX = (1120, 340, 1640, 800)  # 木屋含屋顶
# 只挖桥面，不再用大矩形把桥下溪水一起挖掉
BRIDGE_BOX = (150, 468, 430, 552)
PAPER_RIM = 28  # fade outer paper edge
WATER_BLUR = 18
EDGE_BLUR = 8


def mist_modulation(phase: float, xx: np.ndarray, yy: np.ndarray, mod_xx: float, mod_yy: float, mod_fine: float) -> np.ndarray:
    """整数谐波聚散。只用 1× 与 2×，phase=0 与 phase=2π 相同，循环缝无跳变。

    大团每圈平移一个波长（中点相对起点错开半个波长）；细团两圈、反向。
    """
    bank = np.sin(phase + xx / mod_xx + yy / (mod_yy * 1.7))
    wisp = np.sin(phase * 2.0 - xx / mod_fine + yy / mod_yy)
    # 薄隙仍留一点雾，峰值拉到明显的一团
    mod = 0.12 + 0.58 * bank + 0.30 * wisp
    return np.clip(mod, 0.02, 1.0)


def _stroke_ribbon(draw: ImageDraw.ImageDraw, points: tuple[tuple[int, int], ...], radius: int) -> None:
    """沿溪水中心线画圆头雾带。白=允许雾。"""
    if len(points) >= 2:
        draw.line(list(points), fill=255, width=max(1, radius * 2), joint="curve")
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)


def _dilate_mask(mask_u8: np.ndarray, radius: int) -> np.ndarray:
    """方形最大值膨胀。半径按像素，用来让雾贴着水面稍稍挂出来。"""
    im = Image.fromarray(mask_u8, "L")
    left = int(radius)
    while left > 0:
        step = min(7, left)
        im = im.filter(ImageFilter.MaxFilter(step * 2 + 1))
        left -= step
    return np.array(im)


def _water_core(base_img: Image.Image) -> np.ndarray:
    """蓝水面，外加溪廊里的白沫。返回 0/255。"""
    rgb = np.array(base_img.convert("RGB")).astype(np.int16)
    rr, gg, bb = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    h, w = rr.shape
    ys = np.arange(h)[:, None]
    xs = np.arange(w)[None, :]

    def _inside(window: tuple[int, int, int, int]) -> np.ndarray:
        x0, y0, x1, y1 = window
        return (xs >= x0) & (xs < x1) & (ys >= y0) & (ys < y1)

    # 溪、湖的蓝水。纸边、远山蓝灰和暖色草地进不来。
    water = (bb > rr + 14) & (bb > gg + 2) & (bb > 85) & (rr < 235)
    water &= _inside(LAKE_WINDOW) | _inside(CREEK_WINDOW)
    # 溪床白沫不够蓝，只在溪廊里收，避免把云和纸边算成水。
    foam = (bb > 168) & (bb + 8 >= gg) & (bb + 6 >= rr) & (rr < 240)
    foam &= _inside(CREEK_WINDOW)
    core = np.where(water | foam, 255, 0).astype(np.uint8)
    # 湖面再向上抬一层，雾浮在湖水上方，不向近岸草地铺。
    lx0, ly0, lx1, ly1 = LAKE_WINDOW
    lake = (core > 0) & (ys >= ly0) & (ys <= ly1) & (xs >= lx0) & (xs <= lx1)
    loft = np.zeros_like(lake)
    for shift in LAKE_LOFT_PX:
        loft[:-shift] |= lake[shift:]
    spine = Image.new("L", (w, h), 0)
    _stroke_ribbon(ImageDraw.Draw(spine), CREEK_CENTERLINE, CREEK_SPINE_RADIUS)
    out = np.maximum(core, np.array(spine))
    out = np.maximum(out, np.where(loft, 255, 0).astype(np.uint8))
    return out


def build_envelope(base_img: Image.Image) -> Image.Image:
    """白=允许雾，黑=保护。雾贴着湖面和溪水，中央草地挖空。"""
    w, h = base_img.size
    core = _water_core(base_img)
    # 湖面抬升那一层少扩一点，避免爬上远岸山坡；水面本身按 WATER_DILATE 挂出一圈。
    lx0, ly0, lx1, ly1 = LAKE_WINDOW
    ys = np.arange(h)[:, None]
    xs = np.arange(w)[None, :]
    lake_band = (ys >= ly0 - max(LAKE_LOFT_PX)) & (ys <= ly1) & (xs >= lx0) & (xs <= lx1)
    halo = _dilate_mask(core, WATER_DILATE)
    # 抬升层如果被同样膨胀，会在山坡上摊开。山坡上只留未膨胀的核心。
    hillside = lake_band & (ys < ly0)
    halo[hillside] = core[hillside]
    # 膨胀不得逃出湖面/溪水允许区，远山和中央草地保持无雾。
    allow = np.zeros_like(halo, dtype=bool)
    for window in (LAKE_ALLOW, CREEK_ALLOW):
        x0, y0, x1, y1 = window
        allow |= (xs >= x0) & (xs < x1) & (ys >= y0) & (ys < y1)
    halo[~allow] = 0
    # 绿岸压低。水面核心保持满强度，草地只留很窄的一圈软边。
    rgb = np.array(base_img.convert("RGB")).astype(np.int16)
    green = (rgb[:, :, 1] > rgb[:, :, 2] + 10) & (core == 0)
    halo = halo.astype(np.float32)
    halo[green] *= 0.22
    env = Image.fromarray(np.clip(halo, 0, 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=WATER_BLUR))
    # 草坪、小路、屋顶、桥面、纸边。先挖再轻模糊，岸边软、草地不铺雾。
    draw = ImageDraw.Draw(env)
    draw.rectangle(list(MEADOW_BOX), fill=0)
    draw.ellipse(list(PATH_ELLIPSE), fill=0)
    draw.rectangle(list(COTTAGE_BOX), fill=0)
    draw.rectangle(list(BRIDGE_BOX), fill=0)
    draw.rectangle([0, 0, w, PAPER_RIM], fill=0)
    draw.rectangle([0, h - PAPER_RIM, w, h], fill=0)
    draw.rectangle([0, 0, PAPER_RIM, h], fill=0)
    draw.rectangle([w - PAPER_RIM, 0, w, h], fill=0)
    env = env.filter(ImageFilter.GaussianBlur(radius=EDGE_BLUR))
    return env


def build_protect_masks(size: tuple[int, int]) -> tuple[Image.Image, Image.Image, Image.Image]:
    """Semantic allow-masks (white allow) for optional hard gate in shader."""
    def allow() -> Image.Image:
        return Image.new("L", size, 255)

    path = allow()
    ImageDraw.Draw(path).ellipse(list(PATH_ELLIPSE), fill=0)
    cottage = allow()
    ImageDraw.Draw(cottage).rectangle(list(COTTAGE_BOX), fill=0)
    bridge = allow()
    ImageDraw.Draw(bridge).rectangle(list(BRIDGE_BOX), fill=0)
    return path, cottage, bridge


def _muldiv255(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    t = a.astype(np.int32) * b.astype(np.int32) + 128
    return ((t >> 8) + t) >> 8


def sample_layer(
    layer_rgba: np.ndarray,
    base_px_x: np.ndarray,
    base_px_y: np.ndarray,
    origin: tuple[int, int],
    phase: float,
    drift_px: float,
    lift_px: float,
    deform: float,
    mod_xx: float,
    mod_yy: float,
    mod_fine: float,
    strength: float,
) -> tuple[np.ndarray, np.ndarray]:
    """直线 RGB 与覆盖度 ca。覆盖度稍后只与包络相乘一次。"""
    h, w = layer_rgba.shape[:2]
    ox, oy = origin
    # 水平漂移带动调制采样点；垂直抬升让雾带边缘一圈内升起再落下
    drift = drift_px * np.sin(phase)
    lift = lift_px * (1.0 - np.cos(phase)) * 0.5
    lx = base_px_x - ox - drift + deform * 0.55 * np.sin(phase * 2.0 + base_px_y / DEFORM_X_PERIOD)
    ly = base_px_y - oy - lift + deform * np.cos(phase + base_px_x / DEFORM_Y_PERIOD)
    xi = np.floor(lx).astype(np.int32)
    yi = np.floor(ly).astype(np.int32)
    inside = (xi >= 0) & (xi < w) & (yi >= 0) & (yi < h)
    rgb = np.zeros(base_px_x.shape + (3,), dtype=np.float64)
    a = np.zeros(base_px_x.shape, dtype=np.int32)
    if not inside.any():
        return rgb, a
    xs = xi[inside]
    ys = yi[inside]
    pix = layer_rgba[ys, xs]
    mod = mist_modulation(phase, xs.astype(np.float64), ys.astype(np.float64), mod_xx, mod_yy, mod_fine)
    ca = np.clip(np.floor(pix[:, 3].astype(np.float64) * mod * strength), 0, CA_CAP).astype(np.int32)
    rgb[inside] = pix[:, :3]
    a[inside] = ca
    return rgb, a


def composite_frame(
    base_rgb: np.ndarray,
    far: np.ndarray,
    near: np.ndarray,
    mask_u8: np.ndarray,
    phase: float,
    strength: float = 1.0,
) -> np.ndarray:
    h, w = base_rgb.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    far_rgb, far_a = sample_layer(
        far, xx, yy, FAR_ORIGIN, phase, FAR_DRIFT_PX, FAR_LIFT_PX, FAR_DEFORM,
        FAR_MOD_XX, FAR_MOD_YY, FAR_MOD_FINE, strength * FAR_STRENGTH,
    )
    near_rgb, near_a = sample_layer(
        near, xx, yy, NEAR_ORIGIN, phase + NEAR_PHASE, NEAR_DRIFT_PX, NEAR_LIFT_PX, NEAR_DEFORM,
        NEAR_MOD_XX, NEAR_MOD_YY, NEAR_MOD_FINE, strength,
    )
    # 先远后近。覆盖度 = ca 与包络各乘一次，雾色按这个比例盖到原画上。
    out = base_rgb.astype(np.float64)
    mask_i = mask_u8.astype(np.int32)
    for rgb, a in ((far_rgb, far_a), (near_rgb, near_a)):
        cov = _muldiv255(a, mask_i).astype(np.float64) / 255.0
        out = rgb * cov[..., None] + out * (1.0 - cov[..., None])
    return np.clip(np.round(out), 0, 255).astype(np.uint8)


def _paths(base_path, far_path, near_path):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    if base_path is None:
        base_path = os.path.join(repo_root, "assets", "holiday", "exploration", "near_path_02.webp")
    if far_path is None:
        far_path = os.path.join(script_dir, "mist_far_layer.png")
    if near_path is None:
        near_path = os.path.join(script_dir, "mist_near_layer.png")
    return script_dir, repo_root, base_path, far_path, near_path


def export_preview(script_dir: str, base: Image.Image, far: Image.Image, near: Image.Image, env: Image.Image,
                   path_m: Image.Image, cottage_m: Image.Image, bridge_m: Image.Image) -> None:
    tex = os.path.join(script_dir, "godot_preview", "textures")
    os.makedirs(tex, exist_ok=True)
    base.convert("RGBA").save(os.path.join(tex, "near_path_base.png"), optimize=True)
    far.save(os.path.join(tex, "mist_far.png"), optimize=True)
    near.save(os.path.join(tex, "mist_near.png"), optimize=True)
    env.save(os.path.join(tex, "mask_envelope.png"), optimize=True)
    path_m.save(os.path.join(tex, "mask_path.png"), optimize=True)
    cottage_m.save(os.path.join(tex, "mask_cottage.png"), optimize=True)
    bridge_m.save(os.path.join(tex, "mask_bridge.png"), optimize=True)
    print(f"Exported preview textures to {tex}")


def generate(out_dir=None, n_frames=40, base_path=None, far_path=None, near_path=None, export_preview_tex=False):
    script_dir, _repo, base_path, far_path, near_path = _paths(base_path, far_path, near_path)
    if out_dir is None:
        out_dir = os.path.join(script_dir, "anim_frames")
    os.makedirs(out_dir, exist_ok=True)

    base_img = Image.open(base_path).convert("RGBA")
    if base_img.size != BASE_SIZE:
        print(f"WARN: base size {base_img.size} != {BASE_SIZE}")
    far_img = Image.open(far_path).convert("RGBA")
    near_img = Image.open(near_path).convert("RGBA")
    env = build_envelope(base_img)
    path_m, cottage_m, bridge_m = build_protect_masks(base_img.size)
    mask_u8 = np.array(env.convert("L"))
    base_rgb = np.array(base_img.convert("RGB"))
    far = np.array(far_img)
    near = np.array(near_img)

    for i in range(n_frames):
        phase = i / n_frames * 2 * np.pi
        frame = composite_frame(base_rgb, far, near, mask_u8, phase)
        Image.fromarray(frame, "RGB").save(os.path.join(out_dir, f"mist_frame_{i:02d}.png"), optimize=True)

    # Low-motion static: phase 0 with reduced strength
    static = composite_frame(base_rgb, far, near, mask_u8, 0.0, strength=0.35)
    Image.fromarray(static, "RGB").save(os.path.join(out_dir, "mist_static_low_motion.png"), optimize=True)

    # Sample frames
    sample_dir = os.path.join(script_dir, "sample_frames")
    os.makedirs(sample_dir, exist_ok=True)
    for idx in (0, 10, 20, 30):
        src = os.path.join(out_dir, f"mist_frame_{idx:02d}.png")
        if os.path.isfile(src):
            shutil.copy2(src, os.path.join(sample_dir, f"mist_frame_{idx:02d}.png"))
    shutil.copy2(os.path.join(out_dir, "mist_static_low_motion.png"), os.path.join(sample_dir, "mist_static_low_motion.png"))

    # 保护区应几乎不动；水面浓淡在首帧与中帧必须肉眼可辨。循环缝应接近相邻帧，而不是跳变。
    f0 = np.array(Image.open(os.path.join(out_dir, "mist_frame_00.png")))
    f1 = np.array(Image.open(os.path.join(out_dir, "mist_frame_01.png")))
    f10 = np.array(Image.open(os.path.join(out_dir, "mist_frame_10.png")))
    f20 = np.array(Image.open(os.path.join(out_dir, "mist_frame_20.png")))
    f39 = np.array(Image.open(os.path.join(out_dir, "mist_frame_39.png")))
    protect = mask_u8 < 8
    # 包络里较实的部分现在是湖面和溪水，不再是整条谷地。
    water_band = mask_u8 > 100

    def _motion(a, b, label):
        d = np.abs(a.astype(np.int16) - b.astype(np.int16))
        ch = d.max(axis=2)
        water_mean = float(d[water_band].mean()) if water_band.any() else -1.0
        protect_max = int(d[protect].max()) if protect.any() else -1
        print(
            f"{label} mean {d.mean():.2f} water {water_mean:.2f} "
            f"frac>8 {(ch > 8).mean():.3f} frac>20 {(ch > 20).mean():.3f} "
            f"max {int(d.max())} protect_max {protect_max}"
        )

    _motion(f0, f1, "frame00 vs 01")
    _motion(f0, f10, "frame00 vs 10")
    _motion(f0, f20, "frame00 vs 20")
    _motion(f0, f39, "frame00 vs 39 seam")

    env.save(os.path.join(script_dir, "mask_envelope.png"), optimize=True)
    if export_preview_tex:
        export_preview(script_dir, base_img, far_img, near_img, env, path_m, cottage_m, bridge_m)

    print(f"Generated {n_frames} frames + static in {out_dir}")
    print(f"Base: {base_path}")
    print(f"Far: {far_path}")
    print(f"Near: {near_path}")


def main():
    ap = argparse.ArgumentParser(description="Generate #749 mist isolation candidate frames")
    ap.add_argument("--frames", type=int, default=40)
    ap.add_argument("--out", default=None)
    ap.add_argument("--base", default=None)
    ap.add_argument("--far", default=None)
    ap.add_argument("--near", default=None)
    ap.add_argument("--export-preview", action="store_true")
    args = ap.parse_args()
    generate(
        out_dir=args.out,
        n_frames=args.frames,
        base_path=args.base,
        far_path=args.far,
        near_path=args.near,
        export_preview_tex=args.export_preview,
    )


if __name__ == "__main__":
    main()
