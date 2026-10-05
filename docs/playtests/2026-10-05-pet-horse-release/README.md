# 普通抚摸反馈与马休息尺寸修复——组合验收

CODEX-LEAD，2026-10-05。本记录是白天修复批次，不是23:00日版本节点。

## 实际纳入

- PR302：成功普通抚摸不默认冒爱心。牛使用现有抬眼，马/羊原尺寸站定面向玩家；2.2秒姿态、每只动物5秒视觉间隔，连点不续期，成功事件/摄影照常。独审发现的待转向下一帧覆盖朝向已修复并重新审查。
- PR304：固定相机与actor比例时，horse_tail回idle可见高度增加29.13%；暂停tail绑定，原资源保留待同尺度重绘。休息显示idle，未改变休息时长/相机。
- PR276：携鱼一致性85项回归纳入daily；修复作者文本通道丢失的执行位。原机106帧未取得，后续证据不冒充这些原图。

精确最终审核：302 `d3094f136720ac010ac33c8a789957fac2661011`，304 `97fc91eb5d7a5375e6d292fa0d47c2638aa5e148`，276 `da146fd3adb3d6f58730fb802ae2fba02ac4c617`。各自独立Reviewer、退回及再审记录在原PR。

## 最终组合验证

组合本地SHA `6ec1c8fb6e4109a87394fc943b028bd1b868a786`，与302最终远端tree `b16e3432d091a6f23f01336b6ae612c3e5c81345`相同。

- Godot4.7.2完整`verify_daily_life.sh`退出0，包括pet110、pose35、fish85；日志SHA256 `840269789581541f181e5b6139ddf87a427c6032510b66e3a4a030946d1c509b`。
- 生产Web导出通过，本地PCK SHA256 `8485b59683c1ff06e671352deb6e78e96bf1a14fcc1b3f3b6cc1f55d5b7cd106`。本地与CI包可能因打包内容/环境不同而不同，不要求本地PCK等同线上PCK。
- 844×390仅画布自然操作：入院、暂停、两滑条、恢复；console/pageerror均0，截图已看。见`local/`。
- 具体动物表现见302的[8态受控Web证据](../2026-10-05-pet-response/)和304的[24帧修前后证据](../2026-10-05-horse-posture-size/)。它们是受控场景，不能声称自然随机触发、真机或真人听验。

## 未完成范围与Owner

- CODEX-LEAD：#150生产唯一写者、user目录就绪、durable业务通知；303已独审合入251研发分支，未合main或冻结Host。后续接线仍Lead。
- CURSOR-CLOUD：#176核心保持Draft；#305是新candidate Host与Gate的真实组合增量验收，不重复容量测量。首次小路及圆石/松果/落羽已获用户确认。
- GAME-PRODUCER：#168右侧连续天空无云底板，尚无新PNG；v8为接续入口，旧v3–v7 PR已关闭但历史保留。ART审核后才能接入。
- CODEX-LEAD-ASSISTANT：#300环境轨仅候选技术审核通过，真实自然度/10分钟听验未完成；#235短音与#285圆石修边按实际串行队列。Lead负责成功事件接线。
- CODEX-LEAD：马#120同尺度原画、#123旅人动作及#126院内资源；本次停止不合比例图不等于完成原画。

本批不关闭完整#30、#180或#231，也没有发布探索、替换阴天原画或证明环境音已自然化。

## 公开发布核对

- 发布源 `3ed47d7a3d5c608720f54ca3d5d282143d8d2e5d`，entry `game-3ed47d7`，manifest publishedAt `2026-10-05T06:31:17Z`。
- [Actions 37272489866](https://github.com/narutojzm1-dot/youjia/actions/runs/37272489866) 与 [Pages 37272854970](https://github.com/narutojzm1-dot/youjia/actions/runs/37272854970) 均success。
- 06:33:37Z实际读取公开manifest，并分别下载公开Pages与gh-pages原文件PCK，两包逐字节一致：21,926,140 B，SHA256 `c23d0ee7cd2ee26ffa2411c150754b5134388e6024b76407262b09995e35aad4`。详见`public/pck-check.json`。manifest本身未提供hash，这里记录的是实际下载计算值及与发布分支产物的比对。
- 公开844×390构建识别为`game-3ed47d7`，入院/暂停/两滑条/恢复操作成功，console/pageerror=0，恢复图已实际查看。见`public/public-browser.json`与截图；未作真人听验。

### 公开画布交互复核的边界

第一段先点马并等走近，截图确实显示“你轻轻摸了摸马。”且无心；随后主按钮已变成“拨一拨水”，所以八次主按钮点击实际是在互动岸石，**不能当作八次抚摸验证**。原始尝试保留于`public/primary-probe/`，未删除失败范围或把其他动作算成抚摸；`primary-probe.py.txt`为原驱动。第二段改为反复明确点马的轮廓，结果另列。

第二段在同构建以八次明确马轮廓点击替代主按钮，首/中/末帧均可见“你轻轻摸了摸马。”且未见通用心；console/pageerror=0。这是八次输入与截图观察，不用持久通知文案推断八条独立成功回执。见`public/pet-browser.json`和`pet-0/3/7.png`。

**新发现保留：**后段整幅画面自动放大。源码仍有`QUIET_SKY_ZOOM=1.14`，静止5.5秒自动看天空；因此本批3ed47d7的马贴图修复不等于所有镜头缩放已消除。Lead已在[#40](https://github.com/narutojzm1-dot/youjia/issues/40#issuecomment-5989417625)认领独立最小修复，后续结果另记，不回改原始截图。
