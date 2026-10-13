# 原有三组花草：公开发布核验（#642 / PR699）

Agent-ID：CODEX-LEAD。核验日期2026-10-13。本归档是纯文档提交，不更改运行代码、公告数据或线上身份；实际发布源码始终按下表的 e13eec3 完整 SHA 记录，后续文档提交不是新的运行版本。双端实际 PCK 下载核验于 11:01:34 UTC 完成，普通公开入口 UI 观察在其后进行。

## 版本与发布

| 项目 | 精确身份 / 结果 |
| --- | --- |
| 原实现 PR | [PR699](https://github.com/narutojzm1-dot/youjia/pull/699) |
| 最终审核候选 | `6882157ec4e56e9128672aff9bef2b123e09182d` |
| CODEX-LEAD 最终审核 | [5502171904](https://github.com/narutojzm1-dot/youjia/pull/699#pullrequestreview-5502171904) |
| 候选完整 CI | [38380751215](https://github.com/narutojzm1-dot/youjia/actions/runs/38380751215)，success，10:27:51 UTC |
| 实际合入 / 发布源 | `e13eec3f5956de7d2c3a6e4c21876fa6375cbcc6` |
| Publish | [38383693495](https://github.com/narutojzm1-dot/youjia/actions/runs/38383693495)，success，10:54:06 UTC |
| Pages | [38386509611](https://github.com/narutojzm1-dot/youjia/actions/runs/38386509611)，success，10:55:27 UTC |
| 固定 gh-pages 提交 | `5be0c73840ed94b20303f9f268f12d82fd51500d` |
| 实测入口 / PCK | `game-e13eec3` / `game-e13eec3.pck` |
| 双端 PCK 字节数 | `85,511,664` |
| 双端 PCK SHA256 | `3146be2c2ade327103353900280b263395b4ad39e67d182281ec73505162f9ad` |

[Actions身份记录](actions.json)和[完整校验结果](verification.json)保留时间、公开URL、HTTP状态、响应头、实际字节数及SHA256。公共清单与固定gh-pages清单一致；HTML的build、mainPack、fileHashes和fileSizes也均与实际完整下载的两份PCK一致，结果PASS。固定端首次完整下载耗时约3分35秒，实际成功后才记PASS，没有用旧包或仅Content-Length替代下载哈希。

原公共HTML按原字节无损gzip归档为[public-index.html.gz](public-index.html.gz)，解压后的SHA256见verification.json。PCK大文件仅用于本机完整校验，不提交仓库；归档只含公开证据，无私人邮箱、原始邮件、凭据或玩家存档。

## 普通公开入口体验

CODEX-LEAD 在桌面浏览器新标签中直接访问[普通公开入口](https://narutojzm1-dot.github.io/youjia/)，未附加查询参数。以下原始截图均为 **1280×720 桌面视口**；本次公开操作由主执行者完成，归档者逐张读取截图并核对控制台记录。没有使用本地夹具替代公网，也没有清除旧存档。

| 证据 | 本次观察 |
| --- | --- |
| [01 加载过程](01-public-loading.png) | `game-e13eec3`；截图时已读取 91.5 / 119.2 MiB 解压后资源，耗时 133 秒。加载缓慢但继续推进，未点击重试，随后正常启动。119.2 MiB 是加载器显示的解压资源总量，并非上述 PCK 文件字节数。 |
| [02 旧档入院](02-public-old-save-yard.png) | 正常走进小院，同源旧档仍为假期第 24 天。 |
| [03 暂停构建](03-public-build.png) | 歇一会儿面板显示实际构建 `game-e13eec3` 与公告入口。 |
| [04 公告检查中](04-public-announcement.png) | 原三组花草的新增功能、修复及未完成范围可见；此图仍显示“正在检查线上版本”，不能作为最新版本确认。 |
| [05 线上核对完成](05-public-latest-confirmed.png) | 同一公告随后明确显示“已与线上核对：当前是最新发布版本”。 |
| [06 门前花草纸片](06-public-flower-paper.png) | 点按门前花草、角色走近后，正常打开“门前盆花”纸片，可见“先收起来”与“回到院子”。 |
| [07 关闭纸片](07-public-paper-closed.png) | 选择“回到院子”后纸片关闭、院内界面恢复；本次没有更改花草收起状态。 |

[console-errors.json](console-errors.json) 在这次捕获中为 `[]`，只代表本次观察范围内没有记录到控制台错误。首载缓慢的原始画面保留，不将其改写为秒开，也不推断网络、缓存或 GPU 的单一根因。

三组完整收起/复原、真关页重开恢复及照片冻结的候选阶段证据另见[普通 Web 记录](../2026-10-13-original-plants-web/README.md)、[原生与 GPU 记录](../2026-10-13-original-plants-runtime/README.md)及[最终 CI 修订](../2026-10-13-original-plants-ci-fixes/README.md)。本次公开复核没有重复改变三组状态，不能把候选阶段的每个步骤写成本次公网重测。

## 交付范围和限制

已发布子片只覆盖小院原有墙边、门前、池边三组花草的“先收起来”与“放回原处”，保存确认后更新画面，新照片冻结拍摄时三组状态和v1资源，旧照片保持原貌。保持原晴天/阴天底图，局部净底只覆盖对应区域。

近郊采花、自由布置、园艺种植/经验、新物种与蝶蜂等不在本片；整个#642和成长总Goal仍未完成。实体手机/真实触摸不由浏览器视口模拟代替。公开文件核验PASS不等于用户美术验收，也不抹去原候选退回、返修及先前验证记录。
