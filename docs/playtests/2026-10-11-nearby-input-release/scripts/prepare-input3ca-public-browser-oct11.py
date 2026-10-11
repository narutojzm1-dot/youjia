from pathlib import Path
R=Path(r'D:\games\youjia-test\assistant-recovery')
p=R/'browser-hud734-ordinary-oct11.py'
s=p.read_text(encoding='utf-8')
assert s.count("url = 'http://127.0.0.1:'+port+'/'")==1
s=s.replace("url = 'http://127.0.0.1:'+port+'/'", "url = 'https://narutojzm1-dot.github.io/youjia/'")
assert s.count("candidate-source.json")==2
s=s.replace('candidate-source.json','verified.json')
old="        snap('title');action(title);page.wait_for_timeout(8000);snap('yard')"
assert s.count(old)==1
s=s.replace(old,"        assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed before ordinary proof'\n"+old)
old="        page.reload();page.wait_for_function('window.first',timeout=180000);page.wait_for_timeout(700);snap('reload-title')"
assert s.count(old)==1
s=s.replace(old,"        page.reload();page.wait_for_function('window.first',timeout=180000);assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed during verification';page.wait_for_timeout(700);snap('reload-title')")
s=s.replace('NEARBY_FINAL_HUD734_ORDINARY_COMPLETE','NEARBY_PUBLIC_INPUT3CA_ORDINARY_COMPLETE')
out=R/'browser-nearby-public-input3ca-oct11.py'
assert not out.exists()
out.write_bytes(s.encode('utf-8'))
print('Created ordinary public driver from final tested candidate driver; no player-state writes')
