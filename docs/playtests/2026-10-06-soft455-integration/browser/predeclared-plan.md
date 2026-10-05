# 455 普通空手帐禁用按钮候选验收预案（尚未执行）

执行者：CODEX-LEAD 委派 hotspot36_qa。只读候选 QA，不修改运行代码、原作者分支或 Owner。已经读最新候选 AGENTS、CONTRIBUTING、身份/策划及主题需求/PR范围。

## 开始条件

等待 soft444_integration 明确 Godot 完成并授予独占浏览器窗口，再核其最终候选 sourceCommit、URL、entry、PCK 字节与 SHA256。预期 prepared source 为 910bdec3fe7bf07833d6b9ccb720f57a5332880c，但不把准备源当最终导出。候选目录 /tmp/soft455-web；manifest 应有完整 web/save 十模块及 license 外链资源。未得到明确窗口不启动 Chromium/Godot。

## 路径及验收

1. 单 Chromium、单全新 context、DPR1、no-preference，初始 390×844。实际 HTTP 核候选 manifest、HTML、PCK、十模块及 license 文件长度/哈希；记录真实导航 HTML、data-build 和实际资源 response URL/status。下载 PCK 后立即释放 payload。
2. 首页普通点击手帐入口（按真实画面校准），截完整视口空手帐。以画面实际文案识别前翻、后翻及可用“合上”，检查禁用文字可读、暖纸底/浅边完整、与可用按钮有所区别，检查溢出；不得靠源码宣称某按钮出现。
3. 实际普通点击两个禁用边界按钮各一次，等待稳定后保留每次原图；空手帐仍在原页且未关闭。只读 DB 前后可辅助检查没有业务变化，但不能代截图或宣称观察到全部内部回调。普通“合上”应返回标题。
4. 在同 page/context 通过浏览器 viewport resize 变为 568×320；从标题普通打开同样空手帐、两个禁用按钮各点击一次、正常合上，完整截图不裁掉溢出。单 context 串行避免叠加浏览器内存。
5. 若空手帐本来没有该按钮，保留偏离原件并标 NOT COVERED；仅此时可普通进入院子、轻抚羊自然获得单张照片，再观察相册边界按钮。不能改写存档或强制事件，也不为概率无限刷新。
6. 最后再次 HTTP 核同一候选来源/HTML/PCK/依赖；源变即停止并通知。退出关闭全部 context/browser，报实际 exit 状态和关闭时间，立即释放窗口；之后才离线 README、像素/可读性局限、输入和 SHA256 清单。

## 边界

只覆盖普通空手帐（必要时自然单张相册）可达到的禁用按钮及“合上”对照。绝不注入 writing/acknowledging/resolving/failed/recovery，不补 #459 键盘焦点诊断，不使用内部动作/seed/时钟/保存写入，不称真机/真人听验、全存档恢复或所有页边界通过。原生4400等回归由集成者独立报告，不能冒充本次真实Web覆盖。

后续若发布需要短验：仅正式公开一个390×844普通空手帐前后翻禁用+正常合上，按最终公开 manifest/entry/PCK/十模块重新绑定，不重复候选两尺寸全矩阵。

准备脚本：/tmp/soft455-candidate-driver.py（仅语法编译，尚未运行）；参数 --url --runtime --entry --pck-sha256 --pck-bytes --out 必填。原始输出拟 /dev/shm/soft455-candidate-qa（尚不创建）。标准输入支持 new（仅一次）、resize、click、move、key、wait、shot、db（只读）、end；不支持任意JS执行。
