# 460/455 正式空手帐禁用按钮后验预案（未执行）

仅准备。等待 CODEX-LEAD 确认 PR460 合入和正式 Actions/Pages 发布完成、实核最终 main full SHA、公开 manifest/动态 entry/PCK长度/哈希以及独占浏览器窗口。PR head8a401350不是预设最终发布源，准备候选910b也不是正式源。

## 绑定

公开地址预期 https://narutojzm1-dot.github.io/youjia/；实际读 game-release.json，schema/sourceCommit/entry 及 storageModules.entry 取正式公开值，分别校验 game-{source7}、save-{source7}，禁止使用candidate index/web/save标识。必须传root核定完整源/entry/PCK长度和hash；license源文件长度/hash单独由最终源核定，因为当前公开manifest没有license字段。

单page开始/结束均实际下载 manifest、HTML、动态entry.pck、10个versioned存档模块和open-source-licenses.html。模块对manifest哈希，PCK与license对源核定长度/哈希，HTML前后同hash，真实导航HTML也同hash；实际DOM data-build必须等于正式entry，并记录实际JS/WASM/PCK/modules response。释放下载payload；出现source变动或校验失败立刻停止保存原始失败，不混合不同build作通过证据。

## 普通玩家路径

一个全新profile/单context/单page，390×844 DPR1 no-preference，标题普通点击“翻开相册”。完整空页拍摄，不裁图；真实画面检查两禁用翻页按钮的文字/暖纸底/边框与可用“合上”的区别。实际点前翻及后翻各一次，指针移开、等待250ms后各拍原图，确认仍是空手帐原页；四份只读current可作旁证，但不据此声称全部回调验过。普通“合上”应回标题。

同page/context viewport resize至568×320，再从标题走同样空手帐路径、两次禁用点击及正常合上。两视口共享此全新context，不称两次fresh启动。普通空页若无目标按钮则保原图并记NOT COVERED，不通过注入取得状态；不自动扩展到自然照片或重复候选矩阵之外工作。

原始输出拟 /dev/shm/soft460-public-qa。驱动 /tmp/soft460-public-driver.py（仅compile未执行）；开始前可查内存，参数保留renderer-process-limit=1，始终单浏览器/context。结束完整关闭context/browser并报告exit/UTC/释放窗口，再离线写README、像素/DB辅助结果、输入、哈希清单。

## 不覆盖

不注入业务状态/种子/时钟/存档，不调用内部动作；不补#459键盘焦点诊断、不验音频/真人听感、真机触摸、writing/acknowledging/resolving/failed/recovery状态、不称所有相册页边界或全存档可靠性验收。仅正式公开已合入455的普通空手帐禁用视觉与不响应点击行为。
