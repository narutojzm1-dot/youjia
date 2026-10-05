# 双羊轻抚关注：独立正式候选 Web 实玩

执行者：CODEX-LEAD 内部独立 QA（horse180_repro）；实现者 pet30_impl。只做实玩，不改实现，不代替最终源码独审。

## 候选身份

- 作者提供 runtime SHA `098e611233e20f8a5eccb47afc43a6341f09dedb`（含4fa150集成）。正式无observer导出，URL `http://127.0.0.1:8196/`。
- 实际流式下载 `index.pck` SHA256 `c72c05a4bce738d92d4e23d6b6ce99a2e2a1b1f5442b2467f995da8e0540e821`，匹配作者候选；未存重复PCK。响应URL/状态见 responses.json。
- 实际console Godot `4.7.2.stable.official.ed1daf0bf`；Chromium151.0.7922.173，1280×800 DPR1正常模式鼠标，后以390×844 DPR1重开同测试profile。
- 独立持久测试profile `isolated-profile/`，初始新档。全部交互为 Playwright mouse.click（等价真实鼠标输入），没有调用Main/observer、改坐标状态、改存档、改随机数或DOM伪图。没有用触摸路径，避免混入BUG382。

## 实际流程与图像观察

1. initial标题→cmd0正常走进院子，step0为玩家与初始双羊。
2. cmd1点击近身小黏人羊，step1有“你轻轻摸了摸羊”成功文案，小羊展耳抬头转向左侧玩家，没有心形。step2为随后自然状态。
3. cmd3尝试较远动物后两羊有自然走动/重叠，不单凭这张图宣称第二只已成功。cmd4–6正常HUD连续点击三次，各自保留原图；没有默认心、没有因连点产生可见夸张放大。step7为随后观察，cmd8普通地面点击走开，step8两羊有自然移动，未保持刚才固定站位。
4. 为明确第二只，cmd9选中较长体型呆羊；cmd10正常点击地面走近。step10玩家位于呆羊右侧，羊原朝左。cmd11点击HUD“打个招呼”，step11成功文案出现，呆羊长脸转向右侧玩家，身体/脚落点没有明显跳变或强拉伸；step12随后自然观察。小黏人羊与长体呆羊的画风和体型差异仍保留。
5. cmd13正常打开手帐，step13出现自然首次共享照片“绵羊愿意靠近我了。你伸出手。它没有走。”，成片可见黏人羊展耳关注姿态。没有注入摄影事件。该照片是羊物种共享首次轻抚记录，不能说两只各有一张首照。
6. cmd14关闭整个浏览器进程。另起浏览器使用相同持久profile，改390×844窄屏：reopened/initial为正常标题；reopened/cmd0点击“翻开相册”，reopened/step0仍是同一张照片与文字，画中的羊关注资源仍能回放，布局完整在屏内。这是实际关页/重开后的保存回放，不是仅reload或只检查数据字段。

## 关键原图（全部实际查看，未编辑像素）

- 黏人羊：step0.png / step1.png / step2.png。
- 连点及走开：step4.png–step8.png。
- 呆羊成功前后：step10.png / step11.png / step12.png。
- 自然共享照片：step13.png。
- 关浏览器后窄屏回放：reopened/initial.png / reopened/step0.png。

动作与UTC在 actions.json / reopened/actions.json，console原文在 logs.json / reopened/logs.json，响应来源在 responses.json / reopened/responses.json，原图尺寸及SHA在 image-manifest.json。两次会话console.error/pageerror均为空（GPU性能warning保留）。

## 范围与限度

本次真实路径看到两只各自成功关注、转向玩家、无默认心，体量和脚底没有明显异常跳变；自然走动及相机变化存在，因此不把不同时间截图当精确脚锚数学证明。仅测试有限三次连续点击和后续观察，不宣称穷尽所有连点时序。手帐只验实际拍到的黏人羊共享首照，未重置另拍呆羊，不宣称双羊独立照片均覆盖。

低动效没有正式可达入口，未注入设置，故此处未做Web低动效；作者原生覆盖另列。未覆盖真机触摸、其它浏览器、长时间挂机、所有镜像方向及全部天气组合。天气按游戏自然变化，未改玩法触发。此结果不代表已合入或已公开发布，仍需最终SHA独审与发布核验。
