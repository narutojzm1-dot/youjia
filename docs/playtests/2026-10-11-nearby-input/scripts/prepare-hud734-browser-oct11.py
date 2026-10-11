from pathlib import Path
folder=Path(r'D:\games\youjia-test\assistant-recovery')
s=(folder/'browser-nearby-public-quiet-point-oct11.py').read_text(encoding='utf-8')
def replace(old,new):
    global s
    assert s.count(old)==1,old
    s=s.replace(old,new)
replace("url = 'https://narutojzm1-dot.github.io/youjia/'","url = 'http://127.0.0.1:'+port+'/'\nassert json.loads((candidate/'candidate-source.json').read_text(encoding='utf-8-sig'))['source']==source")
replace("assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed before ordinary proof'","assert json.loads((candidate/'candidate-source.json').read_text(encoding='utf-8-sig'))['source']==source")
replace("assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed during verification';","")
replace("baseline=payload().get('keepsakes',{}).copy();action(exit_point)","""baseline=payload().get('keepsakes',{}).copy()
        if w==1280:
            # Real mouse UI actions, no sleep/screenshot between HUD and ground.
            action((324,h-43));action(exit_point)
            trace=page.evaluate('window.domInputTrace')
            pressed=[e for e in trace if e['kind']=='mousedown']
            delta=pressed[-1]['t']-pressed[-2]['t']
            assert delta<400, 'fast mouse fixture exceeded dedupe interval'
            (folder/'fast-mouse.json').write_text(json.dumps({'elapsed_ms':delta,'inputs':trace,'source':source},indent=2),encoding='utf-8')
        else: action(exit_point)""")
replace("returned();snap('collected-return')","""returned();snap('collected-return')
        before=payload()['world_weather']['weather']
        cycle=['sun','overcast','rain'];expected_weather=cycle[(cycle.index(before)+1)%3]
        action((w/2,h-99) if w<700 else (324,h-43))
        wait_state(lambda v:v['world_weather']['weather']!=before,'one weather click durable')
        page.wait_for_timeout(700)
        assert payload()['world_weather']['weather']==expected_weather, 'one physical click/touch must advance weather once'
        snap('one-weather-click')""")
replace("NEARBY_PUBLIC_WEB_COMPLETE","HUD734_ORDINARY_WEB_COMPLETE")
(folder/'browser-hud734-ordinary-oct11.py').write_text(s,encoding='utf-8')
