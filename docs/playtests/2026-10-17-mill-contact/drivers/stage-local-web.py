import pathlib,shutil,sys,hashlib,json,datetime
R=pathlib.Path(__file__).parent;S=R/'source';dist=R/'web';source=sys.argv[1];work=R/('web-versioned-'+source[:7]);work.mkdir(exist_ok=True)
short=source[:7];entry='game-'+short
shutil.copy2(dist/'index.html',work/'index.html')
for ext in ['pck','icon.png','apple-touch-icon.png','png']:
 p=dist/('index.'+ext)
 if p.exists():shutil.copy2(p,work/(entry+'.'+ext))
for folder,prefix in [('save','save-'),('boot','boot-')]:shutil.copytree(S/'web'/folder,work/(prefix+short),dirs_exist_ok=True)
sys.path.insert(0,str(S/'tools'))
from stage_web_engine import stage
engine=stage(dist,work,entry)
p=work/'index.html';text=p.read_text(encoding='utf8').replace('./web/save/','./save-'+short+'/').replace('./web/boot/','./boot-'+short+'/')
text=text.replace('<html','<html data-build="'+entry+'"',1).replace('href="index.icon.png"','href="'+entry+'.icon.png"').replace('href="index.apple-touch-icon.png"','href="'+entry+'.apple-touch-icon.png"')
p.write_text(text,encoding='utf8')
manifest={'schema':'youjia.release/v1','sourceCommit':source,'entry':entry,'engine':'4.7.2.stable.official.ed1daf0bf','publishedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'engineAssets':engine}
for key,folder in [('storageModules','save-'+short),('loaderModules','boot-'+short)]:manifest[key]={'entry':folder,'sha256':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted((work/folder).glob('*.mjs'))}}
(work/'game-release.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
old=pathlib.Path('C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-0537/public-check/public')
shutil.copytree(old/'save-24c9dd3',work/'save-24c9dd3',dirs_exist_ok=True)
assert json.loads((old/'game-release.json').read_text())['storageModules']['sha256']==manifest['storageModules']['sha256']
(R/'local-versioned-layout.json').write_text(json.dumps({'source':source,'local_release_layout_only':True,'actual_stage_web_engine_used':True,'old24_modules_exact':True,'pck_sha256':hashlib.sha256((work/(entry+'.pck')).read_bytes()).hexdigest()},indent=2),encoding='utf8')
print('Local versioned export staged; all 10 storage modules exactly match prior public24 bytes.')
