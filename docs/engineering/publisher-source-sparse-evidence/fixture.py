"""Read-only production audit; only isolated file:// fixtures are mutated.
Uses exact frozen publisher/helper/modules. All engine version calls use a stub.
"""
from pathlib import Path
import subprocess,tempfile,shutil,json,os,hashlib,re,time,sys
HERE=Path(__file__).resolve().parent;SOURCE=Path(__file__).resolve().parents[3]
OUTPUT=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(tempfile.mkdtemp(prefix='publisher130-report-'))
OUTPUT.mkdir(parents=True,exist_ok=True)
REPORT={'source_commit':subprocess.check_output(['git','-C',str(SOURCE),'rev-parse','HEAD'],text=True).strip(),'audit_base_commit':'9623ba22c8edc564e5c89dc6b0171324e9230764','action_commit':'11d5960a326750d5838078e36cf38b85af677262','git_version':subprocess.check_output(['git','--version'],text=True).strip(),'engine_processes':0,'production_mutations':False,'modes':[]}
REPORT['input_file_sha256']={str(p.relative_to(SOURCE)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [SOURCE/'tools/publish_gh_pages.sh',SOURCE/'tools/select_web_bundle_pruning.py',SOURCE/'.github/workflows/publish-pages.yml',*sorted((SOURCE/'web/save').glob('*.mjs'))]}
COMMANDS=[]
def run(*args,cwd,check=True,env=None):
 t=time.monotonic();r=subprocess.run(args,cwd=cwd,env=env,text=True,capture_output=True)
 COMMANDS.append({'command':list(args),'returncode':r.returncode,'seconds':round(time.monotonic()-t,4)})
 if check and r.returncode:raise AssertionError((args,r.returncode,r.stdout,r.stderr))
 return r

def git(path,*args,**kw):return run('git',*args,cwd=path,**kw)
def out(path,*args):return git(path,*args).stdout.strip()
def identity(path):git(path,'config','user.name','Isolated Publisher Fixture');git(path,'config','user.email','fixture@example.invalid')
def write(root,path,data):
 p=root/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data.encode() if isinstance(data,str) else data)
def commit(path,title):git(path,'add','-A');git(path,'commit','-qm',title);return out(path,'rev-parse','HEAD')
def missing(path):return set(x[1:] for x in out(path,'rev-list','--objects','--all','--missing=print').splitlines() if x.startswith('?'))
def tracked_content(path,ref='HEAD'):
 return {n:out(path,'rev-parse',ref+':'+n) for n in out(path,'ls-tree','-r','--name-only',ref).splitlines()}
def real_helper(wt,source,current='game-c',keep=2):
 return run('python3',str(source/'tools/select_web_bundle_pruning.py'),current,str(keep),cwd=wt,check=False)
def cfg(path,key):
 r=git(path,'config','--get',key,check=False);return r.stdout.strip() if r.returncode==0 else None

def setup(root):
 remote=root/'remote.git';seed=root/'seed'
 git(root,'init','--bare',str(remote));git(remote,'config','uploadpack.allowFilter','true');git(remote,'config','uploadpack.allowAnySHA1InWant','true')
 git(root,'init','-b','main',str(seed));identity(seed);git(seed,'remote','add','origin',remote.as_uri())
 for name in ('publish_gh_pages.sh','select_web_bundle_pruning.py'):write(seed,'tools/'+name,(SOURCE/'tools'/name).read_bytes())
 for p in (SOURCE/'web/save').glob('*.mjs'):write(seed,'web/save/'+p.name,p.read_bytes())
 for name in ('game-sharing.json','game-verification.json','template-provenance.json','template.json'):write(seed,name,json.dumps({'fixture':name}))
 write(seed,'art/concepts/producer_world_20261005/near_path_anchors.candidate.json','{"anchor":"fixture"}')
 write(seed,'assets/example.bin',b'asset fixture\x00\xff');write(seed,'test/docs/fixture.json','{"nested":"retained"}')
 write(seed,'.github/workflows/publish-pages.yml',(SOURCE/'.github/workflows/publish-pages.yml').read_bytes())
 write(seed,'site/game-release.json','{"prior":"fixture"}');write(seed,'.gitignore','dist/\n')
 for n in range(3):
  write(seed,'docs/qa-evidence.bin',('unique source docs revision %d\n'%n)*70);write(seed,'source-version.txt',str(n));commit(seed,'source history '+str(n))
  if n==1:git(seed,'tag','fixture-tag')
 main=out(seed,'rev-parse','HEAD');main_files=tracked_content(seed)
 # Explicit known hashes for all three unique document revisions.
 doc_blobs={out(seed,'rev-parse',f'main~{i}:docs/qa-evidence.bin') for i in range(3)}
 git(seed,'checkout','-b','other-branch');write(seed,'docs/other-branch.bin','unique excluded branch archive');commit(seed,'other evidence');other_blob=out(seed,'rev-parse','HEAD:docs/other-branch.bin');git(seed,'checkout','main')
 git(seed,'push','origin','--all');git(seed,'push','origin','--tags')
 git(seed,'checkout','--orphan','gh-pages');git(seed,'rm','-rf','.')
 for name in ('ff','a','b'):
  for ext in ('pck','js','wasm'):write(seed,f'game-{name}.{ext}',f'{name}.{ext}')
  write(seed,'index.html','old root '+name);write(seed,'docs/pages-audit.txt','existing Pages archive '+name);commit(seed,'publish '+name)
 git(seed,'push','origin','gh-pages')
 return remote,seed,main,main_files,doc_blobs|{other_blob}

