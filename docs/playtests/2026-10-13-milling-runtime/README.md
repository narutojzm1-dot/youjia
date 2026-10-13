# #700 / #797 磨粉运行候选：原生定向回归与 GPU 表现

这是本地候选的工程与表现证据归档。**普通 Web 整链、最终候选 CI 和公开发布尚未完成。** 搬运物在肖像照片中的归属问题现已追加专门的原生修复与回归证据；本包最初的 21 项视图测试本身没有覆盖或证明那条肖像链。不将受控测试写成普通玩家体验。

测试开始时是 `45ea143b64ba28e59431d1334610ee3321b5eaa6` 上的未提交运行改动；之后运行切片提交为 `0554df0199fddc90c96998795c3c9dfff4e8fd17`，归档时已与 main 合成 `8b0413ed9b1100704713de257060528a9e945a4e`。这些后续提交身份不改写早先实际测试阶段；视图和导演源文件哈希分别保存在 `sources.json` 与 `logs/integration/source-files.sha256.json`，不能把本包当作未来修改后的全量验收。

## 磨盘画面与可达性

晴天：[原始 GPU 图](gpu/integrated-working-sun.png)；阴天：[原始 GPU 图](gpu/integrated-working-overcast.png)；低动效：[原始 GPU 图](gpu/integrated-reduced-overcast.png)。均为 Godot 4.7.2 stable、OpenGL Compatibility、RTX 4070 Laptop GPU 输出的 **1280×720 原始 PNG**，没有缩放重编码、补画或改动像素。

- 原画来自 PR796，运行 PNG 与档案源逐字节一致：`a9248478d8cea22d8244e355b72d71c860a7e4330f3154e844965192b6086f64`，2,358,584 bytes，1335×1178 RGBA。mipmap 和天气乘色属于运行显示；原 PNG 未后处理。
- 最终锚点 `(525,469)`，操作站位 `(553,486)`，素材画布宽 90 世界像素，脚底碰撞半径 `(28,9)`。早期 `(480,495)` 会与出生奶牛碰撞，靠屋 `(450,454)` / `(410,468)` 大半被牛羊遮挡，未采用。
- 真实出生动物布局中，寻路返回 `[(528,504),(553,486)]`。磨盘本体加入碰撞，不能直接穿过其中心。
- GPU 夹具用正常 `world.tick(0)` 初始化人物尺寸与前后层级，再受控设置站位、原有 feed 帧和进度。手部实际为 `(521.3815,431.8344)`，距投料点 `(530,423)` 约 12.3 像素，位于上盘前缘，脚在磨盘前方。这证明姿态/层级适配，不证明玩家已自主完成全链。
- 不旋转或拉伸整件磨盘原图。微小出粉提示只跟随导演提供的进度，没有私有时钟；低动效下固定，取消后消失，不代表已入账的面粉。
- 阴天原图乘色 `(0.83,0.87,0.92)` 后再使用原有院景天气过滤。昼夜仍由世界统一处理，没有第二套夜间计时。
- `fish_first_catch` 等保留人物的照片事件可冻结磨盘、接地细线、工作细线和颜色。既有动物肖像策略会滤掉所有 Line2D；那类肖像保留磨盘原图而不保留新增细线。搬运物归属问题的单独修复见下方追加证据，不由磨盘原图冻结结论替代。

## 实际回归结果

下列都为独立测试数据目录里的原生定向回归。日志完整保留，未去掉错误或失败记录。不同阶段的重复运行不重复计算为新增覆盖。

| 范围 | 最终已完成结果 | 原日志 |
| --- | --- | --- |
| 独立磨盘视图、碰撞、照片冻结与无存档副作用 | 21 / 0 失败 | `logs/view/yard-mill-view-suite.log` |
| 统一自主磨粉导演与事务 | 136 / 0 失败 | `logs/integration/milling_director.log` |
| 原池岸导演兼容 | 292 / 0 失败 | `logs/integration/pond_growth_director.log` |
| 三餐实体导航 | 28 / 0 失败 | `logs/integration/meal_navigation.log` |
| 物理院景与动物路线 | 676 / 0 失败 | `logs/integration/physical_yard.log` |
| 成长材料计划 | 77 / 0 失败 | `logs/integration/growth_materials.log` |
| 面粉进餐 | 24 / 0 失败 | `logs/leader/flour_meal-final.log` |
| 做饭 | 139 / 0 失败 | `logs/leader/house_cooking-final.log` |
| 睡眠 | 154 / 0 失败 | `logs/leader/house_sleep-final.log` |
| 进餐账本 | 85 / 0 失败 | `logs/leader/meal_ledger.log` |
| 进餐计划 | 28 / 0 失败 | `logs/leader/meal_planner.log` |
| 做饭音频 Host 状态 | 71 / 0 失败 | `logs/leader/meal_audio_host.log` |
| 公告数据与布局 | 102 / 0 失败 | `logs/leader/release_notes-final.log` |
| 背篓窄屏修正与面粉条目 | 1660 通过 | `logs/leader/yard_basket_grid-flour.log` |

