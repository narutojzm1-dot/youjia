#!/usr/bin/env python3
"""可复现的溪流隔离流向候选（#749）。

沿近郊小路原画左下溪床生成流向图。水纹贴图横向循环，相位直接往下游平移；
笔触仍用双相位，避免非循环细节在回绕时跳一下。岸、桥、石、纸边逐像素保持不动。

与 godot_preview/stream_flow.gdshader 使用同一套常量。
# 2026-10-14 隔离候选：不改 assets/、不改生产 shader、不接入场景。
# 2026-10-14 修正：旧水纹只用 2/4 次偶数谐波，半圈平移后与自身重合。
## 双相位正好差半圈，两层采到同一个纹素，亮带在每一帧都一样。
## 第 0 帧和第 20 帧因此逐像素相同，看起来是静帧。水纹改为整圈才重复。
"""
from __future__ import annotations

import argparse
import os
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# 与 stream_flow.gdshader / stream_flow_preview.tscn 的默认值一致
BASE_SIZE = (1672, 941)
# 一圈沿弧长往下游走的距离（像素）。水纹贴图横向正好一圈，phase 0 与 1 重合。
# 溪床弧长大约 314 像素。180 像素/8 秒大约是半条溪，亮带能跟着弯走到前景。
TRAVEL_PX = 180.0
# 笔触细节只走很短的一段，避免沿切线抄近路时捞到岸上的颜色。
ADVECT_TRAVEL_PX = 12.0
# 水纹振幅（约等于 0–255 的电平）。正值偏暖高光，负值只略压暗，避免霓虹青。
# 水面本身已经偏亮，振幅要大到亮带挪开后电平差仍能被人看见，并扛住 mp4/gif 量化。
RIPPLE_AMP = 118.0
ADVECT_GAIN = 0.50
# 笔触位移的电平上限。不夹的话，亮沫挪到暗水上会闪成一块硬斑。
ADVECT_CLAMP = 8.0
# water_detail.png 的编码：0.5 为无细节，±DETAIL_SCALE 撑满 0–1。
DETAIL_SCALE = 48.0
# 横向坐标 n 的半宽（像素）。coord_sn 的 G 通道把 [-N_MAX, N_MAX] 映到 0–1。
N_MAX = 28.0
# 低动效静帧：仍是一幅完成的画，只留很轻的水纹。
LOW_MOTION_STRENGTH = 0.20
# 高光略偏纸色，暗部少减蓝，避免整条溪发青或发灰。
POS_TINT = np.array([1.02, 0.98, 0.62], dtype=np.float64)
NEG_TINT = np.array([-0.62, -0.48, -0.22], dtype=np.float64)

# 只在这扇窗里认溪水。窗外的湖、远山和草坪不进这条候选。
CREEK_WINDOW = (155, 530, 390, 870)
# 膨胀后仍允许有水纹的范围。比检测窗宽一圈，到不了中央草地。
CREEK_ALLOW = (128, 536, 404, 848)
# 桥面整块保护。与雾体候选同一矩形，不让水纹爬上桥板。
BRIDGE_BOX = (150, 468, 430, 552)
PAPER_RIM = 28
# 桥下出水口附近找中心线起点。
SEED_BOX = (300, 552, 385, 578)


def _paths(base_path: str | None) -> tuple[str, str, str]:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    if base_path is None:
        base_path = os.path.join(repo_root, "assets", "holiday", "exploration", "near_path_02.webp")
    return script_dir, repo_root, base_path


def _coolness(rgb: np.ndarray) -> np.ndarray:
    """蓝水面高于暖岸。正值偏水，负值偏石、草和纸。"""
    rr = rgb[:, :, 0].astype(np.float32)
    gg = rgb[:, :, 1].astype(np.float32)
    bb = rgb[:, :, 2].astype(np.float32)
    return bb - (rr + gg) * 0.5


def _blur_l(values: np.ndarray, radius: float) -> np.ndarray:
    im = Image.fromarray(np.clip(values, 0, 255).astype(np.uint8), "L")
    return np.array(im.filter(ImageFilter.GaussianBlur(radius=radius))).astype(np.float32)


def _smooth_mask(values: np.ndarray, radius: float) -> np.ndarray:
    """0–1 蒙版的轻模糊。先抬到 0–255 再缩回。"""
    return _blur_l(values * 255.0, radius) / 255.0


