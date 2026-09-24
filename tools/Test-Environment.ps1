[CmdletBinding()]
param(
    [string]$SdkRoot,
    [string]$GameRoot,
    [string]$SteamRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$evidenceRoot = Join-Path $repoRoot 'evidence'

function Get-SdkStatus([string]$Candidate) {
    $sourceRoot = [IO.Path]::Combine($Candidate, 'Development\SrcOrig')
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        $sourceRoot = [IO.Path]::Combine($Candidate, 'Development\Src')
    }
    $requiredSources = @(
        'Core\Classes\Object.uc',
        'Engine\Classes\Actor.uc',
        'XComGame\Classes\XComGameState_HeadquartersXCom.uc',
        'XComGame\Classes\XComGameState_Unit.uc',
        'XComGame\Classes\XComGameState_ResistanceFaction.uc'
    )
    $missing = @($requiredSources | Where-Object {
        -not [IO.File]::Exists([IO.Path]::Combine($sourceRoot, $_))
    })
    $compiler = [IO.Path]::Combine($Candidate, 'Binaries\Win64\XComGame.com')
    $compilerPresent = Test-Path -LiteralPath $compiler -PathType Leaf
    [pscustomobject]@{
        Root = $Candidate
        Exists = (Test-Path -LiteralPath $Candidate -PathType Container)
        SourceRoot = $sourceRoot
        MissingSourceFiles = $missing
        Compiler = $compiler
        CompilerFilePresent = $compilerPresent
        BasicFilesPresent = ($missing.Count -eq 0 -and $compilerPresent)
        Note = 'File presence only; version, API semantics, build templates and compiler execution still require verification.'
    }
}

$steamRoots = @()
if ($SteamRoot) { $steamRoots += $SteamRoot }
$steamRegistry = Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
if ($null -ne $steamRegistry -and $steamRegistry.PSObject.Properties['SteamPath']) {
    $steamRoots += $steamRegistry.SteamPath
}
foreach ($process in @(Get-Process -Name steam -ErrorAction SilentlyContinue)) {
    if ($process.Path) { $steamRoots += Split-Path -Parent $process.Path }
}
$steamRoots += @('C:\Program Files (x86)\Steam', 'D:\steam')
$steamRoots = @($steamRoots | Sort-Object -Unique)

$libraries = @('C:\SteamLibrary', 'D:\SteamLibrary')
$libraryFiles = @()
foreach ($root in $steamRoots) {
    if (Test-Path -LiteralPath (Join-Path $root 'steamapps') -PathType Container) {
        $libraries += $root
    }
    $libraryFile = Join-Path $root 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $libraryFile -PathType Leaf) {
        $libraryFiles += $libraryFile
        $vdf = Get-Content -LiteralPath $libraryFile -Raw
        foreach ($match in [regex]::Matches($vdf, '"path"\s+"([^"]+)"')) {
            $libraries += $match.Groups[1].Value.Replace('\\', '\')
        }
    }
}
$libraries = @($libraries | Sort-Object -Unique)

if ($SdkRoot) {
    $sdkCandidates = @([IO.Path]::GetFullPath($SdkRoot))
} else {
    $sdkCandidates = @($libraries | ForEach-Object {
        [IO.Path]::Combine($_, 'steamapps\common\XCOM 2 War of the Chosen SDK')
    })
}
$sdkChecks = @($sdkCandidates | ForEach-Object { Get-SdkStatus $_ })

if ($GameRoot) {
    $gameCandidates = @([IO.Path]::GetFullPath($GameRoot))
} else {
    $gameCandidates = @($libraries | ForEach-Object {
        [IO.Path]::Combine($_, 'steamapps\common\XCOM 2\XCom2-WarOfTheChosen')
    })
}
$gameChecks = @($gameCandidates | ForEach-Object {
    [pscustomobject]@{
        Root = $_
        GameExePresent = [IO.File]::Exists([IO.Path]::Combine($_, 'Binaries\Win64\XCom2.exe'))
    }
})

$documentsRoot = [Environment]::GetFolderPath('MyDocuments')
$userGameRoot = Join-Path $documentsRoot 'My Games\XCOM2 War of the Chosen\XComGame'
$engineIni = Join-Path $userGameRoot 'Config\XComEngine.ini'
$launchLog = Join-Path $userGameRoot 'Logs\Launch.log'
$configuredLanguage = $null
$oldCommandLine = $null
$logTimestamp = $null
if (Test-Path -LiteralPath $engineIni -PathType Leaf) {
    $languageLines = @(Select-String -LiteralPath $engineIni -Pattern '^\s*Language\s*=')
    if ($languageLines.Count -gt 0) { $configuredLanguage = $languageLines[-1].Line.Trim() }
}
if (Test-Path -LiteralPath $launchLog -PathType Leaf) {
    $logTimestamp = (Get-Item -LiteralPath $launchLog).LastWriteTime.ToString('o')
    $commandLines = @(Get-Content -LiteralPath $launchLog -TotalCount 40 | Where-Object {
        $_ -match '^Init: Command line:'
    })
    if ($commandLines.Count -gt 0) { $oldCommandLine = $commandLines[0] }
}

$sdkFound = @($sdkChecks | Where-Object BasicFilesPresent).Count -gt 0
$gameFound = @($gameChecks | Where-Object GameExePresent).Count -gt 0
$blockers = @()
if (-not $sdkFound) { $blockers += 'WOTC SDK with source and compiler not found in checked candidates.' }
if (-not $gameFound) { $blockers += 'WOTC game executable not found in checked candidates.' }

$report = [ordered]@{
    CheckedAt = (Get-Date).ToString('o')
    Scope = 'Read-only checks; writes only this report inside the mod repository. No recursive whole-disk scan.'
    SteamLibraryFiles = $libraryFiles
    SteamLibraries = $libraries
    Sdk = $sdkChecks
    Game = $gameChecks
    ExistingUserEnvironment = [ordered]@{
        ConfigPath = $engineIni
        ConfiguredLanguage = $configuredLanguage
        LaunchLogPath = $launchLog
        LaunchLogLastWriteTime = $logTimestamp
        PreviousCommandLine = $oldCommandLine
        GameRunning = (@(Get-Process -Name XCom2 -ErrorAction SilentlyContinue).Count -gt 0)
        Note = 'Existing environment only; not a test result for this mod.'
    }
    BasicPrerequisitesPresent = ($sdkFound -and $gameFound)
    Blockers = $blockers
    Compilation = 'NOT_RUN'
    InGameVerification = 'NOT_RUN'
    SaveLoadVerification = 'NOT_RUN'
    Phase1Passed = $false
    Phase2Allowed = $false
}
New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$reportPath = Join-Path $evidenceRoot 'environment.json'
$json = $report | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($reportPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Write-Output "Environment report: $reportPath"
Write-Output "Basic prerequisites present: $($report.BasicPrerequisitesPresent)"
foreach ($blocker in $blockers) { Write-Output "BLOCKED: $blocker" }
Write-Output 'Phase 1 has not passed. Compilation and in-game tests have not run.'
if ($blockers.Count -gt 0) { exit 2 }
exit 0
