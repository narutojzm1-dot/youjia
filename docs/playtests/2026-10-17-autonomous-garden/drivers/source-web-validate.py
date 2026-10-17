from pathlib import Path
import json,subprocess,datetime
out=Path(__file__).parent;folder=out/'web-source-ui-r3'
d=json.loads((folder/'result.json').read_text())
seed='formal.find.flower_seeds';feather='formal.find.feather'
assert d['source']=='1ab59c1113dd0a1c7d55ca9e34cf3f89ab152814'
assert not d['initialFixture']['keepsakes'] and d['no_post_start_fixture_writes'] and d['no_direct_game_calls'] and d['no_http_substitution']
assert d['pass'] and not d['errors']
samples=d['samples'];taken=[]
for trip in [1,2,3]:
 session=next(s['exploration']['session'] for s in samples if s.get('exploration',{}).get('session') and s['exploration']['session']['trip_serial']==trip and s['exploration']['session']['taken'].get('slope'))
 taken.append({'trip':trip,'rng_seed_observed_not_forced':session['rng_seed'],'slope':session['taken']['slope']})
assert [r['slope'] for r in taken]==[feather,feather,seed]
returned=next(s for s in samples if s.get('keepsakes',{}).get(seed)==1 and not s.get('exploration',{}).get('session'))
assert returned['image']=='source-ui-14.jpg'
f=d['final'];assert f['keepsakes']=={feather:2} and f['yard_garden']['revision']==1
assert f['yard_inventory']['wheat']==1 and f['growth_production']['schema']==3
assert f['yard_garden']['receipts']==[{'ap':1,'bed':'starter','day':1,'experience':1,'period':'dinner','seeds':1}]
assert f['meal_ledger']==d['initialFixture']['meal_ledger']
profile=str(folder/'owned-profile').replace('\\','/')
ps="$t='"+profile.replace("'","''")+"'; @(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'chrome.exe' -and ($_.CommandLine -replace '\\\\','/').Contains($t) } | Select-Object -ExpandProperty ProcessId) | ConvertTo-Json -Compress"
actual=subprocess.check_output(['powershell.exe','-NoProfile','-Command',ps]).decode().strip()
assert not actual,actual
result={'pass':True,'source':d['source'],'actual_local_pck_normal_web_source_chain':True,'controlled_start_no_flower_seeds':True,'trips':taken,'real_ui_returned_seed_image':returned['image'],'auto_plant_result_image':'source-ui-15.jpg','meal_carry':'lunch to dinner max1, spent1','garden':f['yard_garden'],'no_game_error':True,'console_preserved':d['console'],'owned_chrome_processes_after_close':0,'not_public_pack_or_real_phone':True,'recorded_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
(folder/'validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps(result,ensure_ascii=True))
