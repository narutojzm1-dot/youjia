from pathlib import Path
import subprocess,hashlib,shutil,json,os,datetime
r=Path('/tmp/youjia-photo461');e=Path('/tmp/photo461-evidence');out=Path('/tmp/photo461-web')
assert (e/'run.exit').read_text().strip()=='0' and (e/'outer.exit').read_text().strip()=='0'
actual=json.loads((e/'validation-result.json').read_text());assert actual['status']=='passed' and actual['specialized_checks']==1290 and actual['godot_daily_suites']==74
live=[]
for line in subprocess.check_output(['ps','-eo','pid,stat,comm,args'],text=True).splitlines()[1:]:
 p=line.split(None,3)
 if len(p)>=3 and not p[1].startswith('Z') and 'Godot' in p[2]:live.append(line)
assert not live,live
subprocess.run(['python','/tmp/photo461-package-preview.py'],check=True)
subprocess.run(['python','/tmp/photo461-clean-generated.py'],check=True)
cache=r/'.godot';assert cache.is_dir();assert subprocess.run(['git','-C',str(r),'check-ignore','-q','.godot']).returncode==0
cachebytes=sum(p.stat().st_size for p in cache.rglob('*') if p.is_file());shutil.rmtree(cache)
a=out/'index.wasm';b=Path('/tmp/soft455-web/index.wasm');ha=hashlib.file_digest(a.open('rb'),'sha256').hexdigest();hb=hashlib.file_digest(b.open('rb'),'sha256').hexdigest();sa=a.stat();sb=b.stat()
assert ha==hb and sa.st_size==sb.st_size and sa.st_dev==sb.st_dev and sa.st_mode==sb.st_mode
os.link(b,a.with_name('index.wasm.photo461-hardlink'));os.replace(a.with_name('index.wasm.photo461-hardlink'),a);assert a.stat().st_ino==b.stat().st_ino
record={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'no_live_godot':True,'removed_only_ignored_cache':str(cache),'cachebytes':cachebytes,'hardlink':{'target':str(a),'source':str(b),'bytes':sa.st_size,'sha256':ha,'mode':oct(sa.st_mode)},'total_logical_freed':cachebytes+sa.st_size,'note':'All source, PCK, images and logs retained. All linked wasm export directories frozen; never export into them again.'};(e/'engine-release-cleanup.json').write_text(json.dumps(record,indent=2)+'\n')
metadata=json.loads((e/'candidate-release.json').read_text());assert hashlib.file_digest((out/'index.pck').open('rb'),'sha256').hexdigest()==metadata['files']['index.pck']['sha256'];print(json.dumps({'window':'released','candidate':metadata,'cleanup':record},indent=2))
