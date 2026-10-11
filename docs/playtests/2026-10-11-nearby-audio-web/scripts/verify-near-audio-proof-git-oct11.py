from pathlib import Path
import subprocess,json,hashlib
W=Path(r'D:\games\youjia-test\assistant');R=Path(r'D:\games\youjia-test\assistant-recovery')
D='docs/playtests/2026-10-11-nearby-audio-web'
rows=json.loads((W/D/'evidence-index.json').read_text(encoding='utf-8'));bad=[]
for row in rows:
 original=(R/row['source']).read_bytes()
 blob=subprocess.check_output(['git','show','HEAD:'+D+'/'+row['path']],cwd=W)
 if blob!=original or len(blob)!=row['bytes'] or hashlib.sha256(blob).hexdigest()!=row['sha256']:bad.append(row['path'])
result={'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=W).decode().strip(),'rawFiles':len(rows),'rawBytes':sum(x['bytes'] for x in rows),'mismatches':bad,'checks':'Actual committed Git blob bytes against original local source bytes, index byte counts and SHA256; not merely working-tree equality.'}
(R/'near-audio-proof-git-verification-oct11.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result));assert not bad
