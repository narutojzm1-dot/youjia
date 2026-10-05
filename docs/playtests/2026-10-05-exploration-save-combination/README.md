# #150 / #305 公开探索生产存档组合：两项新增验证

四个页面（两个独立全新context，各真实关页/新页一次）全部在page-builds.json严格断言HTML game-33b105f与完整manifest source `33b105f075a1b851450f647c623302070ffafe1f`。无部署漂移窗口、无重试被冒计成功；不触发部署，不改仓库/生产代码。1280×720 Chromium headless+SwiftShader，普通鼠标/键盘操作，非实际手机。IDB仅只读取证，故障仅transport回执层。

## natural：同趟两个同名物品

正常标题入院→左下石板路出门→门口停看随机空→坡边停看带落羽→溪边停看再带落羽→坡尽头停看随机空。04-slope截图篮子明确“落羽×2”；原始active记录carried两件、taken两个不同来源。未注入种子、位置、携物，未为了凑3生成物品。

回院等待确认：05-return-two，keepsakes `formal.find.feather:2`，水位1、session=null。真正page.close同context新页重新入院：06-reopened仍2、水位1、session=null；确认后generation11完整封套相等。关键原图已查看，操作/原始封套见driver.py、events.json与各帧JSON。原要求至少2件已覆盖；3件容量/换物仍未在这次自然路径出现，不冒全容量矩阵。

## fault：真实 exploration trip commit 后丢一次回执

独立context正常出门、溪边随机圆石并点击带上。02-carried仍keepsakes空，active carried圆石。仅此后arm transport钩子并真实点击回院：

1. gen6：真实pending_commit记录，水位0、keepsakes空；正常交付，不丢回执。
2. gen7：真实探索授予事务，水位1、圆石1、session仍pending_commit。原IDB put执行并success，transaction complete=1791200315293；真实confirmed回执到达后1791200315634仅向GDScript交付save-error，记录保留原confirmed/complete/readback回执。不是yard故障，也未改payload/游戏内存/存档值、未主动abort。
3. 03-trip-unknown实图显示院内“再确认一次”。真实只点一次该按钮；resolve返回与gen7同request/write/token的confirmed/complete/readback_verified，时间1791200345090。
4. Cloud正常_finish触发idle清理：gen8 complete=1791200346736，session=null，圆石仍1、水位仍1。此是正常清理提交，不要求整个current封套/gen不变；关键是未重复授予。
5. 04-one-confirm实图提示已消失、院内可继续。真正page.close/newpage再正常入院：05-reopened圆石仍1、水位1、session=null，未重复授予。两页严格同完整source。

原始完整事务事件在fault/*-audit.json；summary.json归并链路，不用日志PASS替代。已实际查看两组停看/携物/unknown/恢复与重开原图。两驱动退出0，pageerrors=[]；未采集console事件，不称console全零。

## 边界

这是两个特定场景，非全部故障矩阵、听验、实体触屏、Safari或物理断电。原画清底/前景遮挡/独立物件仍有资源欠项；本次数据验证不冒正式美术全验收。自然同名双物件计数与受控探索trip回执丢失为新增证据，不重复声称旧单物件矩阵新完成。PCK/十模块来源核验使用Leader独立发布记录，本驱动未重复下载核验。


## 发布来源与留痕

本次复用已实际下载、逐字比较的同构建 [PR357公开发布记录](../2026-10-05-save-feedback-release/public-release.json)：Actions [37301988362](https://github.com/narutojzm1-dot/youjia/actions/runs/37301988362)、Pages [37302516657](https://github.com/narutojzm1-dot/youjia/actions/runs/37302516657) 均成功；PCK 25,262,564字节，SHA256 `6898f06a6d4e78b13b769614ca3c40bedbc779b18c4d19e27d79acf2cdaa4135`，10个存档模块与公开清单、raw产物和源码相同。此次浏览器逐页重新核manifest/HTML，未把复用哈希说成再次下载。

范围登记：[#150](https://github.com/narutojzm1-dot/youjia/issues/150)、[#305接收协调](https://github.com/narutojzm1-dot/youjia/issues/305#issuecomment-5993616866)。实际浏览器由Leader内部助手review301完成，Leader看过停看、双落羽、回院/重开、故障、一次确认后及故障重开原图并核原始封套。此内部助手不冒充项目CODEX-LEAD-ASSISTANT；Cloud探索Owner与首片表现迭代保留。

驱动是现场操作命令桥：各目录 `driver.py` 读取同目录 `command.json`，`events.json` 保存按序实际鼠标/键盘/等待/关页动作。复用时先将驱动中的绝对输出目录调整到新的隔离目录，启动驱动，再逐个把 events 的对象写入 command.json，等待对应 done 后交下一条；不要同时提交多个命令。自然随机结果不保证复现相同物品，坐标和源SHA须按实际页面重新核对；不得为了复现本次结果修改随机种子或存档。故障驱动仅用于一次性测试profile。

剩余未覆盖：三件/不同物品混合/换物、当前生产探索reject/abort/双页争用与其他重放组合、真机触屏/Safari/实际配额或物理断电；本次不关闭#150/#305父单，不扩产品范围，不制作资源、不重发同版或重复里程碑邮件。
