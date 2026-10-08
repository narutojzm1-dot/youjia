# #565 夜间音景与睡眠声音候选

Owner CODEX-LEAD。基线 main `a7eba513d805547a01528fb30d9d632f230fcb01`，保留 PR542 `03828df70e1c0cc60c504183d8bdcfd803cb8bd8` 为合并祖先。候选未合入、未发布；公开game-ccee83a不变。实际最终SHA及CI见关联PR。

## 已实现

- 20:00–05:00公共时钟换原创夜曲；小院/近郊共享夜曲，白天各自曲目。没有第二套时钟、后端或存档。
- 夜间淡出白天鸟风底，淡入蛙虫与稀疏嘶声；雨天叠加轻雨。新增四轨和完整生成/来源/解码测量见 [资源说明](../../../art/concepts/night_soundscape_20261009/README.md)。
- 保存未确认或失败时不打呼噜，仅 house.stage=sleep 播呼吸；暂停冻结呼吸、后台暂停全部，醒来/退标题即止。环境开关/零音量覆盖呼吸。
- 四环境层合计权重始终1，淡化过程中也不超1；共享Ambience 0.3 authored ceiling。音乐仍独立。缺轨只静音该层；离院撤销并释放所有候选缓存。

## 验证及边界

|验证|结果与证据|
|---|---|
|生产状态与真实Main适配|regional_audio 129项通过；包含候选实际资源、昼夜/天气/睡眠、帧间增益预算、保存前不播、醒来停止、后台最终事实、关音/零音量/缺轨/标题释放|
|已有回归|yard_audio104、ambience_output_ceiling30、house_sleep53、audio_button_input648、exploration_slice305均通过；各原始日志同目录|
|真实原生音频驱动|Windows WASAPI / 48kHz，六段实际Master总线PCM + 四轨真实末尾跨界循环；非Dummy/headless，无麦克风/无系统回环录音。day/night/rain-night/sleep/wake均非零，environment-off精确零，采集无掉帧；`native-pcm.json`及`capture.log`|
|采集材料|night/rain-night/sleep/environment-off四段原生录音转Ogg，同目录；原WAV SHA见recordings.json。受控测试调用生产AudioDirector，不冒充普通游戏手势或人耳听验|
|Web导出|Godot4.7.2 Web release成功；正式游戏普通浏览器体验另追加在本页|
|尚未通过|耳机/扬声器听感、整曲/接缝听验、十分钟持续听验、浏览器实际PCM与缓存长时测量、实体手机。不能以波形或UI截图代替|

## 解除交付门禁

在这条完整候选上进行#196声音听验（曲目区分/夜间舒适度/蛙虫蛇辨识/不突兀呼噜/首尾与交叉淡化/开关/后台/十分钟）。Leader接续修订与CI/公开包核验；只在真实验收后合入发布，不重做已有生成与接线，不擅自要求用户重复确认已批准的声音方向。

Web普通UI：1280×720新本地档进入小院、暂停、环境关→开、继续；warn/error为空。`web-environment-off.jpeg`只证明按钮可操作，不证明出声。严格完成契约反例96项通过（gate.log）；缺失日志/零检查/伪前后缀不会放行。最终候选补缺失白天轨不得停止夜间轨的回归。

## 最终候选普通Web（本地8774）

候选最终代码（125项缺轨修复后）重新Web导出并刷新。第1天旧进展恢复为阴天，正常时间推进到暖窗亮起的夜晚，点家门后走入并在约十余秒内返回第2天，显示“早安，新的一天”。再次刷新进入仍第2天。夜间画面有工具观察，但保存截图时已到次晨，故图片按真实内容命名，不冒称夜间图片。`web-morning-confirmation.jpeg`、`web-morning-day2.jpeg`、`web-day2-restored.jpeg`保留实际次晨及重开。

390×844模拟视口中暂停、分别关闭/重新开启音乐和环境声，按钮与滑杆可见可点；`web-mobile-controls.jpeg`记录两开关关闭，最后恢复开启，候选暂停待续。warn/error为空。以上是普通UI与存档恢复证据，未读取/注入浏览器内游戏对象；不证明真实听感、浏览器PCM或实体手机。

## 原生循环返修

代码自查发现BrowserBgmPlayer.force_loop只提供Web循环，新增环境声部没有旧Director的finished重启回调；四条Ogg默认loop=false会令原生播一遍后停止。将四条导入设为loop=true，不覆盖旧资源；新增4项实际导入断言（专项现129项），以及WASAPI下从各曲末尾0.2秒处开始、0.8秒后仍playing且播放位置已回到开头的真实跨界测试，四条均通过。六段PCM已在此最终循环修复代码上重新采集，原始日志/录音/哈希同步替换；不再沿用返修前录音冒充最终验证。

普通Web夜间→次晨截图为循环修复前代码（Web当时已force_loop），修复后重新导出并补普通重开验证；不宣称两次操作是同一次运行。最终CI以PR最新SHA为准，听感门禁保持。
