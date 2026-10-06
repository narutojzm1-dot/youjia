# PR432 正式公开：两条空篮触摸/键盘路径有限通过

独立执行 review301。正式source `96f090a63e0997244924a7463bd0e52a025b57b1`，两fresh Chromium context、1280×720 DPR2、has_touch/is_mobile模拟。各页开始/结束四份manifest完整SHA一致，HTML均game-96f090a；每页通过同context HTTP请求实际下载版本PCK，200、27,085,436字节、SHA256 `8b5c85763a480a9f7a6e40196ccd0a5b04b645be2a79391c0c1b63eca04c6aa0`。这是实际下载核验，不冒浏览器引擎响应CDP逐字拦截。未使用旧candidate ff17哈希。

## 触摸

实际touchscreen.tap标题→出口(329,563)，初入与追加等候均仍近郊空篮；普通路面(706,500)触摸后人物走开，追加等候仍近郊（touch-still-outside.png已亲看）。之后tap院门(1060,390)，保7秒取样并继续14秒正常等待；touch-return.png明确“回到院里了。空手走一趟也舒服。”，不是初次arrive或restored中断提示。本次路面输入没有复现旧版异常返院。

## 键盘

第二fresh context标题与出门仍用普通touch输入；近郊ArrowLeft保持1800ms后人物沿路走开（keyboard-walked.png），ArrowRight保持5000ms、正常等待2500ms后keyboard-return.png明确“回到院里了。”。已亲看outside/walked/return原图。本路径不是纯键盘标题导航，也不是携物返回矩阵。

## 限制及保留观察

两路线按计划各一次，无额外重试；driver实际exit0，pageerror/console error数组为空。原图与真实输入/导航/DOMContentLoaded/console单调时序全保留，未写业务状态、位置、seed、时钟或存档。未观察全DB，不证明物品守恒/携三物/故障恢复；不是真机触摸、听验或全场景验收。

触摸返院原图仍可见院景右偏，关联既有#400范围，不声称432修复镜头。正常初次入院图自然含arrive文案，验收只以明确正常返回图判断。该有限通过不覆盖#399全部剩余验收或其他输入问题，不自动关父单。

run.py为实际执行驱动，result.json为最终原始输出，run.log/exit-code.txt记录实际退出；archive-manifest.json列全部原件hash（不含自身）。没有修改图片或重新命名旧失败为通过。
