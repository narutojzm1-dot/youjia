# PR392 短横屏标题候选浏览器 QA

PASS 标题布局与普通鼠标路径（本地候选，非公开上线）。正式无 observer Web，source `95925950d795b39a5444e9cad911644171442627`；PCK 25275168 bytes，SHA256 `5783b3dccd5ad06b4b1a5ba85d8408075dd65fc8bf93a38d645a29856f594cbf`，构建记录来自实际8195/candidate-build.json，已保存。

六个独立干净 profile：CSS568×320、640×300、844×340，每组DPR2/3。正常鼠标点击许可/相册/合上/进入院子；标题、相册、院子原图已实际查看，标题整列标题/副题/说明/两按钮/许可/两行操作提示均在纸片及视口内，无截断。相册空态可打开关闭，进入院子成功。568×320 DPR2同页旋转320×568再回568×320，标题恢复两种布局并能进入院子。

首次六组许可按钮命中并打开新标签，但本地导出遗漏配套 open-source-licenses.html，实际404，全部原popup图及result记录保留。Leader补跟踪site页面/声明原字节，运行码/PCK未变。随后第七个干净profile568×320 DPR2用同正常鼠标点击重验：实际新页标题Open Source Licenses、正文与下载链接已可见，license-recheck-popup.png已查看。此处不把第一次404藏为通过；是本地支持文件补齐后通过。

result.json 包含原鼠标/resize/profile动作、popup实际URL/title/text，run.py驱动和cmd*.json可复用。游戏页error列表为空；popup初次404单独在popups记录，不被空errors列表抹去。initial-probe保留最初坐标/新标签观察探针，不冒完整矩阵。

浏览器Chromium headless/SwiftShader，mobile能力context但输入全部mouse.click，无业务状态注入。这是CSS可用视口模拟，不是物理手机、真实浏览器地址栏或触摸验收。中文页面实际验收，英文布局覆盖归原native suite，未冒英文Web；院子短横屏较小构图为观察结果，非本标题切片已改善的声明。生产源码未修改。

## Leader 最终组合及归档

原作者591206a祖先保留；先合main4fa并以runtime959259做完整4.7.2 daily与正式导出（exit0），后合已独审main0ffc得到a28e09c862f8cd6e11981e6215fdba079275f683。daily列表冲突显式保留羊关注和本标题两入口及100755，Main标题运行代码无再改。最终组合import、title1541、sheep56、interaction110、cleanup95、confirm562、pause168均实际exit0。原五项Godot.import自动修改未提交。公开部署/体验尚未在此候选档声称完成。

归档精选六尺寸标题、旋转、许可修正前后及一组相册/院子原图（未加工），其余实际看过的原图哈希列all-original-images.json。原动作/result包含初次六个404，不能把空游戏errors当所有弹页成功；当前公开许可证实际HTTP200且与补齐本地字节相同。资源补齐不是生产代码修复。正文中本地绝对路径是采集追溯，不作为GitHub可访问链接。
