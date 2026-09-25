[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SdkRuntime
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runtime = (Resolve-Path -LiteralPath $SdkRuntime).Path.TrimEnd('\')
$workspace = [IO.Path]::GetFullPath((Join-Path $repo '..\..\work')).TrimEnd('\')
if (-not $runtime.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SdkRuntime must be an isolated copy under this task workspace work directory. Never pass the Steam SDK installation.'
}
$compiler = Join-Path $runtime 'Binaries\Win64\XComGame.com'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) { throw 'SDK compiler not found.' }
$modName = 'WOTCTrainerPanel'
$stage = Join-Path $runtime "XComGame\Mods\$modName"
$moduleSource = Join-Path $runtime "Development\Src\$modName"
# These are exact, dedicated build directories inside the verified workspace runtime.
foreach ($target in @($stage, $moduleSource)) {
    $absolute = [IO.Path]::GetFullPath($target)
    if (-not $absolute.StartsWith($runtime + '\', [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($absolute) -ne $modName) { throw 'Unsafe build target.' }
    if (Test-Path -LiteralPath $absolute) { Remove-Item -LiteralPath $absolute -Recurse -Force }
    New-Item -ItemType Directory -Path $absolute -Force | Out-Null
}
& robocopy (Join-Path $runtime 'Development\SrcOrig') (Join-Path $runtime 'Development\Src') '*.uc' '*.uci' /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'Failed to stage SDK source.' }
Copy-Item -LiteralPath (Join-Path $repo "Src\$modName\Classes") -Destination $moduleSource -Recurse
foreach ($folder in @('Config', 'Localization')) {
    $source = Join-Path $repo $folder
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $stage -Recurse }
}
New-Item -ItemType Directory -Path (Join-Path $stage 'Script') -Force | Out-Null
$metadata = "[mod]`r`npublishedFileId=0`r`nTitle=WOTC Trainer Panel`r`nDescription=Local trainer panel for strategy, barracks, items and mission controls`r`nRequiresXPACK=true`r`n"
[IO.File]::WriteAllText((Join-Path $stage "$modName.XComMod"), $metadata, [Text.UTF8Encoding]::new($false))
$binary = Join-Path $runtime "XComGame\Script\$modName.u"
if (Test-Path -LiteralPath $binary) { Remove-Item -LiteralPath $binary -Force }
$evidence = Join-Path $repo 'evidence'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $evidence "build-$timestamp.txt"
$sourceFiles = @(Get-ChildItem -LiteralPath (Join-Path $repo 'Src'), (Join-Path $repo 'Config'), (Join-Path $repo 'Localization') -Recurse -File | Sort-Object FullName | ForEach-Object {
    [pscustomobject]@{ Path = $_.FullName.Substring($repo.Length + 1).Replace('\', '/'); SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
})
$argsList = @('make', '-nopause', '-unattended', '-nohomedir', '-mods', $modName, ($stage + '\'))
Push-Location (Split-Path -Parent $compiler)
try {
    & $compiler @argsList 2>&1 | Out-File -LiteralPath $log -Encoding utf8
    $compilerExit = $LASTEXITCODE
} finally { Pop-Location }
Get-Content -LiteralPath $log -Tail 18 | Write-Output
$summary = @(Select-String -LiteralPath $log -Pattern '^Success - 0 error' | ForEach-Object Line)
$modWarnings = @(Select-String -LiteralPath $log -Pattern 'WOTCTrainerPanel\\Classes.*: Warning,').Count
$success = $compilerExit -eq 0 -and $summary.Count -gt 0 -and (Test-Path -LiteralPath $binary -PathType Leaf)
$result = [ordered]@{
    Time = (Get-Date).ToString('o'); Compiler = $compiler; Arguments = $argsList
    ExitCode = $compilerExit; BinaryExists = (Test-Path -LiteralPath $binary -PathType Leaf)
    BuildSucceeded = $success; Log = $log; InGameVerified = $false
    CompilerSummary = $summary; ModWarningCount = $modWarnings; SourceFiles = $sourceFiles
}
if ($success) {
    Copy-Item -LiteralPath $binary -Destination (Join-Path $stage "Script\$modName.u") -Force
    $result.BinarySHA256 = (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash
}
[IO.File]::WriteAllText((Join-Path $evidence 'latest-build.json'), ($result | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
if (-not $success) { throw "Compilation did not produce a verified script package. See $log" }
Write-Output "Compiled mod staging directory: $stage"
