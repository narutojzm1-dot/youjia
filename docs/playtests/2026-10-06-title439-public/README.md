# PR439 标题声明链接正式公开验收

Agent-ID: CODEX-LEAD；归档实施者 horse180_repro。普通独立浏览器验收由 review304 完成，本归档不是作者自审。原实现 GROK-CONTRIBUTOR 的 b5423a67c9ca7aa0d9fd414a2d6ed1a5eadfbd31 保留为真实祖先，PR436 随集成 PR439 合入。

PR439 最终 68084b6cffc52e5911c49f1004b4da5154281671 经独立终审6001101655批准，合并/正式源 089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21。Actions37360164187与Pages37361682942均成功，gh-pages72eab79ca8af05b67dd6e3c29081b05d5ec8c203。CI验证阶段实际71次Godot启动，另Web导出1次，共72次；这是启动计数，不冒72个独立suite。

## 发布来源与原件

root于2026-10-05T19:13:55.552033Z实际读取公开manifest/HTML、下载版本化PCK并对照发布原件，PCK27,088,396 bytes，SHA256 `fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8`。十个存档模块也与精确源一致。此哈希来自实际下载，不是manifest自带PCK字段。

最初两次默认URL传播/缓存核对失败原日志 `pr439-public-release.log`、`pr439-public-release-final.log` 原样保留，不算成功；带query的新读取成功见fresh.log和release.json。随后默认不带query根页面与manifest稳定一致见unversioned-settled.json，不能以最新成功抹除早期传播过程。

## 独立正式普通UI结果

完整[独立报告](qa/README.md)、33原件清单、驱动/实际命令、result/错误及原PNG均逐字节归档。一页新档Chromium DPR2顺序实际resize为1280×720、568×320、640×300、390×844：声明链接normal/hover/实际mouse.down/真实Tab焦点均可读；四次鼠标打开真实许可新标签并关闭返回，另桌面一次Tab→Enter真实打开并返回。五次许可响应HTTP200，URL/title/完整text留存；errors=[]，exit0且浏览器已关闭。

每次声明正常态仅说明声明本身无焦点，其他按钮可留键盘焦点；不冒整页所有控件无focus。页面首末均核完整089d源、HTML和实际HTTP下载PCK；下载校验不是拦截引擎响应。

范围不包含Web实际像素对比数值、完整可访问性审计、其他菜单按钮颜色、原生许可窗口、实体手机/触屏或耳听。原生340数值专项与公开可读性证据分列，不以一方冒另一方。#413原范围具备此次有限证据，待本纯文档最终独审合入后由负责人按原范围结项；本文不提前称原单已关闭。#438故障/保全正式档案另片，不把同构建包含代码等同本次标题QA覆盖了存档故障。无需为普通UI另发里程碑邮件。

只新增证据与更新REQ035/决定，无代码/资源/配置改变；不重复导出或部署。
