#!/usr/bin/env python3
"""Keep unchanged Godot engine URLs stable while pinning the game PCK to source."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys


def stage(dist: Path, work: Path, game: str) -> dict:
    extensions = ('js', 'wasm', 'audio.worklet.js', 'audio.position.worklet.js')
    files = {ext: dist / f'index.{ext}' for ext in extensions if (dist / f'index.{ext}').is_file()}
    if not {'js', 'wasm'} <= files.keys():
        raise ValueError('Godot engine JS/WASM missing')
    hashes = {ext: hashlib.sha256(path.read_bytes()).hexdigest() for ext, path in files.items()}
    signature = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
    engine = f'engine-{signature}'
    for ext, path in files.items():
        shutil.copyfile(path, work / f'{engine}.{ext}')
    html = work / 'index.html'
    text = html.read_text(encoding='utf-8')
    match = re.search(r'const config = (\{.*?\});', text)
    if not match:
        raise ValueError('Godot config missing')
    config = json.loads(match[1])
    config['executable'] = engine
    config['mainPack'] = f'{game}.pck'
    sizes = config['fileSizes']
    sizes[f'{engine}.wasm'] = sizes.pop('index.wasm')
    sizes[f'{game}.pck'] = sizes.pop('index.pck')
    config['fileHashes'] = {
        f'{engine}.wasm': hashes['wasm'],
        f'{game}.pck': hashlib.sha256((dist / 'index.pck').read_bytes()).hexdigest(),
    }
    text = text[:match.start(1)] + json.dumps(config, separators=(',', ':')) + text[match.end(1):]
    script = "script.src = 'index.js'"
    if script not in text:
        raise ValueError('Godot script URL missing')
    text = text.replace(script, f"script.src = '{engine}.js'")
    html.write_text(text, encoding='utf-8')
    return {'entry': engine, 'sha256': {f'{engine}.{ext}': digest for ext, digest in hashes.items()}}


if __name__ == '__main__':
    dist, work, game = sys.argv[1:]
    record = stage(Path(dist), Path(work), game)
    (Path(work) / 'engine-assets.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    print(f"[publish] reusable engine: {record['entry']}")
