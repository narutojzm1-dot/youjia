from pathlib import Path
R=Path(r'D:\games\youjia-test\assistant-recovery')
s=(R/'browser-nearby-public-desktop-retry-oct11.py').read_text(encoding='utf-8')
s=s.replace('from playwright.sync_api import sync_playwright','from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError')
s=s.replace('page.set_default_navigation_timeout(180000)','page.set_default_navigation_timeout(600000)')
needle="        cdp.on('Network.responseReceived',lambda e:responses.append(e) if e['response']['url'].endswith(('.pck','.mjs')) else None)"
assert s.count(needle)==1
s=s.replace(needle,needle+"""
        loading_trace=[];loading_snapshots=[]
        for event_name in ['Network.requestWillBeSent','Network.responseReceived','Network.dataReceived','Network.loadingFinished','Network.loadingFailed']:
            cdp.on(event_name,lambda e,n=event_name:loading_trace.append({'event':n,'data':e}))
        def loading_save():
            (folder/'loading-network.json').write_text(json.dumps({'source':source,'events':loading_trace,'snapshots':loading_snapshots,'page_console_errors':errors},indent=2),encoding='utf-8')
        def loading_state():
            return page.evaluate("({build:document.documentElement.dataset.build,hidden:document.querySelector('#loading').hidden,status:document.querySelector('#loading-status').innerText,detail:document.querySelector('#loading-detail').innerText,timings:window.youjiaLoadTimings})")
""")
needle="        try:page.wait_for_function('window.first',timeout=180000)"
assert s.count(needle)==1
s=s.replace(needle,"""        cold_start=time.perf_counter()
        try:
            while not page.evaluate('window.first'):
                if time.perf_counter()-cold_start>=600:raise AssertionError('cold first-frame observation exceeded600s')
                try:page.wait_for_function('window.first',timeout=10000)
                except PlaywrightTimeoutError:pass
                current=loading_state();current['elapsed_ms']=(time.perf_counter()-cold_start)*1000
                loading_snapshots.append(current);loading_save()
                print('ACTUAL_LOADING '+json.dumps(current,ensure_ascii=False),flush=True)
                if current.get('timings',{}).get('failed'):raise AssertionError('actual loader reported failed')
                if 180000<=current['elapsed_ms']<191000:page.screenshot(path=str(folder/'cold-at180.png'),scale='css')
            loading_snapshots.append(loading_state()|{'stage':'cold-complete','elapsed_ms':(time.perf_counter()-cold_start)*1000});loading_save()
""")
s=s.replace("            (folder/'startup-errors.json').write_text", "            loading_save()\n            (folder/'startup-errors.json').write_text")
needle="        (folder/'reload-observation.json').write_text"
assert s.count(needle)==1
s=s.replace(needle,"        loading_snapshots.append(loading_state()|{'stage':'warm-complete','observed_elapsed_ms':(time.perf_counter()-reload_start)*1000});loading_save()\n"+needle)
out=R/'browser-nearby-public-desktop-observed-oct11.py'
assert not out.exists()
out.write_bytes(s.encode('utf-8'))
print('Same live page observed in10s intervals up to600s; records real bytes/Range/headers/timing; no game writes')
