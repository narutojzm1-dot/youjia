# PR444 本地候选普通键鼠体验

执行者 `/root/soft444_integration`，CODEX-LEAD实施代理；**不是独立终审**。时间2026-10-05 UTC / 2026-10-06北京时间。单Chromium依次三个fresh context，DPR2：1280×720、390×844、568×320。普通Playwright mouse/keyboard；没有调用Godot grab_focus/emit_signal、注入业务或存档、强造照片。

## 候选来源

实际运行代码14a85a532f9510306b7921b9daa23409d17799c6；本地候选不是公开发布。三个context首末共6次完整candidate-release.json与实际HTTP下载PCK核对，均27,088,652字节 / SHA256 c8b05b9bbe0a5359d223b8686212366676c549538e3845279b4b84d4f8a92530。加载器首帧把html dataset.build设为export executable `index`；source绑定用不可变候选manifest与实际包，不能把dataset单独当commit。

## 实际观察

| 路径 | 1280×720 | 390×844 | 568×320 |
| --- | --- | --- | --- |
| 普通按住标题play | 深色字、按下底/边可辨，松开进入院子 | 同；另移出再松开取消点击 | 同；另移出再松开取消点击 |
| 标题键盘焦点/Enter | 初始空白点击后Tab1/2未见圈；未补该路径 | 取消普通mouse-down后Tab→ShiftTab，play可见赭色圈，Enter入院 | 同左，完整外圈及文字在纸面内 |
| Escape暂停、音乐鼠标关/开后移开 | 两次标签清楚，恢复原开状态 | 同左 | 同左，两列短屏不截字 |
| 暂停键盘焦点 | music后ShiftTab两次，restart实际焦点圈可辨 | 还额外Tab定位music，Enter关/开后保留焦点与深色字 | ShiftTab→Tab定位music，Enter关/开后保留焦点与深色字 |
| Enter打开确认/取消 | restart真实Enter打开，普通鼠标取消返回暂停；另有纯鼠标打开/按住取消 | restart真实Enter打开，按住取消后松开回暂停 | 两列内ShiftTab三次到restart，真实Enter打开，按住取消后松开回暂停 |

三种尺寸最后暂停图音乐均恢复“开着”，未接受restart或title离开确认。按住态和键盘圈没有观察到文字发白、裁切或盖掉纸底；图片为实际可读性观察，非Web像素对比值实测。普通中心点击和键盘路径没有发现布局/操作回归，不等于测遍按钮边缘命中框。

初始空白点击后Tab未显示焦点的全部图保留；不能将其改写为初次Tab就通过，也不据此单独判新缺陷。后续通过普通mouse-down/移出松开，再Tab切换才取得标题焦点；暂停音乐等也通过普通键鼠切换获得焦点，不是注入。

41张PNG、所有动作和console/source原件保留。errors=[]，exit0，三个context与浏览器均已关闭。前一启动的驱动dataset错误断言单列在 sibling `initial-binding-failure/`：实际包绑定正确、无游戏console错误、未发交互；修正驱动按真实entry=index检查后重跑，候选bundle未改变。

## 未覆盖

没有真实耳听、实体手机、触屏、英文、完整无障碍/像素对比、disabled/save-error状态、全边界点击、相册翻页或新自然照片。相册是预案可选子项，本次未执行，不以内部主题5080替代其真实图。公开部署及正式版本体验后验，最终独立SHA审查仍由另一代理完成。