背篓先出现 **4 / 1640 失败**：中文、英文的 568×320 与 844×390 石头小纸面超出底部。失败全文是 `logs/leader/yard_basket_grid.log`；修正顺序后 `yard_basket_grid-order.log` 为 1640 通过，再加入面粉覆盖后 `yard_basket_grid-flour.log` 为 1660 通过。不能只保留最后的绿灯。

导演的 before-view、材料初次运行和面粉初次运行日志也保留，供检查先后关系。纹理导入日志仅证明实际导入执行，没有替代美术或声音听验。71 项音频 Host 状态测试也不声称新的人耳、硬件或 Web 目的端听验。

### 后续追加：搬运物肖像归属修复

在 `8b0413ed9b1100704713de257060528a9e945a4e` 之后的未提交限定修复中，导演材料和做饭食材两个精灵增加 `photo_player_carried` 元标记，`PhotoMoment._collect` 将其归为 `player`；固定磨盘没有这个标记。这样隐藏拍照者的动物肖像也隐藏其手持材料，包含玩家操作的照片仍可记录材料。确切 7 个源文件哈希与实际日志哈希在 `logs/integration/summary-photo-final.json`；最终提交号由原 PR 另记，避免文档自引用。

追加原生结果为 `growth_carried_photo` **39**、`photo_moment_save` **48**、`photo_moment_render` **2613**、`yard_mill_view` **21**，全部通过（本批合计 2721 项，包含重复视图覆盖，不与之前数字简单累加）。对应完整日志在 `logs/integration/`。

照片渲染套件起初有 **8 项失败**，原文保留在 `photo_moment_render-before-line-fixture.log`：旧夹具将所有 Line2D（包括磨盘两条接地线）都视作牵绳。夹具修正后仍校验真实牵绳的 17 点与逐点几何，并分别校验磨盘细线遵守现行照片策略，未把原几何断言删除以获得通过。这一追加证明限定修复的原生链，不提前声称普通 Web 肖像链通过。

## 复现

使用包含上述运行切片的工作副本、Godot **4.7.2 stable** 和可用 OpenGL Compatibility GPU。不要把验证脚本指向玩家自己的 APPDATA 或已有游戏存档。`reproduce.ps1` 使用一个新建的临时输出/APPDATA 目录，隐藏启动窗口，先导入资源，再跑 21 项视图回归和 GPU 截图；不修改 PNG 原画、不启动 Web 服务。

从仓库根执行（把引擎参数换成已安装的 console 可执行文件）：

```powershell
pwsh -File docs/playtests/2026-10-13-milling-runtime/reproduce.ps1 -GodotExe '<Godot_v4.7.2-stable_win64_console.exe 的绝对路径>'
```

其他定向套件的原入口是 `res://test/{milling_director,pond_growth_director,meal_navigation,physical_yard,growth_materials,flour_meal,house_cooking,house_sleep,meal_ledger,meal_planner,meal_audio_host,release_notes,yard_basket_grid}_suite.gd`，使用同样的隔离环境并逐个 `--headless --path <repo> --script <入口>`。执行前依据源哈希确认修订；不同源码上的新结果应另留日志，不覆盖本档原证据。

捕获脚本 `capture.gd` 的绘制操作与实际原版本一致，唯一维护改动是把私人绝对输出路径换成 `YOUJIA_MILL_CAPTURE_DIR`，并加输出/隔离保护。原执行脚本 SHA-256 为 `610c41739dc5a2460ab941ee9d95ee25c24caa15231fbdda2964f79e0a11cd3f`。归档脚本及复现包装脚本此轮没有再次执行；原截图仍来自原捕获版本。所有复制日志逐字节未变，因为它们未含私人绝对路径；每项原始与归档哈希及规范化说明在 `sources.json`。

`manifest.json` 枚举本目录全部文件（不把清单本身列入），`.gdignore` 阻止归档脚本参与常规项目扫描。没有打包 APPDATA、存档、私人邮件或无关运行文件。

## 尚未覆盖

普通玩家 Web 磨粉→面粉做饭→重开恢复、普通 Web 肖像搬运物归属、最终完整 CI、实体手机/触控和公开 Pages/PCK 身份核验均须另留真实证据。本包不提前把这些项目记作通过。
