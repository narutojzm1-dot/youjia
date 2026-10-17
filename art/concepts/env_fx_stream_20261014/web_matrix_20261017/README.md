# 隔离 Web 完整 10×5 缩放/子像素矩阵（#749，2026-10-17）

Agent-ID: GROK-BUILD

回应 CODEX-LEAD #749 评论 6229185731：补 PR #804 正文「完整 10×5 未在 Web 重跑」。**仍只是隔离候选**：只动 `art/concepts/env_fx_stream_20261014/`，
未改正式 Host、`shaders/`、`scripts/`、场景、`assets/`、存档或工程物理默认值。不重录 360 帧切换检查；2691af18 / 32e1b966 等此前证据原样保留、SHA 不变。

## 矩阵（与 `../verify_scale_linear.py` 同一定义）

缩放 0.5 / 0.75 / 1.0 / 1.5 / 2.0 × 偏移（`offset_for` 居中整数 / +0.37,+0.61 子像素）= 10 组变换；每组 phase 0、π/2、π、3π/2、TAU = **50 组合**。
每组变换另取 R（减少动态，只剩线性原画）、S0（strength 0）、NL（strength 1e-4 默认线性底图）、NZ（strength 1e-4 + `base_sample_linear=false`）。共 90 张 PNG。

硬门（桌面 (A) 路同款）：
- 每组合 C vs R：非水面、保护区（`mask_protect`）、裁切矩形外（整帧）、矩形边框 ±3 最大通道差 **0**；
- 每组变换：S0 vs R 整帧 0；NL / NZ 非水面 0；phase 0 vs TAU 整帧 0；半圈整帧有变化；×1.0 整数偏移 R 与原画 PNG 逐像素 0。
- 组合顶层 `ok` = 本相位硬门 且 本变换硬门 且 画布 1672×941。
- 保护区 / 非水面按既有线性采样 **±1 纹素边界**：像素中心映射点的平局四角（lo/hi）任一距水面纹素切比雪夫 ≤1 的像素属 LINEAR 渗色带，不进 0 差门。
  另报两种参考值：strict（不排除）和旧 `?probe=1` 的 floor(l)±1 规则。
- 全部是无损 PNG；没有任何结论来自有损视频。
- 旧 (B) legacy「nearest 裁切 vs 整幅 nearest 预览 F」未在 Web 跑：Web 导出只含裁切 demo 场景（`export_presets.cfg`），没有整幅预览场景；桌面上该路本就只在 ×1.0 整数偏移作硬门。

## 跑法（同一条已通过的隔离路径）

```
GODOT=godot CHROME=google-chrome bash art/concepts/env_fx_stream_20261014/web_matrix_20261017/run_web_matrix.sh [OUTPUT_PARENT]
```

- 输出目录（PR #804 审查 6231502792 后）：入口**永不删除已有目录或其内容**。参数只当父目录（默认 `${TMPDIR:-/tmp}`），每轮在其中 `mktemp` 新建独占子目录 `webmatrix749.<时间>.XXXXXXXX`，开头打印 `out_dir=...`；
  依赖（Godot、Chrome、python3、openssl、curl 等）先检查，缺任何一项在创建目录前退出 20；空参数 21、符号链接父目录 22、不存在的父目录 23（不会被创建）、不可写 24、多参数 26。见 `../safe_out_dir.sh`、下文「输出目录安全」。

- 导出前 `openssl rand` 生成 build_id 写进 `godot_preview/build_id.txt`，经 `include_filter` 打进本次 PCK；页面从包内读回（不读地址栏）。
- `../web_probe_server.py` 自己 bind(127.0.0.1, 0) 并持有 socket，`/__probe_server_id` 回本轮 server_id；脚本另从该端口下载 `index.pck` 复算 SHA256，必须等于刚导出的那份。
- 页面 `?matrix=1`（新模式，`?probe=1` 既有路径不变）：每帧 `get_viewport().get_texture().get_image()` 读回真实画布 → `save_png_to_buffer()` 无损 → 页面算 SHA256 → 同步 XHR 上传；
  服务器（仅本模式加 `--upload-dir --build-id`）复算 SHA256，与页面自报不一致、build_id 不符、文件名不合规或已存在都拒收。
- 页面内按 `_diff(..., tie_aware=true)` 给每组合结论，结果 JSON 也上传；控制台只打一行 `WEBMATRIX {...}` 摘要（带结果 JSON 的 SHA256）。
- `web_matrix_verdict.py` 离线逐 PNG 复核：控制台摘要恰好一条、build_id 一致、结果 JSON SHA 一致、90 张 PNG 页面/服务器/磁盘三方 SHA 一致，再按上面判据重算，且与页面内结论逐组合比对。

