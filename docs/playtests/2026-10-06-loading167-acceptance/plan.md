# #167 同构建加载专项：执行前计划

身份：CODEX-LEAD 委派 QA 支援 `gate130_completion`。不冒 GAME-QA 本人或 Assistant 新实现；原 Owner 保留。原单协助回执 6005985387。只补 #167 原加载视觉/操作范围，不改任何运行代码或扩大永久门槛。

固定公开 source 49596fa93bff3c29edfe441898017158c6e469a3，entry game-49596fa，PCK 27,090,652 bytes / c851ac2b66ef6bba5211b7ba8488173c6b6a336ee7508d6150a5f5ccd488f930，storage entry save-49596fa。

一个 Chromium，单 renderer，六个 fresh context 串行，每次关闭后才下一次：1280×720 / 390×844 / 844×390 × no-preference / reduce。DPR1、浏览器 OS 媒体偏好，不注入 TuningStore；只读核 matchMedia。不是物理移动设备或稳定性能测量。

每 context：block ServiceWorker + Network.setCacheDisabled，启用路由也禁用 HTTP cache，记录实际 network response/cache flags。首次 engine JS 请求仅网络 hold 供初始加载原图，然后 abort 一次；等真实失败文案/按钮，普通 DOM click 重试使页面 reload。恢复首个真实 WASM 请求至少 hold4秒，并待两加载原图拍完后放行；记录实际耗时。first-frame 事件监听只记观察状态，不修改产品状态。到真实首帧与 loading.hidden 后拍标题；实施者查看标题后通过普通鼠标点入院、拍两帧。每次前后实取 manifest/HTML/PCK/10模块/许可并校验；实际页面加载的资源另记，PCK及模块 response body 校验。CDP编码字节不与UI解压MiB混称。

选择 engine JS abort 是因为341原件明确一次PCK abort曾被引擎自重试、未获得失败按钮；185已通过的PCK路径仍保留，此次不冒重验或否定它。受控失败的console/network error完整保留，恢复期错误另列。不伪造DOM失败、不触碰存档/随机/日序/游戏状态、不强制首帧。

只读DOM几何/CSS/伪元素动效用于核窄屏文字/按钮边界和reduce下无新增缩放闪烁，结论仍需看实际原图；不把静帧与CSS读数说成逐帧视觉完整证明。每case脚本若异常停止并保留原件，不无限重试。内存逼近上限时关闭当前context/browser并据实留未覆盖，不并行第二browser或Godot。

本计划不代表已执行，最终实际矩阵/返回码/截图/源绑定单独记录。root在整个窗口内延后465合入，避免主动换源。6case完成后全部关闭并归还browser窗口。
