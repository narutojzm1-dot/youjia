# #30 鹅成功投鱼后的收翅关注候选

CODEX-LEAD内部实施host_budget_impl，认领5994160535。复用CastArt已有goose_calm图与metadata，无新增资源，不称接食。成功消费鱼之后acknowledge_feed选鹅calm/鸭attend，最多2.2秒，视觉间隔5秒不影响合法鱼消费。移除鹅默认heart；显式feed身份处理外部位移/lead/posed打断，普通calm不被误当投鱼。原hold_expression3.5及鹅骑马/演出调度不改。

运行候选de98add31d5dac72dbaeb27a66c1c6b871b84a70，Godot4.7.2导入/生产Web导出通过，PCK2a121f43b5bff60b3490f90f9c9b72de56ad2811705977ea37d7803c184fd99a。专项25通过：正常setup、成功/距离/空鱼、实际纹理与朝向/脚锚、相册快照捕获重建、冷却合法消费且不续期、位移/lead/posed/退出取消、低动效、普通calm隔离。鱼到期原真实approach覆盖由interaction_photo保留。

首次专项3失败来自复制测试误将duck_attend文件名替换成goosettend及沿用鸭idle锚点；修改测试为已有goose_calm路径和已注册(694.5,1216)后通过，未借机改资源或门禁。原interaction_photo鹅默认heart断言按新需求换为本人calm与无心。完整 Godot 4.7.2 daily 实际 exit 0，日志见 daily.log；运行时代码为上述 de98add，随后提交仅归档文档。GOOSE 25、DUCK 24、interaction_photo 110 及整套后续门禁通过。

真实生产导出无 observer，普通 UI 随机钓获后成功投鹅，宽屏 1280×720 与窄屏 390×844 六张连续关键原图见 web/。review301 和实施者均实际看过成功帧：鹅收翅站姿、成功文案、无默认爱心；pageerrors/consoleerrors 均为空。脚锚、精确时长/冷却与低动效由 native 专项覆盖，不冒称浏览器隐藏开关操作或真实手机。相册快照重建由专项覆盖，本次自然 Web 不称已拍照回放。首次投中鸭的失败探针在 web/excluded-probes 明确排除。

候选尚待独立最终 SHA 审查，不称已合入/公开发布。
