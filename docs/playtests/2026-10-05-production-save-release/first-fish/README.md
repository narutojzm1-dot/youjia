# #40 首次钓鱼留影：公开 game-d242509

2026-10-05 09:51:15 UTC，https://narutojzm1-dot.github.io/youjia/ 实际 html data-build=game-d242509。Chromium1280×720独立全新context，不使用真实玩家profile。只实际首页、池塘、收杆、手账按钮点击；无seed/位置/状态/时钟注入。实际截图按钮分类见driver与原模板，15.92s观察到收杆提示后点击。

before-catch 为收杆前；capture00–17为点击后的顺序截图，实际截图耗时超过100ms等待，不能当固定10fps录像。capture04已实际查看：首次鱼照片在正中显影，卡片约x522..759、y211..510，背景屋顶/右棚保持同一构图。capture05照片已消退；没有观察到强烈场景缩放、卡片飞向角落或缩小入册。18帧屋顶与右棚固定大小裁块±4px平移搜索均最佳位移(0,0)，landmarks.json保留结果；首帧亮度变化较大，其他帧误差很小，不能称每像素完全相同。该图像比对支持背景构图稳定，不替代全帧光流/连续视频证明。

album与reopened截图：首次鱼照片、同一画面和“从水塘里钓起了第一尾鱼。”文字均保留。真实关闭页面，在同一独立context新建页面进入后打开手账，重开照片已实际查看。result.json errors=[]，自然链路成功。

公开只执行这一轮。此前local练习已钓获/入册，但快捷context用法导致驱动重开报错，不能引用为local重开成功；正式公开driver已改显式context并完整退出0。此处公开证据与/workspace/fish40-qa/local分离。

仓库归档选择before/capture00/04/05/reopened原始PNG；landmarks.json为实际18帧计算结果，其余原帧未在此重复入仓。驱动路径需按仓库位置调整；模板来自已归档fishing-active-hud/retest，非游戏状态注入。
