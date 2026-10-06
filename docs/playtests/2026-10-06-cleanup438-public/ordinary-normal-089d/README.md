# PR438 普通公开路径在 PR439 构建上的有限验收

结论：本次普通路径 PASS；没有故障注入或业务状态写入。浏览器已关闭，实际进程 exit 0、页面 errors=[]。

## 来源与操作

公开来源完整 SHA `089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21`（含 PR438），入口 `game-089d453`。两个实际页面各自首末读取 manifest、核对 HTML；四次 manifest 均同源。每页通过 HTTP 实际读取 PCK：27,088,396 字节，SHA256 `fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8`。这是 QA 的独立下载核对，不声称拦截了引擎加载的响应体，也不替代 Leader 的 raw/source/十模块核验。

全新 Chromium context，1280×720、DPR2、has_touch/is_mobile。标题进入、自然轻抚羊、翻册、外出移动和点门使用 touchscreen.tap；树荫停点观察/拾取实际使用键盘 E/T，因此不是全触摸控件矩阵。只进行一次自然外出、一个树荫停点，实际遇见并拾取松果。点门自然返院，等候后采样，再等待 5 秒采样；真实 page.close 后同 context 新 page 重新进入、翻册，并再等待 5 秒采样。完整输入时序及来源位于 result.json，驱动为 run.py。

## 实际只读存档观察

| 采样 | generation | records 键 | 松果 / 授予水位 | session |
|---|---|---|---|---|
| before-trip | 2 | current | 0 / 0 | 无探索记录 |
| before-return | 6 | current、intent | 0 / 0 | trip-1 已携松果，record_revision=3 |
| after-return | 9 | current | 1 / 1 | null |
| settled-return（再等5秒） | 9 | current | 1 / 1 | null |
| reopened | 9 | current | 1 / 1 | null |
| settled-reopened（再等5秒） | 9 | current | 1 / 1 | null |

末四份只读数据库 JSON 原字节完全一致；所有六份的 album/photo_moments 相同。原自然羊照片入册后，真关页重开仍显示原照；shade-take、settled-return、reopened-album 原图已人工查看。松果没有重复授予。这里仅确认采样时 intent 不存在、session=null，不将其推断为未直接读取的内部队列状态。

## 边界

本档只覆盖一次普通自然松果路径与照片持久化；没有受控故障、未知字段档案、三物件矩阵、物理断电、真机、真实系统触摸或听验。未知字段拒绝保全由 Native 及另一独立受控故障档案说明。早前本地候选的首次 Target crashed 与唯一短链重试保留在原候选档案，本档不抹去它，也不将未证实原因归于产品或资源。浏览器模拟输入和 viewport 不等于物理手机验收。

全部本次原始 PNG、六份只读 JSON、result、驱动与日志保留；archive-manifest.json 列出原字节 SHA256。未复制 PCK 或缓存。未改生产代码或公开存档内容。
