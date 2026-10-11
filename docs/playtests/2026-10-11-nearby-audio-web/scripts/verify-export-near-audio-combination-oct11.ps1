param([string]$StartAt='')
$ErrorActionPreference='Stop'
$validationRepo='D:\games\youjia-test\assistant-recovery\nearby-audio-web-validation'
$proofRoot='D:\games\youjia-test\assistant-recovery\nearby-audio-web-proof-oct11'
$exportRoot='D:\games\youjia-test\assistant-recovery\nearby-audio-combination-web'
$godotBinary='D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe'
$overridePath=Join-Path $validationRepo 'override.cfg'
if(Test-Path -LiteralPath $overridePath){throw 'Pre-existing override requires inspection'}
New-Item -ItemType Directory -Path $proofRoot,$exportRoot -Force | Out-Null
$sourceSha=(git -C $validationRepo rev-parse HEAD).Trim()
$priorIsolated=$env:YOUJIA_TEST_ISOLATED_DATA
$priorXdg=$env:XDG_DATA_HOME
$results=[Collections.Generic.List[object]]::new()
if($StartAt){
 foreach($priorResult in (Get-Content -LiteralPath (Join-Path $proofRoot 'native-results.json') -Raw | ConvertFrom-Json)){
  if($priorResult.status -eq 'PASS'){$results.Add($priorResult)}
 }
}
$caseDefinitions=@(
 @{name='import';args=@('--editor','--import','--quit');marker=$null},
 @{name='regional_audio';args=@('--script','test/regional_audio_suite.gd');marker='^REGIONAL_AUDIO checks=[1-9][0-9]* failures=0$'},
 @{name='yard_audio';args=@('--script','test/yard_audio_suite.gd');marker='^YARD_AUDIO checks=[1-9][0-9]* failures=0$'},
 @{name='hud_pointer_input';args=@('--script','test/hud_pointer_input_suite.gd');marker='^HUD_POINTER_INPUT checks=[1-9][0-9]* failures=0$'},
 @{name='nearby_direct_pick';args=@('--script','test/nearby_direct_pick_suite.gd');marker='^NEARBY_DIRECT_PICK checks=[1-9][0-9]* failures=0$'},
 @{name='exploration_slice';args=@('--script','test/exploration_slice_suite.gd');marker=$null},
 @{name='exploration_trip_capacity';args=@('--script','test/exploration_trip_capacity_suite.gd');marker='^EXPLORATION_TRIP_CAPACITY checks=[1-9][0-9]* failures=0$'}
)
try {
 $enabled= -not $StartAt
 foreach($case in $caseDefinitions){
  if($case.name -eq $StartAt){$enabled=$true}
  if(-not $enabled){continue}
  $profileName='youjia-assistant-audio-565-'+[guid]::NewGuid().ToString('N')
  [IO.File]::WriteAllText($overridePath,"[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"$profileName`"`n",[Text.UTF8Encoding]::new($false))
  $env:YOUJIA_TEST_ISOLATED_DATA=Join-Path $env:APPDATA $profileName
  $env:XDG_DATA_HOME=$env:YOUJIA_TEST_ISOLATED_DATA
  $logPath=Join-Path $proofRoot ($case.name+'.log')
  $began=Get-Date
  & $godotBinary --headless --path $validationRepo @($case.args) *> $logPath
  $exitCode=$LASTEXITCODE
  $logText=Get-Content -LiteralPath $logPath -Raw
  $marker=$case.marker
  if($case.name -ne 'import'){
   $suitePath=$case.args[-1]
   $entries=@(Get-Content -LiteralPath (Join-Path $validationRepo 'tools/lib/godot_suite_completions.tsv') | Where-Object {($_ -split "`t",2)[0] -eq $suitePath})
   if($entries.Count -ne 1){throw "Completion registration missing or ambiguous: $suitePath"}
   $marker=($entries[0] -split "`t",2)[1]
  }
  $valid=$exitCode -eq 0 -and $logText -notmatch '(?m)^(SCRIPT ERROR:|ERROR:)'
  if($marker){$valid=$valid -and @($logText -split '\r?\n' | Where-Object {$_ -cmatch "^$marker$"}).Count -gt 0}
  $results.Add(@{name=$case.name;exit=$exitCode;status=$(if($valid){'PASS'}else{'FAIL'});seconds=((Get-Date)-$began).TotalSeconds;source=$sourceSha;profile=$profileName;completionPattern=$marker})
  $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $proofRoot 'native-results.json') -Encoding utf8
  Get-Content -LiteralPath $logPath -Tail 4
  if(-not $valid){throw "Verification did not complete: $($case.name)"}
 }
} finally {
 if(Test-Path -LiteralPath $overridePath){Remove-Item -LiteralPath $overridePath}
 $env:YOUJIA_TEST_ISOLATED_DATA=$priorIsolated
 $env:XDG_DATA_HOME=$priorXdg
}
& $godotBinary --headless --path $validationRepo --export-release Web (Join-Path $exportRoot 'index.html') *> (Join-Path $proofRoot 'web-export.log')
$exportExit=$LASTEXITCODE
$exportLog=Get-Content -LiteralPath (Join-Path $proofRoot 'web-export.log') -Raw
Get-Content -LiteralPath (Join-Path $proofRoot 'web-export.log') -Tail 4
if($exportExit -ne 0 -or $exportLog -match '(?m)^(SCRIPT ERROR:|ERROR:)'){throw 'Web export failed'}
Copy-Item -LiteralPath (Join-Path $validationRepo 'web') -Destination $exportRoot -Recurse
@{source=$sourceSha;parents=@('5d23acbec9d756fc5e3ddee678e2db478ff18935','e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169');candidateOnly=$true;pckSha256=(Get-FileHash -LiteralPath (Join-Path $exportRoot 'index.pck')).Hash.ToLowerInvariant();exportExit=$exportExit;exportedAt=(Get-Date -Format o)} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $exportRoot 'candidate-source.json') -Encoding utf8
Write-Output "AUDIO_COMBINATION_WEB_EXPORT source=$sourceSha exit=0"
