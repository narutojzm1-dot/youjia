# 公告热修：公开 game-c44cc7e 实际验证

关联原单 [#771](https://github.com/narutojzm1-dot/youjia/issues/771)、实现 [PR #785](https://github.com/narutojzm1-dot/youjia/pull/785)、本地 gzip 对照归档 [PR #786](https://github.com/narutojzm1-dot/youjia/pull/786)。本目录只补公开版本的文件与普通 Web 体验证据，不重复原候选截图或实现。

## 精确发布身份

- 实际源码：`c44cc7e077dfa8dae07faba5a3463634306b8bc5`；构建号 `game-c44cc7e`。
- 代码候选：`c8ea3853818ade88d52a8621fda36cd28423ab84`，完整 [CI 38346352704](https://github.com/narutojzm1-dot/youjia/actions/runs/38346352704) 成功。
- [发布 38348401184](https://github.com/narutojzm1-dot/youjia/actions/runs/38348401184) 成功，UTC 05:10:31 完成。
- [Pages 38350052791](https://github.com/narutojzm1-dot/youjia/actions/runs/38350052791) 成功，UTC 05:13:23 完成；固定 gh-pages 为 `5acef1f8c93b3076a7f2ff32c26622dd7485ab6a`。
- 公开 manifest 与固定 gh-pages manifest 全文一致：source／entry 对应上述身份，publishedAt 为 `2026-10-13T05:10:08Z`。HTML 的 data-build、mainPack 与之吻合。
- 实际下载的公开及固定 gh-pages `game-c44cc7e.pck` 同为 **74,466,564 bytes**，SHA256 **0575be928650c5a59b2f37bd330952f5dc9762b671db503f4d01c52f550d3dac**，也等于 HTML 声明。两端各下载一次，UTC 05:17:00 完成。

见 [verification.json](verification.json)、[actions.json](actions.json)、[public-manifest.json](public-manifest.json) 与 [pages-manifest.json](pages-manifest.json)。大体积 PCK 不重复纳入证据目录。

## 普通公网 UI 实测

执行人：CODEX-LEAD。入口为 `https://narutojzm1-dot.github.io/youjia/`，浏览器视口 **844×390**，继续原有第 24 天存档。截图保存于北京时间 13:23–13:24，文件尺寸与 SHA256 见 [evidence-manifest.json](evidence-manifest.json)。

| 步骤 | 实际观察 | 截图 |
| --- | --- | --- |
| 打开「歇一下」暂停面板 | 构建标签显示 `game-c44cc7e`，底层仍为原有院子 | [18：公开构建号](18-public-c44cc7e-pause.jpg) |
| 首次打开公告 | 显示“暂时无法检查更新；以下仍是本版本公告”，本包公告仍可读；执行人未观察到新的 gzip 错误 | [19：首次查询未成功](19-public-c44cc7e-query-unavailable.jpg) |
| 返回暂停面板，再次打开公告 | 明确显示“已与线上核对：当前是最新发布版本”，当前构建及热修公告正确 | [20：重开后线上核对成功](20-public-c44cc7e-latest.jpg) |

三个原始 JPEG 已逐张查看并核对文字，均为 844×390。首次查询失败的精确根因未由截图确定；这里保留其真实表现，不把最后成功改写成首次即成功，也不承诺所有网络查询都成功。此次覆盖公开正常查询与一次失败后重开恢复；本地 gzip 强制对照、无效 schema、另一版本提示仍引用 PR #786，不能把本地候选截图 14–17 标成公开 c44。

## 保留的部署传播历史与边界

UTC 05:11:55 Pages 仍在部署时，公开 manifest/index 尚是 eb8，首次文件身份核对未通过；原始结果保存在 [before-pages-completed-verification.json](before-pages-completed-verification.json)。Pages 完成后重新读取入口，再开始新包下载，最终双端核验通过。前一次没有下载旧 PCK，也未重复派发工作流。

本目录的 844×390 是实际浏览器视口证据，不等于实体手机或真实触摸验收。没有把整份存档的全部字段恢复、所有网络故障、所有输入方式或成长系统认定为通过。成长候选及其 Web 做饭音频修复不属于本次已发布公告热修。
