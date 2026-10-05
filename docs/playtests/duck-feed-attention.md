# #30 鸭成功投鱼后的关注回应

CODEX-LEAD 内部实施子代理 host_budget_impl。只将成功投鱼映射到轻抬头关注，不表示接食、咀嚼或新增关系收益。5秒为单只鸭的视觉间隔，不影响合法新投鱼消费；失败、过期持鱼不演。关注最多2.2秒，随后原作息恢复；移动、特殊摆拍和退出清除姿态。

资源由 GAME-PRODUCER 制作，复用 PR343 `45ef92b9e3afe94a4df0648caa90c37394d7870e` 的 `duck_attend_v2.png`，重命名部署为 `cast_v2/duck_attend.png`。原字节 SHA256 `45343cf93eeac5b25ecfa6fdc55cbdc4f792add98a8f8fb4ace8e37512137eae`；1254×1254；alpha>=200 bbox [202,44,1137,1206)，manifest使用xywh [202,44,935,1162]。同原idle锚点(670,1205)，复用idle比例34/1140，不能按新bbox重新撑高。原来源/提示词及独立审画记录完整保留在上述PR的 PROVENANCE.md、REVISION_V2.md、REVISION_V2_REVIEW.md、engine-evidence/；未重新生成/修改图或覆盖Producer分支。

原PR批准范围为候选和静帧，当前行为接线仍须完整最终SHA独审及运行验证；不以此关闭接食资源#122。

## 最终行为与体验证据

成功投鸭仅自然关注及原成功文案，不再调用默认心形投鱼overlay；鹅成功反馈不变。重复合法投鸭仍消费持鱼，但在视觉间隔内不延长关注、不刷爱心。

专项20检查通过，包含失败/空持鱼、消费、成功与重复无默认heart、脚锚、PhotoMoment原纹理捕获/清洗/重建、移动/位移/posed/退出取消、五秒后恢复、鹅原成功反馈保留。真实Godot4.7.2 Web导出后使用正常UI点击与Space，未经注入玩家位置/持鱼/随机数/计时器；最终natural-catch.png为本次真实钓获，natural-fed.png为随后成功投鸭且无默认心形，natural-album.png为正常打开既有照片。未给投鸭新增解锁照片；鸭关注纹理照片兼容由独立受控专项验证，不能把既有手帐照片称鸭新照片。浏览器pageerror为0，PCK哈希见evidence.json。

验证过程曾因作者在daily中途还原Godot自动改写的既有import导致云带缓存加载失败，该轮作废。随后保持import缓存一致完整重跑；原heart版本截图和未钓获的试跑不作为最终证据。

复跑：用隔离 XDG_DATA_HOME 执行 Godot `--headless --path . --script test/duck_feed_attention_suite.gd`；完整门禁为 `GODOT=/path/to/Godot bash tools/verify_daily_life.sh`；Web `--export-release Web dist/index.html` 后需把 web/save 模块复制到 dist/web/save 再运行附带 browser.py。自然钓鱼有原始随机失手概率，脚本截图需人工核实成功文案，脚本完成本身不代表钓获成功。

### daily门禁状态（候选提交时）

取消鸭默认heart后，完整daily的前缀通过，但旧 interaction_photo 两断言仍要求“鸭heart跟随移动”，因此该完整命令退出非零。已按最新授权改成实际recipient关注姿态、其他鸭不演、无heart、移动清除；鹅断言保留。修订后 interaction_photo 单跑110检查通过。这是旧期望与新行为冲突，不是鱼消费或照片退化；不能把此前完整命令称exit0。最终版本完整daily将另行整跑，候选审查可并行，未通过不合入。

最终补验：上述候选代码 `ec135774a5211047334f7ba26d9d4fd7c598520a` 已整跑完整 `tools/verify_daily_life.sh`，进程exit0，SCRIPT ERROR/ERROR/FAIL扫描为空。包含修订interaction_photo110、fish_carry、旧photo/UI/新版save bridge全部门禁；日志daily-final.log。此补充仅证据更新，没有再修改运行代码。

### 独审补门禁：正常 setup、持续姿态和窄屏

未修改运行代码。专项现在24检查：不再手工设置duck.posed，正常setup后成功投鱼，再tick0.1，核实实际attend纹理、朝向和渲染脚锚仍正确。duck_feed_attention已注册完整daily列表；本次补测不冒称重新跑完完整daily，前次完整exit0对应精确代码ec135774a5211047334f7ba26d9d4fd7c598520a。

隔离test/duck_attention_web构建仅加只读autoloader，读取真实Main/YardWorld和Sprite2D状态；不改位置、持鱼、随机数、计时器或调用交互方法。真实Chromium151在1280×720及390×844通过正常首页、自然钓获、点击具体duck_c完成投鱼。120ms后两者实际texture均duck_attend.png、ack_left分别1.8346/1.8903、foot_error=0、carry为空、heart为空，另两鸭未attention。截图和同一recipient只读JSON存readback；已人工查看两张attention截图。此证据为观测夹具导出，其PCK哈希独立记build.json，不替代既有无探针生产导出或称线上体验。复现：指定GODOT/OUT执行test/duck_attention_web/build.sh，再用Playwright Python执行run.py --web OUT --out evidence。

本地同步main04f9ae3后的候选e38b0bbb567e09cfde711cd54f8780e16ddcaba2再跑专项24通过（postmerge-24.log）。daily列表冲突仅合并两边新增suite，保留day_label_layout/exploration_slice；未把合并前的双尺寸Web/完整daily证据称新main全量复验。

### main 组合与无观测器生产导出补验

本地最终运行源码79db352df17efd6c56208f48b8f8f9e0e11438e5（合main04f9ae3，含Cloud322探索接线）完成duck24、interaction_photo110、exploration_slice116、day_label_layout173；新类导入前首次exploration_slice因旧本地class cache缺ExplorationHost解析失败，未作为通过证据；正常Godot导出刷新后重新独立运行116/173通过，未改运行代码或断言。前述ec135完整daily与当前组合增量分别记载，不冒当前完整daily重跑。

本次无observer的正式Web导出PCK 22,827,252bytes，SHA256 236f4f2b71216ecd52798a698ac82087359a40121d4bde51f8876b3be5fe057c；正常标题→岸边钓鱼→Space收鱼→Space投给鸭子→手帐，原图06真实钓获、07成功投鸭且无默认心形，root已看图，pageerror为空。循环后的额外Space会转向马的招呼，所以不能把较后帧当投鸭；选图只保留真实对应事件。物种/姿态精确字段绑定仍以前述只读观测器证据为准，不声称此无观测生产包读取内部状态。生产导出及受影响组合日志、驱动见merged-production/。尚未宣称公开发布。

### Cloud342 同期合入后的最终组合

远端PR353初次终审期间Cloud自主合入原画沿路PR342（main bc213f9），因此本分支再合该main，并重新执行正式导入、鸭24/交互照片110/原画探索143，全部通过；导出也成功，PCK25,260,420bytes/SHA256 849a23ff5c028bfa9917b3e3417de12d3938c2153bd54dfab7680dc07618371e，对应本地运行SHA e61011587af75084ce1b69fa37d296882199da69，见painted-combination/。本次无冲突合并忠实保留Cloud原实现，鸭运行代码未改。既有自然投鸭与宽窄observer属于前述构建；此处不伪称新包再次完整E2E，公开新组合发布后另补真实体验。
