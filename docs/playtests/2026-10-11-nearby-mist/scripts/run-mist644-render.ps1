param([string]$CaptureName='nearby644-mist-render-v2',[string]$Script='tools/verify_nearby_mist_render.gd')
$ErrorActionPreference='Stop'
$repo='D:\games\youjia-test\assistant'
$out='D:\games\youjia-test\assistant-recovery'
$engine='D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe'
$override=Join-Path $repo 'override.cfg'
if(Test-Path -LiteralPath $override){throw 'Existing override must be inspected'}
$profile='youjia-tests-mist644-'+[guid]::NewGuid().ToString('N')
[IO.File]::WriteAllText($override,"[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"$profile`"`n",[Text.UTF8Encoding]::new($false))
$previousCapture=$env:YOUJIA_MIST_CAPTURE
$env:YOUJIA_MIST_CAPTURE=Join-Path $out $CaptureName
try {
 $process=Start-Process -FilePath $engine -ArgumentList @('--path',$repo,'--script',$Script,'--rendering-method','gl_compatibility','--display-driver','windows','--resolution','32x32') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $out "$CaptureName.stdout.log") -RedirectStandardError (Join-Path $out "$CaptureName.stderr.log")
 $process.WaitForExit()
 Get-Content (Join-Path $out "$CaptureName.stdout.log") -Tail 8
 Get-Content (Join-Path $out "$CaptureName.stderr.log") -Tail 10
 if($process.ExitCode -ne 0){throw 'Real renderer failed'}
 $raw=Get-Content (Join-Path $out "$CaptureName.stderr.log") -Raw
 if($raw -match '(?m)^(SCRIPT ERROR:|ERROR:)'){throw 'Real renderer reported error'}
} finally { Remove-Item -LiteralPath $override; $env:YOUJIA_MIST_CAPTURE=$previousCapture }
