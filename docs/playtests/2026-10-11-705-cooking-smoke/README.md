# #705 做饭烟囱叶子返修记录（GROK-CONTRIBUTOR）

针对 CODEX-LEAD 对 `8ae4e0a67e6c1155260b80705e544a2187f53549` 的退回。本记录只覆盖烟囱表现叶子、隔离套件和隔离演示。没有挂 Main，没有假做饭事件，也没有实机看烟。

## 跑过的命令

Godot `4.7.2.stable.official.ed1daf0bf`。隔离数据目录与 `tools/verify_daily_life.sh` 相同：单独的 `XDG_*`，并设置 `YOUJIA_TEST_ISOLATED_DATA`。套件通过 `tools/lib/verified_godot.sh` 的 `run_verified_godot_suite` 启动，完成行仍是登记过的 `[cooking-smoke] PASS: N checks`。

本机工作区起初没有 `.godot` 导入缓存。第一次直接跑套件时，无关自动加载、字体和音频打出 `ERROR`，套件自己已经打印 PASS，但 wrapper 因日志里的 `ERROR` 失败。随后按每日脚本的顺序先导入再跑本套件。导入与套件的 wrapper 退出码都是 0。没有重跑完整 `verify_daily_life.sh`。

```bash
export GODOT=/tmp/youjia-godot-472/Godot_v4.7.2-stable_linux.x86_64
state=$(mktemp -d /tmp/youjia-daily-check.XXXXXX)
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
export YOUJIA_TEST_ISOLATED_DATA="$XDG_DATA_HOME"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
source tools/lib/verified_godot.sh
run_verified_godot "$state/import.log" --headless --path . --editor --import --quit
run_verified_godot_suite "$state/run.log" test/cooking_smoke_suite.gd --headless --path .
```

导入后的套件日志见 [suite.log](suite.log)：`[cooking-smoke] PASS: 37 checks`，日志中没有 `SCRIPT ERROR` / `ERROR:` / `FAIL`。37 项包含软圆中心与四角、寿命渐变末尾 alpha、做饭中切换夜色、以及 `ui.reduced_motion` 变化时做饭标志保持而发射重刷。重复 `set_cooking(true)` 不增加节点。

隔离演示场景 `res://scenes/presentation/cooking_smoke_demo.tscn` 用同一 Godot `--headless --path . --quit-after 20` 启动，退出码 0，没有脚本错误。这只说明场景能起来。按键与按钮是 C 做饭、P 暂停、N 夜色、M 减少动态。没有打开窗口看烟。

## 仍要 Leader / QA 看的

- 真实做饭开始/结束事件和屋顶锚点仍未接入。默认锚点 `Vector2(292, 218)` 只是院门热点附近的占位。
- 烟的观感（水粉轻缕、昼夜、镜头缩放、开始/停止/暂停、减少动态）没有实见，不能写成观感通过。
- 合入与 Pages 仍由 CODEX-LEAD 处理。
