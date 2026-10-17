from pathlib import Path
import json,subprocess,datetime,gzip,hashlib,shutil
out=Path(__file__).parent
root=Path(r'C:/Users/jiangzengming/.codex/worktrees/growth-garden-700/youjia')
source='73c41fa714d4045d48d799c3dff7142dc43df595'
audit=json.loads((out/'public-files/audit.json').read_text())
web=json.loads((out/'web-public/result.json').read_text())
pack=json.loads((out/'public-pack.json').read_text())
workflow=json.loads((out/'publish-complete.json').read_text())
natural=json.loads((out/'web-natural-bloom/result.json').read_text())
assert natural['pass'] and natural['final']['holiday_day']==4 and natural['noTimeAdvanceOrFutureDateFixture']
assert audit['pass'] and audit['source']==source
assert web['pass'] and web['source']==source and web['actual_public_site']
assert pack['identity']['sourceCommit']==source and pack['all_photo_fields_retained']
assert workflow['publish']['conclusion']=='success' and workflow['pages']['conclusion']=='success'
dest=out/'evidence-ready'
for sub in ['web-public']:
 for p in (out/sub).glob('*'):
  if p.is_file():
   target=dest/sub/p.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target)
for name in ['audit.json','public-pack.json','publish-complete.json','fixture-public-old-photo.json','old-photo-public-fixture-source.json','validate-public-fixture.gd','prepare-public-driver.py','public-fixture-validation-r2.log','public-fixture-validation-r3.log','public-fixture-validation-diagnostic.log']:
 p=out/'public-files'/name if name=='audit.json' else out/name
 target=dest/'public'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target)
