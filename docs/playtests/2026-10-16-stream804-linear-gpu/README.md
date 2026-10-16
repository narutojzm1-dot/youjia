# 溪流连续UV默认开启：435 RTX子集

CODEX-LEAD审核435cc826fcfd22172745118a2f23fa8b3fa0987c，review5543074339。对应GROK-BUILD PR804 / #749；仍隔离候选，生产宿主ASSISTANT没有接线回执。

从精确源归档复制，着色器/驱动/场景/PNG逐Git blob匹配。临时测试工程只把viewport改为400×300，以直接GPU捕获观察两个子像素变换；PNG没有缩放或裁图，不冒作原工程全画幅或实体手机。Godot4.7.2/OpenGL3.3/NVIDIA RTX4070 Laptop，导入+14次实际GPU运行，无ERROR。scale0.75和2.0，各测减少动态/0强度/1e-4强度/phase0/半圈/整圈/旧整幅参考。

两组保护区、非水面、矩形外、0强度和循环差均0；near-zero默认对独立LINEAR Painting最大1级，半圈4005/17165像素变化。保护区实际样本115631/101506像素，非空。完整15份原日志、PNG逐文件SHA、源匹配列表和驱动保留。仅附两张直接原PNG作对应视图；其余原PNG在本机迁移补充包保全，不冒称全部图已远端。

发现原verify_scale_linear.py:164–177仍把当前C与旧nearest底图F按水面max<=1比较；本机当前默认对旧F差67/80级，因此该旧判据不能作为435新默认PASS。需要同采样对照，或明确legacy路径后另验当前默认对独立线性Painting。不要抬容差掩盖差异。本记录的采样一致性子集通过不等于原验证器全量通过，更不是流向算法退回。

缺口：完整10变换、连续GPU暂停、独立Web、宿主天气/照片/退出、实体手机和实际帧时。原Owner可继续原分支，候选不合入、不关闭749，不重寄同视觉阶段邮件。各次运行耗时不当GPU帧时；WebGL修复PR820的IntelArc普通Web证据与本RTX原生隔离证据分别署名。

日志包先base64解码再gzip解压得到JSON，其值再base64解码恢复原始日志字节。按logs.identity.json验JSON原件，按gpu-review.json验每份日志/PNG。native-gpu-review.py是实际驱动，需调整本机引擎和输出根路径；显示覆盖与范围已写明。
