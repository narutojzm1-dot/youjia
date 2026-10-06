# PR473 普通候选 QA：接续离线验收

本目录原始浏览器运行由 `/root/soft444_integration` 执行，本次 `/root/qa478_recovery` 仅接续离线验收；没有重跑候选浏览器，也没有修改原始 JSON、run.py、HTML、manifest 或 PNG。协作身份为 CODEX-LEAD 独立普通 QA，非另一登记角色的接收回执。

## 来源与执行事实

- source `a0a856f64e7764fbab5270412025e62b8e34cafd`；tree `0945747d4680e899bbfe5253a60ca5c0f8cf92e1`；候选入口 `index`，URL `http://127.0.0.1:8483/`。
- PCK 27,097,128 bytes；SHA256 `91028b52ee7c2d4441ce2e368b600a3fb2a70dfeaf8a309229611709bccd1207`。
- 原 driver session `86621`，started `2026-10-06T01:47:48Z`，actual CLOSED `2026-10-06T01:55:33Z`，actual exit `0`；原执行记录 `live_chromium: []`、`errors: []`、`console_errors: []`。
- 已逐条核对 result.json 的 before/after 实际 HTTP 绑定、HTML 实际加载哈希、10 个存储模块与许可页状态/大小/哈希；前后 manifest 一致。另对只读 export 的 PCK、HTML、10 模块与许可页逐文件流式 SHA256 核对成功，未解析 PCK 结构。详见 offline-verification.json。

## 离线亲看结论

本接续验收者逐张通过本地 view_image 查看全部 17 张完整原 PNG：标题 1 张、desktop 6 张、portrait 5 张、landscape 5 张；未制作拼图或裁图，未批量载入。桌面工具展示有缩小显示，原 PNG 分辨率和字节未变。

原运行是一个 fresh context，同一页面从 1280×720 → 390×844 → 568×320，实际 DPR 2，中文、正常动效、普通鼠标输入。三个尺寸均可见暖纸提示“点此打开拍立得手帐”；真实 hover 出现、leave 消失、rehover 再现，点击打开空手帐，点击“合上”回院且无残留提示。桌面提示纸面贴底，文字完整可读；不声称外扩阴影全部在视口内。竖屏与短横纸面和文字可见。

最后第 17 张 `landscape-05-returned.png` 已实际亲看：空手帐关闭，回到院子，底部按钮恢复，无残留工具提示。其 SHA256 为 `3ddd2f882b17ee121ace2a5b0d6e5dacf1a4607f9122d1a333d6d0cccfd1a4b3`。

## 工具中断事实与边界

原执行期间发生图片工具传输/加载 HTTP 503，导致最后关闭手帐的命令延后；依父代理交接及原 analysis.json 记录，原上下文保持到正常关闭，没有因此重开。该 503 是工具图片交付事实，不记为游戏错误；长时间空手帐停留不是设计的压力测试。本接续 17 次 view_image 均成功。

Main 启动固定中文，普通 UI 无语言切换；英文仅另档受控 native 覆盖，本目录不冒普通英文通过。实际点击最小间隔 8272.423ms（driver 下限550ms），不属于极快连点验证。不冒触摸、真机、键盘焦点、照片内容/存储恢复、真人听验、全部 DPR、低动效普通浏览器或完整游戏体验通过。此目录只证明精确候选的有限普通路径；最终 SHA 独审、CI、合入、发布和公开验证另行绑定。

## 冻结

SHA256SUMS 按文件名字典序覆盖本目录全部原始证据及本次 README/offline-verification.json，清单自身不列入。冻结后不再改动。归档可用硬链接保留原 PNG 字节，再流式验证清单。
