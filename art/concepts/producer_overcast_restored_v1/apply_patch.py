"""Replay the delivered pixel patch; this is not the original creative process."""
from pathlib import Path
import argparse, hashlib, json
from PIL import Image
p=Path(__file__).resolve().parent
args=argparse.ArgumentParser()
args.add_argument('source',type=Path)
args.add_argument('output',type=Path)
opt=args.parse_args()
meta=json.loads((p/'measurements.json').read_text())
if hashlib.sha256(opt.source.read_bytes()).hexdigest()!=meta['source_sha256']:
    raise SystemExit('Source hash mismatch; expected original v8 no-cloud plate')
if opt.source.resolve()==opt.output.resolve():
    raise SystemExit('Do not overwrite source')
im=Image.open(opt.source).convert('RGB')
patch=Image.open(p/'pixel-patch.png').convert('RGBA')
im.paste(patch,tuple(meta['bbox'][:2]),patch.getchannel('A'))
im.save(opt.output)
expected=Image.open(p/'sky_base_candidate.png').convert('RGB')
if im.tobytes()!=expected.tobytes():
    raise SystemExit('Pixel replay mismatch')
print('Exact candidate pixel replay verified; file encoding may vary by Pillow version')
