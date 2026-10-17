from pathlib import Path
p=Path(__file__).parent
s=(p/'garden-bloom.cjs').read_text(encoding='utf8')
start=s.index(' const initial=')
stop=s.index(' await page.evaluate(async({d,m})=>',start)
s=s[:start]+''' const initial=JSON.parse(await fs.readFile(path.join(__dirname,'web-source-ui-r3/result.json'),'utf8')).final;
 result.actualSourceChainSnapshotImportedAsStart=true;result.noTimeAdvanceOrFutureDateFixture=true;result.initialFixture=initial;
 assert.equal(initial.holiday_day,1);assert.equal(initial.yard_garden.receipts[0].day,1);
'''+s[stop:]
start=s.index(' result.bootMs=await boot();')
stop=s.index('})().catch',start)
s=s[:start]+''' result.bootMs=await boot();
 const began=Date.now();let prior=0;
 while(Date.now()-began<1700000){
  await page.waitForTimeout(15000);
  const d=await read(),row={seconds:(Date.now()-began)/1000,day:d.holiday_day,elapsed:d.holiday_day_elapsed,garden:d.yard_garden};
  result.samples.push(row);assert.deepEqual(d.yard_garden,initial.yard_garden);
  if(d.holiday_day!==prior){prior=d.holiday_day;await page.screenshot({path:path.join(dir,'natural-day-'+prior+'.jpg'),type:'jpeg',quality:93});console.log(JSON.stringify(row));}
  await save();
  if(d.holiday_day>=4){result.final=d;result.naturalWallClockSeconds=row.seconds;await page.screenshot({path:path.join(dir,'natural-bloom-day4.jpg'),type:'jpeg',quality:94});break;}
 }
 assert.equal(result.final?.holiday_day,4);assert.equal(result.errors.length,0);assert(!result.console.some(x=>/SCRIPT ERROR|WebGL|INVALID_OPERATION/.test(x)));
 result.pass=true;await save();console.log('NATURAL_BLOOM_PASS '+result.naturalWallClockSeconds);
'''+s[stop:]
(p/'garden-natural-bloom.cjs').write_text(s,encoding='utf8')
print('Prepared actual natural-day transition observation, no clock changes after start')
