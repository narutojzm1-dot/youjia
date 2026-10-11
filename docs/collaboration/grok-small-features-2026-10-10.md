# GROK-CONTRIBUTOR 小功能队列（2026-10-10）

用户直接授权：bug较少，可将边界清楚、可控、不影响Leader主干的小功能交给Grok，减轻细节工作。此规则扩展2026-10-08的bug-only限制，保留修bug职责；不恢复旧全局UI Owner身份，不与GROK-BUILD混淆。

## 当前分工与任务

| 顺序 | 原单 | Owner / 状态 | 产物与依赖 |
| --- | --- | --- | --- |
| 1 | [#703 绘本气泡](https://github.com/narutojzm1-dot/youjia/issues/703) | GROK-CONTRIBUTOR / 已回执，PR #718 待返修 | 独立气泡及小鸡/已确认播种情境接入，可立即开发；无成长数值/存档改动 |
| 2 | [#704 轻交互音](https://github.com/narutojzm1-dot/youjia/issues/704) | GROK-CONTRIBUTOR / 已回执，PR #720 待返修 | 背篓/相册/暂停开关与翻页短音制作、接入、真实听验，可独立推进 |
| 3 | [#705 做饭烟雾](https://github.com/narutojzm1-dot/youjia/issues/705) | GROK-CONTRIBUTOR / 已指定、待本人回执 | 烟囱局部效果先制作；正式接入依赖Leader真实做饭开始/结束事件，不以隔离演示冒上线 |

每项原单定义具体范围和验收。前三项来自用户#700，不是任意扩展玩法。2026-10-11已核对#703/#704本人回执及PR；#705仍待回执。核对最新#242：Grok此前仅在修#598/PR651，后续已由Leader#676完成；旧界面PR已交Cloud，不能因重新授权小功能重复接回。

## 文件和方法边界

- Grok优先新增scripts/presentation/下独立叶子组件、独立资源和测试；允许为自身切片完成必要运行挂载，不只交候选等别人接线。
- #703 owns resident_bubble.gd / resident_barks.gd、气泡专用文案，现有World/Main只做锚点与已确认事件订阅。
- #704 owns ui_interaction_audio.gd / assets/holiday/audio/ui_grok/；复用AudioDirector，允许最小cue登记。Main限已列UI事件音效钩子；不改Cloud面板布局、快捷栏策略、音量UI或事件业务逻辑。
- #705 owns cooking_smoke.gd及其资源；建议set_cooking(active)/set_paused接口。Leader提供真实餐食状态与锚点；不自行推断饭点就是正在做饭。
- Leader保留成长模型、餐食选择/时间/行动点/经验/奖励、做饭与睡眠/刷牙导演、SaveStore/codec/WebHost、纪念状态、农田迁移。
- ASSISTANT保留近郊。Cloud保留整体UI与面板布局；上述气泡和限定音效钩子是用户本次授权的Grok切片，不形成所有UI全面转交。
- 不覆盖音频Draft542/623/317；不改其他Owner在途资源与方法。真实方法重叠在原PR协调，不锁整个Main，开发步骤无需Leader逐次批准；最终提交必须经过下述Leader审核。

## 执行与完成定义

Grok先回执当前项、分支、精确SHA/方法范围，再按1→2→3持续交付；阻塞只约束实际依赖步骤，前两项不等待做饭系统。明确范围的小功能可继续从已授权需求拆分，先在原单标明Owner和范围，无需逐个请求产品批准；新玩法、成长规则和未决产品数值仍归用户/Leader主线。

每个切片由Owner制作、实现、必要接入、验证并提交PR，Leader负责最终审核及合入。保留桌面/窄屏真实体验；音效要求真实出声和重复听验，条件缺失据实记录。候选/隔离演示/已接入/已发布分别说明，不将headless或自动分析当真实体验。取消逐PR强制子代理审核规则保持，日23:00Leader集中审查保持。

#242仅作短索引，讨论回原issue/PR。本次安排未修改外部Grok客户端定时器，不假定Grok已读或在线。

## 2026-10-11 用户追加：Grok所有提交须Leader审核

GROK-CONTRIBUTOR的bug、小功能及其后续修订，均须由CODEX-LEAD审核最终完整SHA，核对需求、文件边界、代码/资源质量、存档兼容和必要测试/真实体验。在原PR记录审核人、精确SHA、结论、证据和未解决项；通过且满足门禁后由Leader合入，Grok不得仅凭自测或CI自行合入。审核后SHA变化须复核。Leader每轮主动查看其新提交、对话/行内评论及评审，不仅依赖通知；无变化的已审版本不重复审。此为GROK-CONTRIBUTOR专门要求，不恢复全员逐PR外审或强制子代理审核，普通开发步骤不增加逐次批准。下文冲突的历史规则以本条为准。

每轮先核对Grok关联原单、PR、提交与移交谱系；已移交给Cloud或由他人合入的历史成果不得重复认领。已经合入却缺审核记录的变更须如实补审，不能补造事前通过。退回意见留原PR逐项闭环；没有真实体验/听验不能写通过。首次登记时三项均待回执；当前#703/#704已提交，#705仍待本人回执，不将规则留言视为已接收。

## 2026-10-11 05时轮最终SHA审核

- #718：`76b3df7f144f42eab7a71dfdb5172de38ed25061`，CODEX-LEAD退回。主场景3306/3339行动态调用结果使用`:=`导致busy类型无法推断，本机Godot4.7.2 check-only复现解析失败；另需修正小鸡提示每帧抽签导致触发过密，并补真实播种/暂停/近郊/窄屏体验。详见[原PR审核](https://github.com/narutojzm1-dot/youjia/pull/718#issuecomment-6102162511)。
- #720：`445204d0d5073e4f72dc14190df1b31a3358a163`，CODEX-LEAD退回。ui_interaction_audio_suite.gd结尾if缩进错误，本机隔离测试解析失败、未运行断言；真实按键链、静音/音量/解锁、重复听验仍缺。详见[原PR审核](https://github.com/narutojzm1-dot/youjia/pull/720#issuecomment-6102162651)。
- 两项均保持Grok Owner，不由Leader并行覆盖；作者修订最终SHA后复核，不以当前CI或候选说明代替通过。#705未回执。
