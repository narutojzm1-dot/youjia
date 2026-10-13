param([Parameter(Mandatory=$true)][string]$Label,[Parameter(Mandatory=$true)][string[]]$Cases)
$ErrorActionPreference='Stop'
$taskRepo='D:\games\youjia-test\assistant'
$proofBase='D:\games\youjia-test\assistant-recovery\nearby-find-audio-main-oct13'
if($Label -notmatch '^[a-z0-9-]+$'){throw 'Invalid label'}
$proofRoot=Join-Path $proofBase $Label
if(Test-Path -LiteralPath $proofRoot){throw 'Evidence directory already exists'}
New-Item -ItemType Directory -Path $proofRoot -Force | Out-Null
$godotBinary='D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe'
$overridePath=Join-Path $taskRepo 'override.cfg'
if(Test-Path -LiteralPath $overridePath){throw 'Pre-existing override must be inspected'}
$sourceSha=(git -C $taskRepo rev-parse HEAD).Trim()
$priorIsolated=$env:YOUJIA_TEST_ISOLATED_DATA
$priorXdg=$env:XDG_DATA_HOME
$results=[Collections.Generic.List[object]]::new()
$allPassed=$true
try {
 foreach($caseName in $Cases){
  if($caseName -notmatch '^[a-z0-9_]+$'){throw 'Invalid case'}
  $profileName='youjia-assistant-find16-oct13-'+[guid]::NewGuid().ToString('N')
  [IO.File]::WriteAllText($overridePath,"[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"$profileName`"`n",[Text.UTF8Encoding]::new($false))
  $env:YOUJIA_TEST_ISOLATED_DATA=Join-Path $env:APPDATA $profileName
  $env:XDG_DATA_HOME=$env:YOUJIA_TEST_ISOLATED_DATA
  $logPath=Join-Path $proofRoot ($caseName+'.log')
  $started=Get-Date
  $caseArgs=if($caseName -eq 'import'){@('--editor','--import','--quit')}else{@('--script',"test/${caseName}_suite.gd")}
  & $godotBinary --headless --path $taskRepo @caseArgs *> $logPath
  $code=$LASTEXITCODE
  $logText=Get-Content -LiteralPath $logPath -Raw
  $marker=$null
  if($caseName -ne 'import'){
   $entries=@(Get-Content -LiteralPath (Join-Path $taskRepo 'tools/lib/godot_suite_completions.tsv') | Where-Object {($_ -split "`t",2)[0] -eq "test/${caseName}_suite.gd"})
   if($entries.Count -ne 1){throw 'Missing or ambiguous completion registration'}
   $marker=($entries[0] -split "`t",2)[1]
  }
  $valid=$code -eq 0 -and $logText -notmatch '(?m)^(SCRIPT ERROR:|ERROR:)'
  if($marker){$valid=$valid -and @($logText -split '\r?\n' | Where-Object {$_ -cmatch "^$marker$"}).Count -gt 0}
  $results.Add(@{name=$caseName;exit=$code;status=$(if($valid){'PASS'}else{'FAIL'});seconds=((Get-Date)-$started).TotalSeconds;source=$sourceSha;profile=$profileName;completionPattern=$marker;importMetadata='Godot-generated metadata retained separately, not production changes'})
  $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $proofRoot 'native-results.json') -Encoding utf8
  Get-Content -LiteralPath $logPath -Tail 5
  if(-not $valid){$allPassed=$false;break}
 }
} finally {
 if(Test-Path -LiteralPath $overridePath){Remove-Item -LiteralPath $overridePath}
 $env:YOUJIA_TEST_ISOLATED_DATA=$priorIsolated
 $env:XDG_DATA_HOME=$priorXdg
}
if(-not $allPassed){exit 1}
Write-Output "FIND16_NATIVE label=$Label source=$sourceSha cases=$($results.Count) status=PASS"
