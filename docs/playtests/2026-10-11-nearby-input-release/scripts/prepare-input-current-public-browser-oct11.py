from pathlib import Path
R=Path(r'D:\games\youjia-test\assistant-recovery')
s=(R/'browser-nearby-public-input3ca-oct11.py').read_text(encoding='utf-8')
guard="        assert page.evaluate('document.documentElement.dataset.build')=='game-'+source[:7], 'public source changed before ordinary proof'\n"
assert s.count(guard)==1
s=s.replace(guard,'')
marker="        package={'source':source"
assert s.count(marker)==1
guard="""        actual_build=page.evaluate('document.documentElement.dataset.build')
        if actual_build!='game-'+source[:7]:
            page.screenshot(path=str(folder/'public-version-changed.png'),scale='css')
            (folder/'public-version-changed.json').write_text(json.dumps({'expected_source':source,'actual_build':actual_build,'errors':errors,'resources':[r['response']['url'] for r in responses]},indent=2),encoding='utf-8')
            raise AssertionError('public source changed before ordinary proof: '+actual_build)
"""
s=s.replace(marker,guard+marker)
out=R/'browser-nearby-public-input-current-oct11.py'
assert not out.exists()
out.write_bytes(s.encode('utf-8'))
print('Prepared source guard before received-byte comparisons')
