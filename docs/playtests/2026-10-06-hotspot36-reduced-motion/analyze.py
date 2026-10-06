"""Recompute read-only comparisons; screenshots remain unmodified."""
from pathlib import Path
import json
from PIL import Image, ImageChops
ROOT = Path(__file__).resolve().parent
PUBLIC = ROOT / 'public'
pairs = [
    ('flower', '02-flower-reduce-00.png', '02-flower-reduce-01.png', (308,181,389,236)),
    ('flower-later', '02-flower-reduce-00.png', '02-flower-reduce-02.png', (308,181,389,236)),
    ('shore', '07-shore-reduce-00.png', '07-shore-reduce-01.png', (542,490,623,525)),
    ('fence', '11-fence-reduce-00.png', '11-fence-reduce-01.png', (870,408,909,451)),
]
comparisons = []
for label, a, b, box in pairs:
    x = Image.open(PUBLIC / a).convert('RGB').crop(box)
    y = Image.open(PUBLIC / b).convert('RGB').crop(box)
    rows = list(ImageChops.difference(x,y).get_flattened_data())
    changed = sum(any(v) for v in rows)
    comparisons.append(dict(label=label,a=a,b=b,roi_xyxy=box,pixels=x.width*x.height,
        changed_pixels=changed,max_channel_delta=max(max(v) for v in rows),exact_equal=changed==0))
(PUBLIC / 'pixel-comparison.json').write_text(json.dumps(comparisons,indent=2)+'\n')
records = json.loads((PUBLIC / 'result.json').read_text())['inputs']
commands = [r for r in records if 'command' in r]
checks = []
for target, shot, duration in [('flower','04-flower-repeat-active',1.8),('shore','08-shore-repeat-active',1.65),('fence','12-fence-repeat-active',2.0)]:
    idx = next(i for i,r in enumerate(commands) if r['command']=={'op':'shot','name':shot})
    trigger, capture_request, hold, after_request = commands[idx-1:idx+3]
    assert hold['command']['op']=='hold'
    checks.append(dict(target=target,trigger=trigger,active_screenshot_request=capture_request,
        movement_request=hold,after_screenshot_request=after_request,
        trigger_to_movement_request_seconds=hold['monotonic']-trigger['monotonic'],
        nominal_feedback_seconds=duration,
        caveat='Input invocation and screenshot request/completion are not renderer frame timestamps; disappearance can overlap natural expiry.'))
(PUBLIC / 'timing-analysis.json').write_text(json.dumps(checks,indent=2)+'\n')
print(json.dumps({'comparisons':comparisons,'movement_request_seconds':[r['trigger_to_movement_request_seconds'] for r in checks]},indent=2))
