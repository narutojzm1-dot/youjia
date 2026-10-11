$ErrorActionPreference='Stop'
$repo='D:\games\youjia-test\assistant'
$out='D:\games\youjia-test\assistant-recovery\hud734-final-web'
if(Test-Path -LiteralPath (Join-Path $repo 'override.cfg')){throw 'Existing override must be inspected'}
$source=(git -C $repo rev-parse HEAD).Trim()
New-Item -ItemType Directory -Path $out -Force | Out-Null
& 'D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe' --headless --path $repo --export-release Web (Join-Path $out 'index.html') *> 'D:\games\youjia-test\assistant-recovery\hud734-final-export.log'
$code=$LASTEXITCODE
Get-Content -LiteralPath 'D:\games\youjia-test\assistant-recovery\hud734-final-export.log' -Tail 5
if($code -ne 0){throw "Final export exit=$code"}
if((Get-Content -LiteralPath 'D:\games\youjia-test\assistant-recovery\hud734-final-export.log' -Raw) -match '(?m)^(SCRIPT ERROR:|ERROR:)'){throw 'Final export logged errors'}
Copy-Item -LiteralPath (Join-Path $repo 'web') -Destination $out -Recurse
@{source=$source;diagnosticTrace=$false;export=(Get-Date -Format o);pckSha256=(Get-FileHash -LiteralPath (Join-Path $out 'index.pck')).Hash.ToLowerInvariant()} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out 'candidate-source.json')
Write-Output "Final uninstrumented source=$source"
