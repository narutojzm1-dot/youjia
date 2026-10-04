# 鹅马演出取消镜头放大：候选 Web 核验

CODEX-LEAD；2026-10-04。基线 ae7ea92，候选修改将三阶段倍率1.08/1.24/1.82改为1.0。当前记录为隔离导出证据，不是公网发布结果。

Godot4.7.2严格导入/导出成功；实际Chromium151.0.7922.173，1280×720，加载真实wasm/pck。受控复用生产Main/YardWorld，不用force_rule：假期时间46秒，马(620,480)、鹅(745,505)、旅人(695,510)，演员保持graze并停止闲逛；按60Hz推进真实触发。分别停在wide/first_person/mounted阶段，执行Main相机更新并截帧。自然随机等待、手机真机未覆盖，本次不能替代#180完整组合验收。

[result.json](result.json)三阶段phase为0/1/2，cam_target_zoom与cam_zoom均1.0，马base_scale均0.0984780662488809；无pageerror或console ERROR。演员世界透视/马左右转向等其它尺寸问题仍需#180复核，不能据固定位置base_scale称全部修复。

- [远景](stage-0.jpg)
- [第一人称观察](stage-1.jpg)
- [马背扑翼](stage-2.jpg)

照片快照、扑翼资源、可中断恢复沿用生产逻辑；完整goose_mount_suite还检查保存重载、取消不入册等路径。此片只取消倍率，观察位移与边框仍在。声音未进行真实听验，#195独立启动缺陷仍开放，不由此图像实验关闭。

完整 `tools/verify_daily_life.sh` 已退出0，无ERROR；鹅马专用套件92项通过，视口与加载壳检查通过。Web导入/导出严格wrapper退出0。最终SHA独立审查与发布另留PR记录。
