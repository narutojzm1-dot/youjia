from pathlib import Path
p=Path('C:/Users/Zengm/AppData/Local/Temp')
s=(p/'youjia-webgl-matched.cjs').read_text(encoding='utf-8')
s=s.replace("await page.screenshot({path:path.join(dir,name+'.jpg'),type:'jpeg',quality:72});row.after=elapsed();await save();", "row.skipped_for_no_capture_control=true;row.after=elapsed();await save();")
s=s.replace("await page.addInitScript(()=>{window.__matchedFrames", "await page.addInitScript(await fs.readFile('C:/Users/Zengm/AppData/Local/Temp/youjia-webgl-trace.js','utf8'));\n await page.addInitScript(()=>{window.__matchedFrames")
key="await record('returned');await shot('04-returned');"
assert key in s
s=s.replace(key,key+"\n await until(130);result.glTrace=await page.evaluate(()=>window.__glTargetTrace);result.seconds=elapsed();result.finished=new Date().toISOString();result.exit=0;await save();await page.screenshot({path:path.join(dir,'after-complete.jpg'),type:'jpeg',quality:72});console.log(JSON.stringify({label,seconds:result.seconds,conflicts:result.glTrace.count,first:result.glTrace.conflicts[0]}));return;")
(p/'youjia-webgl-trace.cjs').write_text(s,encoding='utf-8')
print('Prepared separate130s GL observer control; matched620s controls unchanged')
