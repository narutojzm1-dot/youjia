# PR402 / REQ032 原生声明集成候选

Agent-ID: CODEX-LEAD（内部实施子代理 host_budget_impl，非外部 Assistant）。保留GROK原作者c496ec19054ea1cbd34661a4f7abf21bf2342acb祖先并合main d323db1。运行代码2541189b4b8e161fb9190a290cfbf23e6028ea9e；后续仅本记录及需求台账。未推送/合入/发布，实施者不作独审。

## 实际结果

- Godot 4.7.2独立最小项目，精确生产声明模块与正式suite，124/124、actual exit0、无ERROR。九组首开+同一存活窗口五组resize，包括短横屏、桌面恢复、正文保全、OK可见、确认/取消后连接数回基线，以及取消同时排队resize。不是完整游戏启动或完整daily结果。
- X11真实原生窗口/llvmpipe，真实XTest指针点击OK后CONFIRM_CLOSED=true、点击关闭X后CANCEL_CLOSED=true，driver actual exit0。同一打开窗口从宽屏缩390×844再568×320、恢复1280×720。已实际查看原始竖屏/短横屏/恢复桌面截图：标题、关闭X、正文滚动条、OK都在屏内。短横屏client524×251、position(22,49)，外框也计入边距；桌面文字恢复560×320。
- 原始截图为整个X11显示器，无裁剪修图。窗口尺寸由harness设置，普通指针操作用于关闭；不冒物理真机或玩家整局体验。测试项目不加载游戏assets/autoload。
- daily永久入口已登记，模式100755；bash -n exit0。最初独立项目阶段未跑完整工程；随后按root要求复用已完成daylabel全工程cache串行完整daily与Web导出，实际结果见下方续验。

## 被拦候选与原始证据

baseline保留作者120项通过及实际同窗resize裁切：576宽在390窗口右侧溢出。作者测试实际是关闭重开，不能代表live resize。baseline README所列最初键盘/ALSA探索不是确认关闭证据；本归档选用Dummy音频+真实指针的final记录。

candidate/initial-deferred-missing.log保留初次同步回调短横屏两个断言失败；引擎在信号后再处理窗口位置，改deferred。candidate/client-only-suite.log虽然124通过，client-only-short.png实际标题/X顶部仍裁切，实施者看图拦下，不能作为最终通过。最终按主题embedded_border与title_height将装饰外框纳入布局，suite改验外框。最终suite.log、native-final.log、driver.log与validation.json绑定最终运行代码。

复现：从对应SHA取声明模块与suite到附带project.godot的独立目录，运行Godot --headless --path DIR --script test/licenses_dialog_fit_suite.gd。原生使用baseline/xorg.conf启动独立:93显示，candidate/run_native.py记录路径固定/workspace/pr402-candidate；可修改输出/工程位置后复跑，源模块不可换成旧版。不需复制生产assets。


适用边界：当前Godot默认主题与列出的至少320×300视口；不承诺任意自定义theme、操作系统原生外框或更小窗口的完整显示。完整工程后续门禁见本记录下方续验，不将最初独立模块测试冒作完整回归。


## 完整工程续验

准确运行源fdc12c043352059ad91877c0472046fe7ce73410（已合06da REQ031公开记录），复用/workspace/youjia-daylabel-integration完整资源/cache的新validation分支，不改其他活动工程。Godot4.7.2严格tools/verify_daily_life.sh实际exit0，新增licenses124、title1541、confirm562及完整共享存档/相册/输入/桥/加载门禁通过。完整原始full-daily.log与exit文件保留。

随后同树串行正式Web export-release actual exit0，无ERROR/SCRIPT ERROR；原始export.log/exit与export-build.json含PCK及十模块哈希。模板XDG_DATA_HOME=/tmp/262-export-state/data。仅5个已知历史.import自修保持工作区，未提交；无声明以外运行时修改。导出/workspace/confirm373-export复用8195，未碰8194。

最新main d0af19仅writer404发布docs，随后集成保留双方需求状态，没有运行代码/测试/daily变化，不以无变化理由重复整套。最终CI与独立最终SHA审核仍必要；本地通过不等于已发布。

普通Web补验：新隔离Chromium profile，CSS568×320/DPR2、正常标题许可按钮mouse click打开HTML新页，Godot声明正文可读，page/console errors=[]、driver actual exit0，前后candidate-build相同且实际下载PCK哈希匹配。两张原图已看；web目录保原driver/result/exit。此为原有Web入口不回归证明，不冒Web可复现原生dialog修复；无状态注入。
