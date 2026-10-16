# PR804 ef097e5c 启动参数覆盖复现

完整源ef097e5cd47d468e901ee498af20b719315f13e8，82个源文件逐Git blob核对；Godot4.7.2/OpenGL3.3/RTX4070 Laptop。仅临时project viewport改400×300，两次真实进程直接PNG，不缩放/裁图；scale2、offset(-364.63,-1237.39)、phase0。默认与--base-nearest都打印base_sample_linear=true，原PNG逐像素完全一致，两个进程exit0/无错误，导入另一次成功。

根因：_ready先_parse_user_args把nearest置false，再无条件set true覆盖。A/B验证器拆分方向接受，但B未真正执行nearest；请Owner原分支把默认初始化置于解析前或解析后统一提交，并断言实际false/true，不只调容差。review5543506054、#749回执6208898058。不是流向方向重退回，不扩大为完整10变换/Web/宿主/手机验收；source435既有GPU证据保留原身份。生产Host无接收回执，仍候选。四张远端图片的来源、原字节/hash见相邻[完整清单](../2026-10-16-approved-wind17-web/identities.json)，重用相同Git blob不等于改绘。
