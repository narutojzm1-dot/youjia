from pathlib import Path
import json, hashlib
from playwright.sync_api import sync_playwright

R = Path(r'D:\games\youjia-test\assistant-recovery')
O = R / 'nearby-find-audio-oct12'
L = O / 'web'
assert (L / 'summary.json').exists(), 'Do not analyze an unfinished run as a completed run'
files = sorted(L.glob('*-context-*.webm'))
assert len(files) == 4, [p.name for p in files]
results = []
with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    browser_version = browser.version
    page = browser.new_page()
    def serve(route):
        name = route.request.url.rsplit('/', 1)[-1]
        if not name:
            route.fulfill(status=200, content_type='text/html', body='<!doctype html><title>Local recorded audio analysis</title>')
        else:
            assert name in [f.name for f in files]
            route.fulfill(status=200, content_type='audio/webm', body=(L / name).read_bytes())
    page.route('http://audio-proof.local/**', serve)
    page.goto('http://audio-proof.local/')
    for path in files:
        data = page.evaluate('''async name => {
          const bytes = await (await fetch(name)).arrayBuffer();
          const ctx = new AudioContext({sampleRate: 48000});
          try {
            const b = await ctx.decodeAudioData(bytes);
            const channels = Array.from({length:b.numberOfChannels}, (_,i)=>b.getChannelData(i));
            let globalSum = 0, globalPeak = 0, nonFinite = 0, overUnity = 0;
            const seconds = [];
            for (let start=0; start<b.length; start+=b.sampleRate) {
              const end=Math.min(b.length,start+b.sampleRate); let sum=0,peak=0;
              for (const c of channels) for (let i=start;i<end;i++) {
                const v=c[i]; if(!Number.isFinite(v)){nonFinite++;continue;}
                sum+=v*v;peak=Math.max(peak,Math.abs(v));if(Math.abs(v)>1)overUnity++;
              }
              globalSum+=sum;globalPeak=Math.max(globalPeak,peak);
              seconds.push({startSeconds:start/b.sampleRate,durationSeconds:(end-start)/b.sampleRate,rms:Math.sqrt(sum/((end-start)*b.numberOfChannels)),peak});
            }
            return {durationSeconds:b.duration,sampleRate:b.sampleRate,channels:b.numberOfChannels,frames:b.length,decodedFloatBytes:b.length*b.numberOfChannels*4,rms:Math.sqrt(globalSum/(b.length*b.numberOfChannels)),peak:globalPeak,nonFinite,overUnity,seconds};
          } finally {await ctx.close();}
        }''', path.name)
        data.update(path=path.name, bytes=path.stat().st_size, sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        assert data['nonFinite'] == 0 and data['overUnity'] == 0, data['path']
        if path.name.startswith('long-'):
            assert data['durationSeconds'] > 700, data['durationSeconds']
        if 'context-2' in path.name:
            assert data['rms'] > 1e-6, data['rms']
        results.append(data)
        print(json.dumps({k:v for k,v in data.items() if k!='seconds'}), flush=True)
    browser.close()
(O / 'recording-software-analysis.json').write_text(json.dumps({'method':'Fresh separate Chrome decodeAudioData of actual captured WebM/Opus, per-channel 48000 Hz sample measurement; no game mutation and no hardware playback. Signal/finite/clipping metrics do not judge music quality, audible seams, headphone/speaker balance or perceptual continuity. Deliberate control mute intervals remain in the recording.','browser':browser_version,'results':results}, indent=2)+'\n', encoding='utf-8')
print('NEAR_FIND_AUDIO_RECORDING_ANALYSIS_COMPLETE')
