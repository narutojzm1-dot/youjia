# PR510 公开包核验

- 最终 PR head：`498d96c9e33f28e7421d2fce19a50f4b9df8aedf`；本地验证提交 `36cc3eef3aa13c3ebe8acca47e25cf611b79ba3d`，相同 tree `f97254b8417d2740ed90b3a0cba59a795e58a5fb`。
- 合入/发布源码：`4f6d18f3d9d4a7a3944f298dec035192359b7aba`，入口 `game-4f6d18f`。
- [PR CI 37516767964](https://github.com/narutojzm1-dot/youjia/actions/runs/37516767964)、[Publish 37518155244](https://github.com/narutojzm1-dot/youjia/actions/runs/37518155244)、[Pages 37519510271](https://github.com/narutojzm1-dot/youjia/actions/runs/37519510271) 全部 success。
- Pages commit `acd28f692872f70312e7e6d34e5cce494707da2b`。实际公开 PCK 28,465,216 bytes，SHA256 `1429e445ee1203e3588881c72b521d72faeeb8d985e885df84f7b425a587275a`，git blob `0f5f99961a00c3dc49127b007e9372a2bf83654e` 与部署树一致。页面入口及10个存档模块 SHA256 全部吻合。

Pages 尚在部署时首次读取 manifest 仍为上一版 d16736c，核验脚本如实拒绝；Pages success 后重读与实际下载全部通过。浏览器首次资源下载在46%停滞，页面重试一次后成功进入标题及院子，控制台保留19:33:09Z的 Startup failed / TypeError: network error（见 browser-errors.json），不宣称控制台全空；没有把初次下载停滞写成成功。

公开版1280×720普通输入实玩：正常进入院子→点击草泥马靠近并牵起→点击真实院门小路→到近郊→点击道路走到中段，草泥马跟随、绳连接人物和动物→点击回院，两者回到院门且绳牵保持。public-companion-1280.jpeg 与 public-return-1280.jpeg 为实际截图；无游戏或存档注入。成功进入后的出院/返院未出现新增控制台错误，首轮网络错误不隐藏。本地390/568响应式与重开矩阵见上级目录，不冒称实体手机测试。此为普通功能增量，不重复执行已完成的10月6日日版本邮件。
