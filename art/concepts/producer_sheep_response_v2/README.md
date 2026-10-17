# 两羊回应返修候选 — GAME-PRODUCER #121

接续GROK-BUILD原PR166（21416b95d99cca8602d42d1521c58d28304b51c6），保留原候选。本稿回应ART5970264669及本地独立复核提出的原尺寸头耳变化难辨问题。使用内置image_gen，以各自cast_v2/sheep_clingy.png和sheep_dull.png为编辑目标，transparent_background=true。生成原件字节复制，无本地像素处理；逐稿提示见txt，原件/实际Godot截图哈希见measurements.json。

选择黏人羊v2及呆羊v3。黏人羊耳朵横向展开、吻部放平朝玩家；呆羊保留长脸/衔草/垂耳，以克制微抬头区分回应。呆羊v2因颈胸过高被独立拒绝，原件3460d6c127f4673ba070582ea05117edf8e7c99c7ab36979a11bbee6100c97ac保留本地producer-recovery/sheep-response-v2，不作为接入资产。

独立GAME-PRODUCER-REVIEW-DUCK-ART实际看两原件、idle及正确比例场景，分别APPROVE仅进入接入校准；呆羊v3解除长颈/胸升问题，两羊身份与回应差异保持。不是正式互动验收。此前旧图仍难辨的结论不被PR已合入覆盖。

隔离Godot4.7.2 OpenGL：羊固定(600,480)，玩家在朝向侧110px；深度按YardGround，黏人原config.36、呆羊.34，CastArt目标高70除原idle bbox高度1083/916及legacy.36。新图不按各自高度重新归一化。地锚分别沿用(576,1178)/(732.5,1124)。此为清草地视觉校准，非正式羊活动范围、互动距离或导航调整。

复现将render_study.gd挂隔离Node2D主场景，视口1280×720；项目根准备本目录两候选、cast_v2两个idle原件、resident_walk_authored_v1/idle.png复制为player.png，以及现有晴院背景yard.png。源依赖与计算来自main5bb2102aa7d4fbf1c53953d9148762a0495c4c89。图中的Sprite2D替换只作静帧采样，不是连续视觉验收；idle前后输出同名，不声称已保存三段视频。

剩余：连续切换/逐蹄与镜像、成功互动及中断、照片真实纹理路径、手机与PCK体积验证。尚未写正式manifest/CastArt或改FeltActor，运行时仍为sheep→idle。无需新增反应延迟规则、好感值、额外帧或任务。
