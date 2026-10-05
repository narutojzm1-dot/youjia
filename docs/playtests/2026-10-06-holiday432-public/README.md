# PR432 正式发布与两条空篮路径有限验收

CODEX-LEAD归档；独立普通Web执行 review301，归档助手 /root/horse180_repro。此切片只文档。432发布时PR431相册与Cloud427独立在途；归档整合时431经433已独审合c6e5c9b8b1764f8c41eb492b56b4d11da7f1386b，公开CI在途、尚未公开验收，相关实现仅随最新main继承，不纳入此432发布证据。随后Cloud427 c6c1已合main cdec7a6a5b8f13307048e60f6e1f57d49f5b5881，但INVALID回退共享保全缺口未修，Leader已取消该源发布37356141984；433安全CI37355933384继续。本档案对当前main仍仅docs差异，不把427合入视为修复/发布。

## 来源与实际发布

PR432精确最终 `0c3b3e079ac98f082670e10f73b83b246f86e8b6` 已独立APPROVE，合入 source `96f090a63e0997244924a7463bd0e52a025b57b1`，见原审查与merge回执。运行实现及68次Godot完整daily/14专项历史见[实现证据](../2026-10-06-holiday-start-once/README.md)。

[Actions37353041717](https://github.com/narutojzm1-dot/youjia/actions/runs/37353041717) verify-export-publish success；[Pages37353907443](https://github.com/narutojzm1-dot/youjia/actions/runs/37353907443) build/deploy/report-build-status success；不可变 gh-pages `d0948065af086850779b6b0cafe8a65d4aebca96`。Leader在2026-10-05 18:12:25.965397 UTC实际核验公开manifest source、HTML game-96f090a、公开PCK与上述gh-pages包一致、十个存档模块与source逐个一致且MIME正确。

PCK为27,085,436 bytes，实际下载 SHA256 `8b5c85763a480a9f7a6e40196ccd0a5b04b645be2a79391c0c1b63eca04c6aa0`，不是manifest自带PCK哈希，也不是候选ff17值。原脚本/JSON/log均归档。

## 正式普通Web有限通过

[独立QA原报告](browser/README.md)，两fresh Chromium context各一次；每页首末manifest与HTML绑定96f，每页通过同context HTTP请求实际下载版本PCK核验。不是CDP拦截Godot引擎响应。真实touchscreen.tap完成标题/出门/路面走开/停留，失效点保持近郊；点门后保存7秒中间图并正常再等14秒，原图明确“回到院里了。空手走一趟也舒服。”。另一fresh页出门后用真实键盘左右沿路，正常返回明确“回到院里了”。原图已由QA与Leader亲看，不用errors为空替代功能验收。

全部QA17原件及其manifest保留，图片无加工；程序exit0、pageerror/console errors为空。触摸返回仍可见#400院景右偏，未掩盖或宣称已修。

## 剩余边界与协作

本次只闭合公共启动重复受理的发布＋两条空篮路径有限回归，不关闭#399。全三种物件/全DB/保存故障矩阵、实体手机与听验未覆盖；一次有限携物关页补验见下文；历史正式失败[PR429档案](../2026-10-06-exploration399-touch/README.md)保留。Main启动方法本切片实现已交付释放，不占Assistant382 _input/modal/slider，Cloud427仍独立，其他PR未算入本发布。

重大稳定性邮件已由Leader去重后于2026-10-05T18:18:12Z成功发送to:me，Gmail id `1a10d49a3375f426`，去重key `milestone:holiday-start-once:game-96f090a`；[146回执](https://github.com/narutojzm1-dot/youjia/issues/146#issuecomment-6000443044)，非日版本邮件重复。archive-hashes.json仅记录此目录实际复制原件的字节/哈希，无PCK/profile归档。

## 同版一次自然携物补验（在前述邮件之后完成）

独立review304，[完整原件与边界](carry/README.md)：同96f正式版，两页4次首末manifest/HTML绑定及2次实际PCK下载8b5c核对。一次自然近郊趟，touch行走/触门，普通E/T观察拾取，得到松果1＋圆石2（3件2种，不是三种物品、不是全触摸采集）。真实28秒走到门后返回原图显示“回到院里了。松果、圆石×2都收好了。”。

随后真page.close→同context newpage→标题入院。重开院子截图没有背包数量UI，不以画面冒充数量验收；独立只读IndexedDB技术证据显示after-return与reopened records/current封套逐字段完全相同，generation12、松果1/圆石2、session=null、committed serial1，无再次授予。不是全数据库对象相同、ack时序证明或整浏览器重启。before-return generation8为第三次拾取后尚未确认的中间快照，保留且不引用为最终篮子。

18原件及原hash清单完整复制，输入/DB仅观察未写入，exit0/errors为空。不覆盖落羽、全数量/路线、存储故障、Cloud427矩阵或整个#399结项。432重大邮件发送时该补验仍在途，历史邮件说明保持原样，本次没有重复发邮件。