def trace_centerline(cool: np.ndarray) -> list[tuple[float, float]]:
    """从桥下出水口沿冷色脊往下游走。单步限制横向，避免跳进旁边石滩。

    # 下游在画面里是 +Y（从桥走向前景）。
    ## 每步固定增加 y，切线不会朝上游折返。
    """
    h, w = cool.shape
    x0, y0, x1, y1 = SEED_BOX
    patch = cool[y0:y1, x0:x1]
    ly, lx = np.unravel_index(int(np.argmax(patch)), patch.shape)
    x = float(x0 + lx)
    y = float(y0 + ly)
    pts: list[tuple[float, float]] = [(x, y)]
    prev_dx = 0.0
    for _ in range(52):
        y_next = y + 6.5
        if y_next > 832:
            break
        yy = int(round(y_next))
        if yy >= h - PAPER_RIM:
            break
        span = 26
        xa = int(max(CREEK_ALLOW[0], np.floor(x - span)))
        xb = int(min(CREEK_ALLOW[2], np.ceil(x + span)))
        cols = np.arange(xa, xb)
        row = cool[yy, xa:xb]
        inertia = x + prev_dx * 0.4
        score = row - 0.025 * (cols - inertia) ** 2
        k = int(np.argmax(score))
        best = float(np.clip(cols[k], x - 12.0, x + 12.0))
        if float(row[k]) < -6.0:
            best = x + prev_dx * 0.2
        prev_dx = best - x
        x, y = best, y_next
        pts.append((x, y))
        if len(pts) > 10 and y > 760:
            tail = []
            for px, py in pts[-4:]:
                cy = int(np.clip(round(py), 0, h - 1))
                cx = int(np.clip(round(px), 0, w - 1))
                tail.append(float(cool[cy, cx]))
            if max(tail) < -2.0:
                break
    xs = np.array([p[0] for p in pts], dtype=np.float64)
    ys = np.array([p[1] for p in pts], dtype=np.float64)
    kernel = np.array([1.0, 2.0, 3.0, 2.0, 1.0])
    kernel /= kernel.sum()
    smooth = np.convolve(np.pad(xs, 2, mode="edge"), kernel, mode="valid")
    kept: list[tuple[float, float]] = []
    cool_at: list[float] = []
    for xx, yy in zip(smooth, ys):
        cy = int(np.clip(round(yy), 0, h - 1))
        cx = int(np.clip(round(xx), 0, w - 1))
        kept.append((float(xx), float(yy)))
        cool_at.append(float(cool[cy, cx]))
    while len(kept) > 8 and cool_at[-1] < 0.0 and cool_at[-2] < 0.0:
        kept.pop()
        cool_at.pop()
    return kept


def _polyline_metrics(pts: list[tuple[float, float]]) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """弧长、单位切线。切线 y 分量保持为正，下游不掉头。"""
    arr = np.array(pts, dtype=np.float64)
    seg = np.diff(arr, axis=0)
    length = np.hypot(seg[:, 0], seg[:, 1])
    length = np.maximum(length, 1e-6)
    tangent = seg / length[:, None]
    # 画面 +Y 是下游。追踪步长已经保证 dy>0，这里再夹一下避免数值噪声。
    tangent[:, 1] = np.maximum(tangent[:, 1], 0.08)
    tangent /= np.hypot(tangent[:, 0], tangent[:, 1])[:, None]
    arc = np.concatenate([[0.0], np.cumsum(length)])
    return arc, tangent, length


def measure_radii(cool: np.ndarray, pts: list[tuple[float, float]], tangent: np.ndarray) -> np.ndarray:
    """每个顶点的水面半宽。窄处水纹更密，宽处更静。"""
    h, w = cool.shape
    radii = np.zeros(len(pts), dtype=np.float64)
    for i, ((x, y), (tx, ty)) in enumerate(zip(pts, list(tangent) + [tangent[-1]])):
        nx, ny = -ty, tx

        def walk(sign: float) -> int:
            last = 0
            for dist in range(1, 36):
                xx = int(round(x + sign * nx * dist))
                yy = int(round(y + sign * ny * dist))
                if xx < 0 or yy < 0 or xx >= w or yy >= h:
                    break
                if cool[yy, xx] > 1.5:
                    last = dist
                elif dist > 4 and cool[yy, xx] < -6.0:
                    break
            return last

        half = max(walk(1.0), walk(-1.0))
        radii[i] = float(np.clip(max(half + 4, 11), 11, 24))
    # 沿中心线平滑，避免半宽一节一节跳
    kernel = np.array([1.0, 2.0, 3.0, 2.0, 1.0])
    kernel /= kernel.sum()
    return np.convolve(np.pad(radii, 2, mode="edge"), kernel, mode="valid")


def map_flow_field(
    shape: tuple[int, int],
    pts: list[tuple[float, float]],
    arc: np.ndarray,
    tangent: np.ndarray,
    radii: np.ndarray,
) -> dict[str, np.ndarray]:
    """每个像素相对中心线的弧长 s、横向 n、切线和本地半径。窗外保持 0。"""
    h, w = shape
    x0, y0, x1, y1 = CREEK_ALLOW
    xs = np.arange(x0, x1, dtype=np.float64)
    ys = np.arange(y0, y1, dtype=np.float64)
    grid_y, grid_x = np.meshgrid(ys, xs, indexing="ij")
    flat_x = grid_x.ravel()
    flat_y = grid_y.ravel()
    best_d2 = np.full(flat_x.shape, 1e18)
    best_s = np.zeros(flat_x.shape)
    best_n = np.zeros(flat_x.shape)
    best_tx = np.zeros(flat_x.shape)
    best_ty = np.ones(flat_x.shape)
    best_rad = np.full(flat_x.shape, 16.0)
    for i in range(len(pts) - 1):
        x_a, y_a = pts[i]
        dx = pts[i + 1][0] - x_a
        dy = pts[i + 1][1] - y_a
        len2 = dx * dx + dy * dy
        if len2 < 1e-8:
            continue
        t = np.clip(((flat_x - x_a) * dx + (flat_y - y_a) * dy) / len2, 0.0, 1.0)
        px = x_a + t * dx
        py = y_a + t * dy
        ddx = flat_x - px
        ddy = flat_y - py
        d2 = ddx * ddx + ddy * ddy
        tx = tangent[i, 0]
        ty = tangent[i, 1]
        # 切线 × 偏移：左侧为正，顺着弯道的横向坐标
        signed = tx * ddy - ty * ddx
        seg_s = arc[i] + t * np.sqrt(len2)
        seg_rad = radii[i] * (1.0 - t) + radii[i + 1] * t
        closer = d2 < best_d2
        best_d2 = np.where(closer, d2, best_d2)
        best_s = np.where(closer, seg_s, best_s)
        best_n = np.where(closer, signed, best_n)
        best_tx = np.where(closer, tx, best_tx)
        best_ty = np.where(closer, ty, best_ty)
        best_rad = np.where(closer, seg_rad, best_rad)

    def _full(fill: float) -> np.ndarray:
        out = np.full((h, w), fill, dtype=np.float32)
        return out

    dist = _full(1e6)
    ess = _full(0.0)
    enn = _full(0.0)
    etx = _full(0.0)
    ety = _full(1.0)
    erad = _full(16.0)
    dist[y0:y1, x0:x1] = np.sqrt(best_d2).reshape(grid_y.shape).astype(np.float32)
    ess[y0:y1, x0:x1] = best_s.reshape(grid_y.shape).astype(np.float32)
    enn[y0:y1, x0:x1] = best_n.reshape(grid_y.shape).astype(np.float32)
    etx[y0:y1, x0:x1] = best_tx.reshape(grid_y.shape).astype(np.float32)
    ety[y0:y1, x0:x1] = best_ty.reshape(grid_y.shape).astype(np.float32)
    erad[y0:y1, x0:x1] = best_rad.reshape(grid_y.shape).astype(np.float32)
    return {"dist": dist, "s": ess, "n": enn, "tx": etx, "ty": ety, "radius": erad}


