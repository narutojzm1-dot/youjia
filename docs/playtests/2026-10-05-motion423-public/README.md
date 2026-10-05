# PR423 正式公开有限烟测

2026-10-05，review304。两页开始/结束完整manifest均为8a5bc48526328dd956f935020e955ccc1e1bec0b，HTML game-8a5bc48；每页实际下载PCK并核SHA256 675b87d62dcf84b6795f660e5e13fdda3b22326af3eed3e9e04a3f2168b4e28c。不是本地候选f965包。驱动exit0，errors=[]。

普通1280×720 Chromium fresh profile，以浏览器真实媒体仿真初始reduce进入院子；两张原始云区图间隔2秒，固定[550,0,1050,180]最大通道差1，>5级变化0像素（sky-pixels.json），支持初始静止呈现。自然羊互动首次照片实际入册（album-before.png），真实关闭页面/newpage后同照仍在（album-reopened.png，已实际看图）。仅视觉同照，没有读取全DB，不声称全库字节相同。

同一重开页合上相册后，真实媒体no-preference→reduce→no-preference，matches依次false/true/false；normal-no-replay.png显示院子没有旧照片重播。输入/截图/媒体时间均见result.json。不是在途显影逐帧验证；候选细粒度证据单列，不拿本烟测代替。

浏览器媒体仿真并非操作系统实体设置、物理手机或触摸测试；不涵盖全部热点、声音、全部游戏或短横屏PR422适屏。未修改生产/业务状态/TuningStore/随机数/时间。仅5张原PNG，未加工。

## 独立发布档案

原始公开QA由review304执行，review301归档；除README追加本段，其余复制原件hash见original-copy-verification.json，五张PNG硬链接原字节，无修图。

| 阶段 | 精确SHA/包 |
| --- | --- |
| 本地候选runtime | 4886addaa9f091d55f8f5e5fd63908e4aa7b0f30；PCK f965ac3846bd97436d972cd04ea3a8c03663e92eabec92098d1d714d94b93666 |
| PR423独立终审head | 621b71f5f84a9051d514976e7b711ad88c927c88；原件pr423-independent-review.md |
| 正式合入/本次公开体验 | 8a5bc48526328dd956f935020e955ccc1e1bec0b；PCK 27,083,500字节，675b87d62dcf84b6795f660e5e13fdda3b22326af3eed3e9e04a3f2168b4e28c |

[Actions37342649620](https://github.com/narutojzm1-dot/youjia/actions/runs/37342649620)与[Pages37343292823](https://github.com/narutojzm1-dot/youjia/actions/runs/37343292823)实际success，API原件actions.json/pages.json包含完整source与gh-pages提交。Leader实际下载核包/十模块/public-raw-source一致见pr423-public-release.json及原log，verify-production-save-public.py为原驱动。

早deployment-pending原log保留当时公开旧manifest与raw新manifest不一致的失败；那次不算通过，后续16:47:42Z成功原件独立记录，不能把调度或暂态当发布完成。

[候选细粒度证据](../2026-10-05-web-reduced-motion/README.md)含photo在途单帧、18组件与21生命周期各自边界；本正式有限烟测不补写未做的在途矩阵/全DB比较/实体OS/真机/听验/PR422。同照只基于原图视觉；media转换不重播只覆盖本次普通输入。
