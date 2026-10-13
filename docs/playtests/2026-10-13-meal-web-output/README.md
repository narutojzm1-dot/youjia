# 做饭音频 Web 输出修复证据（最终候选已验证）

Agent-ID: CODEX-LEAD。本目录归档最终软件输出验证与历史失败；运行代码已由 PR766 合入 `d4c5b092a465186316c5ff35d0a17d2c57b0b379`，本目录本身不作为公开发布通过记录。

## 版本与结论

| 阶段 | 精确源码 | 已有证据 | 状态 |
| --- | --- | --- | --- |
| 修复前普通玩法 Web | `9783d956c20c95d4d244db328a69f82836549d9f` | 正常钓鱼、自然午餐；原入口仅增加目的端软件观察夹具；诊断 JSON / C1 WebM / 原观察器 | 做饭源触发，但目的端输出为零 |
| 本地修复回归 | `eaaf41b9e96126cf30c816fade239052c4fd561c` | 批准素材哈希、原生功能回归、受控 backend 缓存释放 | 本地回归通过；不能替代 Web 出声 |
| 最终整合后的普通玩法 Web | `48f02b32215629de6393ac6e6bec83786054b4d3` | 三餐自然输出及第四餐暂停/实际运行中总静音/恢复/自然停止；完整诊断、C1/C2 WebM、普通入口重开 | 已通过本轮软件输出验证；已合入；尚待公网核验 |

`before-9783d95/audio-check.html.gz` 是历史观察入口快照，依赖当时的引擎/PCK/启动与存档模块；这个证据目录本身不是可独立运行的游戏导出，不应拿历史 HTML 去配新 PCK。最终头已从新导出的 index.html 重新制作观察入口，保留新构建身份与原启动核对，文件在 after-final-web/。

## 修复前实际 Web 失败

音乐与环境声通过正常 UI 关闭，音效保持开启；玩家正常钓到可用鱼并自然进入午餐。没有注入物品、时钟、存档或游戏私有状态。这里是带软件输出观察的普通玩家操作链，不等于完全无观察代码的正式发行页。

- 观察器原样转发 `AudioNode.connect` / `AudioBufferSourceNode.start`，额外并行接入 Analyser 与 MediaStreamDestination；100 ms 采样，连续 10 秒窗口。不会读取/调用游戏、存档、时钟或 `__manusBgm`，不请求麦克风权限。
- 做饭源在约 `129293.6 ms` 触发，后续循环源与两次锅勺源均可见。锅勺源 `shortPeak=0.3129386603832245`，是非零 PCM。
- `129000 ≤ wallMs < 139000`：99 次快照，C1/C2 各 198 个目的端 tap 读数，最大 RMS 与 peak 均为 **0**；状态 running，观察器 failures 为空。
- 全程 C1 目的端 2926 个读数均为 0；此前 C2 音乐有非零读数，说明观察器具备测到非零信号的能力。不能用“源非零/事件触发”替代“目的端出声”。
- 原始 `context-1.webm` 33516 B 已逐字节保留。当前无可用解码器，未另行解码它；零输出判定基于目的端 Analyser 记录，未伪称人工听过或硬件录音。

## 修复与批准素材边界

11 做饭循环改用已经存在的 `BrowserBgmPlayer`；12 仅 `meal.spoon` 显式选择同一 Web renderer，其他 cue 不迁移。11 保留原 forward loop `0..2.6 s`，12 保持短声不循环；同一批准 PCM 版本见 `sources.json`。默认未授权静音、真正做饭状态驱动、暂停/失焦/中断/静音清理、停止和退出释放均保留。13 肚子叫仍由生产 Host 禁播；没有再次要求用户批准已批准的 11/12。

## 本地回归与失败历史