def _rect_mask(shape: tuple[int, int], box: tuple[int, int, int, int]) -> np.ndarray:
    h, w = shape
    ys = np.arange(h)[:, None]
    xs = np.arange(w)[None, :]
    x0, y0, x1, y1 = box
    return (xs >= x0) & (xs < x1) & (ys >= y0) & (ys < y1)


def _paper_mask(shape: tuple[int, int]) -> np.ndarray:
    h, w = shape
    ys = np.arange(h)[:, None]
    xs = np.arange(w)[None, :]
    rim = PAPER_RIM
    return (xs < rim) | (xs >= w - rim) | (ys < rim) | (ys >= h - rim)


def build_masks(rgb: np.ndarray, cool: np.ndarray, field: dict[str, np.ndarray]) -> dict[str, np.ndarray]:
    """软水面蒙版，以及必须逐像素不动的保护区。

    # 白水沫可以轻轻动；石头、绿岸、桥面、纸边是硬保护，模糊之后再挖掉。
    """
    h, w = cool.shape
    rr = rgb[:, :, 0].astype(np.float32)
    gg = rgb[:, :, 1].astype(np.float32)
    bb = rgb[:, :, 2].astype(np.float32)
    lum = (rr + gg + bb) / 3.0
    allow = _rect_mask((h, w), CREEK_ALLOW)
    bridge = _rect_mask((h, w), BRIDGE_BOX)
    paper = _paper_mask((h, w))
    # 水面：冷色，或溪床里偏白的沫。门槛放在脚本里，方便和诊断一起看。
    like = np.clip((cool + 1.0) / 14.0, 0.0, 1.0)
    foam = (lum > 186.0) & (cool > -14.0) & (np.abs(rr - bb) < 38.0) & allow
    like = np.maximum(like, foam.astype(np.float32) * 0.88)
    like *= allow.astype(np.float32)
    # 先轻轻连上被石块隔开的窄水缝，再把石头挖回去。
    like_u8 = _blur_l(like * 255.0, 0.0)
    like_dilated = np.array(Image.fromarray(like_u8.astype(np.uint8), "L").filter(ImageFilter.MaxFilter(3))).astype(np.float32) / 255.0
    like = np.maximum(like, like_dilated * 0.85)
    dist = field["dist"]
    radius = np.maximum(field["radius"], 1.0)
    t = np.clip(dist / radius, 0.0, 1.0)
    fall = 1.0 - t * t * (3.0 - 2.0 * t)
    soft = like * fall.astype(np.float32)
    soft[~allow] = 0.0
    # 石头：暖灰、不冷、亮度中等。膨胀 1px，免得水纹啃到石边。
    stone = (cool < -0.5) & (lum > 58.0) & (lum < 188.0) & (rr + 5.0 >= bb) & (gg + 6.0 >= bb)
    stone &= allow
    stone_u8 = (stone.astype(np.uint8) * 255)
    stone_d = np.array(Image.fromarray(stone_u8, "L").filter(ImageFilter.MaxFilter(3))) > 0
    green = (gg > bb + 8.0) & (gg + 4.0 > rr)
    hard = bridge | paper | stone_d | green | ~allow
    # 半径外也是硬边，避免高斯把水纹铺成一块矩形。
    hard = hard | (dist > radius)
    soft[hard] = 0.0
    soft = _smooth_mask(np.clip(soft, 0.0, 1.0), 1.15)
    soft[hard] = 0.0
    soft = np.clip(soft, 0.0, 1.0).astype(np.float32)
    # 疏密：窄渠更明显，宽水面更轻；再乘一条不随时间走的沿程起伏。
    narrow = np.clip((20.0 - radius) / 12.0, 0.0, 1.0)
    static_busy = 0.78 + 0.22 * np.sin(field["s"] / 78.0 + 0.6).astype(np.float32)
    density = np.clip(0.58 + 0.42 * narrow.astype(np.float32) * static_busy, 0.45, 1.0)
    density[soft <= 0.0] = 0.0
    protect = soft <= 0.0
    return {"mask": soft, "density": density.astype(np.float32), "protect": protect, "stone": stone_d}


