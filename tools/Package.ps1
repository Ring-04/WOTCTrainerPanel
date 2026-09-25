[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SdkRuntime,
    [string]$Version = '0.9.0-beta'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runtime = (Resolve-Path -LiteralPath $SdkRuntime).Path.TrimEnd('\')
$workspace = [IO.Path]::GetFullPath((Join-Path $repo '..\..\work')).TrimEnd('\')
if (-not $runtime.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SdkRuntime must be an isolated copy under this task workspace work directory. Never pass the Steam SDK installation.'
}
if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+-[A-Za-z0-9.-]+$') { throw 'Version must look like 0.9.0-beta.' }
$modName = 'WOTCTrainerPanel'
$stage = Join-Path $runtime "XComGame\Mods\$modName"
if (-not (Test-Path -LiteralPath (Join-Path $stage "$modName.XComMod") -PathType Leaf)) {
    throw "No staged mod directory at $stage. Run tools\Build.ps1 first."
}
$buildFile = Join-Path $repo 'evidence\latest-build.json'
if (-not (Test-Path -LiteralPath $buildFile -PathType Leaf)) { throw 'evidence\latest-build.json is missing. Run tools\Build.ps1 first.' }
$build = Get-Content -LiteralPath $buildFile -Raw | ConvertFrom-Json
if (-not $build.BuildSucceeded) { throw 'The latest recorded build did not succeed; refusing to package it.' }
$packageName = "$modName-v$Version"
$outRoot = Join-Path $repo 'dist'
$packageDir = Join-Path $outRoot $packageName
# dist is a disposable build artifact directory; the checked-in source and the verified staging
# directory are the only inputs, so a stale package is always safe to delete.
$absoluteOut = [IO.Path]::GetFullPath($outRoot)
if (-not $absoluteOut.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($absoluteOut) -ne 'dist') { throw 'Unsafe package target.' }
if (Test-Path -LiteralPath $packageDir) { Remove-Item -LiteralPath $packageDir -Recurse -Force }
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
$modDir = Join-Path $packageDir $modName
Copy-Item -LiteralPath $stage -Destination $modDir -Recurse
$doc = Join-Path $repo 'docs\INSTALL-AND-TEST.zh-CN.md'
$hasDoc = Test-Path -LiteralPath $doc -PathType Leaf
foreach ($readme in @('README.md', 'README.zh-CN.md')) {
    $readmeSource = Join-Path $repo $readme
    if (Test-Path -LiteralPath $readmeSource -PathType Leaf) {
        Copy-Item -LiteralPath $readmeSource -Destination (Join-Path $packageDir $readme)
    }
}
if ($hasDoc) {
    $docTarget = Join-Path $packageDir 'docs'
    New-Item -ItemType Directory -Path $docTarget -Force | Out-Null
    Copy-Item -LiteralPath $doc -Destination (Join-Path $docTarget 'INSTALL-AND-TEST.zh-CN.md')
}
$files = @(Get-ChildItem -LiteralPath $modDir -Recurse -File | Sort-Object FullName | ForEach-Object {
    [pscustomobject]@{ Path = $_.FullName.Substring($packageDir.Length + 1).Replace('\', '/'); Bytes = $_.Length; SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
})
$binaryEntry = $files | Where-Object { $_.Path -eq "$modName/Script/$modName.u" }
if ($null -eq $binaryEntry) { throw 'The packaged script package is missing.' }
if ($binaryEntry.SHA256 -ne $build.BinarySHA256) {
    throw "Packaged binary $($binaryEntry.SHA256) does not match the verified build $($build.BinarySHA256). Rebuild before packaging."
}
$installDoc = ''
if ($hasDoc) { $installDoc = 'docs/INSTALL-AND-TEST.zh-CN.md' }
$manifest = [ordered]@{
    Package = $packageName
    ModName = $modName
    Version = $Version
    BuiltAt = $build.Time
    BuildLog = Split-Path -Leaf $build.Log
    CompilerSummary = $build.CompilerSummary
    ModWarningCount = $build.ModWarningCount
    InGameVerified = $false
    InstallsAs = $modName
    LaunchOptions = 'War of the Chosen; no -allowconsole required'
    InstallDoc = $installDoc
    Files = $files
}
[IO.File]::WriteAllText((Join-Path $packageDir 'PACKAGE.json'), ($manifest | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
$zip = Join-Path $outRoot "$packageName.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $packageDir -DestinationPath $zip -CompressionLevel Optimal
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Output "Package folder: $packageDir"
Write-Output "Package zip:    $zip"
Write-Output "Zip SHA256:     $zipHash"
Write-Output "Script SHA256:  $($binaryEntry.SHA256)"
Write-Output "Source of truth: build $($build.Time), $($build.CompilerSummary -join '; '), mod warnings $($build.ModWarningCount)"
