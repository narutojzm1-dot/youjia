# #36 窄屏触屏补证

公开 game-a067ce9，result.json 与结束 manifest-after.json 完整源均为 a067ce9b6674d5c1b35cdc2410f3d507f0f4d6a0。这是后续版本独立取证，不替换原1a3842c桌面证据。新独立Chromium profile，390×844/DPR2，is_mobile=true、has_touch=true；所有入院和场景输入均调用 touchscreen.tap，没有mouse回放或业务状态/位置/种子注入。软件WebGL模拟，不是真实物理手机。

实际正常触屏：
1. initial→tap220,280；touch-windowbox-00 黄色蝴蝶/花瓣在花箱上方实际可见，角色仍在院内，回应文字同步。该原图已查看。
2. 试图向岸边tap350,580被不可落脚拒绝（touch-walk-bank），保留失败，不冒到达。tap345,525正常走向岸边（touch-approach），然后tap270,580命中岸石；touch-shore-00明确“水塘岸石·拨一拨水”，角色脚在岸上；01/02绘画涟漪与蜻蜓实际同框可见，原图已查看。后续反馈自然消散。天气自动转阴，本证据不批准天气同构图。

完成两处有目的热点触屏尝试，不继续第三热点/刷命中。driver退出0，console/pageerrors=[]。动作/实际输入monotonic时间在result.json。关键原图已查看：initial、windowbox00/03、walk-bank、approach、shore00/01/02/06；其余保留原始时序不冒全审画。

限制：栅栏触屏未覆盖；未做即时移动取消（未在单driver中触发后100–300ms移动），不能拿自然消散代替。低动效无正常UI入口仍未覆盖；非真机、非所有手机尺寸。shore06出现上下黑边与场景移位，属于后续自然运行时刻，尚未归因，不将此帧作为热点几何/稳定镜头通过依据。
