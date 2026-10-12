param([switch]$ExportOnly)
$ErrorActionPreference='Stop'
$taskRepo='D:\games\youjia-test\assistant'
$proofRoot='D:\games\youjia-test\assistant-recovery\nearby-find-audio-oct12'
$exportRoot='D:\games\youjia-test\assistant-recovery\nearby-find-audio-web-oct12'
$godotBinary='D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe'
$overridePath=Join-Path $taskRepo 'override.cfg'
if(Test-Path -LiteralPath $overridePath){throw 'Pre-existing override requires inspection'}
New-Item -ItemType Directory -Path $proofRoot,$exportRoot -Force | Out-Null
$sourceSha=(git -C $taskRepo rev-parse HEAD).Trim()
$priorIsolated=$env:YOUJIA_TEST_ISOLATED_DATA
$priorXdg=$env:XDG_DATA_HOME
$results=[Collections.Generic.List[object]]::new()
if(-not $ExportOnly){
 try {
  foreach($name in @('import','nearby_find_audio','exploration_slice','nearby_direct_pick','exploration_trip_capacity','hud_pointer_input')){
   $profileName='youjia-assistant-find16-'+[guid]::NewGuid().ToString('N')
   [IO.File]::WriteAllText($overridePath,"[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"$profileName`"`n",[Text.UTF8Encoding]::new($false))
   $env:YOUJIA_TEST_ISOLATED_DATA=Join-Path $env:APPDATA $profileName
   $env:XDG_DATA_HOME=$env:YOUJIA_TEST_ISOLATED_DATA
   $logPath=Join-Path $proofRoot ($name+'.log')
   $began=Get-Date
   $caseArgs=if($name -eq 'import'){@('--editor','--import','--quit')}else{@('--script',"test/${name}_suite.gd")}
   & $godotBinary --headless --path $taskRepo @caseArgs *> $logPath
   $exitCode=$LASTEXITCODE
   $logText=Get-Content -LiteralPath $logPath -Raw
   $marker=$null
   if($name -ne 'import'){
    $entries=@(Get-Content -LiteralPath (Join-Path $taskRepo 'tools/lib/godot_suite_completions.tsv') | Where-Object {($_ -split "`t",2)[0] -eq "test/${name}_suite.gd"})
    if($entries.Count -ne 1){throw "Completion missing or ambiguous: $name"}
    $marker=($entries[0] -split "`t",2)[1]
   }
   $valid=$exitCode -eq 0 -and $logText -notmatch '(?m)^(SCRIPT ERROR:|ERROR:)'
   if($marker){$valid=$valid -and @($logText -split '\r?\n' | Where-Object {$_ -cmatch "^$marker$"}).Count -gt 0}
   $results.Add(@{name=$name;exit=$exitCode;status=$(if($valid){'PASS'}else{'FAIL'});seconds=((Get-Date)-$began).TotalSeconds;source=$sourceSha;generatedImportMetadata='separate snapshot; five existing source imports normalized by Godot';profile=$profileName;completionPattern=$marker})
   $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $proofRoot 'native-results.json') -Encoding utf8
   Get-Content -LiteralPath $logPath -Tail 5
   if(-not $valid){throw "Verification did not complete: $name"}
  }
 } finally {
  if(Test-Path -LiteralPath $overridePath){Remove-Item -LiteralPath $overridePath}
  $env:YOUJIA_TEST_ISOLATED_DATA=$priorIsolated
  $env:XDG_DATA_HOME=$priorXdg
 }
}
& $godotBinary --headless --path $taskRepo --export-release Web (Join-Path $exportRoot 'index.html') *> (Join-Path $proofRoot 'web-export.log')
$exportExit=$LASTEXITCODE
$exportLog=Get-Content -LiteralPath (Join-Path $proofRoot 'web-export.log') -Raw
Get-Content -LiteralPath (Join-Path $proofRoot 'web-export.log') -Tail 4
if($exportExit -ne 0 -or $exportLog -match '(?m)^(SCRIPT ERROR:|ERROR:)'){throw 'Web export failed'}
Copy-Item -LiteralPath (Join-Path $taskRepo 'web') -Destination $exportRoot -Recurse -Force
@{source=$sourceSha;candidateOnly=$true;generatedImportMetadata='separate snapshot; five existing source imports normalized by Godot';pckSha256=(Get-FileHash -LiteralPath (Join-Path $exportRoot 'index.pck')).Hash.ToLowerInvariant();exportExit=$exportExit;exportedAt=(Get-Date -Format o)} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $exportRoot 'candidate-source.json') -Encoding utf8
Write-Output "FIND_AUDIO_WEB_EXPORT source=$sourceSha exit=0"
