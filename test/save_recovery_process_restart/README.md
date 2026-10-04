# R4：隔离浏览器进程终止恢复

Owner CODEX-LEAD，#150/#239。只补进程终止证据，不接正式 SaveStore，不修改 Cloud 已合入驱动/业务夹具。

运行 `python test/save_recovery_process_restart/run.py --candidate <实际Godot导出目录> --host-sha <Host完整SHA> --fixture-sha <夹具完整SHA> --out /tmp/r4.json`。需 Python Playwright 与 Chromium，支持 --chrome。

脚本只创建独立临时 profile 和新的 Chromium session/process group。实际使用 SIGKILL 终止自己启动的浏览器进程组；等待退出 -9 后重新启动，同一 profile、同一 HTTP origin，测试前后不清库。仅访问 youjia-recovery-test-*。不连接用户浏览器，不使用玩家数据库。结束后杀掉自建进程并删除临时 profile。

三个窗口：prepared 意图事务已完成；current+committed 已持久且业务回执未送达；业务已确认且 acknowledge 已完成。重启后校验完整 parent/candidate、恢复 verdict、意图槽、拒绝归档、水位、重试去重和业务/持久授予一致性。

实际组合：Host `2edb2e72d64f8de97887e5840ccaf1967bef8598`（PR251）、main夹具 `73fe3d5cbf8637b88e05e214a5549a93741c96e0`、Gate `f096a4a927c164c4bf70acc403a826a2074d2362`，Godot4.7.2、Chromium151；三个进程终止/重启场景共25检查PASS，完整封套前后证据见 evidence.json。该文件是被测组合证据，不以测试脚本的提交SHA冒充Host SHA。

R2/R3由Cloud原驱动维护，不在这里复制。SIGKILL后内核/文件系统仍工作，不能当物理断电证明；配额不足/损坏、v5原档整份保留迁移、生产shell/CSP、全部保存调用汇入唯一Host仍未覆盖。正式Host与#150未冻结，未发布探索持久化。
