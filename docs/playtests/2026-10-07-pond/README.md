# F1：beibei 找龟并接回水塘

2026-10-07，CODEX-LEAD；#503 / #504；F1 已由 PR517 发布。父版本为 main `acc83e423bd6ca9340333d9134c36cbafef4680e`。

## 公开发布核验

- PR517 最终 head `970fbef9e8996c9eeea9216b0d203103ff14ce2e`；本地源 `326dcc687c668fd306491d7e11cacbff6a061877`，两者 tree 均为 `bf3fe87318e58bcd510c6f8b8f7a274913ac2cfc`。
- 合入/公开 source `f84f11d1753cc902d418a30185b84027c3f51ba6`；CI37546754470、Publish37547822659和Pages37548770063全部成功。CI及Publish日志均有 POND_RESIDENTS 42、POND_INTEGRATION 40，零失败。
- Pages提交 `4d6f7dc9a31187a351ecd0e882d38f704c929470`；实际公开入口 `game-f84f11d`，PCK 37,293,136 字节，SHA256 `0fc26bf71d11a8f9045a56268280bba722bb014687a91557185bacc09be0ebdc`，Git blob `57c33305214f6810a5515e42e1da1ef6bf90b7a6`。公开HTML入口及全部10个存档模块哈希一致，见 `public/verification.json`。
- 正式浏览器重新加载确认版本入口；旧第5天幼犬与松果1仍保留，控制台无warn/error，见 `public/`。这个公开存档仍为幼犬，未将它冒充成年犬找龟的正向体验；完整自然同行→找龟→收养→重开保留由下文普通本地Web旧档验证。
- F2 小米/鸡成长在独立 `codex/lead-chick-millet` 本地接续，不含于本公开包；F3鸡龟/鹅龟未交付。不重复10月6日已经完成的日版本邮件。

## 范围与结果

成年 beibei 是当前正式旅程的同行者时，在村边水岸停下观察，会走近并用完整低头姿势探查 2.4 秒。提交确认后才显示乌龟；玩家可选择接回小院水塘。乌龟有唯一居民身份，提篮满空不影响接回。院内先在左岸石头休息，重开仍在；F2 小米、小鸡成长及 F3 鸡龟/鹅龟关系尚未交付。

`world_residents` schema1 升级至 schema2 保留 beibei 的成长时钟和身份。未知/损坏数据拒绝写入，不重置为新档。发现和接回使用真实生产保存队列，重复操作不重复收养；回院后重试沿用冻结的资格，不能复活旧旅程。

## 验证证据

- Godot 4.7.2 Windows 隔离原生测试：POND_RESIDENTS 42、POND_INTEGRATION 40、WORLD_RESIDENTS 43、BEIBEI_INTEGRATION 46、ANIMAL_HIDDEN_FIND 92，全部零失败。日志目录：`%TEMP%/youjia-basket-check-20028cef-ba85-4046-bb2e-6283e3615fb6`。覆盖生产文件读回、旧档、位置/成年/同行资格、满篮守恒、低动效不跳过时间、焦点丢失取消、重复点击、回院后重试与照片实际纹理。
- 最终岸边落点原生 OpenGL 再验 40 项通过：`%TEMP%/youjia-basket-check-e2a3e514-75e4-4e70-9cd8-54c9d4108ef6`。本目录 `searching-1280.jpeg`、`found-en-390.jpeg`、`found-zh-CN-568.jpeg` 是受控夹具视觉证据；夹具设定成年档和同行种子，不冒充自然概率体验。`pond-reopened-1280.jpeg` 为最终岸边石头落点。
- 普通 Web 沿用 E 自然成长至第25天的旧存档，无注入时钟/状态/随机数。先遇到羊同行和独行，水岸不出龟；之后自然选中成年 beibei，步行到村边水岸→观察→出现乌龟→确认接回→返院→刷新重新进入，乌龟保留，旧犬保留。`web-found.jpeg` 留发现画面。最初岸边位置偏水面，实玩后改到左侧石头，最终包再重开验证；不会把早期位置当最终截图。
- 最终本地 Web PCK：37,293,492 字节，SHA256 `6e45ad81f19f0eafc580effb4a74d1afcf65cd5ea7229bab69cd27d401f05be6`；`%TEMP%/youjia-pond-export.log` 无引擎错误。控制台见 `web-console.json`。本地包与 Linux 发布包可能因导入不同，公开包须单独核验。

## 资源

来源、原始输出、提示词与哈希见 [原画记录](../../../art/candidates/pond-stories-2026-10-07/README.md)。运行时使用原始透明完整画作，不拉伸局部或拼接肢体。龟目前岸边休息；未实现游泳遮挡、骑鸡或鹅龟争执。
