param(
    [Parameter(Mandatory = $true)][string]$GodotExe
)
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$captureRoot = Join-Path ([IO.Path]::GetTempPath()) ('youjia-milling-reproduce-' + [guid]::NewGuid().ToString('N'))
$testData = Join-Path $captureRoot 'appdata'
New-Item -ItemType Directory -Path $testData -Force | Out-Null
$env:APPDATA = $testData
$env:YOUJIA_TEST_ISOLATED_DATA = $testData
$env:YOUJIA_MILL_CAPTURE_DIR = $captureRoot

function Invoke-GodotEvidence([string]$Label, [string[]]$ExtraArgs) {
    $quotedRoot = '"' + $repoRoot + '"'
    $toolArgs = @('--path', $quotedRoot) + $ExtraArgs
    $process = Start-Process -FilePath $GodotExe -ArgumentList $toolArgs -WindowStyle Hidden -PassThru -Wait `
        -RedirectStandardOutput (Join-Path $captureRoot ($Label + '.stdout.log')) `
        -RedirectStandardError (Join-Path $captureRoot ($Label + '.stderr.log'))
    if ($process.ExitCode -ne 0) { throw "$Label failed with exit $($process.ExitCode); inspect $captureRoot" }
}

Invoke-GodotEvidence 'import' @('--headless', '--editor', '--quit')
Invoke-GodotEvidence 'view-suite' @('--headless', '--script', 'res://test/yard_mill_view_suite.gd')
$captureScript = '"' + (Join-Path $PSScriptRoot 'capture.gd') + '"'
Invoke-GodotEvidence 'gpu' @('--script', $captureScript, '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
Write-Output "New isolated evidence: $captureRoot"
