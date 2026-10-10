# #641 阳台生活公开交付回执

Owner: CODEX-LEAD。PR691公开核验完成，2026-10-10北京时间下午；不是23:00日结或第二封日推。

- 实现 PR691，远端 head `c8f97c5312d81cdb01cc0deff846850a94612ded`，与本地作者提交 `419e8d9ec434e2a273b2041239c2f9c207a70fb7` 同树 `484751a26af164827289ef3c4fe57054002d6cc5`。
- 主分支合入 `45c23fef88ae09c31e9460a607afe838d45cb672`。
- 完整 PR 检查 [38035594295](https://github.com/narutojzm1-dot/youjia/actions/runs/38035594295) 成功，包括全部游戏验证与 Web release 导出。
- [完整路径、原画及测试记录](../2026-10-10-balcony-morning/README.md)：阳台3867检查、室内睡眠154检查均零失败；五个实际GPU受控睡眠案例完整结束，窄屏阴天和本地Web旧档验证完成。

公开 [Publish38036683105](https://github.com/narutojzm1-dot/youjia/actions/runs/38036683105) 与 [Pages38037729966](https://github.com/narutojzm1-dot/youjia/actions/runs/38037729966) 均成功。Pages源提交 `6d8d3aea7151a12bb4eb2390e02fcc2d6f486e03`；普通公开 manifest 已指向上述主分支合入 SHA，入口 `game-45c23fe`。

实际下载 PCK **68,707,076字节**，SHA256 `2f32d6e50783dc6769311cf4a1ee96103cef5e9836dfe239eab184aed6610168`，Git blob `8a64dd1eb738eba598723fb8d9b8283ccd965f5a` 与 origin/gh-pages 一致。实际 index.html 的 blob `94c4a013665745d1197cbc5b94cb32371e843b91` 同样一致；十个存档模块、四个引擎文件和两个加载模块的实物SHA256全部通过。[完整实物清单](verification.json)。首次部署后普通URL短暂返回旧manifest，等待普通URL更新后才完成核验，没有以带查询参数的页面替代普通公开地址。

普通公开页面刷新可见加载标识 game-45c23fe，进入后恢复第21天、已长大的beibei和原快捷栏。390×844重排完成后时钟、背篓和底部操作无截断；实体手机触摸与生活音效真实听验未覆盖。未替换 #635 未通过的斜向步态。

## #638 公开自然跨夜补验

升级前公开source ca16e0a24f2ad077c5d90f925e39e36959fc896c 的真实旧档，从第20天下午3:12起持续停留户外，不点击睡眠、不注入时间或存档。先观察晚上11:45，再观察上午1:14仍为第20天，最终自然进入第21天上午6:17。窗灯和归棚随夜晚发生，但没有强制玩家入屋；凌晨也能留在院里。其后暂停、刷新到新公开source45c23fe，再正常点击入院，仍为第21天早晨，原成长与快捷栏保留。截图：[下午第20天](day20-afternoon.jpg)、[午夜后仍第20天](day20-after-midnight.jpg)、[自然第21天清晨](day21-dawn.jpg)、[新版本窄屏旧档交互](old-save-mobile.jpg)。原始截图为JPEG，保存时保留原字节并使用相应后缀，没有栅格处理。已有PR656跨场景时钟、暂停与重开验证继续有效，本次补齐原单尚缺的公开自然过夜验收。

本片不改变 ASSISTANT 近郊模块。23:00日结与邮件按原去重规则处理；本轮不是另一次日推邮件。
