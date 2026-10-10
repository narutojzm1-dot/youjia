# #639 户外闲坐、侧卧打盹公开交付回执

Owner: CODEX-LEAD，2026-10-10北京时间下午实际执行。不是23:00日结，不额外发送日推。

实现[PR694](https://github.com/narutojzm1-dot/youjia/pull/694)最终head `7480b01818797255780f5d3da976a52710c30e16`，原作者本地 `663b9f61ba89a71d01a25aaf1db6210d32d57d41`，同树 `0535259deb48e2b298f4e9dbd88178f4f9754fde`；主分支合入 `3a9f54eb9a363adf76a34eb5e27b8c8df43e16d0`。保持旧Grok #665参考/原提交，没有把站姿裁切示意当正式坐卧。

[完整CI38041525219](https://github.com/narutojzm1-dot/youjia/actions/runs/38041525219)、[Publish38042709219](https://github.com/narutojzm1-dot/youjia/actions/runs/38042709219)、[Pages38043798476](https://github.com/narutojzm1-dot/youjia/actions/runs/38043798476)均成功。CI实际日志包含resident_idle_rest61/0、house_sleep154/0、balcony_morning3867/0；完整游戏验证及Web release导出通过。Pages源 `34226bfc96c57df4b75c916eb34f9b3d56724131`，普通公开manifest指向上述主分支source，入口 `game-3a9f54e`。

实际下载PCK **69,547,976字节**，SHA256 `181f9ac13787888f1ca80923ef7f5de015a2e0d390f448407570a3cd042bcd0b`，blob `9bba0ca115a7e382aa1c729f33bae069cb808925`；实际index.html为360,314字节，SHA256 `c8c441fb5f141d763a979a2e8affaf100f38a7b914b672cab8f3612e03fd65e5`，blob `6563e11aef14fc60037207a0941dee3f5997ffe2`。两者均与origin/gh-pages一致；十个存档模块、四个引擎文件、两个加载模块的实际SHA256全部核验通过。[完整实物清单](verification.json)。一次Git promisor对象读取遇到DNS失败如实保留；正常公开下载及上述核验随后成功，没有将失败当作通过。

普通公开页面刷新可见[0.2.0·第2版内部测试与game-3a9f54e](loading-version.jpg)，普通点击入院恢复[第21天、已长大的beibei与原快捷栏](old-save.jpg)。点地移动后无时间/状态注入，真实自然[坐下](sit.jpg)→[夜间侧卧闭眼](nap.jpg)；午夜后仍第21天。40ms方向短按后[站起并实际移位](wake.jpg)，没有吞掉短按或强制跳到次日；新加载页warn/error为空。已暂停游戏并保留公开页供继续体验。

[实现与本地证据](../2026-10-10-idle-rest639/README.md)：45秒可用空闲坐下，再90秒侧卧；八独立原画姿态、最多0.36秒六阶段起身，点地目的地/短按保留、UI重置、减少动态、碰撞/深度锚点与室内睡眠兼容。原生受控GPU连续4350帧十四阶段捕获；本地普通Web真正关页重开保留第2天，最终390×844阴雨侧卧→点击起身移动通过。原生受控场景、普通Web和公开旧档证据分别标明，不混作同一种验收；实体手机触摸、当前音效真实听验未覆盖。

#634可读版号需求亦核对完成：原Grok PR650已经实现，普通公开HTML与实际加载页均有0.2.0/第2版内部测试，构建SHA只作次级诊断；原单评论6096152739已据实关闭，没有重复修改版号代码。

#639核心验收完成。整体Goal仍有#635/#642及其他未完成项，本片不宣称整个游戏闭环完成；不改ASSISTANT近郊模块或Cursor界面方法。下一主功能先推进#642小院花圃分层/可拆换和持久化边界；原PR685概念PNG是圆形占位、文字缺字，实查不是可运行原画，不能当作正式花圃资源接入。外采花草继续按ASSISTANT近郊Owner协调，不在本回执中宣称接收或开工。