| 回归 | 结果 | 文件 |
| --- | --- | --- |
| meal_audio | 107 checks，0 failures；覆盖最后的直接 SFX 静音清理 | `native-eaaf41b/meal_audio-renderer-final.log` |
| meal_audio_host | 71 checks，0 failures | `native-eaaf41b/meal_audio_host-renderer-final.log` |
| 真实 Main house_cooking | 119 checks，0 failures | `native-eaaf41b/house_cooking-renderer-final.log` |
| audio_button_input | 648 checks，0 failures | `native-eaaf41b/audio_button_input-renderer-final.log` |
| yard_audio | 87 checks 通过；首次退出有告警，详见下段 | `native-eaaf41b/yard_audio-renderer-final.log` |
| 已有 backend 缓存生命周期 | 12 个断言通过；fake AudioContext，非出声测试 | `native-eaaf41b/backend-cache-lifecycle.cjs` 与 `.log` |

这些测试在 9783 基础上的本地修复过程中执行；107 项最后覆盖 `eaaf41b` 的 SFX 监视增量，其他套件在此最后一处小增量前已通过。最终整合头精确 CI 38353346196 已成功，实际 Web 连续录音已另归档；不能把这些本地日志标成新整合 SHA 的全量运行。

首次 yard_audio 虽然 87 项通过，退出仍报告 **8 ObjectDB instances / 4 resources**；同环境原 HEAD Director 基线和修复版 verbose 复查均干净，原因未定、未复现。保留三份日志，不写成“所有运行控制台无错误”。

首次 house_cooking 被旧 `.import` 指向不存在的云层 ctex 阻断；隔离进程终止后做本地 editor import，随后 119 项成功。原失败 `house_cooking.log` 与 `renderer-import.log` 保留；import 改动的五份 tracked 描述文件已原字节恢复，没有进入修复提交。上述原生测试使用独立 APPDATA，不读写玩家浏览器存档。

缓存实验直接执行已存在的 backend JS，使用 fake AudioContext 验证 active 时缓存不可释放、stop 后即使逻辑 player 仍活着也能释放，buffers/bytes/playing 归零，dispose 后 players 归零；只证明清理语义，不证明实际浏览器输出。

## 最终 Web 结果与文件

详见 [最终候选录音分析](after-final-web/README.md) 和 continuous-analysis.json。三次自然完整餐次的循环/锅勺均有目的端输出；第四自然午餐验证正常菜单暂停停止、回到真实游戏运行时总静音保持零输出、解除后恢复非零、再次暂停及自然完成尾部归零。没有游戏材料/时钟/存档注入；录音结束后普通无观察器入口同档重开，库存与池岸保留。精确头 CI 38353346196 成功，Root 已合入 PR766 → `d4c5b092a465186316c5ff35d0a17d2c57b0b379`（tree 与 48f02 相同），仍不宣称公开包已核验上线。

原始观察 HTML 与诊断为无损 gzip（HTML 解压后才可查阅源码）：修复前、首餐历史快照、最终连续录音均保留所有窗口（包括失败字段和空/静音窗口），不存重复的大 JSON。compressed-sources.json 记录压缩文件和解压后的 bytes/SHA256；files-sha256.json 枚举实际归档文件且不自包含。

解压示例（Python 3，在本目录执行；新输出不属于原清单）：

```python
from pathlib import Path
import gzip, hashlib
src = Path('after-final-web/continuous-diagnostics.json.gz')
raw = gzip.decompress(src.read_bytes())
assert len(raw) == 34749247
assert hashlib.sha256(raw).hexdigest() == '8bef32f21c1f654906f9c18f9f4c676aa3307b425d066afe9684b2cdda1e0b35'
Path('continuous-diagnostics.json').write_bytes(raw)
```

本目录不含私人邮件、收件地址或用户回复原文。已批准源音与本轮软件输出分开记录；没有要求用户重复确认相同声音。未覆盖人耳/硬件、真机触控、全三餐窄屏或全部声音。仍保留首次 yard 告警、原生 import 失败及早期 iframe 异常的真实限制，不用本轮通过抹去历史失败。