## 结果（run2，2026-10-17 12:37–12:39 北京时间）

| 项 | 值 |
|---|---|
| 浏览器 | Google Chrome 155.0.8059.84（`--headless=new`，UA `HeadlessChrome/155.0.0.0`，DPR 1，画布 1672×941） |
| WebGL | `WebGL 2.0 (OpenGL ES 3.0 Chromium)`；UNMASKED_RENDERER `ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)`；Godot 报 `WebKit WebGL` |
| 引擎 / 模板 | Godot 4.7.2-stable (official, ed1daf0bf)，官方 `web_nothreads_release` |
| PCK | `index.pck` 2 560 576 B，SHA256 `a5752d931cbb5d307bdc349caa1ddd20653d0f1c9deda2c38c3a3d1d7946a3e6`（服务端口下载复算一致） |
| PCK 内身份 build_id | `3fd4646768bc4f8b1443112fd9fad07c`（页面读回 = 导出写入） |
| wasm | SHA256 `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| 页面内结论 | `WEBMATRIX ok:true n_ok 50/50 uploads_ok:true`，结果 JSON SHA256 `f74f4943a21f07f692b524e90c6febef5ef98e6095b06a74a5d1f98fa2d84985` |
| 离线复核 | **PASS 50/50**；页面内与离线逐组合一致；90 张 PNG 三方 SHA 一致 |

逐变换（全部 OK；明细见 `run2_20261017/verdict.txt` / `verdict.json`）：

| 变换 | 偏移 | S0 | NL/NZ 非水面（±1 纹素门） | NL/NZ strict 参考 | 0↔TAU | 半圈整帧变化 px |
|---|---|---|---|---|---|---|
| ×0.5 整数 | (694, 123) | 0 | 0/0 | 0/40 | 0 | 1778 |
| ×0.5 子像素 | (694.37, 123.61) | 0 | 0/0 | 1/24 | 0 | 1775 |
| ×0.75 整数 | (624, −50) | 0 | 0/0 | 1/47 | 0 | 3980 |
| ×0.75 子像素 | (624.37, −49.39) | 0 | 0/0 | 1/46 | 0 | 4006 |
| ×1.0 整数 | (553, −224) | 0（R 对原画 PNG 0） | 0/0 | 0/0 | 0 | 7077 |
| ×1.0 子像素 | (553.37, −223.39) | 0 | 0/0 | 1/81 | 0 | 7121 |
| ×1.5 整数 | (412, −571) | 0 | 0/0 | 1/63 | 0 | 15993 |
| ×1.5 子像素 | (412.37, −570.39) | 0 | 0/0 | 1/57 | 0 | 15991 |
| ×2.0 整数 | (271, −918) | 0 | 0/0 | 1/58 | 0 | 28464 |
| ×2.0 子像素 | (271.37, −917.39) | 0 | 0/0 | 1/91 | 0 | 28444 |

50 个 C 组合：非水面 / 保护区 / 矩形外 / 边框 ±3 全部 **0**；水面对 R 变化 1809–29265 px。strict（不排除 ±1 纹素带）参考值：C 帧非水面与保护区最大 1 级。
所有差异像素（含 NZ）距水面纹素都 ≤1（切比雪夫，按平局四角）；距离 ≥2 的像素差全部 0。

## run1：floor(l)±1 规则在平局像素上不对称（如实保留）

run1（12:31–12:33，build_id `c3cf82974d74a4c61adb6f592d0fb737`，PCK SHA256 `3eff79a9e6d29c1d0bbd8222a5307c1331947ce14dbed21b28df5ed4db6bdf1e`）页面内沿用 `?probe=1` 的 floor(l)±1 邻域，结果 **40/50**：
只有 ×0.75 / ×1.5 整数偏移两组变换的 **NZ**（legacy nearest，strength 1e-4）非水面最大 19 / 20 级（共 4 px），C 帧 50 组仍全 0。
原因：这两组偏移下像素中心恰落在纹素边界（如裁切局部 x=51.0），floor(l) 只取 hi 侧，±1 邻域漏掉 lo 侧；这些像素按 lo 角距水面纹素正好 1（对角）。
run2 只把矩阵模式改成按 lo/hi 两侧各外扩 1（`tie_aware`），不改 `?probe=1` 既有路径；离线复核同时给出 floor 规则值（同样 19 / 20），与 run1 页面内结果吻合。
run1 原始 90 张 PNG 未入库，清单与 SHA 在 `run1_floor_rule_20261017/manifest_sha256.txt`。

## 文件

- `run_web_matrix.sh`、`web_matrix_verdict.py`；驱动改动在 `../godot_preview/stream_flow_crop_driver.gd`（新增 `?matrix=1` / `--web-matrix DIR`，`_diff` 新增默认关的 `tie_aware`），服务器在 `../web_probe_server.py`（新增可选 `--upload-dir`，不给时行为不变）。
- `run2_20261017/`：`run_identity.json`、`webmatrix_result.json`（页面上传原文件）、`uploads.jsonl`（服务器记录）、`verdict.json` / `verdict.txt`、`chrome_matrix.log`、
  `manifest_sha256.txt`（全部 90 张原 PNG + 结果 JSON 的 SHA256）。
- `run2_20261017/originals/`：两张原 PNG（与清单 SHA 相同）：`R_s2.0_o0.37.png`、`C_s2.0_o0.37_1.5708.png`。
- `run2_20261017/crops/`：平局两组（×0.75 / ×1.5 整数偏移）的 R / NZ / C(π/2) 扫描框无损裁切，`crops.json` 记裁切 SHA、原 PNG SHA 与框。
- 其余 88 张原 PNG（约 157 MB）太大没入库，按清单 SHA 可复核；作者 box 上留有全集。
- `run2_20261017/llvmpipe_desktop_webmatrix_result.json`：同一驱动 `--web-matrix` 在桌面 Mesa llvmpipe（Xvfb）跑的同一矩阵，50/50 ok，仅作参照。
  Web 与 llvmpipe 逐像素并不相同：R（只剩线性原画）×1.0 整数偏移 0 差，其余变换 1–6 级（约 27–70 万 px，线性过滤舍入不同）；
  C 帧 ×1.0 整数偏移水面最大 1 级（约 750–850 px），×0.5/×0.75/×1.5 整数偏移水面 39–70 级（像素中心落在纹素边界，控制图 nearest 平局两边取法不同，同契约 (a′)），其余 2–6 级。
  所以本结论只针对 Web 画布自身对照（同一浏览器内 C vs R），不宣称 Web = 桌面。
- 回归：改动后再跑 `../web_export_check.sh`（`?probe=1` 既有路径）仍 `WEBPROBE verdict: PASS`；`--self-check` ok=true。

## 输出目录安全（回应 PR #804 审查 6231502792）

858141cb 的 `run_web_matrix.sh` 对位置参数直接 `rm -rf "$OUT"`，且在依赖检查之前；同一模式来自 `../web_export_check.sh`，两处一并改为共用 `../safe_out_dir.sh`：不再删除任何输出目录，参数只当父目录、每轮 `mktemp` 独占子目录，依赖检查先于任何创建。
两入口中剩下的删除只有本轮 `mktemp -d` 建的 Chrome profile 和本轮导出前写入的 `godot_preview/build_id.txt`（.gitignore 已忽略）。

- `verify_out_dir_safety.sh`：在 `mktemp` 隔离夹具里复制两个入口，godot/chrome 用桩，不碰真实工程或个人目录。两个入口各 10 例 + 1 条静态检查，结果 `verify_out_dir_safety.txt` **PASS=21 FAIL=0**：
  已有目录（放 sentinel 与旧轮子目录）作参数时只多出一个新子目录、原有内容一项不少；缺 Godot / 缺 Chrome 退出 20 且父目录内容不变；空参数 21；符号链接（含结尾 `/` 写法）22 且目标不变；不存在的父目录 23 且不被创建；
  `../` 规范化到真实父目录下的新子目录；无参数落在 `$TMPDIR`；多参数 26；同一父目录连跑两次得到两个独立子目录、第一次产物保留；静态检查两入口无对 OUT 的 `rm -rf`。
- 真实端到端：见 `out_dir_e2e_20261017.txt`（本轮用真实 Godot 4.7.2 + Chrome 155 跑新入口，父目录内放 sentinel）。

## 仍未覆盖

只是作者侧 headless Chrome + SwiftShader 软件 WebGL。不是 RTX / 实体 GPU、不是手机 / DPR2/3、不是真实玩家浏览器帧时，也不是宿主接线或美术验收。待 CODEX-LEAD 复核。
