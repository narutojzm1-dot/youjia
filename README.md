# 悠长的假期

一款 2D 休养观察游戏（Godot 4.7）。你突然有了一个悠长的假期，住进阿尔卑斯山脚的独一户：院子、小水塘、羊圈，几只鸭子、两只羊、一头牛、一只大鹅，还有一只经常吐痰的草泥马。

没有失败、倒计时、金币、体力、任务红点或"今日待办"。走近、喂草、溜草泥马，或者发呆。动物的表情会在天气、距离、谁站在谁旁边刚好对上时自己出现，被收进手帐式拍立得相册。草泥马的表情是主线。

**在线游玩：** https://narutojzm1-dot.github.io/youjia/

## 操作

| 按键 | 作用 |
| --- | --- |
| WASD / 方向键 | 散步 |
| 空格 / 底部行动按钮 | 执行按钮显示的动作（拿草、喂草、牵行、放开、抚摸、种植、钓鱼） |
| 鼠标点击 / 触屏 | 选择动物、花圃、水塘，或点击草地散步 |
| Esc | 暂停 / 歇一会儿 |

## 画风

- 动物与角色：毛毡质感
- 天空、山脉、院子与天气：水粉涂料
- 色彩：高明度、暖饱和的多巴胺配色

## 项目结构

- `scripts/game/expression_catalog.gd`：数据驱动的表情条件表（天气 × 谁在谁旁边 × 所在区域 × 玩家状态）
- `scripts/game/yard_interaction.gd`：统一键盘和行动按钮的上下文动作，保留点击选择的具体动物
- `scripts/game/yard_prop_visual.gd`：花圃和钓鱼道具的共享绘制，供院子与照片使用
- `scripts/ui/photo_moment.gd`：记录事件当时的姿态、道具与状态，兼容旧相册
- `scripts/game/yard_world.gd`：固定院子、动物模拟与表情评估
- `scripts/entities/felt_actor.gd`：毛毡动物（换表情贴图、毛球吐痰粒子）
- `scripts/main.gd`：标题、HUD、暂停与拍立得相册
- `localization/zh-CN.json`：简体中文文案

`gh-pages` 分支是 Web 导出后的静态站点，由 GitHub Pages 直接托管。

字体使用 SIL Open Font License（见 `assets/template/fonts/*-OFL.txt`），第三方声明见站点中的 `THIRD_PARTY_NOTICES.txt`。

## 验证

使用 Godot 4.7.2 执行 `npm run verify:daily`，或指定 `GODOT=/path/to/godot`。测试使用隔离的 XDG 存档目录，覆盖交互、自然行走、照片读写、旧存档兼容和手机视口。原生画面检查与 Web 浏览器实测应分别记录。

## 产品文档

- [游戏策划基准](docs/game-design.md)：玩家承诺、体验循环、设计边界、当前系统和未决方向。
- [产品决策与需求变更台账](docs/decisions.md)：需求编号、状态、决策依据、实现记录和线上复核。
- [在线版游玩复核](docs/playtests/2026-10-02-game-1347743.md)：构建 `game-1347743` 的体验步骤与截图证据。
- [协作与合入规范](CONTRIBUTING.md)：用户、Codex 集成负责人和 GROK/其他功能贡献者的分工与冲突处理。
