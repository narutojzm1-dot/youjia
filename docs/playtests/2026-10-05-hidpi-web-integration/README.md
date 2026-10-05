# PR321 Web HiDPI 集成验证

CODEX-LEAD 内部集成，2026-10-05。保留 GROK-CONTRIBUTOR `84f61b218da98ba1ea3b6f482a84a3a7b4392214`，先合并当时 main `c9c10a3`（含照片主体修复），没有改作者 HiDPI 实现。按作者明确请求追加 daily `web_hidpi`、保留 Git 100755，并登记 REQ026/更新已发布 REQ025 状态。

## 一次完整回归

Godot 4.7.2 严格 `tools/verify_daily_life.sh` 退出 0，包含 HiDPI 102项、照片主体9项、通知纸底49项、既有全部suite。`daily.log` SHA256 `d83db73a1196d3a0e436a3f2128f7a3ccb0a62640cf9411c8b2f743e28fe4563`。只执行一次完整 daily。

生产 Web 导出无错误，`index.pck` SHA256 `a026ffb390bbd7672676b2a76f67e80bc852bda369e903a2244c30e24bec6085`。

## 未改生产导出的自然浏览器

Chromium 151 / SwiftShader，真实导出包，正常开始游戏、暂停/Escape、鼠标输入、viewport resize。不是原生模型或改游戏状态的模拟。

- DPR1/2/3，各跑844×390横屏、390×844竖屏；另跑1260×886@1.75。七组均 console error/pageerror 为0（`matrix.json`）。
- canvas保留物理像素：390×844@3为1170×2532，844×390@2为1688×780，但截图 CSS HUD/字号/竖屏布局一致。已实际查看DPR1/2横屏、DPR3竖屏及旋转截图。1.75倍率1260×886实际canvas CSS高度885，物理1550取整带来1px差，不作为完整逐像素相等。
- 独立补跑真实音乐/环境滑杆输入：横屏DPR1/2/3、竖屏DPR3，百分比可变（横屏21%/71%，竖屏20%/68%），截图已查看；不宣称音频听觉验证（`input.json`）。
- 同一活会话用Chromium CDP调整DPR3→2→1.75，canvas分别1170×2532、780×1688、682×1477，暂停布局仍正确（`dynamic.json`，截图已查看）。这是浏览器倍率仿真，不是手机真机、物理换屏或真实浏览器缩放UI的完整验收。

初始固定坐标脚本的animal步骤有落到地面/花箱的情况：自然留影会移动镜头，不能把“发出点击”写成“成功抚摸”。保留JSON原始记录，不计为宠物命中验收；另用下面只读观测验证输入。

公开 Actions/Pages/manifest/PCK 与最终独立审查由PR收尾记录。本地通过不代表已上线；本切片未覆盖真实Safari/iOS、DPR>4或浏览器倍率<1的产品体验。

## 只读观测导出的真实 World 点击

另建隔离导出，只加 `read_only_observer.gd.txt` 自动加载：读取真实动物visual_hit_rect经canvas变换的当帧屏幕中心、真实鼠标事件及反变换目标，监听生产notice信号。未改/传送任何角色、镜头、存档或状态，未直接调用交互；Playwright按观测坐标发真实mouse点击。此包与上面的未改生产包明确分开，不把观测器加入正式project。

844×390 DPR1/2 与390×844 DPR3三组均第一次点击命中 `pet:sheep_a`，随后生产notice为 `notice.pet.sheep`；0console/pageerror，见 `observed-input.json`。DPR1/2输入都是CSS (287,201)→world约(300.046,475.292)，DPR3竖屏CSS(234,465)→world约(299.886,475.568)。已查看DPR3实际“你轻轻摸了摸羊”截图。这个结果排除了DPR导致world指针错位；先前固定坐标失配未被隐藏。
