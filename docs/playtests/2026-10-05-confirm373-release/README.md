# PR373 确认纸片窄屏：公开鼠标几何验收

状态：PR373 **已合入、已发布；仅本次鼠标几何路径已体验**。不宣称触摸通过，#382 公开触摸问题仍单列，PR386 在独立审核中，不将其候选算入本构建。

## 发布来源

公开源 `e0d699b8cbaecfabc24a70d2144a7188b5808880` / `game-e0d699b`。[Actions37315224106](https://github.com/narutojzm1-dot/youjia/actions/runs/37315224106) success/head同源；[Pages37316204902](https://github.com/narutojzm1-dot/youjia/actions/runs/37316204902) success，gh-pages `968ad49b12f931304ca551696b4183c799393ed1`。

[Leader公开包原始核验](package-verification.json) 时间 `2026-10-05T13:23:39.276074+00:00`：PCK **25,272,016字节**、SHA256 `4c367301d2962621ffba4da8b033ac221d89a3ad861e5773f42f1713c8b7a5f2`，公开与raw一致；十个存储模块公开/raw/源码三方一致。浏览器QA与包核验角色分开，不虚构本轮新native回归。

## 实际体验

独立QA原文见 [qa-notes.md](qa-notes.md)，原始 [run.py](run.py) 与 [results.json](results.json) 保留。四个全新context分别为CSS390×844、360×640，各DPR2/3；每页HTML与实读manifest均绑定上述完整SHA，pageerror/console error列表为空。正常鼠标标题进入→暂停→回到门口确认→再待一会儿取消→暂停菜单→继续待着回院；390 DPR2另同页旋转为844×390。

13张原图全部归档：四组 `*-confirm.png` 显示居中纸片及完整标题、解释、按钮和下沿；四组 `*-cancel-pause.png` 显示取消后暂停菜单；四组 `*-yard.png` 显示继续后的院子；`390x844-dpr2-rotate-confirm.png` 显示旋转后重新居中。音量界面100%只是视觉观察，不是听验。

虽然context声明mobile/touch能力，驱动仅mouse.click，**没有touchscreen.tap**。本轮不证明触摸、真机、英文Web、确认“好”实际返回标题、续玩/重置或完整输入矩阵；不替代原作者对应证据。没有状态注入或运行代码修改。#382已公开复现触摸问题，独立PR386候选不能以本次鼠标通过代替自身审核/发布/验收。

[archive-provenance.json](archive-provenance.json) 保留每个原件路径、字节数和SHA256；原件来自 `/workspace/confirm373-public/` 与 `/workspace/pr373-public-release.json`，无重新编码图片、缓存或大包。此为功能公开归档，不是日版本节点。
