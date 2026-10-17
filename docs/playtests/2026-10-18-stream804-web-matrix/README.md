# #749 / PR804 Windows真实Web完整矩阵复核（CODEX-LEAD）

复核完整头33106846329d0917e46f4bbc9c239cd2701bd5f2。隔离工程从该Git对象直接archive到独占输出目录，未改作者源；导出前仅注入专属build_id。Windows Godot4.7.2 + Chrome155.0.8059.85，默认硬件ANGLE/NVIDIA RTX5090D v2 Direct3D11，DPR1，1672×941实际画布。

本轮PCK2560720B/SHA256 7e13af97f98b5733e7598a3bfb995650a722454256491a39cc8454526b523284，包内build_id d068dad9a41ce6ce91e9517fa0c5459d。专属服务器bind(0)并持有socket，下载被服务的完整PCK与导出哈希一致。页面实际读回、上传90份无损PNG和结果JSON；服务端/页面/磁盘SHA相互核对，原作者离线判定器用本机bundled Python的numpy/Pillow对全部90PNG复算。50/50通过，浏览器/离线结论一致；S0、0↔TAU、非水面、保护区、裁切外和边框±3硬门全0，半圈有变化，×1整数R对原画0。

`matrix-originals.tar.xz`是可逆压缩容器，含全部90份原PNG、上传日志/结果JSON及本轮实际PCK。清单列逐原件SHA，已逐个解码重新校验，非只存两张采样图。源码和判定器仍以PR804该完整头为准；这里的Windows启动器不冒充原Linux shell全链。未改生产shader/Host/照片/存档。

失败必须分开读：首次Leader手动Windows启动器漏建uploads目录，页面50个像素组合本身通过但上传失败，顶层ok=false；不是作者候选像素失败。第二轮补独占uploads目录后上传和页面顶层通过；启动器最初调用系统Python缺numpy，随后使用bundled Python对同一份原件真实复算通过，没有重录或覆盖失败。失败日志与两份身份保留。原作者此前40/50→50/50的floor/lo-hi边界问题仍留原PR，本轮不改标。

此结论只解除完整隔离DPR1 Web矩阵的Leader复核等待。仍是Draft美术候选，未生产挂接/未合入；DPR2/3、实体手机、生产Host天气/昼夜/照片/切换和性能增量未验收，#749保持开放。旧方向“没问题”回执6194352528不当作后续所有范围验收，也无需重复索取同版方向批准。

Raw Windows text artifacts retain their original bytes under raw-bytes/*.gz; raw-byte-records.json records the decoded hashes. Readable JSON and driver copies use LF. No original result or failure was deleted.
