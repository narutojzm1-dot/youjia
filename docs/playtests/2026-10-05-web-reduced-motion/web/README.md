# Web 系统低动效候选真实 UI QA

候选运行源码4886addaa9f091d55f8f5e5fd63908e4aa7b0f30；localhost8195，非公开发布。每个实际页面前后full manifest精确匹配，逐页实际PCK SHA256 f965ac3846bd97436d972cd04ea3a8c03663e92eabec92098d1d714d94b93666匹配，HTML game-4886add。全部输入为普通鼠标/键盘；Playwright reduced_motion emulation产生真实浏览器matchMedia事件，非实际OS设置/物理手机。无业务状态、TuningStore、随机种子、位置或时间注入。

## 有效观察

attempt1：fresh初始reduce/normal两profile自然羊照片均入册；reduce真关页再打开可看到原照片。无动物/无HUD云区[550,0,1050,180]两原帧间隔2秒：reduce最大通道差1、>5级差0像素；normal最大差10、>5级差363像素。原图实看构图一致，1级全局细微色差不当云移动。sky-pixels.json存指标。该差异支持游戏呈现实际响应初始媒体偏好，不单凭matches值推断。

photo-fast：普通首次羊互动自然生成照片，原始240×300浏览器clip真实捕获可见卡片；随后立即emulate_media reduce（348904.700372），下一原clip开始348904.703583仍见完整卡片；下一采样卡片已正常收起。之后恢复normal原全图未重播旧照片。此为可见照片期间实际媒体切换及正常结束观察；剩余可见采样仅一帧，**不能单独证明整个剩余时间无渐隐**，应与实现/独立生命周期回归共同评估。原clip是浏览器截图区域原件，无后处理修改。

## 保留且不冒通过的测量限制

attempt1卡边阈值过白，两次photo_detection=false；照片实际已入册，但这不算在途切换。photo-refined修正米白阈值抓到原自然照片，但全屏截图耗时使下一帧已截止，不独立证明在途效果。photo-fast以原clip降低测量开销，仅上述有限结论。

前三组 returned-title 原图实际仍为确认框（等待过短），后续 reentered-normal 原图实际是真标题，**文件名不是已返回并重复进院的证据**。另以title-cycle独立短链补真实标题/进院（须看对应实际图，不能沿用早期命名）。截图不证明监听注册数量；重复绑定/清理由root独立21项JS生命周期回归负责。missing/throw matchMedia由root独立测，本目录未重复。未测试音频/物理设备，未声称发布完成。

所有driver与result保留真实输入和截图时间；错误数组以各result为准。运行原图未修改，首轮失败/不足样本全部保留。

实看补验：title-cycle/actual-title.png 为真实标题，actual-reentered-yard.png 为真实院子；其后实际matchMedia true→false，错误为空。该普通回标题/再次进入链已补齐，但仍不以UI推断监听数量。

## #400 附带观察（不归因、不另起复测）

同一photo-refined普通profile：no-preference-sky-a.png入院图院景左纸边约x95；no-preference-photo-detected.png自然照片出现时左纸边约x213，no-preference-photo-after.png仍约x213；no-preference-photo-later.png又约x97。原始视口均1280×720。这是同候选普通输入链中实看可见的院景边界偏移，可关联已登记#400；不能据此猜测根因，也不把候选低动效改动当作已修#400。未修改镜头，未额外探索/复测此项。
