# PR322 公开探索首片真实浏览器验收

source 81d225c15962a32d7a48a066154859488a155aa4，入口HTML game-81d225c与实际manifest在启动时核对。未触发部署，PCK/模块源验证由Leader另行完成。首次页面画卷是PR322过渡占位；本次运行中PR342原画版同期合入部署，后续重开未逐页锁定版本，限制见文末，不称美术终验。

Chromium+SwiftShader，1280×720及390×844，两个独立全新context，普通鼠标/键盘操作。未注入坐标位置、种子、携物或业务状态；正常路口点击、方向键走动、E停下看看、实际带上/回院按钮。仅readonly IndexedDB current读取用于证据。driver.py与events.json是实际驱动和操作序列，JSON各帧保存完整已确认封套。

## 已完成

- 1280：正常标题→点击院左下石板路→门口停看（随机空手）→溪边停看（随机圆石）→带上→回院。05-basket：active carried圆石，但keepsakes空；06-return：实际“圆石收好了”、keepsakes圆石1、水位1、session=null。
- 07-reopened：真正page.close→同context新页→入院；圆石仍1，无重复授予。
- 390：独立context，正常标题→院左下路口→门口/溪边停看→点击“带上圆石”。13-mobile-carried：active携圆石，keepsakes空；在外出中真正page.close。14-mobile-interrupted-reopen：新页正常入院，session=null、水位1、圆石1，恢复成功。
- 390空手另趟：15-mobile-empty-out实际篮子空→回院→等待15秒。16-mobile-empty-back：session=null、水位2、圆石仍1，空手没有追加物品。

## 观察与边界

已实际查看路口/画卷、两尺寸停看/带上、回院与恢复截图。390按钮可见可操作，未见本次链路阻断；画卷近景留纸边为现有占位行为。此为桌面窄视口，不冒实际触屏硬件验证。方向键按住时间为headless环境操作，不宣称正常设备步速体验。

1280第二趟空手回院仅等5秒的08-empty-return读到pending_commit；导航已回院不等于写入完成。之后关闭该context，故不把08当该趟持久成功证据；390空手完整确认由16单列补齐。随机只遇到/带回圆石，不称本次已验三物件、容量上限、换物、全部停留点或旧档迁移。未做配额/强制失败注入。带回物仍仅存档记录，无院内展示，后者属后续范围。

最终17-mobile-final-reopen再一次真实关页重开：圆石仍1、水位2、session=null，未重复授予；最终截图已查看。驱动退出0，pageerrors=[]（未额外采集console事件，不把它冒称console全零）。

版本取证限制补充：只在首次页面断言game-81d225c并记录manifest。后续重开未逐页记录HTML/source，若此间公开index更新，无法仅由现有记录排除跨构建；恢复JSON事实仍成立，但不宣称每页都已单独核为81。
