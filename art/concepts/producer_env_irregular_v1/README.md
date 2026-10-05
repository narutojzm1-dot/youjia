# 不等间隔阵风试听候选

Agent-ID: GAME-PRODUCER；#194 / PR300 接续。候选隔离，不替换正式音乐/环境资源，不接声音后端。此前 PR300 的原稿、分支及技术审核保留。

旧候选每32秒重复相同包络。本稿从同一原轨重新滤波，安排5次不同间隔、时长、强弱的平滑起伏；不在旧包络上再套一层。底层仍是程序合成风噪，不是实录自然声；整段128秒仍循环，不能称永不重复。自然度、持续嘶声、配乐混合及10分钟舒适度未听验，不合入生产。

来源：GROK-BUILD 原创 `art/concepts/audio_b_stems_v1/bed_yard_env.ogg`，无外部采样；来源说明保留在该目录 SOURCES.md。精确源版本为 PR300 的 `b8e5e6dc916dacd1eaf45b36c9f17584d36fc16c`，原轨与旧候选 SHA256 在 build.py 中强制验证。旧候选路径 `art/concepts/assistant_env_v2/env_gust_candidate.ogg`。

## 试听

打开 listen.html，手动播放。三条对照轨统一至约 -27 dBFS RMS，只减增益；这不是主观等响或 LUFS 匹配，滤波频谱差异仍会影响响度。先比较规律性、持续噪声、起落是否突兀，再单独听候选原电平。接缝片第8秒是原轨末尾到开头，片段自身不循环。10分钟按钮仅重复候选，届时记录设备、实际听取时间及舒适度，不能以计时器结束代替人耳结论。没有配乐混合/游戏同步证据。

本地最初 WAV 草稿不是这里的最终 OGG；压缩后再次测量，以 measurements.json 为准。OGG 容器可能有不同序列号，复现比较解码 PCM hash 与指标，不要求容器二进制一致。

## 重建

使用 measurements.json 记录的 Python/numpy/scipy/soundfile/libsndfile 版本。安装依赖后运行：

```text
python build.py --source /path/to/bed_yard_env.ogg --previous /path/to/env_gust_candidate.ogg --output /path/to/new-output
```

生成器不联网、不改输入。输出包含全轨、接缝、三条RMS对照及实测记录；默认写本目录。独立技术审核和真实听验分开，当前不宣称声音更自然或功能已完成。
