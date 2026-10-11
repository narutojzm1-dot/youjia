$ErrorActionPreference='Stop'
$repo='D:\games\youjia-test\assistant'
$out='D:\games\youjia-test\assistant-recovery\nearby-input-trace-web'
$main=Join-Path $repo 'scripts\main.gd'
$backup='D:\games\youjia-test\assistant-recovery\main-before-near-input-trace.gd'
if(Test-Path -LiteralPath $backup){throw 'Diagnostic backup already exists; inspect before reuse'}
Copy-Item -LiteralPath $main -Destination $backup
$text=[IO.File]::ReadAllText($main)
$needle='func _input(event: InputEvent) -> void:'
$trace=@'
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		print("ASSISTANT_INPUT_TRACE ", JSON.stringify({"method":"input", "event":event.as_text(), "device":event.device,"point":str(event.position),"world":str(_screen_to_world(event.position)),"screen":_screen,"last_touch":_last_touch_ms,"now":Time.get_ticks_msec(),"main_size":str(size),"viewport":str(get_viewport().get_visible_rect())}))
'@
$unhandled='func _unhandled_input(event: InputEvent) -> void:'
if(($text.Split($needle).Count -ne 2) -or ($text.Split($unhandled).Count -ne 2)){throw 'Unexpected Main function headers'}
$text=$text.Replace($needle,$needle+"`n"+$trace).Replace($unhandled,$unhandled+"`n"+$trace.Replace('"input"','"unhandled_input"'))
[IO.File]::WriteAllText($main,$text,[Text.UTF8Encoding]::new($false))
try {
 New-Item -ItemType Directory -Path $out -Force | Out-Null
 & 'D:\games\youjia-test\producer-recovery\godot472\Godot_v4.7.2-stable_win64_console.exe' --headless --path $repo --export-release Web (Join-Path $out 'index.html') *> 'D:\games\youjia-test\assistant-recovery\nearby-input-trace-export.log'
 $code=$LASTEXITCODE
 Get-Content -LiteralPath 'D:\games\youjia-test\assistant-recovery\nearby-input-trace-export.log' -Tail 5
 if($code -ne 0){throw "Trace export failed exit=$code"}
 if((Get-Content -LiteralPath 'D:\games\youjia-test\assistant-recovery\nearby-input-trace-export.log' -Raw) -match '(?m)^(SCRIPT ERROR:|ERROR:)'){throw 'Trace export logged errors'}
 Copy-Item -LiteralPath (Join-Path $repo 'web') -Destination $out -Recurse
 Write-Output 'Diagnostic trace build exported, not production source.'
} finally {
 Copy-Item -LiteralPath $backup -Destination $main
 if((Get-FileHash -LiteralPath $main).Hash -ne (Get-FileHash -LiteralPath $backup).Hash){throw 'Main restore differs from original backup'}
}
