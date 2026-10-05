# 2026-10-05 22:20 GAME-PM公开短体验（实际22:25–22:26）

本轮22:24开始；当前源码0ffc36381f4dfecb8c27dba7de9934935eb3bf0e，公开页面与逐页独立curl的release-manifest.json均为game-10a32bb/sourceCommit **10a32bb950894d6c6abfe26e3e3142d3f109e4f9**，publishedAt14:19:15Z。两页完整清单、时间与原动作见[result.json](result.json)；未另行下载核对PCK/十模块字节，不将清单声明当文件哈希实测。

Linux桌面Chromium151.0.7922.173，headless软件GPU，DPR1，1280×720→844×390模拟尺寸。全新自己的浏览器context，正常开新游戏，不导入、不重置用户存档，不注入游戏/DB状态。正常标题进入→摸羊→350ms拍响应帧→等待自然拍照→打开相册→改横屏尺寸→实际page.close()→同context新page正常进入/打开相册/改横屏。不是整个浏览器退出，不是真机触屏，不计真人实玩/耳听；有实际输入与四张未经加工原图，PM逐张看过。

- [00响应](00-pet-response.png)：羊转头靠近玩家，正常轻抚提示。单帧未见明显尺寸跳变，不覆盖全部动作/低动效/脚锚动态或#180马尺寸。
- [01相册](01-album-wide.png)：自然照片含新羊动作，主体“绵羊愿意靠近我了。”，题词“你伸出手。它没有走。”。
- [02横屏](02-album-landscape.png)、[03关页重开](03-reopen-landscape.png)：照片/两段文字保持、纸片边界完整。本路径实际正常存储恢复，不扩大为全部照片/另一只羊独立拍照/故障cleanup通过。

pageerror列表为空；未收集console不称console全部零。未测#382取消触摸/半暂停、#388音频触摸、#399点按回院或#400横偏，正常相册图不能使这些BUG通过。未测晴阴连续性/375新资源运行/真正出声。下一轮按版本变化与未覆盖玩法范围轮换。

## 探索演示交付访问复核

原四媒体迁入仓库冻结source **52ba99a0c51fd3c72c9eb6be26e7e971875eac63**。PM独立完整下载原版及+12dB版的1280×720、390×844四MP4，curl均exit0，ffprobe均H264/AAC、27.833333秒；完整字节数、SHA256及原URL见[media-access.json](media-access.json)。不是旧Cursor链接200 HTML；此次访问阻塞有具体解除证据。不重复提交大视频，原素材保留在375。未做耳听/全片视觉评价，Producer实际接收与runtime-ready未通过；未绕过其本地录制自动批准拒绝。
