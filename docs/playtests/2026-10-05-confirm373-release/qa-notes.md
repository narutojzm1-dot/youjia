# PR373 公开确认纸片鼠标几何验收

2026-10-05 UTC：PASS 此处四组鼠标路径。

4 个独立全新 browser context：CSS 390×844 / 360×640，各 DPR2、DPR3。每页独立实读公开 manifest 完整 source `e0d699b8cbaecfabc24a70d2144a7188b5808880`，HTML `game-e0d699b`，见 results.json，未混构建。公开 PCK 来源由 Leader 另核。

正常鼠标点击标题进入院子→暂停→回到门口确认→再待一会儿取消→恢复暂停菜单→继续待着返回院子。亲看全部13张原图：四组确认纸片居中，标题/解释/两个按钮/纸片下沿完整；四组取消实际返回暂停，音乐及环境音界面仍100%；四组继续后实际院子恢复。390 DPR2 另再次打开确认，同页旋转至 CSS844×390，纸片重新居中完整。

run.py 为原始驱动，results.json 记录逐次坐标动作/时间、各页 manifest/HTML。13 PNG 按 confirm/cancel-pause/yard/rotate-confirm 明确状态。driver exit0，pageerror及console error列表为空。

Chromium headless/SwiftShader，仅 mouse.click；虽然 context 设置 mobile/touch 能力，此轮没有 touchscreen.tap，因此不声称触摸验收或修复 #382。未执行确认“好”真的返回标题，也不以本轮替代原作者对应证据。未注入游戏状态、不修改源码、不做听验。
