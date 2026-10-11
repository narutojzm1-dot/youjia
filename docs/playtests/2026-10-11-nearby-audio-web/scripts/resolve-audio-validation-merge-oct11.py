from pathlib import Path
import re, json, hashlib, subprocess

w = Path(r'D:\games\youjia-test\assistant-recovery\nearby-audio-web-validation')
r = Path(r'D:\games\youjia-test\assistant-recovery\audio-validation-merge-record')
r.mkdir(exist_ok=True)
paths = ['scripts/main.gd','tools/lib/godot_suite_completions.tsv','tools/verify_daily_life.sh','docs/game-design.md','docs/requirements.md','docs/decisions.md']
pattern = re.compile(r'<<<<<<<[^\n]*\n(.*?)=======\n(.*?)>>>>>>>[^\n]*(?:\n|$)', re.S)
records = []
for path in paths:
    p = w/path
    original = p.read_bytes()
    text = original.decode('utf-8').replace('\r\n', '\n')
    matches = list(pattern.finditer(text))
    assert len(matches) == 1, (path, len(matches))
    before = r/path
    before.parent.mkdir(parents=True,exist_ok=True)
    before.write_bytes(original)
    def replacement(match):
        ours, theirs = match.group(1), match.group(2)
        if path == 'scripts/main.gd':
            assert ours == '' and theirs.startswith('\t_sync_world_sound()\n\tif _decor_panel'), (ours,theirs)
            # Current main deliberately removed the old decor preview block.
            # Keep only the candidate's audio call; do not restore obsolete UI.
            return '\t_sync_world_sound()\n'
        return ours + theirs
    merged = pattern.sub(replacement,text)
    assert not any(marker in merged for marker in ['<<<<<<<','=======','>>>>>>>']), path
    p.write_bytes(merged.encode('utf-8'))
    records.append({'path':path,'conflictSha256':hashlib.sha256(original).hexdigest(),'resolvedSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'resolution':'only audio call, preserve current decor-camera methods' if path == 'scripts/main.gd' else 'keep current sections/registrations and append original candidate additions'})
(r/'resolutions.json').write_bytes((json.dumps(records,indent=2)+'\n').encode())
subprocess.run(['git','add','--sparse','--',*paths],cwd=w,check=True)
assert not subprocess.check_output(['git','ls-files','-u'],cwd=w)
subprocess.run(['git','commit','-q','-m','test(assistant): isolate main5d and Leader623 for near Web audio validation'],cwd=w,check=True)
head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=w,text=True).strip()
(r/'combination.json').write_bytes((json.dumps({'head':head,'parents':['5d23acbec9d756fc5e3ddee678e2db478ff18935','e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169'],'purpose':'Local diagnostic candidate only; not merged or published. No author branch changed. Original audio623 and542 ancestry retained.'},indent=2)+'\n').encode())
print('AUDIO_COMBINATION '+head)
