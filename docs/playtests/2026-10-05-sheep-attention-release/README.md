# PR #395 双羊关注：公开版本独立实玩

执行：CODEX-LEAD 内部独立 QA horse180_repro。只做公开真实 UI，不修改实现，不代替最终源码独审。2026-10-05 UTC；具体输入 UTC 在 actions.json。

## 实际来源绑定

- URL https://narutojzm1-dot.github.io/youjia/ 。两次独立浏览器进程各自 manifest-before/after.json 均为 `10a32bb950894d6c6abfe26e3e3142d3f109e4f9`。
- 两页 responses.json 实际请求 `game-10a32bb.wasm`、`game-10a32bb.pck` 均 HTTP 200。不是用本地候选替代公开体验。
- 公开 PCK 流式实际下载 SHA256 `ba7f0804736798ad1401333da9ff2a2ba5baa0ca4162a38c233551e767d0709d`，与 Leader 发布核验一致；没有重复保存大包。
- Chromium 151 / Godot 4.7.2.stable.official.ed1daf0bf。初始独立新 profile，1280×800 DPR1，正常模式 Playwright mouse.click；关闭整个浏览器进程后，同 profile 新进程 390×844 DPR1。
- 无 observer/Main/存档/坐标状态注入，无 DOM 假图，原图未编辑像素。没有触摸和低动效 Web 注入。

## 真实动作、成功与非命中

- initial→cmd0 标题正常进入院子，step0 初始双羊。
- cmd1 用早先画面位置点击，静观镜头平移后的 step1 明确“这里不能落脚”，未算轻抚成功；cmd2 等待留图。cmd3 地面点击实际走近。
- cmd4 点击绵羊二，step4 有橙色“绵羊二”、成功“你轻轻摸了摸羊”及长脸关注姿态向右侧玩家。身体形状保持自然，未见明显夸张放大或默认心形。玩家和脸部有部分重叠，不冒称完整无遮挡每个像素。
- cmd5 普通地面走近另一羊；cmd6 点击绵羊一，step6 有橙色“绵羊一”和轻抚成功，较小羊头转向玩家一侧。step7 随后观察，step9 再正常轻抚成功。小羊与玩家身体重叠较多，可见头部/轮廓，无明显强拉伸，但本轮不把遮挡图当严格脚锚/全 cel 几何证明；更完整无遮挡候选证据在此前独立候选报告。
- cmd8 地面点显示“这里不能落脚”，未计通过。cmd10 普通移动离开原重叠位置。cmd11 点击当时 HUD 实际为拿草，step11“手里多了一束草”，不算轻抚；cmd12 直接点击羊仍出现轻抚成功。以上非目标/未命中动作全部保留，没有剪掉。
- cmd13 正常手帐 step13 自然出现共享首张“绵羊愿意靠近我了。你伸出手。它没有走。”。本公开新档首次成功是绵羊二，与此前候选首次绵羊一不同；不宣称两只各有独立首照，也不对未读内部字段作断言。
- cmd14 关闭整个浏览器进程（session 57303 exit 0）。随后使用同 profile 启动新浏览器页面，reopened/initial 为窄屏标题，reopened/cmd0 点击“翻开相册”，reopened/step0 实际显示同一照片、文字和羊图像，边框/照片/文字/关闭按钮在屏内。不是仅 reload，也不是只读取数据判成功。reopened/cmd1 关闭浏览器。

## 原始证据与结论限度

精选图：step0、step4（绵羊二成功）、step5/step6（绵羊一前/成功）、step7（随后）、step13（自然首照）、reopened/initial、reopened/step0（真正重开回放）。全部原图均实际打开查看。image-manifest.json 列每张原图尺寸及 SHA。

完整 driver.py / cmd*.json / actions.json / logs.json / responses.json 及 reopened 对应文件保留；stop 命令文件保留，actions 最后写入在最后截图，因此 stop 不在动作 JSON 中。首次启动 Playwright APIRequestContext 取 manifest 遇 IPv6 ENETUNREACH，发生于 page.goto 前，未进入游戏；改用 curl 取 manifest 后正式两会话正常，startup-error.txt 保留说明。

两会话 console.error/pageerror 均为空，GPU 性能 warning 保留。本公开复验确认两羊正常成功轻抚、可见关注反馈/无默认心、自然首照实际持久回放。姿态尺寸判断是实际可见范围内目视结果，动物/玩家遮挡与自然移动存在，不冒称全 cel 精确锚点证明。未新增重复全套 native 测试，未覆盖真机触摸、低动效 Web、所有方向/天气、无限连点时序或长期挂机；发布 Actions/模块哈希由 Leader 独立记录。

## 仓库归档与发布核验

本目录只收录精选原 PNG：step0/4/5/6/13、reopened/initial/step0；未归档图仍保留在原始 `/workspace/sheep-attention-public`，完整原图清单 image-manifest.json 保留，不将未收录图伪称本目录已有。完整两页驱动、命令、动作、日志、响应、前后 manifest 与初始网络错误说明均保留，不收录 profile 或 PCK。original-copy-verification.json 记录复制时全部原件逐字节一致（README 后追加此归档说明，前文原始报告未改）。

Leader 提供并已实际核验的 [公开构建记录](pr395-public-release.json) 显示 PCK 27,078,024 字节及十个存档模块公开内容与源一致；本 QA 另行实际下载 PCK 得到同 SHA。Actions [37322717621](https://github.com/narutojzm1-dot/youjia/actions/runs/37322717621)、Pages [37323764810](https://github.com/narutojzm1-dot/youjia/actions/runs/37323764810) success，完整记录见 pr395-actions.json / pr395-pages.json。PR [#395](https://github.com/narutojzm1-dot/youjia/pull/395) 已合入、已公开发布、已做本文有限实际体验，三种状态分别有证据；这不等于 #121/#30 全范围完成。
