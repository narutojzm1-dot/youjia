# #827 旧照片写端隔离

Owner：CODEX-LEAD。`run.cjs` 运行真实 Chrome 的 IndexedDB/Web Locks，使用新的 loopback origin 和自己创建的临时 profile；不访问用户浏览器档案，不以 IndexedDB mock 代替存储升级。需要 Node 和 Playwright（CI 固定 playwright-core 1.62.1）。

```powershell
$env:PLAYWRIGHT_MODULE = '已安装的 playwright 或 playwright-core 绝对路径'
$env:CHROME_PATH = 'Chrome 可执行文件绝对路径'
node test/photo_writer_epoch/run.cjs '测试证据输出绝对路径'
```

`old-70de87a` 是实际历史发布的三个原始存储模块；旧 `store.mjs` SHA256 为 `2193b4397b8662a8ebc754dc4468e4d62964d209b4e1d0f0924a2ec81b409cbe`，驱动开工即校验。`new-photo.json` 来自真实 afcf634 PCK 的 World + PhotoMoment.capture 隔离夹具，包含灶台 atlas；`old-clean-result.json` 来自真实 70de87a PCK 的 SaveDataCodec.clean_moments，原来一条照片清洗后变零条。不是普通游玩触发摄影的证据。

测试先证明旧模块实际接受被旧包清洗掉照片的回写，再验证新模块升级库时记录逐字节不变、旧活连接关闭、旧重开 VersionError、新保存及真实 Chrome 进程关闭重开、prepared/committed intent、封存导入及原 /userfs、阻塞后的延迟升级撤销、缺 records 的损坏库和未来版本保护。测试中的裸库写入只用于建立明确协议夹具，不当作普通游戏链。`CURRENT_STORE_DIR` 可指定旧模块目录复现修前失败；运行失败返回非零。

数据库名称、记录/envelope/payload格式保持。DB version2 是网页写入能力门槛；旧网页遇到拒绝不能继续写，不强刷已在玩的页面、不清档。保护从新 Host 成功打开该库开始生效；新客户端尚未到访前，未升级的旧库不具备此门槛。此修复不声称远程改变旧原生可执行文件的本地存档行为，也不声称所有未来新增业务格式永久兼容。
