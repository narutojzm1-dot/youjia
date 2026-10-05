# 首片近郊往返正式接入：体验证据（#153，CURSOR-CLOUD）

真实 `scenes/main.tscn`，不是原型项目或假宿主。画面里近郊小路的远山取自小院原画，路面、小景、圆石/松果/落羽都是**可替换占位**，不是正式美术验收；正式长卷与小物仍按 GAME-PRODUCER / CODEX-LEAD-ASSISTANT 分工交付。

## 本机渲染（`tools/capture_exploration_slice.gd`，全程触屏事件）

运行方式：`YOUJIA_CAPTURE_DIR=<目录> godot --path . --resolution 1280x720 --script tools/capture_exploration_slice.gd`（需要真实渲染器；存档目录用一次性 XDG）。逐步记录见 `native-*-capture-log.txt`。

| 横屏 1280×720 | 竖屏 390×844 | 说明 |
|---|---|---|
| `native-1280-01-yard-go-out` | `native-390-01-yard-go-out` | 点草地下沿靠近石板路的位置，人走过去；按钮显示「出门走走」（花圃的主要触发范围仍归花圃） |
| `native-1280-02-scroll-start` | — | 画卷起点：院门外，提示随时可回，提篮空着；右上「歇一会儿」「回院」，触屏也能暂停 |
| `native-1280-03-brook-look` | `native-390-02-brook-look` | 溪边停下看：字幕在上方，路边的东西有静止柔光地影；「带上」「接着走」 |
| `native-1280-04-basket` | `native-390-03-basket` | 带上后东西出现在提篮里；可放回 |
| `native-1280-05-shade-swap` | — | 树荫下另有一件：篮子满了显示「换成…」，不堆叠 |
| `native-1280-06-yard-kept` | `native-390-04-yard-kept` | 回院站在小路尽头；提交成功后才说「…收好了」 |

运行结束时存档里分别是 `keepsakes: { formal.find.brook_stone: 1 }`（横屏，树荫下显示「换成落羽」但未换）与 `{ formal.find.feather: 1 }`（竖屏）：带回物经 SaveStore 文件提交写入。每趟的东西按种子随机，空手的停留点也会出现。

截图于 PR #322 审核修订后（出门落点移出花圃范围、画卷内暂停按钮）重新拍摄。

## Web 导出（Godot 4.7.2 Web，无线程模板，Chrome headless + SwiftShader）

`web-1280-01-basket`：键盘走到溪边，E 停下看，T 带上落羽。`web-1280-02-yard-kept`：R 回院，「回到院里了。落羽收好了。」另一次空手往返显示「空手走一趟也舒服」；Esc 暂停面板盖住画卷，再按继续。控制台无错误。Web 截图拍于审核修订前，画卷顶栏还没有暂停按钮。headless 浏览器帧率被节流，走到停留点所需的按住时间比真机长，属于测试环境限制。

## 未覆盖

- Web 端关页重开的恢复只在原生侧用真实 SaveStore 验证（`test/exploration_slice_suite.gd`）；不是 #150 的 Web durable ack。
- 真机触屏手感、读屏、低动效下的实际观感需 GAME-QA 体验。
