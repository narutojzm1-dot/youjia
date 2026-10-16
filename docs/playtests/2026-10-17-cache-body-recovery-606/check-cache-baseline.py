import pathlib,subprocess,json
r=pathlib.Path(__file__).parent/'cache-baseline';r.mkdir(exist_ok=True)
repo='C:/Users/Zengm/.codex/worktrees/ui-audio-704/youjia'
for p in ['web/boot/download_assets.mjs','web/boot/sha256_stream.mjs']:
 f=r/p;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(subprocess.check_output(['git','-C',repo,'show','8c09e77e68f29a7c49f3564b44fc33eee54e41e1:'+p],timeout=15))
(r/'test').mkdir(exist_ok=True)
(r/'test/cache_body_recovery_test.mjs').write_bytes((r.parent/'cache-recovery/test/cache_body_recovery_test.mjs').read_bytes())
(r/'run.mjs').write_text("await Promise.race([import('./test/cache_body_recovery_test.mjs'),new Promise((_,no)=>setTimeout(()=>no(new Error('BASELINE_CACHE_BODY_STALLED')),250))]);",encoding='utf-8')
p=subprocess.run(['C:/Program Files/nodejs/node.exe',str(r/'run.mjs')],cwd=r,capture_output=True,timeout=10)
(r/'baseline.log').write_bytes(p.stdout+p.stderr);assert p.returncode!=0 and b'BASELINE_CACHE_BODY_STALLED' in p.stderr
print(json.dumps({'baseline':'8c09e77e68f29a7c49f3564b44fc33eee54e41e1','first_cache_body_case_stalled':True,'negative_exit':p.returncode}))
