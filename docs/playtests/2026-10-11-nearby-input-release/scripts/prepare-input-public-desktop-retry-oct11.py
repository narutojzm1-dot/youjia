from pathlib import Path
R=Path(r'D:\games\youjia-test\assistant-recovery')
s=(R/'browser-nearby-public-input-current-oct11.py').read_text(encoding='utf-8')
line="        page=context.new_page();page.add_init_script(init)"
assert s.count(line)==1
s=s.replace(line,line+"\n        page.set_default_navigation_timeout(180000)")
assert s.count('        page.goto(url)')==1
s=s.replace('        page.goto(url)', "        page.goto(url,wait_until='domcontentloaded')")
needle="        page.reload();page.wait_for_function('window.first',timeout=180000);assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed during verification';page.wait_for_timeout(700);snap('reload-title')"
assert s.count(needle)==1
s=s.replace(needle,"""        reload_start=time.perf_counter()
        try:
            page.reload(wait_until='domcontentloaded')
            page.wait_for_function('window.first',timeout=180000)
            assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed during verification'
        except Exception as e:
            page.screenshot(path=str(folder/'reload-observation-failed.png'),scale='css')
            (folder/'reload-observation-failed.json').write_text(json.dumps({'error':str(e),'first':page.evaluate('window.first'),'build':page.evaluate('document.documentElement.dataset.build'),'errors':errors,'readonly_payload':payload()},indent=2),encoding='utf-8')
            raise
        (folder/'reload-observation.json').write_text(json.dumps({'elapsed_ms':(time.perf_counter()-reload_start)*1000,'navigation_wait':'domcontentloaded, then actual youjia:first-frame','navigation_budget_ms':180000,'source':source},indent=2),encoding='utf-8')
        page.wait_for_timeout(700);snap('reload-title')""")
out=R/'browser-nearby-public-desktop-retry-oct11.py'
assert not out.exists()
out.write_bytes(s.encode('utf-8'))
print('Desktop retry changes only navigation observation; original 30s load timeout retained')
