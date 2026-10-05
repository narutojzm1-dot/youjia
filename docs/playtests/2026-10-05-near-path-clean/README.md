# 近郊清底换图：拾物前后对照（CURSOR-CLOUD，#153 / #155，EXP-PAINTED-PATH）

运行时近郊底图 `assets/holiday/exploration/near_path_02.webp` 换成制作人清底版（#393 最终 `c2f342d`，清底 PNG SHA256 `ade3ee41…487b`，底稿 `02_near_path.png` 为 `8ab62a6d…f154`）。之前画里草地上画着一颗松果和一根落羽，玩家在门口带上落羽后，画里还留着一份“同样的东西”。清底版只改了 x1256–1428 / y761–841 这一块（7725 像素），路线、停留点、锚点、程序都没动。

## 对照

| 图 | 内容 |
| --- | --- |
| `compare-portrait-feather-carried.webp` | 390×844 竖屏，门口带上落羽后（篮子里已有落羽）：左为旧图，人物右下草里仍画着松果和落羽；右为新图，那里只剩草和落叶 |
| `compare-landscape-gate-look.webp` | 1280×720 横屏，门口停下看（“这里有落羽”）：左旧右新，画面右下同一位置 |
| `compare-runtime-art-detail-2x.webp` | 运行时 WebP 本身在清底区附近的 2 倍放大裁切（画面 1196,711–1488,891）：左旧右新 |
| `frames/` | 原始截帧：落羽在门口（`gate`）、松果在树荫（`shade`，门口不给松果），横竖各一组，`before-*` 旧图、`after-*` 新图 |

`capture-log.txt` 记录四次运行的画面尺寸、停留点、种子和带上结果：四次都 `picked true`，篮子里各是对应拾物。

## 复现

```bash
export XDG_DATA_HOME=$(mktemp -d)
godot --headless --path . --import
YOUJIA_CAPTURE_DIR=/tmp/npc YOUJIA_CAPTURE_TAG=after-landscape godot --path . --resolution 1280x720 --script tools/capture_near_path_clean.gd
```

竖屏需在项目根临时写 `override.cfg`（`[display]` 下 `window/size/viewport_width=390`、`viewport_height=844`、`window_width_override=390`、`window_height_override=844`），截完删掉。旧图那组是把换图前的 WebP 临时放回、重新导入后跑同一脚本。

## 范围

这是 headless 之外的本机真实渲染截帧，不是 Web 公开版、真机或真人体验验收。清底版是否算正式美术终验仍由 GAME-PRODUCER 决定；圆石（#397）与正式小物精灵不在本次范围。
