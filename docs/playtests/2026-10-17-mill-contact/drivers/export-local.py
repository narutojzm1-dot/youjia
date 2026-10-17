import pathlib,json,shutil,subprocess,os,hashlib,sys,datetime
R=pathlib.Path(__file__).parent;S=R/'source';E=R/'export-profile';E.mkdir(exist_ok=True)
T=E/'Godot/export_templates/4.7.2.stable';T.mkdir(parents=True,exist_ok=True)
shutil.copy2('C:/Users/Zengm/AppData/Local/Temp/youjia-local-tools/web-templates/web_nothreads_release.zip',T/'web_nothreads_release.zip')
source=sys.argv[1]
for f in json.loads((R/'source-manifest.json').read_text()):assert hashlib.sha256(pathlib.Path(f['local']).read_bytes()).hexdigest()==f['sha256'],f['path']
identity=S/'config/build_identity.json';original=identity.read_bytes()
(R/'web').mkdir(exist_ok=True)
env=os.environ.copy();env['APPDATA']=str(E);env['YOUJIA_TEST_ISOLATED_DATA']=str(E)
try:
 identity.write_bytes((json.dumps({'sourceCommit':source,'builtAt':datetime.datetime.now(datetime.timezone.utc).isoformat()})+'\n').encode())
 with (R/'export.log').open('wb') as log:
  p=subprocess.run(['C:/Users/Zengm/AppData/Local/Temp/youjia-local-tools/godot/Godot_v4.7.2-stable_win64_console.exe','--headless','--path',str(S),'--export-release','Web',str(R/'web/index.html')],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
 assert p.returncode==0,p.returncode
 with (R/'wasm-repair.log').open('wb') as log:subprocess.run([sys.executable,str(S/'tools/repair_web_index_buffer.py'),str(R/'web/index.wasm')],stdout=log,stderr=subprocess.STDOUT,check=True)
 for folder in ['save','boot']:shutil.copytree(S/'web'/folder,R/'web/web'/folder,dirs_exist_ok=True)
 result={'source':source,'export_exit':p.returncode,'pck_bytes':(R/'web/index.pck').stat().st_size,'pck_sha256':hashlib.sha256((R/'web/index.pck').read_bytes()).hexdigest(),'official_templates':'4.7.2.stable','local_only_gdignore':['docs/.gdignore','art/.gdignore']}
 (R/'export-result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result))
finally:
 identity.write_bytes(original)
