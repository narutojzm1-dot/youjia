# PR433 相册短横屏正式公开有限验收

CODEX-LEAD归档；独立普通Web执行review304，归档助手/root/horse180_repro。仅文档，不改相册或共享存档实现。

## 构建与发布来源

原作者GROK-CONTRIBUTOR `db89cf3995ee3e77aa55567c92235f5d3f580d3e` 祖先保留；PR431经集成PR433精确head `aad4ef6fc0ee9898ab5178a2d307f890fd543d4a` 独立终审APPROVE，合入 source `c6e5c9b8b1764f8c41eb492b56b4d11da7f1386b`，原431自动合入。原审查与merge回执归档。此前[候选证据](../2026-10-06-album431-integration/README.md)和此次正式实玩分开。

[Actions37355933384](https://github.com/narutojzm1-dot/youjia/actions/runs/37355933384) success：69次CI验证引擎启动，另Web导出1次，共70；[Pages37356777602](https://github.com/narutojzm1-dot/youjia/actions/runs/37356777602) build/deploy/report-build-status success。gh-pages不可变源 `c095c5908c258951f27d9a71522cdab98a298d34`。Leader于2026-10-05T18:34:43.716945Z实际核公开manifest/HTML game-c6e5c9b、公开与不可变gh-pages PCK、十模块与精确source及MIME。

PCK实际下载27,086,076 bytes，SHA256 `f80ba8f58617ca6d4e91ce86deb80416f71f09286d7e2faaca99c48ae6d340c3`；不是manifest自带PCK哈希或旧候选包。对应脚本/JSON/log保留。

## 普通公开体验与边界

[独立原报告](browser/README.md)：fresh Chromium CSS1280×720/DPR2，普通鼠标标题入院、自然羊互动得到一张中文照片，正常相册入口；568×300、640×300、568×320三个真实短屏中照片、完整题词与正文、页脚、三按钮均在纸面内。只有一张照片，前后翻页按钮为禁用状态，因此没有翻页验收。正常合上/再打开及恢复桌面尺寸可读。

实际page.close→同context新页→正常标题进入/相册仍显示同张原照；这只是视觉恢复，不是DB字节相等或整个浏览器重启。两页首末4次完整manifest/HTML核同source、两次实际下载PCK核同hash。driver exit0/errors=[]，13原件（8张未编辑PNG、驱动/结果/退出/README）及原hash完整归档。归档者亲看568×300和真新页相册原图；最终代码独审与此前原生专项是另一类证据。

未覆盖多照翻页、全部长题词、英文、触屏、真机、声音或完整保存矩阵；没有DB访问、业务状态/随机种子/时间/位置注入，也没有为了多照强刷事件。早期候选元数据失败留在候选档，此公开样本未失败。

## main与公开版区别

归档base main `515f3550c41555dd4ccc160a767d0f72ccc584d2` 包含后来Cloud427；只取消了cdec源的Actions37356141984发布。当前核验公开版是安全source c6e5c9b，不含427，不能以main内容冒公开内容。共享最小修正47bb仍在途，不在本档案、不称已修/已发布。既有#400镜头偏移及其他父问题不因本相册切片验收而关闭。

普通UI改动本轮不另发邮件。archive-hashes.json只记录实际归档文件，无profile/PCK副本。
