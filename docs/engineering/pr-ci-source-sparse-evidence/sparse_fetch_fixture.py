"""Exercise non-cone sparse + shallow partial fetch in disposable local Git only."""
import json
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent

def run(*args, cwd=None):
    r=subprocess.run(args,cwd=cwd,text=True,capture_output=True)
    if r.returncode: raise RuntimeError(f'{args}: {r.stderr}')
    return r.stdout.strip()

def git(repo,*args): return run('git',*args,cwd=repo)

report={'patterns':['/*','!/docs/'],'cases':[],'production_runtime_tested':False}
with tempfile.TemporaryDirectory(prefix='checkout130-sparse-fixture-') as temporary:
    root=Path(temporary); seed=root/'seed'; origin=root/'origin.git'
    run('git','init','--bare',str(origin));git(origin,'config','uploadpack.allowFilter','true')
    run('git','init','-b','main',str(seed));git(seed,'config','user.name','Fixture');git(seed,'config','user.email','fixture@example.invalid')
    files={
        'project.godot':'project metadata', 'asset-provenance.json':'root asset metadata', '.gitignore':'ignored',
        '.github/workflows/verify-pr.yml':'workflow', 'tools/verify_daily_life.sh':'suite caller',
        'test/suite.gd':'suite source', 'test/docs/fixture.json':'nested docs is deliberately retained',
        'web/loading.html':'loader', 'assets/a.png':'asset blob',
        'art/concepts/producer_world_20261005/near_path_anchors.candidate.json':'anchor fixture',
        'docs/requirements.md':'excluded root docs', 'docs/qa/capture.png':'excluded unique binary stand-in',
        'docs/.gdignore':'ignored docs importer',
    }
    for name,value in files.items():
        target=seed/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(value)
    git(seed,'add','.');git(seed,'commit','-m','base source')
    git(seed,'checkout','-b','feature');(seed/'test/suite.gd').write_text('feature suite');files['test/suite.gd']='feature suite'
    git(seed,'add','.');git(seed,'commit','-m','feature source')
    git(seed,'checkout','main');(seed/'web/loading.html').write_text('main loader');files['web/loading.html']='main loader'
    git(seed,'add','.');git(seed,'commit','-m','main source');git(seed,'merge','--no-ff','feature','-m','proposed merge')
    sha=git(seed,'rev-parse','HEAD');docsha=git(seed,'rev-parse','HEAD:docs/qa/capture.png')
    git(seed,'remote','add','origin',origin.as_uri());git(seed,'push','origin','HEAD:refs/pull/7/merge')
    for mode,sparse,partial in [('sparse_partial',True,True),('sparse_without_filter',True,False),('partial_without_sparse',False,True)]:
        checkout=root/mode;run('git','init',str(checkout));git(checkout,'remote','add','origin',origin.as_uri())
        args=['-c','protocol.version=2','fetch','--no-tags','--prune','--no-recurse-submodules','--depth=1']
        if partial: args+=['--filter=blob:none']
        git(checkout,*args,'origin',f'+{sha}:refs/remotes/pull/7/merge')
        if sparse:
            # Same non-cone operations as actions/checkout v4.
            git(checkout,'config','core.sparseCheckout','true')
            (checkout/'.git/info/sparse-checkout').write_text('\n/*\n!/docs/\n')
        git(checkout,'checkout','--force','refs/remotes/pull/7/merge')
        assert git(checkout,'rev-parse','HEAD')==sha
        actual={str(p.relative_to(checkout)):p.read_text() for p in checkout.rglob('*') if p.is_file() and '.git' not in p.relative_to(checkout).parts}
        expected={k:v for k,v in files.items() if not sparse or not k.startswith('docs/')}
        assert actual==expected,(mode,actual.keys(),expected.keys())
        missing=git(checkout,'rev-list','--objects','--all','--missing=print').splitlines()
        doc_missing=('?'+docsha) in missing
        assert doc_missing==(sparse and partial)
        report['cases'].append({'mode':mode,'head_is_exact_proposed_merge':True,
                                 'all_expected_paths_and_bytes_match':True,
                                 'docs_worktree_present':(checkout/'docs').exists(),
                                 'unique_docs_blob_not_fetched':doc_missing,
                                 'nested_test_docs_and_all_art_retained':True})
report['result']='PASS: 3 Git transport/worktree cases; no game engine executed'
(HERE/'sparse-fetch-fixture.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
