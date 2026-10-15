import hashlib, json, pathlib, struct, wave

root = pathlib.Path(r'D:\games\youjia-test\assistant-recovery')
out = root / 'find16-public-bb04-oct15'
out.mkdir(exist_ok=True)
source = 'bb04fde115877380e3fda8fa80b96ee8753d7180'
base = 'https://narutojzm1-dot.github.io/youjia/'
wav = pathlib.Path(r'D:\games\youjia-test\assistant\assets\holiday\audio\exploration_find_get.wav')
with wave.open(str(wav), 'rb') as reader:
    assert (reader.getnchannels(), reader.getsampwidth(), reader.getframerate(), reader.getnframes()) == (1, 2, 48000, 45600)
    pcm = reader.readframes(reader.getnframes())
assert hashlib.sha256(pcm).hexdigest() == '936184f59a29c5d519f1d1ca831916e8fef997e373778a15a50f26adb90e443e'
floats = b''.join(struct.pack('<f', sample[0] / 32768) for sample in struct.iter_unpack('<h', pcm))
float_hash = hashlib.sha256(floats).hexdigest()
(out / 'expected-audio-hashes.json').write_text(json.dumps({'source': source, 'wavSha256': hashlib.sha256(wav.read_bytes()).hexdigest(), 'pcmSha256': hashlib.sha256(pcm).hexdigest(), 'monoFloat32Le48kSha256': float_hash}, indent=2) + '\n', encoding='utf-8')

observer = (root / 'nearby-find-audio-observer-oct12.js').read_text(encoding='utf-8')
assert observer.count('sources.push({ wallMs: performance.now()') == 1
observer = observer.replace('sources.push({ wallMs: performance.now()', 'const row = { wallMs: performance.now()')
assert observer.count('startArgs: args });') == 1
observer = observer.replace('startArgs: args });', '''startArgs: args }; sources.push(row);
      if (b && b.duration < 2) {
        row.floatHashes = []; row.hashErrors = [];
        for (let channel = 0; channel < b.numberOfChannels; channel++) {
          const samples = b.getChannelData(channel).slice();
          crypto.subtle.digest('SHA-256', samples.buffer).then(digest => {
            row.floatHashes[channel] = [...new Uint8Array(digest)].map(v => v.toString(16).padStart(2, '0')).join('');
          }).catch(error => row.hashErrors.push(String(error)));
        }
      }''')
(root / 'find16-public-observer-oct15.js').write_text(observer, encoding='utf-8')

driver = (root / 'browser-near-find-audio-current347-oct13.py').read_text(encoding='utf-8')
changes = {
    "out=root/'nearby-find-audio-current347-oct13/web';assert not out.exists();out.mkdir()": "out=root/'find16-public-bb04-oct15/web';assert not out.exists();out.mkdir()",
    "export=root/'nearby-find-audio-current347-web-oct13'": "export=root/'find16-public-bb04-oct15'",
    "candidate=json.loads((export/'candidate-source.json').read_text(encoding='utf-8-sig'))": "candidate=json.loads((export/'verified.json').read_text(encoding='utf-8'));assert candidate['source']=='" + source + "';BASE='" + base + "'",
    "root/'nearby-find-audio-observer-oct12.js'": "root/'find16-public-observer-oct15.js'",
    "page.goto('http://127.0.0.1:8798/',wait_until='domcontentloaded');page.wait_for_function('window.first',timeout=120000)": "page.goto(BASE,wait_until='domcontentloaded');page.wait_for_function('window.first',timeout=660000)",
    "e['response']['url'].split('8798/',1)[1]": "e['response']['url'].split(BASE,1)[1]",
    "page.wait_for_function('window.first',timeout=120000)": "page.wait_for_function('window.first',timeout=180000)",
    "'current623 regional audio integration claim.'": "'current623 regional audio integration claim.'",
}
for old, new in changes.items():
    assert old in driver, old
    driver = driver.replace(old, new)
driver = driver.replace("        package=[]", "        assert page.evaluate('document.documentElement.dataset.build')==candidate['entry']\n        package=[]")
driver = driver.replace("        result={'source':candidate['source']", "        short_sources=[s for s in audio()['sources'] if abs(s.get('duration',0)-.95)<.002 and not s['loop']]\n        # Reload resets observation; original recorded steps retain the pickup sources.\n        short_sources=max((r['audio']['sources'] for r in steps),key=len)\n        short_sources=[s for s in short_sources if abs(s.get('duration',0)-.95)<.002 and not s['loop']]\n        assert len(short_sources)==5\n        expected_hash=json.loads((export/'expected-audio-hashes.json').read_text())['monoFloat32Le48kSha256']\n        assert all(s['frames']==45600 and s['channels']==1 and s['sampleRate']==48000 and s.get('floatHashes')==[expected_hash] and not s.get('hashErrors') for s in short_sources),short_sources\n        write('actual-short-source-hashes.json',short_sources)\n        result={'source':candidate['source']")
driver = driver.replace("Ordinary Web covers direct mouse/touch pickup, repeats, mute/pause/return/reload and another tab.", "Actual public HTTPS Web covers direct mouse/touch pickup, repeats, mute/pause/return/reload. Another tab is recorded but only counts as background if real blur/visibility events occurred; previous headless runs did not.")
driver = driver.replace("        page.goto(BASE,wait_until='domcontentloaded');", "        print('FIND16_PUBLIC_COLD_START '+BASE,flush=True)\n        page.goto(BASE,wait_until='domcontentloaded');")
(root / 'browser-find16-public-oct15.py').write_text(driver, encoding='utf-8')

decoder = (root / 'analyze-near-find-audio-current347-oct13.py').read_text(encoding='utf-8')
decoder = decoder.replace("O = R / 'nearby-find-audio-current347-oct13'", "O = R / 'find16-public-bb04-oct15'")
(root / 'analyze-find16-public-oct15.py').write_text(decoder, encoding='utf-8')

packed = (root / 'verify-find16-stamped-pack-oct13.gd').read_text(encoding='utf-8')
packed = packed.replace('b784c2cb9020c11cf17821db4f534c3bcceeb328', source)
packed = packed.replace('\troot.get_node("AudioDirector").release_streams()', '''	var wav := load("res://assets/holiday/audio/exploration_find_get.wav") as AudioStreamWAV
	check(wav != null, "actual public approved WAV loads")
	if wav != null:
		check(wav.data.size() == 91200 and wav.data.sha256_text() == "936184f59a29c5d519f1d1ca831916e8fef997e373778a15a50f26adb90e443e", "actual public decoded PCM is approved source16")
		check(wav.mix_rate == 48000 and not wav.stereo and wav.format == AudioStreamWAV.FORMAT_16_BITS and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED, "actual public short sound format/nonloop retained")
	root.get_node("AudioDirector").release_streams()''')
(root / 'verify-find16-public-pack-oct15.gd').write_text(packed, encoding='utf-8')
print(json.dumps({'source': source, 'float32Hash': float_hash, 'drivers': 'prepared; no test or publication result implied'}))
