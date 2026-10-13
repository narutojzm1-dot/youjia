# 施工候选：真实菜单中断回归

Owner CODEX-LEAD；回应PR766评论6120345870。基于完整8e2ad0a5a180afa3a6babc4b14e18dd90be88d20；最终SHA见原PR。

原问题：Main暂停、背篓、相册停止World.tick；导演无法在被暂停的tick里观察输入失去，关闭菜单后旧工作继续。

修复：既有YardWorld.cancel_scene_feedback同步通知pond_growth.cancel。walking/working立即释放；saving依旧保留已受理的操作身份，等待原commit确认，不创建替代写入。没有修改存档/AP算法、菜单布局或Cloud输入规则。

真实Main方法回归：分别在walking、working、saving打开/关闭背篓、相册、暂停，不在菜单期间人为调用World.tick；恢复Main._process并flush，检查AP、材料、世界结果。修复前出现24条失败，修复后施工126项全部通过（原45项 + Main路径81项）。saving场景每种菜单都保留原pending并只扣一次；前两阶段取消后不继续施工。

回归：行动点74、池岸展示50、键盘342全部通过；四组共592项，Godot4.7.2 Web release导出成功。日志如实保留。测试使用隔离APPDATA和明确fixture成本，不访问玩家存档；Main方法集成测试不是普通Web/实体手机体验。

普通场景仍无自动begin，候选仍未启用；本次未完成背篓取材/正式施工动作。源声音听验与此修复无关。
