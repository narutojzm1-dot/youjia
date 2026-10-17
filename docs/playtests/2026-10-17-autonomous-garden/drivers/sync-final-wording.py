from pathlib import Path
import hashlib,json,shutil
out=Path(__file__).parent
for p in (out/'docs-final').rglob('*.md'):
 s=p.read_text(encoding='utf8')
 s=s.replace('390×844/844×390为桌面模拟、开花为受控第4天，不称真实等待三天/实体手机。','390×844/844×390为桌面模拟；晴阴/冻结照片为受控第4天，另从实际播种结尾自然运行1471.816秒跨过三个日界到第4天见开花、凭据不变。未称三整天墙钟或实体手机验收。')
 s=s.replace('第4天开花采用受控档，非实际等三天；','晴阴/冻结照片的第4天画面采用受控档；自然跨日补验另列下段；')
 rel='../playtests' if '/design/' in p.as_posix() else 'playtests'
 s=s.replace('全部成败与边界见园艺首片证据。','全部成败与边界见[园艺首片证据]('+rel+'/2026-10-17-autonomous-garden/README.md)。')
 p.write_text(s,encoding='utf8',newline='\n')
for name in ['preserve-final.py','sync-final-wording.py']:
 shutil.copyfile(out/name,out/'evidence-ready/drivers'/name)
dest=out/'evidence-ready';items=[]
for p in dest.rglob('*'):
 if p.is_file() and p.name!='manifest.json':items.append({'path':p.relative_to(dest).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(dest/'manifest.json').write_text(json.dumps(items,indent=2)+'\n',encoding='utf8')
print('Updated final wording',len(items),'files')
