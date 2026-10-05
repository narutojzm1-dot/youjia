# 双羊成功轻抚回应接入候选

CODEX-LEAD内部实施；资源Producer PR378 `bccf132251e845262eb2e374d5d645a02c80de62`，运行候选 `098e611233e20f8a5eccb47afc43a6341f09dedb`（包含main共享cleanup `4fa150819c304b03fb6a36a149e71d4bcd911000`）。未自行推送、审核、合入或发布。

使用黏人羊v2的展开耳/平吻、呆羊v3的克制抬头衔草，资源字节不变；原尺寸四图已直接查看。manifest脚锚分别保留原idle(576,1178)/(732.5,1124)，原物种高70和个体.36/.34校准不改，不因新cel bbox重新缩放。两羊以同一attend状态名映射到各自资源；成功事件仍经原近距校验，无效不回应；2.2秒/5秒不变，无新增爱心/关系/延迟。旧idle/shake资源保留；生产PhotoMoment现有可信assets路径允许新图，无需改存档或摄影协议。

原生专项56项通过：实际world成功/远距失败、左右面对玩家、渲染脚点、原基础倍率与自然景深、连点不续期、低动效、pose中断、到时释放、新照实际纹理捕获/sanitize/rebuild、历史idle纹理仍可读。测试有明确受控布局/偏好设置，不冒真实用户Web路径。初版专项错误拿未tick scale与景深tick后scale比，四项失败；修正为保基础倍率且实时深度公式后56通过，无运行时修正以迁就测试。原始失败日志保留本地。

正式无observer导出PCK `c72c05a4bce738d92d4e23d6b6ce99a2e2a1b1f5442b2467f995da8e0540e821`，本地8196仅供候选独立QA。全daily及实际Web结论待附；没有正式低动效/英文UI时不注入冒正常路径，不声称真机或全部121/30完成。

完整daily首轮保留在本地daily.log：interaction_photo旧测试强制羊idle而失败109/110通过。依据本切片批准的专属图，现精确要求sheep_b attend且sprite路径/sheep_dull_glance_v3.png，仍禁止旧shake；牛glance/马idle不变，并未容许任意姿态。35e03e1为最终测试修订，正式候选098的生产代码与纹理不变；其后完整daily重跑结果另附。

完整daily最终实际exit0（工具进程32132）：sheep56、interaction_photo110、interaction_pose35、shared cleanup95、confirm562及最后Web decoder/legacy/loading shell均通过；日志daily-final.log，无SCRIPT ERROR/ERROR/FAIL。最终执行测试断言35e03e1；同一次长daily在进入interaction_photo前加严专属纹理路径断言，不将首轮失败写PASS。正式export实际exit0且无解析错误，27,078,024 bytes；10个随包保存模块与源逐字一致见export-artifacts.json。独立自然Web结果待另附。

## 独立自然Web（horse180_repro）

[原始独立报告](web/README.md)：1280×800鼠标普通路径两羊分别成功关注，有限三次连点无默认爱心/明显体量跳变；物种共享首次照片实际捕获黏人羊展耳，真正关闭整个浏览器后同隔离profile以390×844打开标题相册，照片与文字仍可回放。两会话console.error/pageerror为空。远处重叠点击不算第二只成功；第二只依据step10走近→step11成功及长脸转向。低动效无生产入口，仅原生覆盖；非触屏/真机、不称呆羊另一个独立照片。

仓库仅选9张原PNG（黏人0/1/2、呆羊10/11/12、相册13、reopened标题/相册），原始完整动作/驱动/日志/响应与原图清单均保留；其余图仍在本地/workspace/sheep-attention-web，原报告全部看图声明属于独立QA，不表示其余图已复制到仓库。复制路径和逐字哈希见web/archive-provenance.json，未改PNG像素、未复制profile。实施者也直接看了两羊前后及两张照片关键图，不冒独立代码审。
