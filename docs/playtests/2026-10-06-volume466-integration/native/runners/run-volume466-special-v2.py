import pathlib,subprocess,os,json,datetime,hashlib,sys
r=pathlib.Path('/dev/shm/youjia-volume466');out=pathlib.Path('/dev/shm/volume466-evidence');out.mkdir(exist_ok=True);runid='special-v2';target=out/runid;target.mkdir(exist_ok=False)
engine='/tmp/youjia-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64';now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat();sha=lambda b:hashlib.sha256(b).hexdigest();source=subprocess.check_output(['git','-C',str(r),'rev-parse','HEAD'],text=True).strip();rows=[]
(target/'source.json').write_text(json.dumps({'source':source,'tree':subprocess.check_output(['git','-C',str(r),'rev-parse','HEAD^{tree}'],text=True).strip(),'started':now(),'stage':'import and native controlled suites; no browser','runner_sha256':sha(pathlib.Path(__file__).read_bytes())},indent=2)+'\n')
patterns={k:v for k,v in (line.split('\t') for line in (r/'tools/lib/godot_suite_completions.tsv').read_text().splitlines() if line and not line.startswith('#'))}
for name,entry in [('import',None),('volume-input','test/volume_slider_input_suite.gd'),('volume-style','test/volume_slider_style_suite.gd'),('audio-button','test/audio_button_input_suite.gd'),('confirm-fit','test/confirm_panel_fit_suite.gd'),('pause-notice','test/pause_notice_suite.gd'),('focus-contrast','test/soft_button_focus_contrast_suite.gd'),('web-hidpi','test/web_hidpi_suite.gd')]:
 state=target/'profiles'/name;env=os.environ.copy();env.update({'XDG_DATA_HOME':str(state/'data'),'XDG_CONFIG_HOME':str(state/'config'),'XDG_CACHE_HOME':str(state/'cache'),'YOUJIA_TEST_ISOLATED_DATA':str(state/'data')});[pathlib.Path(env[x]).mkdir(parents=True,exist_ok=True)for x in ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME']]
 cmd=[engine,'--headless','--path',str(r)]+(['--editor','--import','--quit']if entry is None else ['--script','res://'+entry]);log=target/(name+'.log');row={'name':name,'command':cmd,'started':now(),'source':source};print('START',name,flush=True)
 with log.open('wb')as f:
  try:p=subprocess.run(cmd,env=env,cwd=r,stdout=f,stderr=subprocess.STDOUT,timeout=300);code=p.returncode
  except subprocess.TimeoutExpired:code=124
 row.update({'ended':now(),'direct_exit':code,'log':log.name,'log_bytes':log.stat().st_size,'log_sha256':sha(log.read_bytes())})
 errors=subprocess.run(['grep','-En',r'^(SCRIPT ERROR|ERROR:)|(^|[[:space:]])FAIL([[:space:]:]|$)',str(log)],capture_output=True,text=True);row['strict_error_scan_exit']=errors.returncode;row['strict_error_lines']=errors.stdout.splitlines()
 if entry:
  pat=patterns[entry];completion=subprocess.run(['grep','-Ex',pat,str(log)],capture_output=True,text=True);row.update({'completion_pattern':pat,'completion_exit':completion.returncode,'completion_lines':completion.stdout.splitlines()})
 ok=code==0 and errors.returncode==1 and (not entry or row['completion_exit']==0);row['verified']=ok;rows.append(row);(target/'process-results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n');print('END',name,'actual',code,'verified',ok, row.get('completion_lines',[])[:2],flush=True)
 if not ok:
  print('DIAGNOSTIC',log.read_text(errors='replace')[-9000:],flush=True);(target/'outer.exit').write_text('1\n');sys.exit(1)
(target/'outer.exit').write_text('0\n');print('ALL_SPECIAL_PASS',flush=True)