def smooth_directions(field: dict[str, np.ndarray], mask: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """在水面里平滑切线，弯道连续，但不把方向抹到保护区上。"""
    weight = np.clip(mask, 0.0, 1.0)
    tx = field["tx"] * weight
    ty = field["ty"] * weight
    # 用 0–255 承载带符号的方向：先平移再模糊，避免 PIL 丢掉负值。
    def blur_signed(values: np.ndarray) -> np.ndarray:
        encoded = np.clip(values * 0.5 + 0.5, 0.0, 1.0) * 255.0
        blurred = _blur_l(encoded, 2.2) / 255.0
        return (blurred - 0.5) * 2.0

    blurred_tx = blur_signed(tx)
    blurred_ty = blur_signed(ty)
    blurred_w = _smooth_mask(weight, 2.2)
    valid = blurred_w > 0.04
    dx = np.zeros_like(mask)
    dy = np.ones_like(mask)
    dx[valid] = blurred_tx[valid] / blurred_w[valid]
    dy[valid] = blurred_ty[valid] / blurred_w[valid]
    # 权重很小的时候模糊会把方向拉向 0。水面内改回未模糊的切线。
    weak = valid & (blurred_w < 0.18)
    dx[weak] = field["tx"][weak]
    dy[weak] = field["ty"][weak]
    norm = np.hypot(dx, dy)
    norm = np.maximum(norm, 1e-6)
    dx /= norm
    dy /= norm
    # 下游分量保持朝画面下方。平滑不应当把整段溪流倒回去。
    dy = np.maximum(dy, 0.12)
    norm = np.hypot(dx, dy)
    dx /= norm
    dy /= norm
    dx[mask <= 0.0] = 0.0
    dy[mask <= 0.0] = 0.0
    return dx.astype(np.float32), dy.astype(np.float32)


def _value_noise(height: int, width: int, cells_y: int, cells_x: int, seed: int) -> np.ndarray:
    """横向循环的值噪声。纵向不循环，留给溪床横断面。"""
    rng = np.random.default_rng(seed)
    grid = rng.random((cells_y + 1, cells_x + 1)).astype(np.float64)
    grid[:, -1] = grid[:, 0]
    ys = np.linspace(0.0, cells_y, height, endpoint=False)
    xs = np.linspace(0.0, cells_x, width, endpoint=False)
    y0 = np.floor(ys).astype(np.int32)
    x0 = np.floor(xs).astype(np.int32)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * (3.0 - 2.0 * fy)
    fx = fx * fx * (3.0 - 2.0 * fx)
    g00 = grid[y0[:, None], x0[None, :]]
    g01 = grid[y0[:, None], x0[None, :] + 1]
    g10 = grid[y0[:, None] + 1, x0[None, :]]
    g11 = grid[y0[:, None] + 1, x0[None, :] + 1]
    top = g00 * (1.0 - fx) + g01 * fx
    bot = g10 * (1.0 - fx) + g11 * fx
    return top * (1.0 - fy) + bot * fy


def _blur_wrap_x(img: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return img
    out = np.zeros_like(img)
    total = 0.0
    for k in range(-radius, radius + 1):
        weight = float(np.exp(-0.5 * (k / max(radius * 0.55, 1.0)) ** 2))
        out += weight * np.roll(img, k, axis=1)
        total += weight
    return out / total


def make_ripple_tile(width: int = 256, height: int = 96) -> np.ndarray:
    """水纹贴图。R/G 是同一层亮带，横向一整圈才重复，长度对应 TRAVEL_PX。

    # 三道宽高光加几道细纹，位置故意不按半圈对称。
    ## 旧版只用偶数谐波，平移半圈后纹样不变；双相位又正好差半圈，亮带静止。
    ## 这里半圈必须是另一组亮带。相位增加时，亮带沿弧长往下游挪。
    """
    u = np.linspace(0.0, 1.0, width, endpoint=False)
    v = np.linspace(0.0, 1.0, height)
    # 横断面上略错开，亮带跟着弯，不是一根垂直的硬杠。
    shear = (v - 0.5)[:, None] * 0.06
    uu = u[None, :] + shear

    def wrapped_bands(centers: np.ndarray, sigmas: np.ndarray, power: float) -> np.ndarray:
        field = np.zeros((height, width), dtype=np.float64)
        for center, sigma in zip(centers, sigmas):
            du = np.abs(uu - float(center))
            du = np.minimum(du, 1.0 - du)
            field += np.exp(-0.5 * (du / float(sigma)) ** 2)
        field /= np.max(field) + 1e-8
        return np.power(field, power)

    # 中心不落在 +0.5 的另一组上，避免再变成半周期纹样。
    wide = wrapped_bands(
        np.array([0.07, 0.41, 0.73]),
        np.array([0.062, 0.048, 0.055]),
        1.2,
    )
    thin = wrapped_bands(
        np.array([0.19, 0.33, 0.56, 0.86]),
        np.array([0.020, 0.016, 0.018, 0.015]),
        1.55,
    )
    # 溪心更亮，贴岸收一些，亮边不要啃到石头上。
    across = (0.48 + 0.52 * np.sin(np.pi * np.clip(v, 0.0, 1.0)) ** 1.2)[:, None]
    img = (wide * 0.80 + thin * 0.20) * across
    img = _blur_wrap_x(img, 2)
    img = img - img.mean()
    peak = np.max(np.abs(img)) + 1e-8
    wave = img / peak
    # 高光留足摆幅，暗槽只压浅一点，避免把已经偏亮的水色压脏。
    shaped = np.where(wave >= 0.0, wave, wave * 0.62)
    shaped = shaped / (np.max(np.abs(shaped)) + 1e-8)
    enc = 0.5 + shaped * 0.48
    enc = np.clip(enc - enc.mean() + 0.5, 0.06, 0.96).astype(np.float32)
    blue = np.full_like(enc, 0.5)
    return np.dstack([enc, enc, blue])


def _assert_tile_not_half_periodic(tile: np.ndarray) -> None:
    """半圈重合的贴图配上差半圈的双相位，画面会完全不动。"""
    rolled = np.roll(tile, tile.shape[1] // 2, axis=1)
    diff = float(np.abs(tile - rolled).mean())
    if diff < 0.02:
        raise RuntimeError(f"ripple tile is half-period invariant (mean diff {diff:.4f}); flow would be still")
    print(f"ripple tile half-shift mean diff {diff:.4f}")


def build_detail(rgb: np.ndarray, cool: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """只含水色的高频笔触。岸和石头换成附近水色后再取高频，采样越界不会拖进岸色。"""
    core = (cool > 3.0) & (mask > 0.15)
    core_u8 = (core.astype(np.uint8) * 255)
    weight_img = Image.fromarray(core_u8, "L").filter(ImageFilter.GaussianBlur(radius=5))
    weight = np.array(weight_img).astype(np.float32) / 255.0
    plate = np.zeros_like(rgb, dtype=np.float32)
    for c in range(3):
        tinted = (rgb[:, :, c].astype(np.float32) * core.astype(np.float32))
        blurred = np.array(
            Image.fromarray(np.clip(tinted, 0, 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=5))
        ).astype(np.float32)
        filled = np.where(weight > 0.02, blurred / np.maximum(weight, 0.02), rgb[:, :, c])
        # 核心保留原笔触，外围只用渗开的水色
        plate[:, :, c] = np.where(core, rgb[:, :, c], filled)
    low = np.zeros_like(plate)
    for c in range(3):
        low[:, :, c] = np.array(
            Image.fromarray(np.clip(plate[:, :, c], 0, 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius=3.2))
        ).astype(np.float32)
    hp = plate - low
    hp[weight < 0.08] = 0.0
    # 硬保护区不留细节，双相位采样落到这里就是 0
    hp[mask <= 0.0] = 0.0
    return hp.astype(np.float32)


def _encode_detail(hp: np.ndarray) -> np.ndarray:
    enc = np.clip(hp / (2.0 * DETAIL_SCALE) + 0.5, 0.0, 1.0)
    return np.clip(np.round(enc * 255.0), 0, 255).astype(np.uint8)


def _decode_detail(enc: np.ndarray) -> np.ndarray:
    return (enc.astype(np.float32) / 255.0 - 0.5) * (2.0 * DETAIL_SCALE)


def _encode_flow(dx: np.ndarray, dy: np.ndarray, density: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """RG 存单位流向：128 为零，大于 128 指向 +X / +Y（+Y 为下游）。B 疏密，A 水面。"""
    out = np.zeros(dx.shape + (4,), dtype=np.uint8)
    rg_x = np.clip(np.round((dx * 0.5 + 0.5) * 255.0), 0, 255)
    rg_y = np.clip(np.round((dy * 0.5 + 0.5) * 255.0), 0, 255)
    # 水面外明确写成零向量，避免 0 被读成“向左上”。
    rg_x = np.where(mask > 0.0, rg_x, 128)
    rg_y = np.where(mask > 0.0, rg_y, 128)
    out[:, :, 0] = rg_x.astype(np.uint8)
    out[:, :, 1] = rg_y.astype(np.uint8)
    out[:, :, 2] = np.clip(np.round(density * 255.0), 0, 255).astype(np.uint8)
    out[:, :, 3] = np.clip(np.round(mask * 255.0), 0, 255).astype(np.uint8)
    return out


def _encode_coord(s: np.ndarray, n: np.ndarray, density: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """R 是弧长对 TRAVEL 的小数部分，G 是横向 n，B 疏密，A 水面。"""
    u = np.mod(s / TRAVEL_PX, 1.0)
    v = np.clip(n / N_MAX * 0.5 + 0.5, 0.0, 1.0)
    out = np.zeros(s.shape + (4,), dtype=np.uint8)
    active = mask > 0.0
    out[:, :, 0] = np.where(active, np.clip(np.round(u * 255.0), 0, 255), 0).astype(np.uint8)
    out[:, :, 1] = np.where(active, np.clip(np.round(v * 255.0), 0, 255), 128).astype(np.uint8)
    out[:, :, 2] = np.clip(np.round(np.where(active, density, 0.0) * 255.0), 0, 255).astype(np.uint8)
    out[:, :, 3] = np.clip(np.round(mask * 255.0), 0, 255).astype(np.uint8)
    return out


def _sample_tile(tile: np.ndarray, u: np.ndarray, v: np.ndarray, channel: int) -> np.ndarray:
    """tile 横向循环、纵向夹紧。u/v 都是 0–1。"""
    height, width = tile.shape[:2]
    uu = np.mod(u, 1.0) * width - 0.5
    vv = np.clip(v, 0.0, 1.0) * (height - 1)
    x0 = np.floor(uu).astype(np.int32)
    y0 = np.floor(vv).astype(np.int32)
    fx = uu - x0
    fy = vv - y0
    x0 = np.mod(x0, width)
    x1 = np.mod(x0 + 1, width)
    y1 = np.clip(y0 + 1, 0, height - 1)
    y0 = np.clip(y0, 0, height - 1)
    c = tile[:, :, channel]
    g00 = c[y0, x0]
    g01 = c[y0, x1]
    g10 = c[y1, x0]
    g11 = c[y1, x1]
    top = g00 * (1.0 - fx) + g01 * fx
    bot = g10 * (1.0 - fx) + g11 * fx
    return top * (1.0 - fy) + bot * fy


def _sample_image(img: np.ndarray, x: np.ndarray, y: np.ndarray) -> np.ndarray:
    """双线性采样。越界夹到边缘；调用方再用蒙版丢掉岸上的像素。"""
    height, width = img.shape[:2]
    x = np.clip(x, 0.0, width - 1.0)
    y = np.clip(y, 0.0, height - 1.0)
    x0 = np.floor(x).astype(np.int32)
    y0 = np.floor(y).astype(np.int32)
    x1 = np.clip(x0 + 1, 0, width - 1)
    y1 = np.clip(y0 + 1, 0, height - 1)
    fx = (x - x0)[..., None]
    fy = (y - y0)[..., None]
    g00 = img[y0, x0].astype(np.float32)
    g01 = img[y0, x1].astype(np.float32)
    g10 = img[y1, x0].astype(np.float32)
    g11 = img[y1, x1].astype(np.float32)
    top = g00 * (1.0 - fx) + g01 * fx
    bot = g10 * (1.0 - fx) + g11 * fx
    return top * (1.0 - fy) + bot * fy


def _dual_weight(p0: float) -> tuple[float, float, float]:
    """标准流向双相位权重。p0 回绕时权重为 1，另一层回绕时权重为 0。"""
    p0 = p0 % 1.0
    p1 = (p0 + 0.5) % 1.0
    weight = abs(p0 - 0.5) * 2.0
    return p0, p1, weight


def composite_frame(
    base: np.ndarray,
    flow: np.ndarray,
    coord: np.ndarray,
    tile: np.ndarray,
    detail_enc: np.ndarray,
    phase_01: float,
    strength: float,
) -> np.ndarray:
    """由已保存的贴图合成一帧。保护区蒙版为 0 的像素原样拷回。"""
    mask = flow[:, :, 3].astype(np.float32) / 255.0
    density = flow[:, :, 2].astype(np.float32) / 255.0
    dx = flow[:, :, 0].astype(np.float32) / 255.0 * 2.0 - 1.0
    dy = flow[:, :, 1].astype(np.float32) / 255.0 * 2.0 - 1.0
    u = coord[:, :, 0].astype(np.float32) / 255.0
    v = coord[:, :, 1].astype(np.float32) / 255.0
    p0, p1, weight = _dual_weight(phase_01)
    active = mask > 0.0
    out = base.copy()
    if not active.any():
        return out
    ys, xs = np.nonzero(active)
    # 贴图自己横向循环，相位直接平移。不要再把差半圈的两层混在一起：
    # 那会在偶数谐波上采到同一个纹素，亮带停在原地。
    rip = _sample_tile(tile, u[ys, xs] - phase_01, v[ys, xs], 0)
    centered = (rip - 0.5) * 2.0
    # 笔触：两层都沿流向的反方向取样，等于把上游细节送到这里。
    x = xs.astype(np.float32)
    y = ys.astype(np.float32)
    local = _decode_detail(_sample_image(detail_enc, x, y))
    hp0 = _decode_detail(_sample_image(detail_enc, x - dx[ys, xs] * p0 * ADVECT_TRAVEL_PX, y - dy[ys, xs] * p0 * ADVECT_TRAVEL_PX))
    hp1 = _decode_detail(_sample_image(detail_enc, x - dx[ys, xs] * p1 * ADVECT_TRAVEL_PX, y - dy[ys, xs] * p1 * ADVECT_TRAVEL_PX))
    hp = (1.0 - weight) * hp0 + weight * hp1
    # 源点如果没有水面细节，解码接近 0，不会把岸色加进来。
    m = mask[ys, xs] * strength
    amp = RIPPLE_AMP * density[ys, xs] * m
    pos = np.clip(centered, 0.0, 1.0)
    neg = np.clip(-centered, 0.0, 1.0)
    rgb = base[ys, xs].astype(np.float32)
    # 细节只允许轻轻挪动。上下限是电平，不是再乘一次蒙版。
    shift = np.clip(hp - local, -ADVECT_CLAMP, ADVECT_CLAMP)
    rgb = rgb + shift * (m * ADVECT_GAIN)[:, None]
    rgb = rgb + pos[:, None] * amp[:, None] * POS_TINT + neg[:, None] * amp[:, None] * NEG_TINT
    out[ys, xs] = np.clip(np.round(rgb), 0, 255).astype(np.uint8)
    return out


def _save_maps(
    script_dir: str,
    flow: np.ndarray,
    coord: np.ndarray,
    tile: np.ndarray,
    detail_enc: np.ndarray,
    mask: np.ndarray,
    protect: np.ndarray,
) -> None:
    Image.fromarray(flow, "RGBA").save(os.path.join(script_dir, "flow_map.png"), optimize=True)
    Image.fromarray(coord, "RGBA").save(os.path.join(script_dir, "coord_sn.png"), optimize=True)
    Image.fromarray(np.clip(np.round(tile * 255.0), 0, 255).astype(np.uint8), "RGB").save(
        os.path.join(script_dir, "ripple_tile.png"), optimize=True
    )
    Image.fromarray(detail_enc, "RGB").save(os.path.join(script_dir, "water_detail.png"), optimize=True)
    Image.fromarray(np.clip(np.round(mask * 255.0), 0, 255).astype(np.uint8), "L").save(
        os.path.join(script_dir, "mask_water.png"), optimize=True
    )
    Image.fromarray(np.where(protect, 255, 0).astype(np.uint8), "L").save(
        os.path.join(script_dir, "mask_protect.png"), optimize=True
    )


def export_preview(script_dir: str, base: Image.Image) -> None:
    tex = os.path.join(script_dir, "godot_preview", "textures")
    os.makedirs(tex, exist_ok=True)
    base.convert("RGBA").save(os.path.join(tex, "near_path_base.png"), optimize=True)
    for name in ("flow_map.png", "coord_sn.png", "ripple_tile.png", "water_detail.png", "mask_water.png", "mask_protect.png"):
        shutil.copy2(os.path.join(script_dir, name), os.path.join(tex, name))
    print(f"Exported preview textures to {tex}")


def _motion(a: np.ndarray, b: np.ndarray, water: np.ndarray, protect: np.ndarray, label: str) -> float:
    delta = np.abs(a.astype(np.int16) - b.astype(np.int16))
    channel = delta.max(axis=2)
    water_mean = float(delta[water].mean()) if water.any() else -1.0
    protect_max = int(delta[protect].max()) if protect.any() else -1
    water_gt20 = float((channel[water] > 20).mean()) if water.any() else -1.0
    print(
        f"{label} mean {delta.mean():.2f} water {water_mean:.2f} "
        f"frac>8 {(channel > 8).mean():.3f} frac>20 {(channel > 20).mean():.3f} "
        f"water_frac>20 {water_gt20:.3f} "
        f"max {int(delta.max())} protect_max {protect_max}"
    )
    return water_mean


def _direction_diagnostic(coord: np.ndarray, tile: np.ndarray, mask: np.ndarray, n_frames: int) -> None:
    """沿溪床（画面 +Y）跟踪同一条亮带。索引增加是下游，绕回数组头也算往前。"""
    active = mask > 0.45
    if int(active.sum()) < 50:
        print("direction diagnostic skipped: water mask too small")
        return
    u = coord[:, :, 0].astype(np.float32) / 255.0
    v = coord[:, :, 1].astype(np.float32) / 255.0
    cols = []
    height = mask.shape[0]
    for y in range(548, min(830, height), 2):
        xs = np.where(active[y])[0]
        if xs.size < 3:
            continue
        cols.append((y, int(np.median(xs))))
    if len(cols) < 16:
        print("direction diagnostic skipped: center samples too few")
        return
    samples_u = np.array([u[y, x] for y, x in cols], dtype=np.float64)
    samples_v = np.array([v[y, x] for y, x in cols], dtype=np.float64)

    def rip_at(phase: float) -> np.ndarray:
        # 与 composite_frame 相同：整圈平移，不混半圈那一层。
        return _sample_tile(tile, samples_u - phase, samples_v, 0)

    def smooth_line(arr: np.ndarray) -> np.ndarray:
        kernel = np.exp(-0.5 * (np.arange(-5, 6) / 2.2) ** 2)
        kernel /= kernel.sum()
        return np.convolve(arr, kernel, mode="same")

    def crests(arr: np.ndarray) -> np.ndarray:
        smooth = smooth_line(arr)
        peaks = np.where((smooth[1:-1] >= smooth[:-2]) & (smooth[1:-1] > smooth[2:]))[0] + 1
        if peaks.size == 0:
            return np.array([int(np.argmax(smooth))], dtype=np.int32)
        return peaks.astype(np.int32)

    print("direction crest (sample index along +Y, step > 0 means downstream):")
    n = len(cols)
    cursor = int(crests(rip_at(0.0))[0])
    for step in (1, 2, 4, 8):
        if step >= n_frames:
            break
        peaks = crests(rip_at(step / float(n_frames)))
        # 只在预期的下游小步里接上一条亮带，不把另一条亮带记成倒流。
        deltas = (peaks - cursor) % n
        forward = deltas[deltas <= max(8, n // 6)]
        if forward.size == 0:
            delta = int(np.min(deltas))
        else:
            delta = int(np.min(forward))
        cursor = (cursor + delta) % n
        print(f"  frame {step:02d} crest {cursor:3d} step {delta:+d}")
    # 半圈必须换成另一组亮带。差接近 0 表示贴图又退化成半周期，画面会像静帧。
    quarter_diff = float(np.mean(np.abs(rip_at(0.0) - rip_at(0.25))))
    half_diff = float(np.mean(np.abs(rip_at(0.0) - rip_at(0.5))))
    print(f"quarter-travel ripple diff {quarter_diff:.4f} half-travel {half_diff:.4f}")
    if quarter_diff < 0.08 or half_diff < 0.08:
        raise RuntimeError("ripple phase shift is not visible along the creek")


def generate(out_dir: str | None = None, n_frames: int = 40, base_path: str | None = None, export_preview_tex: bool = False) -> None:
    script_dir, _repo, base_path = _paths(base_path)
    if out_dir is None:
        out_dir = os.path.join(script_dir, "anim_frames")
    os.makedirs(out_dir, exist_ok=True)

    base_img = Image.open(base_path).convert("RGBA")
    if base_img.size != BASE_SIZE:
        print(f"WARN: base size {base_img.size} != {BASE_SIZE}")
    rgb = np.array(base_img.convert("RGB"))
    cool_raw = _coolness(rgb)
    cool = _blur_l(np.clip(cool_raw + 40.0, 0, 255), 1.1) - 40.0
    pts = trace_centerline(cool)
    if len(pts) < 6:
        raise RuntimeError("centerline too short; creek trace failed")
    arc, tangent, _seg_len = _polyline_metrics(pts)
    # 顶点比线段多一个，半径按顶点计，切线补最后一段的方向
    tangent_at_vertex = np.vstack([tangent, tangent[-1]])
    radii = measure_radii(cool, pts, tangent_at_vertex)
    field = map_flow_field(cool.shape, pts, arc, tangent, radii)
    masks = build_masks(rgb, cool_raw, field)
    dx, dy = smooth_directions(field, masks["mask"])
    flow = _encode_flow(dx, dy, masks["density"], masks["mask"])
    coord = _encode_coord(field["s"], field["n"], masks["density"], masks["mask"])
    tile = make_ripple_tile()
    _assert_tile_not_half_periodic(tile)
    detail = build_detail(rgb, cool_raw, masks["mask"])
    detail_enc = _encode_detail(detail)
    _save_maps(script_dir, flow, coord, tile, detail_enc, masks["mask"], masks["protect"])

    # 从刚写盘的贴图读回，帧和提交的 png 使用同一套 8-bit 量化。
    flow = np.array(Image.open(os.path.join(script_dir, "flow_map.png")).convert("RGBA"))
    coord = np.array(Image.open(os.path.join(script_dir, "coord_sn.png")).convert("RGBA"))
    tile = np.array(Image.open(os.path.join(script_dir, "ripple_tile.png")).convert("RGB")).astype(np.float32) / 255.0
    detail_enc = np.array(Image.open(os.path.join(script_dir, "water_detail.png")).convert("RGB"))

    print(f"centerline points {len(pts)} arc_px {arc[-1]:.1f}")
    print("centerline", " ".join(f"({p[0]:.0f},{p[1]:.0f})" for p in pts[::3]))
    water_px = int((masks["mask"] > 0.2).sum())
    print(f"water px>0.2 {water_px} protect px {int(masks['protect'].sum())}")

    for i in range(n_frames):
        phase = i / n_frames
        frame = composite_frame(rgb, flow, coord, tile, detail_enc, phase, 1.0)
        Image.fromarray(frame, "RGB").save(os.path.join(out_dir, f"stream_frame_{i:02d}.png"), optimize=True)

    static = composite_frame(rgb, flow, coord, tile, detail_enc, 0.0, LOW_MOTION_STRENGTH)
    Image.fromarray(static, "RGB").save(os.path.join(out_dir, "stream_static_low_motion.png"), optimize=True)

    sample_dir = os.path.join(script_dir, "sample_frames")
    os.makedirs(sample_dir, exist_ok=True)
    for idx in (0, 10, 20, 30):
        src = os.path.join(out_dir, f"stream_frame_{idx:02d}.png")
        if os.path.isfile(src):
            shutil.copy2(src, os.path.join(sample_dir, f"stream_frame_{idx:02d}.png"))
    shutil.copy2(os.path.join(out_dir, "stream_static_low_motion.png"), os.path.join(sample_dir, "stream_static_low_motion.png"))

    # 诊断：保护区应几乎不动；水面要有变化；首尾接缝应接近相邻帧，而不是跳变。
    last = n_frames - 1
    f0 = np.array(Image.open(os.path.join(out_dir, "stream_frame_00.png")))
    f1 = np.array(Image.open(os.path.join(out_dir, "stream_frame_01.png")))
    protect = masks["protect"]
    water = masks["mask"] > 0.35
    _motion(f0, f1, water, protect, "frame00 vs 01")
    if n_frames > 10:
        f10 = np.array(Image.open(os.path.join(out_dir, f"stream_frame_{min(10, last):02d}.png")))
        water_0_vs_10 = _motion(f0, f10, water, protect, "frame00 vs 10")
        # 水面平均电平差要明显高于预审那条「看不出在动」的线。
        if water_0_vs_10 < 12.0:
            raise RuntimeError(f"water-band frame00 vs 10 diff {water_0_vs_10:.2f} is still too small")
    if n_frames > 20:
        f20 = np.array(Image.open(os.path.join(out_dir, "stream_frame_20.png")))
        _motion(f0, f20, water, protect, "frame00 vs 20")
    if last > 0:
        f_last = np.array(Image.open(os.path.join(out_dir, f"stream_frame_{last:02d}.png")))
        _motion(f0, f_last, water, protect, f"frame00 vs {last:02d} seam")
    # 桥、纸边、右下草地再单独报一次，方便审阅时对上区域。
    bridge = _rect_mask(cool.shape, BRIDGE_BOX)
    paper = _paper_mask(cool.shape)
    meadow = _rect_mask(cool.shape, (430, 508, 1672, 941))
    for name, region in (("bridge", bridge), ("paper", paper), ("meadow", meadow)):
        if last <= 0 or not region.any():
            continue
        delta = np.abs(f0.astype(np.int16) - f_last.astype(np.int16))
        print(f"{name}_max {int(delta[region].max())}")
    _direction_diagnostic(coord, tile, masks["mask"], n_frames)

    if export_preview_tex:
        export_preview(script_dir, base_img)
    print(f"Generated {n_frames} frames + static in {out_dir}")
    print(f"Base: {base_path}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Generate #749 stream isolation flow frames")
    ap.add_argument("--frames", type=int, default=40)
    ap.add_argument("--out", default=None)
    ap.add_argument("--base", default=None)
    ap.add_argument("--export-preview", action="store_true")
    args = ap.parse_args()
    generate(out_dir=args.out, n_frames=args.frames, base_path=args.base, export_preview_tex=args.export_preview)


if __name__ == "__main__":
    main()