pck=next(f for f in audit['full_files'] if f['path'].endswith('.pck'))
pub=workflow['publish']['id'];pages=workflow['pages']['id']
summary=f'''## 最终合入与公共站点（实际完成补记）

最终头 `7d14b0d34005990cfd34bdd34dc570ccd8f74468` 的完整CI39044070181成功，Leader最终review5558562469后，PR840沿作者祖先合入运行源码 `{source}`。自动[Publish{pub}](https://github.com/narutojzm1-dot/youjia/actions/runs/{pub})与[Pages{pages}](https://github.com/narutojzm1-dot/youjia/actions/runs/{pages})成功；没有为日17节点重复dispatch。

实核时间 `{audit['recorded_utc']}`，实际公共站点与固定gh-pages `{audit['gh_pages_commit']}` 的 **{len(audit['full_files'])}份完整文件/{audit['complete_downloads']}次完整下载** 一致。双端完整PCK **{pck['bytes']:,}字节**，SHA256 `{pck['sha256']}`；实际隔离PCK身份、图集和公告标题另见 `public/public-pack.json`，文档归档头不当运行包。

`web-public/result.json`：直接HTTPS正式站点，无HTTP包替换/本地假宿主/直接游戏调用。从明确的第4天合法受控档起步（3AP、2花种、保留1麦种），附原15fc公开包实拍照片；不是个人旧profile或普通从零采种。真正先用冻结writer3建档，入场前升级到4后全部records/envelope/payload字节保持；普通键鼠14秒接管无扣料，重新闲置后 **{web['completedSeconds']}秒**确认播种，1种/1AP/1园艺经验，实际关闭Chrome进程且PID归零后 **{web['reopenMs']}毫秒**重开，花畦/库存/生产凭据与原照片保持；旧3重开VersionError且原件不变。

旧照片31项/全部键与数组保持；游戏JSON重存后两处原变换分量约7.04e-18格式舍入，比较明确使用1e-12数值绝对容差；DB升级前后raw rows仍是逐字节严格比较。最初要求照片深层浮点字面完全相等的夹具失败及原始差异保留于 `public`；没有以该容差放宽库存、AP、凭据或写端原件检查。390×844/844×390仍只是桌面模拟视口；完整源链的28项原生证明、受控第4天开花证据与真正公共播种证据各署身份，不相互换标。

本轮普通公开首帧{web['bootMs']}毫秒，页面异常0、无SCRIPT/WebGL错误；控制台仍有一条HTTP404，未记录到该条URL，原件保留，不推断单一根因或写成零404。22份核验文件包含当前manifest/HTML声明的19份和实际旧writer3的3份冻结模块，后者逐字核对原Git blob；不是声称服务端所有历史保留包均下载过。

[公共播种截图](web-public/04-planted.jpg) · [实际重开](web-public/05-reopened.jpg) · [公共连续录像](web-public/garden-continuous.webm)。候选阶段过目邮件已发送一次；公开阶段并入10月17日节点唯一日推。#700继续开放，等级门槛仍待用户决定，完整经验树/自由布置/榛子/新菜谱/实体手机未完成。

另以普通来源链实际结尾存档作为导入起点，在本地同一1ab实际PCK自然运行 **{natural['naturalWallClockSeconds']}秒**，没有在开始后改时钟/日期，跨过第2/3/4天后开花。每15秒观测、每次跨日截图及最终字段见 `web-natural-bloom/result.json` / `natural-bloom-day4.jpg`，原播种凭据不变。这里是从第1天晚间继续到第4天的三个日界，不声称三整天墙钟时长，也不把本地头改标公共头；晴阴受控第4天照片证据另存。
'''
readme=dest/'README.md'
text=readme.read_text(encoding='utf8')
text=text.split('\n## 后续普通Web完整材料来源链（1ab实际包）')[0]
text=text.replace('完整新CI39044070181仍需回原PR核实最终结论，不因本页归档宣称通过。','完整新CI39044070181最终成功；合入和公开补记如下。')
text+='''
## 后续普通Web完整材料来源链（1ab实际包）

`web-source-ui-r3`从明确的合法档但背篓无花种起步，普通键鼠/自然墙钟，未强制随机/写种子或直接调用游戏函数。前两趟从坡地带回落羽，第三趟实际随机取得花种，原rng_seed仅作为观测原件；正常返程1种入篓后，旅人闲置自动取种播种。最终1花种消耗、晚餐receipt记1AP/1园艺XP，使用午餐至多1点结余；2落羽与最后1麦种保持。source-ui-13/14/15分别为拾得/返程/种下；所有UI快照及完整结尾存档、额外严格断言和自有Chrome PID0见result/validation.json。前次r2两趟没拿到种子的尝试仍保留，不能把后来成功改成早期已通过。

这是本地实际1ab PCK的普通Web来源→返程→播种链，不是公共73c41fa包来源链或实体设备。没有页面/SCRIPT错误；本地测试服务器的一条HTTP404控制台原样保留，不声称零404。最终头7d14只改测试，生产代码相同，证据不换标。
'''
text=text.replace('# #700 自主园艺首片：候选与真实验证','# #700 自主园艺首片：公开交付与验证')
title,body=text.split('\n',1)
readme.write_text(title+'\n\n'+summary+'\n\n## 以下保留候选阶段与早期原件\n'+body,encoding='utf8',newline='\n')
changes=out/'docs-final';changes.mkdir(exist_ok=True)
current=f'''## 2026-10-17 / #700 自主园艺首片已公开（CODEX-LEAD）

PR840最终 `7d14b0d34005990cfd34bdd34dc570ccd8f74468` 通过完整CI39044070181和Leader最终审核，沿作者祖先合入 `{source}`。game-73c41fa已通过Publish{pub}/Pages{pages}、公共与固定{len(audit['full_files'])}份完整文件、双端PCK {pck['bytes']}B/SHA256 `{pck['sha256']}`、实际PCK公告/图集/身份及直接正式站点播种/真实关进程重开。后继文档头不当运行包，后续仍按实时站点核对。

坡地花种发现沿原返程FIFO入篓；餐后闲置与石头/小麦共用一次可执行材料选取，实体背篓取种→固定小花畦播种→花种/AP/园艺经验/世界结果同笔确认。生产scope3和Web writer4隔离旧读写端；旧库存、原三组花草、八格农田、池岸/磨粉/灶台与照片保留。1种/1AP/1XP/12秒、单畦位置、三天开花、坡地权重1均为制作调参。复用既有下蹲动作，不称全新专属播种姿势。

普通公共Web从明确的合法受控第4天档起步，{web['completedSeconds']}秒完成播种，实际关Chrome进程后{web['reopenMs']}毫秒重开保持；不是从零随机采种验收或个人旧档。另1ab本地实际包普通Web从无花种起步，第三趟随机取得花种→正常返程→自动播种，source-ui-r3全快照留原头；原生28项、真实Chrome写端69项、旧公开照片及当前包隔离探针各留原件，不改标。390×844/844×390为桌面模拟、开花为受控第4天，不称真实等待三天/实体手机。全部成败与边界见园艺首片证据。

#700继续开放：三种经验达到一级后统一显现是已决方向，但各一级门槛未定，已向用户提问；不自行给等级/奖励定数值。完整经验树、自由花草布置、榛子、新灶台菜谱与实体手机整链未完成。跨日余点、补觉、连续熬夜和#750未决保持。下方带日期旧章节为历史，不作为当前状态。

'''
for name in ['docs/game-design.md','docs/requirements.md','docs/decisions.md','docs/design/growth-phase-2026-10-10.md']:
 old=subprocess.check_output(['git','show',source+':'+name],cwd=root).decode('utf8')
 target=changes/name;target.parent.mkdir(parents=True,exist_ok=True)
 target.write_text(current+old,encoding='utf8',newline='\n')
