# PR447 候选 PhotoArrival 纸衬：四组合普通操作体验

执行者：CODEX-LEAD 委派的只读 QA 助手 `hotspot36_qa`；实施/集成由 `pr130_validation` 持有。2026-10-05 21:15:33–21:20:17 UTC（北京时间10月6日05:15–05:20）。**这是本地实际 Web 导出候选的体验，尚不是正式发布验收。**

## 来源与操作边界

候选 `sourceCommit=85217509f369e2dc06495bb1fa4ff1649b181a47`，`sourceTree=f3cae526a46b8ef889225b096afb8ad5886b8583`；原作者 `faf507ae47a1bd999a32b3720b22cf3391ea5b1e` 保留。实际HTTP地址 `http://127.0.0.1:8447/`，`candidate-release.json`，entry `index`。

每个页面前后分别通过HTTP取完整 manifest、HTML、PCK和十个 `web/save/*.mjs`，共十组核验。PCK实际 **27,076,376 bytes**，SHA-256 **812144231f60d96c5b565d0cf735982b356e2efece0eeb0d4ffde865b600e030**；所有模块的实际字节长度与哈希符合manifest。实际导航收到的HTML字节SHA与候选manifest相符，`result.json`另存真正加载的JS/WASM/PCK/模块URL与HTTP状态；不把本地磁盘存在或响应头当作下载证明。每次大响应计算后释放，不在记录中复制PCK。

Chromium **151.0.7922.173**，Linux headless，DPR1。四个组合都从自己的新浏览器context/profile在指定视口开首页，顺序关闭前个context后再开下个；没有同时运行两个context或另一浏览器。reduce通过浏览器上下文初始媒体偏好模拟，实际 `matchMedia` 记录分别为false/true；不是真实移动设备或操作系统设置实测。

输入只含普通点击、等候、截图、普通相册入口及一次真实关页重开。没有改种子、时间、玩家/动物位置、库存、照片、存档或引擎状态，没有内部调用 `PhotoArrival.play`；四次都实际点羊后出现“你轻轻摸了摸羊”，随后自然产生 `sheep_pet_gentle` 首照。只读IndexedDB用于旁证，不能代替画面。驱动初始化只监听普通首帧事件。

## 四种组合

| 组合 | 实际路径与证据 | 结论 |
| --- | --- | --- |
| 390×844 / 普通 | [入院](portrait-normal-before.png)后点击羊 `(236,474)`；[02](portrait-normal-photo-02.png)、[03](portrait-normal-photo-03.png)、[04](portrait-normal-photo-04.png)有完整相纸；[05](portrait-normal-photo-05.png)、[06](portrait-normal-photo-06.png)已收起；再普通打开[相册](portrait-normal-album.png) | 四周暖色纸衬可见，完整显现期间没有在照片与外框之间透出正在运作的院子；真实照片与题词均在卡片内。 |
| 390×844 / reduce | 从reduce新context正常入院并点击同处羊；[02](portrait-reduce-photo-02.png)至[05](portrait-reduce-photo-05.png)完整相纸，[06](portrait-reduce-photo-06.png)已收起；[相册](portrait-reduce-album.png) | 静态显示中的纸衬完整，照片与题词可读；未用普通模式的截图代替reduce。 |
| 568×320 / 普通 | 原始短横屏首页入院，[入院](landscape-normal-before.png)后点击可见小羊 `(205,113)`；[02](landscape-normal-photo-02.png)为淡入帧，**不能用于完整不透明验收**；[03](landscape-normal-photo-03.png)至[07](landscape-normal-photo-07.png)是完整显现；普通点[相册入口](landscape-normal-album.png) | 短屏完整相纸及题词留在屏内；完整显现的照片四周为实纸衬。此样本没有单独拍到自然到期后的院子，随后普通相册操作使展示退出；不冒称自然收起时序已完整测量。 |
| 568×320 / reduce | 原始reduce短横屏入院，[入院](landscape-reduce-before.png)后点击羊；[01](landscape-reduce-photo-01.png)至[06](landscape-reduce-photo-06.png)是完整静态相纸，[07](landscape-reduce-photo-07.png)已收起；[相册](landscape-reduce-album.png) | 完整纸衬及照片/题词可读，正常收起后相册仍能看这张照片。 |

所有原始截图和完整截图请求/完成时间均保留，未挑选删除等待帧或淡入帧。00/01等尚未出现相纸的画面是正常输入后等保存/呈现的记录，不是模拟失败后暗中补状态。四个首照事件均由一次正常点羊成功触发；没有为相纸重刷profile的失败尝试。

## 纸衬判读方法与限度

先肉眼查看真实候选截图，再对照片四周纸窗内部各一个点作像素旁证：[mat-samples.json](mat-samples.json)。竖屏左/右/上/下为 `(96,390)`、`(295,390)`、`(195,294)`、`(195,493)`；短横屏为 `(198,150)`、`(369,150)`、`(284,70)`、`(284,244)`。四种组合的指定完整帧03，这四点全部精确 **RGB(243,227,203) / #f3e3cb**；相纸出现前同处是不同院子/HUD像素。

短横屏普通02的采样是混合色，实图也确实有整张卡片的预期淡入；完整03等才用于结论。这既不是把淡入当不透明失败，也不是用淡入帧冒充full-hold。采样只覆盖明确四个内部点，**不是每个边缘像素、不是真实GPU帧时间或整个1.10/1.60秒持续窗口的逐帧证明**。截图耗时和额外30ms等待都记在输入里，不把等待值当截图帧率。原有淡入/淡出和相纸布局没在本QA里被修改。

## 相册与真实关页恢复

四个新profile各普通打开相册，均看到本次自然羊照。390普通样本在21:17:12 UTC真正 `page.close()`，保留同一context后21:17:19 UTC新建页面重新加载，再从首页点“翻开相册”：见 [重新打开的相册](portrait-normal-reopened-album.png)。同照片、同题词可见。

[只读封套结果](storage-readonly-summary.json)：关页前后 `current` generation均为2，整个current记录完全一致，`album`与`photo_moments`完全一致，唯一照片ID为 `sheep_pet_gentle`。其他三样本也各有generation2及自身真实首照。没有跨样本复用同一个存档，独立样本照片内容本来可以不同。

这是**同浏览器context内真关页→新页**，不是关闭浏览器进程、物理设备重启、完整旧档迁移或全部照片事件验证。相册与只读封套只是兼容旁证，纸衬结论仍来自在途相纸截图。

## 结束与未覆盖

驱动退出0，最后context及浏览器 **21:20:17 UTC** 关闭，已向集成Owner释放执行窗口。`result.json`中pageerror/崩溃列表为空，console error为空；不等于所有环境无错误。

没有进行真机/触屏/听验、全部语言、所有照片事件、任意窗口尺寸、所有天气、完整相册/存档矩阵或正式Pages发布验收。短横屏上方快门短句与已有HUD同处上方的布局可见，不能把本次纸衬修正扩大成全UI布局验收。相纸淡入和淡出可以让**整张卡片**按原设计透明，本结论仅是完整显示时原透明窗口周围有暖色纸衬，不透院子。四组合以已看到的真实画面通过此限定候选验收。

材料：44张原始PNG、10组前后manifest/HTML、5份只读DB、完整驱动/输入/浏览器日志、[只读分析脚本](analyze.py)、派生JSON、[SHA256SUMS](SHA256SUMS)。所有PNG原样保留，没有编辑、拼接或补画。HTML保留原始响应末尾空行。后续集成PR仍需独立最终SHA审查，合入后另做实际公开版本核验。
