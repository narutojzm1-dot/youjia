# PR391 共享 API 清理契约发布：普通保存路径烟测

2026-10-05 UTC，PASS 此次正常路径。正式公开 source `4fa150819c304b03fb6a36a149e71d4bcd911000`，两次真实页面加载均独立读取公开 manifest 完整 SHA 并校验 HTML `game-4fa1508`，见 page-builds.json。公开包哈希由 Leader 单独核验。

全新一次性 profile，Chromium headless/SwiftShader，1280×720，实际鼠标普通标题进入→点击羊自然生成 sheep_pet_gentle 留影→打开手帐。实际点相册“合上”、等待、暂停、回到门口、“好”，title-return.png 已亲看确实标题页；再正常走进院子打开相册，照片仍在。随后真正 page.close，同 browser context 新建页再次校验来源、普通标题进入、打开相册；reopened-album.png 原照、日期“假期第1天”、题词“绵羊愿意靠近我了。”及“你伸出手。它没有走。”保留。

records.json 完整 readonly IndexedDB 快照：仅 youjia-save-host-v1，没有旧 /userfs 数据库。前 current generation2；正常回标题保存后重开为 generation3，payload 唯一变动字段 holiday_day_elapsed；album 和完整 photo_moments 完全一致。album 单条 sheep_pet_gentle，没有重复入册，records 仅 current、没有 intent。不得称完整封套字节不变：正常时钟保存已改变 generation/提交封套。

run.py 原始驱动、actions.json 原坐标和时间、console.json 原日志/errors、page-builds.json、PNG/records.json均保留。最终 driver exit0，pageerror=[]，console error=[]。已亲看 album、pause、confirm、title-return、return-album、reopened-album。

attempt1/ 保留第一次旧驱动误点：Escape 后立即点暂停未真正进入暂停，名为 title-return 的图实际仍院子，不能用于“回标题”验收。其羊照/真关页恢复仍有效，但最终完整链使用本目录新 profile 重做；这是驱动步骤不足，未据此声称业务故障或掩盖证据。

未注入业务状态或存储故障，未调用新 cleanup API；Cloud 尚未接入该 API，因此此证据不证明探索领域清理恢复已修。非听验、真机或故障矩阵。
