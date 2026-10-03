# REQ-015 · PR99 最终合入门禁

- 检查者：CODEX-LEAD；2026-10-03。
- 精确候选：`1620c2abffab3d087a08472d080df39f32c48b75`；基线：`e11b250538bc437a16d420e4f0e298f363c9eda7`。
- 结论：阻塞，未合入、未发布。成品 Owner WORKBUDDY-CONTRIBUTOR 保留。

## 实际检查与结果

相对最新 main 11 个文件，只包含两帧母版/运行时资源、import、manifest、CastArt 与资源记录。运行时 PNG SHA 与此前 bec7118 候选相同，但 CastArt 注册代码已改变；不能沿用旧候选成功记录。

Godot 4.7.2 执行：

```sh
godot --headless --path . --script scripts/game/cast_art.gd --check-only
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 npm run verify:daily
```

独立 check-only 退出1，错误为 `cast_art.gd:53 Expected statement, found "Indent" instead`。全量日常脚本在导入/加载主场景阶段失败，报告 `[daily-check] Godot reported an error`；主场景无法解析 CastArt，后续套件没有执行通过。没有导出 Web，也没有浏览器画面，不伪造游戏体验证据。

51–52 行 `config.textures["riding_up"/"riding_down"]` 仅一层 tab，退出 `if species=="goose"`，53 行 metadata 又进入两层 tab，语法无效。修复必须将两行置回 goose 分支；metadata 字典的两项也按现有字典缩进对齐。不能仅将整个 metadata 拉到外层，否则会污染其它物种配置。

## 重新开放门禁的验收要求

1. 原 Owner 在自己的分支提交修复，保留最新 main 和其他贡献记录，不强推。更新 PR 正文中的旧 SHA 和审核状态。
2. 新完整 SHA 实际导入、全量回归通过；两帧注册只出现在 goose 配置，共用脚底锚点并保留真正照片捕获→JSON→回放路径。
3. 正常 Web 导出/浏览器启动，以及受控两帧实际绘制核验。候选包体与正式发布净增量分别记录。
4. 独立子代理审核新最终 SHA，批准与验证通过且 head 未改变才合入；后核对 Actions、Pages 清单及公开 PCK。

两帧注册不代表导演已经使用它们。实际马背接触、自然触发、第一视角镜头与真实成片继续在 REQ014 独立验收。没有修改产品定位、动物关系、触发概率、天气或照片表现。
