# #36 栅栏公开模拟触屏归档（范围有限）

Agent-ID: CODEX-LEAD（内部取证host_budget_impl）。仅文档证据，无生产修改。

两个独立Chromium profile，每页HTML实际game-4fa1508与完整manifest source `4fa150819c304b03fb6a36a149e71d4bcd911000` 前置断言；各自前后manifest一致。headless软件WebGL；触屏profile390×844/DPR2/mobile+has_touch，是模拟触屏，不是真机。两个driver均实际exit0，page/console errors=[]。未注入游戏状态、位置、随机、库存或调用游戏业务API；仅普通点击/触摸/Space，首帧DOM事件只读。

## 新增通过：栅栏普通触屏

普通触摸走过院子，靠近后HUD显示“木栅栏边”；tap底部“看看栅栏边”后出现“栅栏脚边的草，被风轻轻压弯”，画面右侧栅栏脚边有草回应，后续文案自然消退。`fence-hit-00.png`、`fence-action-00.png`/01/03均直接查看。未打开围栏、没有新物品/任务提示；未读取库存，不把视觉观察推为内部收益验证。

定位过程真实保留：部分点到不可落脚位置，两次点中移动羊驼进入牵引，均用正常按钮松开；不得把这些命名为fence的早期截图当热点通过。推荐归档initial、walk-east-gate、fence-hit-00、fence-action-00/01/03，其余定位帧未复制入仓；原采集目录 `/workspace/hotspot36-remaining-public` 的全部原图哈希保存在original-capture-manifest.json。

## 未形成通过：取消与携鱼优先级

`unproven-cancel-carry/`保存第二个profile的原动作/来源/错误/driver（未证明的原PNG不入仓）。第二个1280×720/DPR1桌面profile。三次计划栅栏→地面点击，因为当前镜头偏移/天气画面坐标变化及动态动物命中，没有足够证据证明“先命中远热点再走地取消”：第一轮旧坐标不可靠，第二轮后续点中绵羊，第三轮实际进入钓鱼。虽无栅栏成功文案，也不能据此宣称取消验收通过。`cancel-immediate-02`、`cancel-gate-correct-00/03`、`cancel-from-bank-00/02`已直接查看。

普通UI到池边后多次垂钓；真实出现“等着”“收杆”画面，但人工看帧后操作没有稳定在收杆窗口内完成，后续回到动物招呼。`cast-00`、`natural-reel-00`、`reel-observed-00`、`reel-sequence-00`、`reel-after-cancel-probe`已直接查看。不造鱼、不按截图文件名宣称钓获，因此未完成“照片层消失后的持鱼热点优先级”。不把未取得证据判成游戏缺陷。

已有371在途钓鱼优先级、三桌面热点，374花箱/岸石触屏不重复验收。低动效未找到普通用户入口，仍未覆盖。#36长期需求不关闭；本次只新增栅栏触屏可用证据，取消/完整携物/低动效保持待验。原动作与monotonic记录见各result.json，执行脚本run.py保留；PNG未加工。

归档仅六张精选原始触屏PNG，全部直接查看；复制前后字节相同，见archive-provenance.json。未证明探针保留原动作/两页来源及错误，不以缺少截图压缩成通过。旧371/374通过范围仅引用历史，不将本次4fa1508拓展为旧场景全覆盖。

公开HTML原文以html-source.json字符串无损保存，含原始字节长度与SHA256；避免原网页末尾空行触发文档差异门禁，原文未删改。
