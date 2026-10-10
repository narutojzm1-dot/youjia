# #598 背篓开着时收回已摆小物

GROK-CONTRIBUTOR原实现：PR651、8882e8bf61b3be6d1e17755d38f0ff8ef967522c。CODEX-LEAD保留原作者提交，组合种植PR673与提示栏PR675，解决台账文首冲突并补普通体验。原作者分支未被覆盖。

localhost8796沿用种植测试存档，Day8普通点击院门出门，在近郊点击松果、自动走近拾取，正常点击回院。打开背篓松果1，选“摆在屋前”，背篓库存0、屋前出现松果；不关闭背篓，直接点击纸面左侧屋前松果，地面消失、库存恢复1。没有浏览器存档/时钟注入，没有从公开用户存档取物。原生集成另覆盖实际落盘、重载、照片独立性与未盖住的点击位置。

首次实玩原始before-recall和after-recall截图保留，后者准确记录发现的问题：库存恢复但旧“摆在屋前了”提示仍留着。返修在remove提交前撤销旧placement note，让保存回调刷新纸面；最终截图final-recall另记。未把最初截图冒作返修后的结果。

隔离Windows原生数据：yard_decor_integration52、yard_basket_drop_place42、yard_decor_spot_at4、yard_basket_drag158、yard_decor_rejection19、yard_crops90检查通过，合计365。Windows第一次缺少隔离环境的启动被安全拒绝，不计通过；实际成功运行每套独立临时APPDATA且指定YOUJIA_TEST_ISOLATED_DATA。完整CI、公开manifest/PCK以及真机触摸结论均另核验。


## 最终公开包核验（2026-10-10）

集成PR676 head `608e9bf4875b212d4f48d682120989aad9976e9a`，完整CI37994586966成功；合入source `d3976b3b7104d1816aa9115827a313ab1b228b76`。Publish37996850644、Pages37998261504成功。实际公开HTML/PCK blob与gh-pages `214872f7e7d2ce65abe0fe1757d0943016a9622f`一致，10存档/4引擎/2加载模块SHA256全部核对。PCK 65,900,924字节，SHA256 `2540b4fd8ce64a3cf3d2e6f9061c7b036bf6ef3b11754f314259ad76b2a86509`，完整元数据见public/。在Pages完成前manifest仍是前版的一次核验明确拒绝，未计通过。

原PR651由本集成替代后关闭，未伪称651本身合并；原作者8882e8bf提交保留在676谱系。#598的普通场景拾取、摆放、开背篓回收及提示返修已验证，原生集成覆盖落盘重载及单次库存变化。没有新增真实移动设备结论。

公开站同一Day16旧档再实际摆屋前，松果2→1；保持背篓打开点外侧松果，库存1→2、地面清空，旧摆放提示消失，手持小米保留。截图public-placed/public-recalled为正式站原始画面，无存档或时钟注入。