def mode(root,name,partial,sparse,shallow=False,allow_filter=True):
 root.mkdir();remote,seed,main,files,doc_blobs=setup(root)
 if not allow_filter:git(remote,'config','uploadpack.allowFilter','false')
 source=root/'source';git(root,'init',str(source));identity(source);git(source,'remote','add','origin',remote.as_uri())
 args=['-c','protocol.version=2','fetch','--prune','--no-recurse-submodules']
 if partial:args+=['--filter=blob:none']
 if shallow:args+=['--depth=1']
 args+=['origin','+refs/heads/*:refs/remotes/origin/*','+refs/tags/*:refs/tags/*']
 fetch=git(source,*args)
 if sparse:
  git(source,'config','core.sparseCheckout','true');write(source,'.git/info/sparse-checkout','\n/*\n!/docs/\n')
 git(source,'checkout','--force','-B','main','refs/remotes/origin/main');assert out(source,'rev-parse','HEAD')==main
 expected={p:s for p,s in files.items() if not sparse or not p.startswith('docs/')}
 actual={p for p in files if (source/p).is_file()};assert actual==set(expected)
 for p,s in expected.items():assert out(source,'hash-object',p)==s,p
 before=missing(source);source_docs_initially_missing=doc_blobs <= before
 if partial and sparse and allow_filter and not shallow:assert source_docs_initially_missing
 elif not shallow:assert not source_docs_initially_missing
 assert out(source,'rev-parse','--is-shallow-repository')==('true' if shallow else 'false')
 main_log=out(source,'rev-list','--count','main');assert main_log==('1' if shallow else '3')
 if not shallow:assert out(source,'rev-parse','fixture-tag')==out(seed,'rev-parse','fixture-tag')
 # Advance Pages after checkout: exercise the real publisher's subsequent unqualified fetch.
 write(seed,'docs/pages-later.txt','unique Pages documentation after first source fetch');write(seed,'pages-later.txt','retained latest Pages root')
 pages_tip=commit(seed,'Pages changes after source checkout');later_doc=out(seed,'rev-parse','HEAD:docs/pages-later.txt');git(seed,'push','origin','gh-pages')
 git(source,'fetch','origin','gh-pages:refs/remotes/origin/gh-pages')
 after_follow_fetch=missing(source)
 follow_filter=cfg(source,'remote.origin.partialclonefilter');promisor=cfg(source,'remote.origin.promisor')
 wt=root/'pages-analysis';git(source,'worktree','add',str(wt),'origin/gh-pages')
 assert out(wt,'rev-parse','HEAD')==pages_tip
 # All bundle files and root metadata must be materialized even if sparse is inherited.
 for p in ('index.html','pages-later.txt',*[f'game-{n}.{e}' for n in ('ff','a','b') for e in ('pck','js','wasm')]):assert (wt/p).is_file(),(name,p)
 sparse_file=Path(out(wt,'rev-parse','--git-path','info/sparse-checkout'))
 if not sparse_file.is_absolute():sparse_file=wt/sparse_file
 worktree={'core_sparseCheckout':cfg(wt,'core.sparseCheckout'),'extensions_worktreeConfig':cfg(wt,'extensions.worktreeConfig'),'sparse_patterns':sparse_file.read_text() if sparse_file.exists() else None,'docs_materialized':(wt/'docs/pages-audit.txt').exists(),'shallow':out(wt,'rev-parse','--is-shallow-repository'),'full_pages_tip_matches':True,'pages_first_parent_count':int(out(wt,'rev-list','--first-parent','--count','HEAD'))}
 write(wt,'game-c.pck','current staged fixture')
 known=real_helper(wt,source);assert known.returncode==0
 expected_prune=[] if shallow else ['game-a','game-ff'];assert known.stdout.splitlines()==expected_prune,(name,known.stdout,known.stderr)
 write(wt,'game-dead.pck','unknown unpublished fixture');unknown=real_helper(wt,source);assert unknown.returncode==0 and not unknown.stdout
 assert ('shallow bundle history' if shallow else 'incomplete bundle history') in unknown.stderr
 (wt/'game-dead.pck').unlink();(wt/'game-c.pck').unlink();absent=real_helper(wt,source);assert absent.returncode==1 and 'current staged PCK is missing' in absent.stderr
 write(wt,'game-c.pck','current staged fixture');disabled=real_helper(wt,source,keep=0);assert disabled.returncode==0 and not disabled.stdout
 negative=real_helper(wt,source,keep=-1);assert negative.returncode==1
 git(source,'worktree','remove','--force',str(wt))
 # Run exact production publisher twice against this file:// remote, synthetic four-file dist.
 stub=root/'version-stub';stub.write_text('#!/bin/sh\n[ "$1" = --version ] || exit 97\nprintf "fixture-version-only-no-engine\\n"\n');stub.chmod(0o755)
 write(source,'dist/index.html','''<html><head><meta charset="utf-8"></head><body><script>
const config = {"executable":"index","fileSizes":{"index.pck":3,"index.wasm":4}};
script.src = 'index.js'; import('./web/save/bridge.mjs'); import('./web/save/idbfs_source.mjs');
</script></body></html>''')
 for ext in ('js','wasm','pck'):write(source,'dist/index.'+ext,ext)
 env=dict(os.environ,GODOT=str(stub),KEEP_BUNDLES='2',TMPDIR=str(root))
 builds=[];old_modules=None
 for iteration in range(2):
  if iteration:
   with (source/'web/save/bridge.mjs').open('a') as f:f.write('\n// next fixture source build\n')
   git(source,'add','web/save/bridge.mjs');git(source,'commit','-qm','second source fixture')
  sha=out(source,'rev-parse','HEAD');assert out(source,'remote','get-url','origin')==remote.as_uri()
  published=run('bash','tools/publish_gh_pages.sh',sha[:12],cwd=source,env=env)
  (OUTPUT/(name+f'-publisher-{iteration}.log')).write_text(published.stdout+published.stderr)
  check=root/f'published-{iteration}';git(root,'clone','--branch','gh-pages',remote.as_uri(),str(check))
  v=json.loads((check/'game-release.json').read_text());assert v['sourceCommit']==sha and v['entry']=='game-'+sha[:12]
  assert v['engine']=='fixture-version-only-no-engine';entry=v['entry'];modules=v['storageModules'];expect={p.name:p.read_bytes() for p in (source/'web/save').glob('*.mjs')}
  assert len(expect)==10 and set(expect)==set(modules['sha256'])
  assert set(p.name for p in (check/modules['entry']).glob('*.mjs'))==set(expect)
  for mod,content in expect.items():
   assert (check/modules['entry']/mod).read_bytes()==content
   assert modules['sha256'][mod]==hashlib.sha256(content).hexdigest()
   for relative in re.findall(r"(?:from\s*|import\s*\()\s*['\"](\.[^'\"]+)['\"]",content.decode()):
    target=(check/modules['entry']/relative).resolve();assert target.is_relative_to((check/modules['entry']).resolve()) and target.is_file()
  page=(check/'index.html').read_text();assert './web/save/' not in page and f"script.src = '{entry}.js'" in page
  for ext in ('js','wasm','pck'):
   assert (check/(entry+'.'+ext)).read_bytes()==ext.encode();assert (check/('index.'+ext)).read_bytes()==ext.encode()
  if old_modules:
   for mod,content in old_modules[1].items():assert (check/old_modules[0]/mod).read_bytes()==content
  # Excluded historical Pages docs remain tracked and unchanged after real git add -A/commit/push.
  for p in ('docs/pages-audit.txt','docs/pages-later.txt'):
   assert out(check,'rev-parse','HEAD:'+p)==out(seed,'rev-parse','HEAD:'+p)
  bundles=sorted(p.stem for p in check.glob('game-*.pck'));assert len(bundles)==(4+iteration if shallow else 2),bundles
  builds.append({'returncode':published.returncode,'source_commit_matches':True,'versioned_entry_and_four_build_files_valid':True,'module_count':10,'module_bytes_hashes_relative_imports_valid':True,'previous_module_directory_retained':True if old_modules else None,'historical_pages_docs_preserved_in_pushed_tree':True,'bundle_count':len(bundles)})
  old_modules=modules['entry'],expect
 # Missing current PCK must make the exact publisher fail before a remote commit.
 before_rejection=out(remote,'rev-parse','refs/heads/gh-pages')
 write(source,'source-version.txt','missing-current fixture source');git(source,'add','source-version.txt');git(source,'commit','-qm','missing current PCK fixture')
 newsha=out(source,'rev-parse','HEAD');(source/'dist/index.pck').unlink()
 rejected=run('bash','tools/publish_gh_pages.sh',newsha[:12],cwd=source,env=env,check=False)
 assert rejected.returncode==1 and 'current staged PCK is missing' in rejected.stderr
 assert out(remote,'rev-parse','refs/heads/gh-pages')==before_rejection
 (OUTPUT/(name+'-publisher-missing-pck.log')).write_text(rejected.stdout+rejected.stderr)
 final_missing=missing(source)
 if partial and sparse and allow_filter and not shallow:assert doc_blobs <= final_missing
 return {'name':name,'full_source_history':not shallow,'requested_partial_filter':partial,'filter_supported':allow_filter,'sparse_docs_excluded':sparse,'fetch_filter_ignored_warning':'filtering not recognized by server' in fetch.stderr,'main_head_exact':True,'source_non_docs_paths_and_blobs_match':True,'root_metadata_all_art_assets_nested_test_docs_retained':True,'main_history_count':int(main_log),'all_source_docs_blobs_missing_after_checkout':source_docs_initially_missing,'all_source_docs_blobs_still_missing_after_publisher':doc_blobs <= final_missing,'follow_fetch_promisor':promisor,'follow_fetch_filter':follow_filter,'new_pages_doc_missing_after_follow_fetch':later_doc in after_follow_fetch,'worktree':worktree,'retention':{'known_returncode':known.returncode,'known_pruned':expected_prune,'known_stderr':known.stderr.strip(),'unknown_returncode':unknown.returncode,'unknown_preserves_all':True,'unknown_stderr':unknown.stderr.strip(),'missing_current_returncode':absent.returncode,'missing_current_rejected':True,'keep_zero_no_deletion':True,'negative_keep_rejected':True},'actual_publisher_builds':builds,'actual_publisher_missing_current':{'returncode':rejected.returncode,'remote_pages_head_unchanged':True,'current_staged_pck_missing_error':True}}

with tempfile.TemporaryDirectory(prefix='publisher130-partial-') as temporary:
 root=Path(temporary)
 for args in [('full_baseline',False,False,False,True),('full_partial_sparse',True,True,False,True),('full_sparse_no_filter',False,True,False,True),('full_partial_no_sparse',True,False,False,True),('shallow_partial_sparse',True,True,True,True),('full_partial_sparse_filter_unsupported',True,True,False,False)]:
  REPORT['modes'].append(mode(root/args[0],*args));print('PASS',args[0],flush=True)
REPORT['result']='PASS: 6 fetch modes, 30 retention checks, 12 exact-script local publisher builds + 6 missing-PCK rejections; no engine or browser'
(OUTPUT/'fixture-results.json').write_text(json.dumps(REPORT,ensure_ascii=False,indent=2)+'\n')
# Retain only sanitized commands; no network credentials or production remote writes are involved.
(OUTPUT/'fixture-command-results.json').write_text(json.dumps(COMMANDS,indent=2)+'\n')
print(REPORT['result'])

print('Evidence directory:',OUTPUT)