daily=f'''# 2026-10-17 日版本

计划节点：北京时间2026-10-17 23:00，CODEX-LEAD主持。节点进行中已私有去重，最终CI及公开验证跨午夜后完成仍归10月17日；不补造准点完成。PR840合入触发的同一自动发布作为本节点，不重复dispatch。

## 实际公开版本

**game-73c41fa** / `{source}`。[正式游戏](https://narutojzm1-dot.github.io/youjia/)；完整CI[39044070181](https://github.com/narutojzm1-dot/youjia/actions/runs/39044070181)、[Publish{pub}](https://github.com/narutojzm1-dot/youjia/actions/runs/{pub})、[Pages{pages}](https://github.com/narutojzm1-dot/youjia/actions/runs/{pages})成功。源码PR840最终头7d14b0d34005990cfd34bdd34dc570ccd8f74468，Leader review5558562469；不是独立子代理审核。后继证据文档头不当运行包。

实核 `{audit['recorded_utc']}`；固定gh-pages `{audit['gh_pages_commit']}`。公共与固定共{len(audit['full_files'])}份完整文件/{audit['complete_downloads']}次完整下载一致，含实际HTML、manifest、引擎、版本化保存/加载模块和PCK。双端PCK **{pck['bytes']:,}字节**，SHA256 `{pck['sha256']}`；实际PCK内身份、公告、新花畦图集和照片字段另核。[完整成败证据](../playtests/2026-10-17-autonomous-garden/README.md)。

## 全天交付与集中审查

| 范围 | 交付与实际边界 |
|---|---|
| 加载可靠性 | PR831/834缓存读停有限网络恢复及逐资源诊断，既有旧档/真实关进程重开证据见PR832/833/835。#606仍由原Owner续查，不宣称所有挂起根因已定位 |
| 灶台三高度演出 | PR836/837，24c9dd3公开链：放石/压实/起身和照片写端3保护；三阶段136.308秒普通Web，明确合法受控起档。原23/24代PCK与旧档原件各保留身份 |
| 磨盘握柄演出 | PR838/839，15fc174公开链：双手握柄施力、旧照片兼容，公网83.283秒两次磨粉及真实重开。石盘本身不转动，不称新转盘资源完成 |
| 自主园艺首片 | PR840，本节点73c41fa：花种发现/返程入篓、实体背篓取种、自主单畦播种、共享AP/园艺XP/世界结果同笔确认；新透明原画晴阴/冻结照片，writer4保护与scope3兼容。1种/1AP/1XP/12秒、单畦/三天/权重1是制作调参 |
| 团队候选 | PR813音频仍Draft、#196实体听验缺口；PR804仍隔离溪流候选；PR747仍有13–15禁播门禁。当天没有新头/评论不重复审退，也不擅自合入 |

本片普通正式Web从明确合法第4天QA档起步：午餐3AP、2花种、保留1麦种，带原15fc实拍照片。入场前DB3→4原records/envelope/payload字节保持；14秒接管无消耗，{web['completedSeconds']}秒确认播种，实际关进程/PID归零后{web['reopenMs']}毫秒重开保持。旧3拒绝重开且记录不变。照片全部字段/31项保持，重存两处变换值有约7.04e-18的JSON舍入，严格结构+1e-12数值容差明确记录，不称照片字节完全不变；升级raw rows另为精确比较。

本轮普通首帧{web['bootMs']}毫秒；无页面/SCRIPT/WebGL错误，仍有一条未带URL的控制台HTTP404原件，不写成零404或归因已确认。文件核验包含当前声明19份及3份原writer3冻结模块；不是所有历史保留包的全量清理或下载。

28项原生正式发现→返程→实际FIFO落盘/重放/种花/重开、Chrome writer1/2/3→4的69项，以及完整CI各自保留身份。早期两趟普通随机散步没拿到花种仍留原件；后续本地实际1ab PCK的web-source-ui-r3从背篓无花种起步，前两趟带回落羽，第三趟随机拿到花种并返程入篓，随后正常闲置自动播种，1花种/1共享AP/1园艺XP（晚餐时段用午餐至多1点结余），没有写入种子/强制随机或调用游戏函数。这段属于本地实际包普通Web来源链，不改标本节点公共包来源全链。第4天开花采用受控档，非实际等三天；390×844/844×390只是桌面模拟，不冒充实体手机或人耳验证。

自然跨日补验：从上述实际种下的结尾存档导入自己的测试profile后，正常运行{natural['naturalWallClockSeconds']}秒、无开始后改时钟/日期，实际跨到第4天见开花，receipt保持。它覆盖三个日界，非三整天墙钟时长，署1ab本地实际包；受控晴阴/冻结照片与公共新包播种/重开各署原身份。

首轮CI39042305606旧三种可摆物断言失败已保留；最终只修专项范围为DECOR_FINDS且明确禁止花种摆放，44项及失败点之后50套通过，1ab候选运行代码与7d14逐字相同。导入缓存、英文窄格、错误夹具、stamp身份与照片数值比较等失败均留原件，没有放宽生产保护或把旧证据改标新SHA。

## 未完成与下一交付

| Owner | 未完成 / 解除条件与可继续部分 |
|---|---|
| CODEX-LEAD #700 | 完整三类经验树尚未实现，三类均到一级再显现已确认，一级阈值已向用户提问未获回复；不自行设等级。继续已授权且无冲突的成长/真实体验缺口；自由布置、榛子、转盘资源、新菜谱和实体手机仍未完成 |
| CODEX-LEAD / GAME-QA #196 | PR813 db5a88a6c126e3c3a1edf2147aaf5fa4b48f05ef仍Draft，批准源音01–12/16/17不重复索批，软件输出不替代人耳/耳机/外放/实体设备回执；13/14/15退回版本禁播 |
| GROK-BUILD #749 | PR804 33106846329d0917e46f4bbc9c239cd2701bd5f2工具专项21项结论保留，隔离完整矩阵/生产接线/实体性能/最终美术未完成；ASSISTANT近郊边界不变 |
| ASSISTANT / CURSOR-CLOUD / GAME-QA | 各按既有已接收近郊、UI、独立QA继续；未回执不写成已接住。Grok专门Leader最终SHA门禁保留，普通PR不恢复逐PR子代理审批 |

## 迁移与邮件

根D:/work/projects/youjia仍为旧本地迁移快照3f02f0b484，完整备份在D:/work/migration/youjia-migration-20261015，原六工作区/10份stash与忽略文件备份保留。旧迁移提交未推远端，不能只克隆远端当完整迁移；本轮源码与证据另在独立codex分支/PR推送保存，新设备GitHub CLI认证正常。未将历史快照批量合main。

候选阶段截图邮件已经发过一次；本节点公开新阶段并入唯一日推，待本页归档合入后发送，消息ID及去重只保存在私有状态；不公开邮箱或原始邮件。未回复不作美术或听验验收，不据此卡住正常开发。

原生Goal仍blocked/未完成，无resume API，不新建替代目标或伪称恢复；用户已恢复的同一两小时automation保持ACTIVE。
'''
target=changes/'docs/releases/2026-10-17.md';target.parent.mkdir(parents=True,exist_ok=True);target.write_text(daily,encoding='utf8',newline='\n')
manifest=[]
for p in dest.rglob('*'):
 if p.is_file() and p.name!='manifest.json':manifest.append({'path':p.relative_to(dest).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print('Public docs prepared',len(manifest),'evidence files')
