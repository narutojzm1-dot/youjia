from pathlib import Path
import json, hashlib
root = Path(r'C:/Users/jiangzengming/.codex/worktrees/growth-garden-700/youjia')
entry = '''\n## 2026-10-17 CODEX-LEAD 自主园艺首片在研（#700）

用户本轮要求继续成长实现。分支 `codex/lead-garden-700`，基线 `fbc20456149bf9dfb8e66c3645d5537af77c07d3`；接续坡地花种发现→原返程入篓→同一次50/50可执行材料选择→实体背篓取种→院内固定小花畦播种→园艺经验与世界结果同笔确认。独立花畦账本不转换原三组花草、旧池岸或近郊农田；共用三餐AP/FIFO，unknown不另发替代请求。生产scope3阻止旧成长读端漏算园艺开销，Web writer4保护新发现与新图集照片，原envelope/payload不迁移重写。

单畦位置、1份花种/1AP/1XP/12秒、三天后开花和坡地掉落权重1均为制作调参，不说成用户逐项规定。当前已实现并进入实际Web/旧档验证；尚未公开，不称#700全完成。完整经验树、自由花草布置、榛子、新灶台菜谱与实体手机整链仍未完成。原单认领见 [#700](https://github.com/narutojzm1-dot/youjia/issues/700#issuecomment-6235144994)。

'''
for name in ['docs/game-design.md','docs/requirements.md','docs/decisions.md','docs/design/growth-phase-2026-10-10.md']:
    p=root/name;s=p.read_text(encoding='utf8');first,rest=s.split('\n',1);p.write_text(first+'\n'+entry+rest,encoding='utf8',newline='\n')
p=root/'config/release_notes.json';d=json.loads(p.read_text(encoding='utf8'));d['releases'][0]['build']='15fc174'
d['releases'].insert(0,{'date':'2026-10-17','build':'current','title':'从花种开始的小花畦','features':['近郊坡地可以遇到花种，带回院里后收进大背篓。','吃过饭歇一会儿，旅人会取花种播进院内小花畦，留下园艺经验；幼苗过几天开花。'],'fixes':['种花与磨粉、搭灶台共用行动点，取材途中可随时接管；完成保存后才扣料和显示花畦。','保护新花种、种花进度与含花畦的照片，防止旧网页写回覆盖。'],'note':'本次先开放一小畦花；原有花草、灶台、库存和照片保留，完整经验树与自由插花仍在制作中。'})
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
art=root/'assets/holiday/props/garden_v1/flower-garden-atlas-v1.png'
(art.parent/'source.json').write_text(json.dumps({'owner':'CODEX-LEAD','date':'2026-10-17','tool':'image_gen (built-in)','file':art.name,'sha256':hashlib.sha256(art.read_bytes()).hexdigest(),'width':2172,'height':724,'cells':3,'transparent':True},indent=2)+'\n',encoding='utf8')
print('Prepared scope, release note and asset provenance')
