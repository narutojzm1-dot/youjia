# Web 系统低动效入口（候选，真实Web有限QA已归档）

Owner CODEX-LEAD，内部实施host_budget_impl，#36认领5998347852。运行时冻结`4886addaa9f091d55f8f5e5fd63908e4aa7b0f30`，基于main70309c5。仅新平台autoload/project注册与PhotoArrival活动显影兼容，未改Main_input、音频、Cloud、Host或持久schema。

此前正式版TuningStore默认false且persist参数不写盘，只有debug Manus通道，没有玩家自然入口。新autoload紧跟TuningStore，在主场景之前同步读取Web系统matchMedia。生产无用户覆盖，当前值来自系统偏好；不写localStorage/存档。严格boolean初值/change、重新可见/pageshow重新读取，缺失/异常保留默认或最后有效值；exit与重装清理监听。非Web不调用JS，Native普通设置入口仍未交。

Godot的eval不用于取得普通对象：只安装window.__YoujiaMotionPreferenceBinding，然后get_interface取绑定。该全局只有start/stop生命周期，无业务setter/测试开关；重装先停旧实例，旧stop不能删新实例。必须由真实WebQA验证Godot callback、初值及可见效果，Node VM检查不能替代。

PhotoArrival正常显影原截止1.58秒，原低动效1.6秒。normal→reduce杀当前Tween、静态可读至原剩余截止；后续normal不重放，不续期、不重复tucked_away。原已保存照片/快照不改。不是重置世界或暂停游戏。

## 当前证据

- `js-21.log`：JS受控生命周期/严格类型/缺API与异常/重复绑定/旧stop/删除全局21项通过。此为VM契约测试，非真实浏览器。
- `native-18.log`：实际Godot4.7.2 PhotoArrival与真实院景快照，18项通过；切换后按原剩余时间完成一次、静态alpha、不复活dismiss、原快照不变、Nativefallback。此为受控节点操作，不冒普通用户路径。
- 初次native脚本在autoload启动前通过全局class提前编译引发符号不可见，改为启动后动态load；继而测试在信号同步调用栈内free导致locked对象错误，补等待process_frame。原失败日志保留且不计通过，不隐去错误。
- 正确4.7.2完整strict daily实际exit0，65次Godot启动，所有入口通过，原始full-daily.log/exit；随后正式无observer Web导出实际exit0，web-export.log/exit与export-files.json绑定精确runtime。PCK27,083,500字节，SHA256 f965ac3846bd97436d972cd04ea3a8c03663e92eabec92098d1d714d94b93666。独立真实Web有限QA已归档于下节，不代表正式发布。

## 范围限制

院内云带/热点等既有每帧读设置会采用当前值，原分支验收仍按真实QA。Cloud `FindReveal.start` 把reduced参数冻结到calm，**已播到一半的探索获得展示未在本片改为实时切换**；下次动作读取当前系统值。不声明所有在途特效或全部低动效场景均已适配。没有新增玩家按钮/Native偏好适配/物理手机验证/听验。模拟浏览器媒体条件应标系统偏好模拟，不称真实OS设置操作。

## 本地构建标识的采集时间纠正

导出与根写入QA标识并行收尾，export-files.json的index.html实际已含根手工候选metadata（357784字节、SHA256以226aa3ff开头），不是未经stamp的原始HTML清单。该清单描述本地QA目录；PCK/JS/WASM保持引擎原字节。原始Godot web-export.log/exit不变，手工本地stamp不是正式发布；实际manifest/provenance及独立QA随后单独归档。未重导出或改运行代码。

## 独立浏览器证据归档

[QA原始说明](web/README.md)、web各result/全部驱动日志与fallback/result.json保留原字节。23张关键PNG以硬链接原字节归档（无裁剪/重编码），其余取样只有本地原件与[完整选择/hash清单](web-archive-selection.json)，**不能称全部原图公开**。web原README“全部保留”指执行输出，不是本精选归档。初始reduce/normal云带两帧、自然羊照片入册及真关页重开已采样；reduce云区最大差1且>5级差0像素，normal最大差10且>5级差363像素，细微全局色差不冒云移动。

photo-fast实际可见照片时切reduce，下一原clip完整卡片，下一采样已到期，normal恢复不重播；只一帧剩余可见采样，不能独立证明整个余时无渐隐。静态alpha/原截止/一次完成的18项受控Godot组件证据与浏览器普通路径分开。attempt1阈值失败与photo-refined全屏截图错失截止保留原结果/代表原图，不计在途通过。前三组returned-title图其实仍确认框、reentered-normal其实标题，不能按文件名当成功；title-cycle另有真实标题→院子原图补证。截图不证明监听数量，21项JS契约另列。

photo-refined同一1280×720链院景左纸边约95→213→97的原帧保留，关联#400，不推断根因、不声称本切片修复。缺失/抛错matchMedia的fallback为明确API故障注入，只验证正式候选可启动/普通输入，不冒操作系统自然设置。媒体reduce模拟产生真实matchMedia事件，但不是物理OS/手机操作；不含听验。

本地runtime4886add和PCK f965ac保持冻结；本地stamp脚本与motion-local-stamp-evidence.json解释手工QA标识及清单采集时序，不冒正式Pages。合入最新main fb3f990d4c392384149ee41830a314653af839ce只带入PM/Assistant文档，未改变候选运行代码。独立最终SHA审核与正式发布尚待；Native自然入口与Cloud已开始展示的实时切换未交。
