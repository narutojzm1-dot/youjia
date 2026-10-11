from pathlib import Path
import json
from playwright.sync_api import sync_playwright

r = Path(r'D:\games\youjia-test\assistant-recovery')
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    page = browser.new_page()
    page.add_init_script((r/'nearby-web-audio-observer-oct11.js').read_text(encoding='utf-8'))
    page.goto('about:blank')
    page.set_content('<button id="start">start isolated sine calibration</button>')
    page.evaluate("""() => document.querySelector('#start').onclick = async () => {
      window.calibrationContext = new AudioContext();
      const oscillator = calibrationContext.createOscillator();
      window.calibrationGain = calibrationContext.createGain();
      calibrationGain.gain.value = .1;
      oscillator.connect(calibrationGain);calibrationGain.connect(calibrationContext.destination);
      oscillator.start();await calibrationContext.resume();
    }""")
    page.click('#start')
    page.wait_for_timeout(500)
    positive = page.evaluate('audioObservation.diagnostics()')
    page.evaluate('calibrationGain.gain.value=0')
    page.wait_for_timeout(250)
    silent = page.evaluate('audioObservation.diagnostics()')
    assert len(positive['signal']) == 1, positive
    assert .065 < positive['signal'][0]['rms'] < .077, positive
    assert silent['signal'][0]['rms'] == 0, silent
    assert not positive['failures'] and not silent['failures']
    (r/'nearby-audio-observer-calibration-oct11.json').write_bytes((json.dumps({'method':'Synthetic sine positive/silent controls in separate about:blank page; not game audio or listening', 'positive':positive, 'silent':silent},indent=2)+'\n').encode())
    browser.close()
print('AUDIO_OBSERVER_CALIBRATION positive_and_exact_silence passed')
