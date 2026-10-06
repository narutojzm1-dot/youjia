# PR422 短横屏照片布局组合候选

Agent-ID: CODEX-LEAD（内部实施子代理 host_budget_impl）；原布局作者 GROK-CONTRIBUTOR。

保留作者 `813c2d467134489635ec98c99f7046d3a5d8cdb7` 祖先，与已合入系统低动效 `8a5bc48526328dd956f935020e955ccc1e1bec0b` 顺序集成。运行/测试版本 `e54171822c67e602944e015daf3690085c1a1587`。本档为候选，不宣称审核、合入或公开发布。

## 实际验证

Godot 4.7.2 原作者几何专项418、真实Tween/Caption组合656、带实际原生渲染组合662均退出0。原始日志和exit文件随档。组合使用真实Tween暂停与custom_step检查：淡入0.08秒后缩到320×300并切低动效，静态保留至原剩余1.50秒截止；期间恢复normal并旋转不补播、不延长、完成信号一次，照片字典不变。不是自然玩家触发或墙钟浏览器证明。

所有ExpressionCatalog实际题词变体，中英文、假期第10000天、320×300/568×320/390×844均检查真实Label行高与全部行可见。native六张原PNG逐张查看；英文会换行但仍在相纸内部。生产没有普通英文切换入口，英文为受控原生覆盖；真实Web另行验证。支持常见≥320×300；低于该支持下限的极小窗口布局不承诺。

## 保留失败探针

- internal-margin-probe：最初测试擅加“题词内部底边必须8px”，英文实际Label66px高，底293/300，导致自设292.5阈值失败；作者8px是相纸到屏边要求。照片/文字未越界，未为这个额外条件缩小字号。最终改验真实纸边和全部行可见。
- clock-probe：SceneTreeTimer墙钟等待不能精确控制headless Tween当前帧，旧断言失败；改为真实Tween pause/custom_step跨截止测试。此为测试方法修正，不伪称修复了额外运行bug。

环境临时 `docs/.gdignore` 防止无运行依赖的历史文档图片重新导入占用有限磁盘，未提交；生产export原本排除docs。五个历史资源.import自动变动不属于本变更。未改Main、Host、存档、相册、资源或输入。

完整strict daily在该runtime实际67次Godot启动、exit0；生产Web导出exit0，原始日志随档。PCK为27084908字节，SHA256 `566f40b4987914805a05879cae8d94e9604314694986f027d9b51fb40e828e8e`。新目录photo422-export、8197不覆盖423候选8195；新WASM完整导出后cmp与8195同字节，才以硬链接替换新副本以省空间，未写旧inode。export-files.json采集时HTML为原始data-build=index，后续本地QA stamp另列；不是正式发布。普通浏览器独立证据待后续归档。

## 普通 Web 与后续主线组合分界

独立review304在原e541包的两个fresh profile普通自然羊照过程中做DPR2/3转屏与媒体reduce，照片适屏、正常收起、相册同照可读；原始动作/原图/来源/失败检测样本完整保存在[web-e541](web-e541/README.md)。实施者也查看两张有效转屏原图。不是从小视口初始触发，不是每帧alpha/精确截止、物理真机或DB字节证明。前置误检通知/按钮与未捕到卡片两次样本明确排除。

随后main `1f9e340b38f94eb104f78f1978133653901e3a15` 顺序合入得到 `9f4e2121d6168b6bf020266d7cdb3872393fe4f8`。最初“最新main仅docs”的预判已纠正：其还包含Cloud PR418 merge `3e9ff94481e26285cb8616771cf955acdac52362` 的near_path_layout/near_path_scroll回院点击与相关suite。未改Cloud实现，原作者与所有主线祖先保留。

该组合运行photo fit/combo/motion、exploration slice/core、coordinator/native host/save feedback八专项与JS偏好/loading shell，实际exit0；原始driver/log/exit随档。e541完整67次daily与其Web照片证据仍只代表原runtime，不冒9f4全量覆盖。正式最终CI仍需full。

合入主线后空间不足使local-stamp目录首次创建失败，未改代码规避、未启动测试；根释放已结束导出缓存后继续。原export-files.json保持原始未stamp时点；[local-stamp](local-stamp/provenance.json)另存root本地手工stamp后的HTML/manifest哈希、脚本与来源回执，两时点均非正式发布。8197原包未被新组合覆盖。

9f4组合独立导出在photo422-combined-export/8198，exit0。PCK27085260字节，SHA256 `049e6eb4ce22d5d811f932fb219a581195274c4408b857ce351e9a23655ce6aa`；combined-export-files.json为新导出原始index时点。引擎WASM重新导出后逐字节核同才硬链既有相同引擎文件，不写旧包。该组合普通Web后验另记，不能直接套用e541普通QA。

## 最终新组合普通 Web 后验（有限范围）

[combined-web 原件](combined-web/README.md)来自独立review304的9f4、8198单fresh1280×720/DPR2。完整manifest/HTML与实际PCK049e6绑定，errors=[]/exit0。普通自然羊照入册，转568×320后相册原羊照可见；但本次转屏截图已经错过相纸显影，**不算新组合在途适屏重新捕获**。此前e541相同PhotoArrival代码的两视口在途有效证据保持单列。

随后空篮正常出门仍在近郊、沿路走开、鼠标点院门真实回院。没有触屏、三物携回、回院后再次翻册、DB字节保全或全探索矩阵覆盖。完整驱动/输入/结果/来源hash与全部原PNG通过硬链接归档，不复制引擎包、不修改原件。[combined-stamp](combined-stamp/provenance.json)独立保root后stamp来源；index.pck/js/wasm重新核与原导出清单完全同字节。

当前实施/候选验证已完成，待最终SHA独立审查；没有公开发布结论。
