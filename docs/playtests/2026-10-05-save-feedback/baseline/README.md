# 非照片保存确认提示：旧公开版基线复现

实际 HTML game-7c1608c；manifest 完整源 7c1608c7e826f458eaae979d48727b0e6e2bdf58，原始记录 records.json。独立Chromium1280×720全新context，正常首页入院→暂停→回门口→确认触发非照片保存。

受控故障只在JS transport回执交付层：启动时包装安装的YoujiaSaveHost，调用真实host.submit，真实成功回执抵达后仅一次改为save-error CONTROLLED_RECEIPT_LOSS送给GDScript。未修改payload、业务内存、存档记录，不主动abort，也不代造confirmed。IDB put通过原方法，另挂只读success/transaction complete监听；实际complete时间1791198504786先于被丢回执1791198505107，真实回执本身也是confirmed/complete/readback_verified。属于可重复的丢回执实验，不冒自然用户随机故障。

unknown.png实际显示“保存暂时无法继续 / 请先留在这里，再确认一次”。随后真实点击一次(640,172)的“再确认一次”，真实resolve回执为confirmed/complete/readback_verified（1791198511034），current完整封套与点击前相等，generation2未重复提交；恢复后的ack允许intent清理，所以整records不要求不变。

after-one-confirm.png已经实际查看，等待6秒后错误提示仍在，按钮仍可见；基线复现成功。保存已可靠确认与UI仍显示错误不一致。两张图均实际查看，pageerrors=[]，驱动退出0。未改仓库或候选，未证明其他领域错误/结果未知场景。

可复用run.py：将out、URL与首build断言改为候选地址，保留同一真实提交/transport故障/一次按钮流程。不要替换原基线文件来冒称候选执行。
