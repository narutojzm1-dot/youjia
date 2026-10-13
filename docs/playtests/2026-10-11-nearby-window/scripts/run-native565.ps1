param([string]$Name='baseline',[string]$Suite='modal_touch_input',[switch]$Import)
$ErrorActionPreference='Stop'
$repo='D:\games\youjia-test\assistant'
$out='D:\games\youjia-test\assistant-recovery'
$engine='D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe'
$override=Join-Path $repo 'override.cfg'
if(Test-Path -LiteralPath $override){throw 'Existing override must be inspected'}
$profile='youjia-tests-nearby565-'+[guid]::NewGuid().ToString('N')
[IO.File]::WriteAllText($override,"[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"$profile`"`n",[Text.UTF8Encoding]::new($false))
$previousIsolated=$env:YOUJIA_TEST_ISOLATED_DATA
$previousXdg=$env:XDG_DATA_HOME
$env:YOUJIA_TEST_ISOLATED_DATA=Join-Path $env:APPDATA $profile
$env:XDG_DATA_HOME=$env:YOUJIA_TEST_ISOLATED_DATA
try {
 if($Import){ & $engine --headless --path $repo --editor --import --quit *> (Join-Path $out "382-$Name-import.log"); if($LASTEXITCODE -ne 0){throw 'Import failed'} }
 & $engine --headless --path $repo --script "test/${Suite}_suite.gd" *> (Join-Path $out "382-$Name.log")
 $result=$LASTEXITCODE
 Get-Content (Join-Path $out "382-$Name.log") -Tail 15
 $raw=Get-Content (Join-Path $out "382-$Name.log") -Raw
 if($raw -match '(?m)^(SCRIPT ERROR:|ERROR:)'){$result=1}
 Write-Output "Native exit=$result profile=$profile"
 exit $result
} finally { Remove-Item -LiteralPath $override; $env:YOUJIA_TEST_ISOLATED_DATA=$previousIsolated; $env:XDG_DATA_HOME=$previousXdg }
