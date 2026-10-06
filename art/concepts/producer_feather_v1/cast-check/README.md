# 人物与候选同场：静态校准，未验收

复用07b153a中的SequenceResident、NearPathLayout及其逐帧资源，原样复制到隔离Godot4.7.2项目。main.gd只摆放角色/物件并使用L.frame取景，不包含探索Host、HUD、take或发现提示。背景使用已归档02_near_path原PNG；松果来自PR361原件，落羽来自本PR原件，未处理像素。两物件主体高均24原画像素，未随物件深度缩放；因此这些是待校准参数，不是正式替换方案。

脚本生成12张截图：1280×720、390×844、844×390各d663/365/195/0。这里只归档三张代表图，其余保留本地producer-recovery/near-path-cast-check；evidence.json列出所有本地证据哈希，不表示所有文件均在此目录。复现时从注明源提交取scripts/entities/sequence_resident.gd、scripts/exploration/near_path_layout.gd、scenes/experimental/resident_walk_authored_v1.tres及其预加载人物目录；设置Node2D挂载本脚本，使用OpenGL compatibility。背景和两候选以near_path.png、pinecone.png、feather.png放隔离项目根目录。

独立GAME-PRODUCER-REVIEW-PINECONE实际查看7张截图和脚本：

- 人物近大远小可暂保留；脚点未明显离路，但人物偏淡、轮廓细碎，需运动/朝向/脚底接触验证，不凭静态图整体放大。
- 松果在竖屏d195接近人物头部视觉体量且位于更远处；下一步应同深度比较，试更小世界尺寸，64px展示可保留。
- 落羽在亮路上几乎消失。优先选择较暗、干净的路边落点，结合轻量发现反馈，不靠大幅放大解决。
- 绘制顺序只有背景→物件→人物，无前景遮挡层；不能据此证明经过草叶、石块或门柱时遮挡正确。
- 竖屏人物/道路保留，但连续导航与发现距离未验。底图原有大松果/落羽仍在，不能视为候选精灵可读性证据。

后续单向行走采样已修正遮挡前置判断，见[遮挡必要性复核](walk/README.md)：当前没有可指认的强制mask点，不把缺少层当成完整演出的硬阻塞。原有可拾物清底及同深度尺寸对照仍未完。此材料未覆盖真实拿取、音画同步、手机交互或可靠存档。
