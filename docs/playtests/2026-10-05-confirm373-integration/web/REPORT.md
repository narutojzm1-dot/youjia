# PR373 正式候选 Web QA

候选源（构建Owner提供）：6f9d15b8afe2bbc9d9ca0ba2f50a993c06a55b4b。
URL http://127.0.0.1:8195/。实际下载 index.pck 流并计算 SHA256：794fc7656acd4bceaf3c82f9b4f13d08cb52df0df4abcf1bff91905825e7da29，与指定候选一致。没有重复保存 PCK。
运行时：真实 Web 导出，Chromium 151.0.7922.173 headless，独立 new_context、is_mobile=true、has_touch=true；每个组合都是新测试档。未使用 observer、Main 节点访问、场景注入或 DOM 造图。截图为浏览器原始 PNG，未编辑像素。image-manifest.json 包含原图尺寸和 SHA。

## 实际通过

- 390×844 DPR2、390×844 DPR3、360×640 DPR2、360×640 DPR3：正常鼠标点击标题“走进院子”→“歇一会儿”→“回到门口”；确认纸片完整在屏内，左右边框均可见，标题、说明和“好/再待一会儿”两个按钮完整，无裁切。
- 四组合鼠标点击“再待一会儿”均回到暂停，再点“继续待着”回到院子；390证据在主目录，360完整流程证据为 *-flow-cancel.png / *-flow-resume.png。
- 390×844 DPR2 同页带着确认框旋转到844×390，纸片重新居中且全部在屏内：390x844-dpr2-rotate-confirm.png。
- matrix.json、flow.json 的 pageerror/console.error 均为空。实际点击坐标、顺序和标签在 JSON 与脚本中；主验收使用 mouse.click，不把 has_touch=true 当作触摸测试。
- 验收者实际查看了四组合确认原图、四组合取消及恢复原图和横屏原图，判断来自图像内容，不是只检查CANVAS存在。

## 限度与未通过的尝试

- 初次人工逐步 touchscreen.tap 390/DPR2 能正常打开确认框（initial.png、step0/1/2.png）。随后1秒节奏的独立自动touch尝试：pause截图显示暂停页，但在CSS(195,340) tap后 confirm截图显示院子。保留 touch-attempt 下前后原图及原脚本。这是一次未定位的输入/时序异常；没有证明正确处理命中或稳定复现，不命名新BUG，不声称触摸取消/恢复全通过。mouse验证不能替代该触摸限度。
- 在360/DPR2独立测试档额外尝试“好”回门口：*-flow-accepted-door.png 仍显示确认框；下一次点击后 *-flow-continue-old.png 实际显示标题。文件名只是计划动作标签，不能当作结果断言。只能确认这份测试档最终回到门口；没有证据证明继续旧假期成功，也未定位首次点击/延迟原因。
- 未测试重置假期、英文Web、其他浏览器/真机。未修改实现、未批准最终SHA、未发布；独立源码终审由root另行安排。
