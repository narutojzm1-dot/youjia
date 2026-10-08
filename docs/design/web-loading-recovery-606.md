# Web下载停滞与重复下载（#606）

Owner：CODEX-LEAD-ASSISTANT。用户2026-10-08反馈公开`game-070ae5a`稳定卡在下载约50%（44.0/86.8MiB，134秒）。[原单#606](https://github.com/narutojzm1-dot/youjia/issues/606)。本片只修加载/发布，不改变玩法或Host存档协议。

## 已核实的现象

全新无扩展Chrome154，公开源`070ae5a4f45f73105801cc029a1f86def87b6f6b`：WASM39,514,754字节约62秒完成；PCK51,489,076字节传到21,203,344后停滞超过70秒，170秒仍无引擎就绪/首帧，pageerror为空。停滞位置并非必然50%；现有加载器只累计两个文件的解压后字节。

用户截图的`Unchecked runtime.lastError: Could not establish connection. Receiving end does not exist.`属于浏览器扩展runtime接口错误；DOM有Grammarly注入，但不能据此判定具体扩展或加载因果。无扩展也发生传输停滞。依据：[Chrome runtime](https://developer.chrome.com/docs/extensions/reference/api/runtime#property-lastError)。

Pages实际Range探针返回206，`Content-Range: bytes 0-1048575/51489076`，1MiB准确、无content-encoding。旧发布脚本每次改动源码就给相同39.5MB引擎换game-SHA URL；本机候选的完整大PCK也未被普通HTTP缓存稳定保留。不能把CDN命中、HTTP200或进度变化当作资源已经下载完成。

## 修复与边界

- Godot启动期间只接管配置明确指定的WASM/PCK裸`fetch(URL)`；存档模块、其他请求和带选项请求直接走原fetch。成功/失败后恢复原fetch。仍由`Engine.startGame`启动，SaveHost模块安装顺序、runtime promise、`persistentPaths:[]`和首帧门禁保持。
- 请求头或响应体20秒没有数据，或者提前断流，最多重试3次。已输出解压后的字节从同一不可变URL用Range继续；200忽略Range时跳过重复前缀。校验206的开始/结尾/总长、无编码、ETag连续性和实际总字节；错误范围、换版本或超长立即失败，不能拼接出损坏PCK。
- 可选CacheStorage使用独立`youjia-startup-assets-v1`，只存完整启动资源，失败流不会入缓存。最多保留4个资源，保护当前构建的两项，旧项才剪除；缓存不可用/额度失败回落下载。它与`youjia-save-host-v1`的玩家存档独立，不删除或重置任何存档。
- 引擎JS/WASM及两个worklet共同按实际字节SHA256生成稳定`engine-…`地址；PCK保留`game-SHA.pck`，`mainPack`独立配置。构建标签仍显示game-SHA。引擎任一文件改动必须换地址；旧game/index别名及旧版本引擎地址保留。依据：[Godot executable/mainPack配置](https://docs.godotengine.org/en/stable/tutorials/platform/web/html5_shell_classref.html)。
- 下载模块使用`boot-SHA`版本目录并记录实际SHA256；原`save-SHA`存档模块保留版本隔离。源码/候选/正式公开版分别追踪。
- 启动JS/存档依赖模块60秒未就绪会明确报模块下载超时，迟到的模块不得再次启动已失败页面。已开始且持续传输的资源不按总时长判失败。

## 验证

Node测试已覆盖正常单请求、请求头/响应体停滞、提前EOF、断点字节、服务器忽略Range、错误范围/长度/编码、ETag变化、有限失败、取消与无关fetch隔离；缓存测试覆盖恢复后复用、拒存残缺流、上限及当前项保护、存储不可用回落。加载壳测试保持Host与首帧门禁并增加恢复失败和独立构建标签。

实际发布脚本对本地一次性bare remote连续发布三次：只改PCK/模块复用同一引擎URL，改worklet必须换；模块/引擎字节和SHA一致，旧链接保留。现有11项发布历史剪除测试通过。

第一次候选在公开服务器上读真实070ae5a资源，实际触发自动重试，约118.5秒完成首帧并进入小院；这是浏览器替换加载壳的候选验证，不是正式部署。新增完整缓存后继续做冷启动、重开存档和重复启动验证，最终结果写在PR及原始证据中。首次网络下载仍受约87MiB解压后资源和实际线路影响，不能承诺所有网络瞬间加载。

原始记录位于本机`D:\games\youjia-test\assistant-recovery\loading-*`；会归档完整脚本/JSON/截图与明确候选SHA，不提交大PCK。暂未执行物理手机和不同真实网络线路测试。

完整资源缓存候选的本地真实Web验证：PCK51,493,512字节，首请求发送1MiB后人为停滞，约20秒触发Range恢复，从1,048,576继续并正常首帧；重开与再次重开首帧分别1.849/1.755秒，后续均无PCK网络请求，正常点击进入小院并读取原Host当前记录确认背篓一致，pageerror为空。新一次公开线路探针在存档JS依赖下载阶段（0字节）停住，未进入资产下载，250秒超时；它没有验证缓存候选正式上线，失败/未覆盖事实会一并保留，故追加模块就绪超时与迟到启动防护。
