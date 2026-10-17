import pathlib,subprocess,os,json,sys
R=pathlib.Path(__file__).parent;S=R/'source';mode=sys.argv[1];data=R/'native-data'/mode;data.mkdir(parents=True,exist_ok=True)
for folder in ['docs','art']:(S/folder/'.gdignore').write_bytes(b'Local QA skips documentary images and isolated art candidates; not committed.\n')
env=os.environ.copy();env['APPDATA']=str(data);env['YOUJIA_TEST_ISOLATED_DATA']=str(data);env['YOUJIA_MILL_PHOTO']=str(R/'mill-photo.json')
capture=R/'native-capture';capture.mkdir(exist_ok=True);env['YOUJIA_DIRECTOR_CAPTURE']=str(capture)
exe='C:/Users/Zengm/AppData/Local/Temp/youjia-local-tools/godot/Godot_v4.7.2-stable_win64_console.exe'
args=['--headless','--editor','--path',str(S),'--quit'] if mode=='import' else (['--headless'] if mode!='gpu' else ['--position','-1800,-1200'])+['--path',str(S),'--script','res://test/'+('mill_pose' if mode=='gpu' else mode)+'_suite.gd']
name='import-runtime' if mode=='import' else 'native-'+mode
with (R/(name+'.log')).open('wb') as f:
 try:r=subprocess.run([exe,*args],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=210)
 except subprocess.TimeoutExpired:print(json.dumps({'mode':mode,'timeout':True}));raise
log=(R/(name+'.log')).read_text(encoding='utf8',errors='replace')
print(json.dumps({'mode':mode,'exit':r.returncode,'tail':log[-6500:]},ensure_ascii=False))
assert r.returncode==0 and 'Parse Error' not in log and 'Compile Error' not in log
