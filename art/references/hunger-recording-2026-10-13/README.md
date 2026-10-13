# #745 / 13 真实录音参照候选

Owner：CODEX-LEAD。版本 `13-recorded-reference-1281`，2026-10-13。仅供听验；未替换游戏声音、未获用户批准、未上线。GROK-CONTRIBUTOR 的 PR747/R3 原提交保持不变。

用户退回两版合成肚子叫后明确要求先找真实声音。本包保存可播放录音，补齐此前只有声学文献、没有实际录音参照的缺口。不是宣称已经依据参照重制完成 R3，也不冒称人耳验收。

## 来源与授权

- [Stomach gurgling #2 / BigSoundBank](https://bigsoundbank.com/stomach-gurgling-2-s1281.html)，作者 Joseph SARDIN，编号1281。
- 作者页标注 Studio / Realistic、SoundDevices MixPre-3 + Rode NT5；录音来源据作者声明，本项目未独立见证录制过程。
- 页内标注 CC0；[许可页](https://bigsoundbank.com/licenses.html)允许分享、修改、商业使用。2026-10-13核对。保留作者署名和链接。
- MP3为网站公开下载文件，字节未改。文件地址、字节数及SHA-256见 [manifest.json](manifest.json)。

## 听哪个文件

[13-recorded-reference-1281.wav](13-recorded-reference-1281.wav)：0.772秒，48kHz单声道PCM16。只在解码成整数PCM之前衰减6dB；没有拼接、变调、均衡、去噪或合成。它不是网站24位母版。原MP3浮点解码峰值1.00251，有29个超过满刻度的样本，因此没有把直接截幅的PCM作为送听版本；最终WAV峰值−5.98dBFS、RMS−20.75dBFS、满刻度样本0。解码/电平检查不等于听感通过。

复现（ffmpeg 7.1）：

```sh
ffmpeg -i 13-recorded-reference-1281.mp3 -af volume=-6dB -c:a pcm_s16le 13-recorded-reference-1281.wav
```

听验重点：是否能辨认成肚子叫、是否适合角色轻量饥饿提示。用户可以批准这份录音作为13的替换源，或只作为返修参照；没有回复仍然未批准。邮件发送及回复标识仅保存在私有去重记录。

该目录有 `.gdignore`，并位于既有Web导出排除的 `art/*` 中。生产 `MealAudioHost` 继续禁止13；没有修改11/12、素材路由、游戏存档或音量设置。14/15仍待返修，不混记为已完成。
