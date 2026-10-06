# PR464 主线与 Pages 发布链独立复核：PASS

Reviewer：`leader_scope_audit`，仅只读GitHub API、实际完整Actions日志、树对象及公开manifest/HTML；没有新开本地Godot/浏览器、调度、重试、合并、发评论或改代码。检查截止2026-10-05 23:54:28 UTC。

## 精确执行来源

已独审的PR464最终 `0f4226dc6710ef3a11099baf45f707bbfd4fd30e` 合入 main `49596fa93bff3c29edfe441898017158c6e469a3`，完整tree `63ff0706a9c60dd31a69cb412b9629398a67848d`。main真实双父为 `cd836bf9e823b4e6276731b69e57f167c84547b8` 与上述最终head。自动push只观察到同源一轮 [run37390377329](https://github.com/narutojzm1-dot/youjia/actions/runs/37390377329)，job `112033754125`；实际checkout日志精确检出49596fa，没有把PR预览提交冒作main来源。

## 主线实际回归、导出、发布

所有实际步骤success。完整ZIP实际下载97,378 bytes，SHA256 `2fd4337f1281d2ff25629f8768d765488a4f2dec88f633f17ac4467dad5c4bc3`。

- 发布取源仍full history（fetch-depth0且实际fetch无depth参数），使用blob:none与非cone sparse仅排除根docs。此次验证真实应用新版publisher取源机制，未改变发布权限或helper。
- 4.7.2实际75次启动，1import+74套；逐引擎段匹配最终TSV的完整成功格式，含shutter1290、mat550、disabled4400。50门禁受控案例、两Node、retention11项及publisher双构建fixture实际完成。
- 实际Web export完成，无原生/导出ERROR、WARNING、FAIL或资源加载遗漏诊断。helper真实HTML修补验证、版本化模块拷贝、manifest生成、提交及 `HEAD -> gh-pages` 推送成功。

逐套件原件：[实际74套完成行](main-actual-suite-completions.json)。

## gh-pages 内容与保留规则

新发布commit `aeac1d1c37862ba91e454e130d9e266dc08bcfdf`，tree `02fc98f9fdfe7d1f22837753fb22883cea8a9602`，真实父为发布前 `e6d192eab33cc67e32f76656cdc24eb222b2a869`。Git内manifest source49596fa、entry `game-49596fa`、10个版本化存档模块。

发布前后实际完整树比对：保留当前49596fa及最近b300da7、9623ba2、870f4fa四组PCK；仅移除更早 `game-a0bb75e.*` 的8文件。477份此前保存的版本化存档模块、保留包及许可/声明元数据逐blob不变；新10模块逐blob与main49596fa的 `web/save/*.mjs` 精确相同。新版本各bundle文件与对应index别名逐blob相同。没有把PCK文件存在等同于公开下载验收。

## 实际 Pages 部署与公开来源

[Pages run37390958733](https://github.com/narutojzm1-dot/youjia/actions/runs/37390958733) 的head精确为aeac1d1c；build `112035653051`、report-build-status `112035783920`、deploy `112035783942` 全部success。完整Pages日志ZIP30,954 bytes，SHA256 `ef8b6f1654772811cbf5ab1d95cc465a8d395e754eafbda50ccdcacedab7a5e7`，build checkout也实际绑定aeac1d1c。

GitHub Pages deployment `6872095477`，状态记录 `19313652296` 于2026-10-05 23:53:27 UTC实际success，environment为公开试玩地址。不是只以调度或推送成功判断部署。

本reviewer实际HTTP200读取公开manifest与HTML，并计算Git blob证明字节精确对应上述gh-pages提交：

- manifest：1,203 bytes，SHA256 `81af305800effe7f54a48bd74c331034e42298c4c9c4763c1695097647a419c7`，source49596fa、entrygame-49596fa。
- HTML：358,101 bytes，SHA256 `9f3c4d8f66827663a136eaafb1527d5553154c5cea9d69d15157c1be31796385`，data-build、executable、JS入口与save-49596fa路径一致。

公开PCK和许可页字节下载、十模块公开下载由root另行执行；本报告不冒称自己完成它们，也不把候选中文两视口普通首照当作此发布版再次普通体验。此处PASS仅为实际main验证→导出→gh-pages保留与版本化来源→Pages部署→公开manifest/HTML字节链。

全部独立证据及safe摘要：[安全摘要](safe-summary.json)。原始ZIP仅供审计，可读解包日志已过滤认证头/签名URL相关行；没有私人邮箱或凭据写回仓库。
