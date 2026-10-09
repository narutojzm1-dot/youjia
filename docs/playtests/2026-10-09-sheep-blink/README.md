# 双羊稳定休息与局部眨眼（#565）

Owner: CODEX-LEAD。基于 main d9da322986fa7594e2bd2ceec2d274b2e574c3cc，分支 codex/lead-sheep-blink-565。

原实现把两只羊的休息状态都切到同一张 sheep_shake 全身图，恢复各自 idle 时会改变脸型、轮廓和大小。本片去掉自动共享 shake 绑定，让每只羊始终使用自己的站立原画；新增独立随机的 0.30 秒局部闭眼动画。保留历史 shake 文件和照片读取。吃草、回应、行走、卧姿和减少动态优先，不增加存档字段。

## 原画来源

使用内置 image_gen，分别编辑正式 sheep_clingy.png / sheep_dull.png，输出 sheep_clingy_blink.png / sheep_dull_blink.png。完整提示词、模式、哈希、尺寸见 [provenance.json](provenance.json)。实际两张均为1254×1254 RGBA；shader仅采样各自眼部小区域，身体与透明轮廓始终来自原图。新增PNG合计2,694,534字节，原始RGBA解码估算12,580,128字节；不是设备内存实测。

## 已运行验证

- Windows Godot 4.7.2：painted_blink 75、interaction_pose 35、sheep_ground_graze 96、sheep_attention 56、cow_glance 8、large_animal_shelter 27，共297检查全部通过。覆盖实际角色休息/吃草/回应/卧姿/朝向/减少动态、脚锚与轮廓稳定、历史照片。
- RTX4070 OpenGL GPU 0/50/100%闭眼截图：sheep_a眼部变化2480像素，sheep_b变化2339像素；两者眼部外变化0、alpha变化0。见gpu原帧及日志，100%帧已目视检查脸型与眼睑。
- 普通网页 http://127.0.0.1:8777/ ，无状态注入：新Day1进入、开棚、移开入口、小羊点击与打招呼操作、暂停、重开再走入。恢复Day1阴天夜景，牛羊已卧于棚内、马与草泥马保持卧姿；控制台warn/error为空。截图见web。互动截图在回应结束后，不能冒称捕获完整回应/眨眼过程。
- Web导出成功；本地候选PCK SHA256 bd5e877ef4625d35331562400dd7a86baa228865b0dc1d4b81ed796e9fc6e190。不是公开版本哈希。

完整CI、合入及公开manifest/PCK/旧存档核验待PR完成后回填。未做本片手机实机、夜音真实听验；不宣称所有抽搐根因、所有动物或主角步态已完成。PR623听验仍待完成。
