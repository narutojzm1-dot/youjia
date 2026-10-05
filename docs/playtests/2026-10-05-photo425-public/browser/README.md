# PR425 正式公开普通 QA

review304，2026-10-05。正式source ecea67dba1afc9b99b6097970e4965fbcd99c53a，HTML game-ecea67d；真实逐页PCK SHA2562f3ef524dcd455bf2ffddc8aa064e1f6a707f3fef5fd08b8fb5254f7b33c8085。本地候选9f4/e541证据不混入本次公开验收。

## 主链实际覆盖

两个fresh profile从1280×720开始，DPR2/3，普通标题→院子→羊互动自然首次照片。land-actual-card及portrait-actual-card原clip均确实是自然相纸；随后转568×320/390×844并切系统媒体reduce。但两张*-resized-card原图均已经没有相纸：**两路错过在途捕获，不算正式公开相纸适屏通过**，不能只凭detector=true或文件名计通过。两路正常收起后相册可见相应羊照。

横路同一context真关闭原page，再new_page进入并翻册，reopened-album.png原羊照仍可见。合册后普通出门，outside-initial/outside-stable均近郊空篮，未初出即弹回；普通走开，再鼠标点院门，returned-yard.png明确“回到院里了”。返回后真实翻册，returned-album.png仍见同羊照。图片已实际核看。未读取全DB，因此是视觉同照，不是字节级保存证明；未携三物、未fault矩阵。

主链共3页面，6次前后full manifest绑定及3次实际PCK哈希一致，driver exit0/errors=[]。所有鼠标、resize、media及截图单调时间保留result.json。浏览器媒体仿真非实际OS设置；DPR模拟不是实体手机或touchscreen。未做听验，不冒全部游戏验收。

## 有限补捕与限制

仅追加一次earlyreduce：fresh初始reduce，最小14×210原卡边strip检测后直接resize+PNG，避免在途多次调用延误；检测strip单独不足以证明相纸，须看后续完整图。其结果另列，不覆盖主链原失败。没有注入TuningStore/业务/位置/随机种子/游戏时间，也没有延长1.58/1.6秒演出。

补捕实际结果：earlyreduce/land-resized-card.png **真实捕获568×320相纸**，卡片约x183..386/y57..310，顶部“旅人随手拍下了这一刻。”、日期及中文题词均完整在视口内。已实际看图确认。初始reduce，无在途媒体额外切换；352586.526959执行resize，后续land-expired正常收起、land-album原照可见。该独立页面前后full source及实际PCK仍一致，exit0/errors=[]。因此正式公开短横屏初始reduce的转屏适屏已补到；正式竖屏在途仍未捕获，保持未覆盖（候选e541原证据单列）。不继续重复。
