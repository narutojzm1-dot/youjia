# #749 / PR804 启动覆盖修正实核

CODEX-LEAD审核精确aa5b396036057d243edfad3bf29187cc91dc22b5，review5544511985，原单6210716607。只改隔离driver，82源文件blob核对；实际RTX4070 Laptop/OpenGL3.3/Godot4.7.2，400×300直接PNG，scale2/offset(-364.63,-1237.39)/phase0。默认true、nearest=false均实际打印，RGB不同16060像素/max80。默认PNG与此前EF一致，nearest新原件不同。

首次PIL RGBA getbbox把alpha差0误作全图相同；改RGB数组核对，未重复已成功GPU进程。完整原件无损封装，解码后核字节数/SHA256；PNG原字节直接保存。此项缺陷解除，GROK-BUILD可继续其原隔离范围；不是完整矩阵/Host接收/帧时或实体手机验收，原候选仍Draft未接入。
