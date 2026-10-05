# PR357 保存提示公开修复验证

首入及真正关页重开均严格断言实际 HTML `game-33b105f` 与 no-store manifest 完整来源 `33b105f075a1b851450f647c623302070ffafe1f`。不是旧7c1608c基线，也不是本地候选。公开源PCK与模块核验由Leader另行完成。

同旧基线run.py的故障方式：正常首页入院、暂停、回门口确认，真实非照片保存。包装JS transport调用真实host.submit，监听真实current put及transaction complete；只把第一次已armed的真实成功回执交付改成save-error CONTROLLED_RECEIPT_LOSS。不改payload、业务内存、存档值、不主动abort，不伪造成功回执。

- 真实transaction complete时间1791199422682；真实confirmed回执到达后受控丢失时间1791199422684。先完成事务，再丢传输回执。
- unknown.png实际显示“保存暂时无法继续/再确认一次”。
- 仅实际点一次(640,172)“再确认一次”。真实resolve返回confirmed/complete/readback_verified；current完整封套与点击前一致，generation2不重复提交，intent已清。
- after-one-confirm.png：提示消失，正常暂停面板与“继续待着”恢复。已亲看原图；和基线旧公开仍有错误纸片形成明确差异。
- 点击继续待着→正常院子（continued.png）；再暂停/返回首页确认→实际标题（title-return.png）；真正page.close，同context新页面→正常入院（reopened.png）。关键五图均实际查看。首页/重开完整source一致，记录在records.json与summary.json。

独立全新Chromium1280×720、headless+SwiftShader，驱动退出0，pageerrors=[]。没有网络失败重试或被排除的本轮失败；只读IDB检查。不称自然用户随机故障、实体手机/Safari/物理断电或全业务矩阵验收。未采集console事件，不声称console全零。源码与远端分支均未修改，未触发重复部署。
