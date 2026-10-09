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

PR629完整CI37875659070通过，head2ddd1cced70ca6b24c405d269284e229fcbb9f23，tree399d1c9e1da1371d9d19b1c8ccd729dbf4c40e56；合入/公开source96df742897f6e6d55c0378f0dc5ee507a0963384。Publish37876732191及Pages37877832435成功，gh-pages91d88876daec0879b26cabd5c4b1e7377c5ace77。实际公开PCK58,886,408字节，SHA256 51a97cebfd82b263c0d73328b31b2ccc488f98f3b0edb028ecc198740a3e52f2，HTML/PCK Git blob匹配，10存档模块/4引擎资源/2加载模块全部SHA256匹配。普通公开旧Day16阴天存档及手持小米1份恢复，双羊外形各自独立、控制台warn/error为空，随后暂停；见public截图和核验JSON。未做本片手机实机、夜音真实听验；不宣称所有抽搐根因、所有动物或主角步态已完成。PR623听验仍待完成。

补充普通Web：390×844暂停菜单/继续操作通过（04截图，非手机实机）。后续自然跨到Day2，羊从夜间卧姿恢复为各自站立原画（03截图）；点击房门前夜晚已结束，故不把它记为完整睡觉流程。
