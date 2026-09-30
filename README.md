# 悠长的假期

一款 2D 休养观察游戏（Godot 4.7）。你突然有了一个悠长的假期，住进阿尔卑斯山脚的独一户：院子、小水塘、羊圈，几只鸭子、两只羊、一头牛、一只大鹅，还有一只经常吐痰的草泥马。

没有失败、倒计时、金币、体力、任务红点或"今日待办"。走近、喂草、溜草泥马，或者发呆。动物的表情会在天气、距离、谁站在谁旁边刚好对上时自己出现，被收进手帐式拍立得相册。草泥马的表情是主线。

**在线游玩：** https://narutojzm1-dot.github.io/youjia/

## 操作

| 按键 | 作用 |
| --- | --- |
| WASD / 方向键 | 散步 |
| 空格 / 鼠标左键 | 拿草、喂草、牵行草泥马 |
| Esc | 暂停 / 歇一会儿 |

## 画风

- 动物与角色：毛毡质感
- 天空、山脉、院子与天气：水粉涂料
- 色彩：高明度、暖饱和的多巴胺配色

## 项目结构

- `scripts/game/expression_catalog.gd`：数据驱动的表情条件表（天气 × 谁在谁旁边 × 所在区域 × 玩家状态）
- `scripts/game/yard_world.gd`：固定院子、动物模拟与表情评估
- `scripts/entities/felt_actor.gd`：毛毡动物（换表情贴图、毛球吐痰粒子）
- `scripts/main.gd`：标题、HUD、暂停与拍立得相册
- `localization/zh-CN.json`：简体中文文案

`gh-pages` 分支是 Web 导出后的静态站点，由 GitHub Pages 直接托管。

字体使用 SIL Open Font License（见 `assets/template/fonts/*-OFL.txt`），第三方声明见站点中的 `THIRD_PARTY_NOTICES.txt`。
