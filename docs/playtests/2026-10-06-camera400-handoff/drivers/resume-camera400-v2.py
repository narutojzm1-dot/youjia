from pathlib import Path
import subprocess, json, os, datetime, hashlib, ast
assert os.environ.get('CAMERA400_ENGINE_WINDOW')=='granted'
repo=Path('/tmp/youjia-camera400');evidence=Path('/tmp/camera400-evidence/v2-pair');state=Path('/tmp/camera400-v2-state');engine='/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64'
source=json.loads(Path('/tmp/camera400-evidence/v2-source-pair.json').read_text());results=json.loads((evidence/'process-results.json').read_text())
assert len(results)==1 and results[0]['actual_exit']==1
tree=ast.parse(Path('/tmp/run-camera400-v2.py').read_text())
for node in tree.body:
 if isinstance(node,ast.FunctionDef):exec(compile(ast.Module(body=[node],type_ignores=[]),'<retained-runner-function>','exec'),globals())
assert git('rev-parse','HEAD').decode().strip()==source['new_red']
(repo/'scripts/game/yard_world.gd').write_bytes(git('show',source['new_green']+':scripts/game/yard_world.gd'))
git('read-tree',source['new_green']);git('update-ref','HEAD',source['new_green'])
green=run('green-v2',['bash','-c','source tools/lib/verified_godot.sh; run_verified_godot_suite /tmp/camera400-evidence/v2-pair/green-engine.log test/camera400_handoff_suite.gd --headless --path .'],0)
assert green.splitlines().count('[camera400-handoff] PASS: 202 checks []')==1
mocks=run('gate-contract-v2',['bash','test/godot_gate_test.sh'],0)
assert 'CAMERA400 COMPLETION CONTRACT PASS 14' in mocks and 'GODOT GATE CONTRACT PASS 64' in mocks
print('PAIR_COMPLETE: original code FAIL202; fixed code PASS202; new format mocks14 within total64',flush=True)
