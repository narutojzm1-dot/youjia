# #149 实际提交中关页恢复：公开构建

正式成功运行实际 manifest/source 为55cb7cebcf8b61f8e524f38121c997b6bba8553c，进入页与重开页 data-build 均 game-55cb7ce。此为包含PR336的后续文档发布，不能标成d242509浏览器运行。records.json保存启动manifest、两次build及原始数据库记录。

全新独立Chromium1280×720 context；自然入院、鼠标抚羊得到已确认照片A；readonly数据库A current generation2、album包含sheep_pet_gentle。随后实际暂停→回门口→确认触发院子保存B。仅测试层在IDBObjectStore.put已经真实调用之后，对records/current的同一readwrite事务连续发get请求保活，让它尚未complete；不注入世界/照片/存档值、不主动abort、不改生产源码。

真正page.close前两次观测都记录到真实current put发出且success、candidate generation3、同事务读取到prepared intent及parent generation2；最后观测loops40、complete=false、aborted=false。这个点不是“写已完成再关页”：request success明确不等于transaction complete。同context新建页面后启动恢复，current整个封套严格等于A原封套（generation2、payload及哈希身份完整相等），未提交B没有部分混入，intent不残留，archive保留。照片在重开手账中可见，截图已实际查看；pageerrors=[]。新profile无旧来源seal，前后均无seal，不能据此额外声称覆盖有旧seal场景，旧源保全由独立迁移用例证明。

inflight.png实际查看：关页前仍是原世界/返回确认界面；reopened-A.png实际查看：羊照片/原题词保留。这个实验是受控延长真实事务并真正关闭页面，不是物理断电/操作系统杀进程测试。

failed-ui-probe.json属于此前失败坐标探针：已创建A但点错暂停菜单音量按钮，未发生held事务，等待超时；不计入成功验收。成功run.py已按实际UI改为回门口278、确认383，run.log退出0。
