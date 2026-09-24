[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedSdk = (Resolve-Path -LiteralPath $SdkRoot).Path
$sourceRoot = Join-Path $resolvedSdk 'Development\SrcOrig'
if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    $sourceRoot = Join-Path $resolvedSdk 'Development\Src'
}
$classesRoot = Join-Path $sourceRoot 'XComGame\Classes'
if (-not (Test-Path -LiteralPath $classesRoot -PathType Container)) {
    throw 'No Development\SrcOrig (or Src)\XComGame\Classes found. No API evidence exported.'
}

# Candidate files and search terms are research leads, not approved API signatures.
$candidateFiles = @(
    'UIAvengerHUD.uc',
    'UIScreenListener.uc',
    'UIScreen.uc',
    'UIPanel.uc',
    'UIButton.uc',
    'UIInputDialog.uc',
    'XComGameState_HeadquartersXCom.uc',
    'XComGameState_Unit.uc',
    'XComGameState_HeadquartersProjectHealSoldier.uc',
    'XComGameStateContext_ChangeContainer.uc',
    'XComGameState.uc',
    'XComGameStateHistory.uc',
    'X2StrategyGameRuleset.uc',
    'X2StrategyElement_DefaultRewards.uc',
    'X2CharacterTemplateManager.uc',
    'X2ItemTemplateManager.uc',
    'X2DownloadableContentInfo.uc'
)
$terms = 'OnInit|InitButton|OnClicked|AddResource|GetResource|AbilityPoints|CreateCharacter|AddToCrew|Heal|SubmitGameState|CreateChangeState|ModifyStateObject|CreateNewStateObject|CleanupPendingGameState'
$files = @()
foreach ($name in $candidateFiles) {
    $file = Join-Path $classesRoot $name
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        $files += [pscustomobject]@{ RelativePath = "XComGame/Classes/$name"; Found = $false }
        continue
    }
    $lines = @(Get-Content -LiteralPath $file)
    $declarations = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '\b(function|event|var)\b' -and $lines[$i] -match $terms) {
            $declarations += [pscustomobject]@{ Line = ($i + 1); Text = $lines[$i].Trim() }
        }
    }
    $files += [pscustomobject]@{
        RelativePath = "XComGame/Classes/$name"
        Found = $true
        Sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        LineCount = $lines.Count
        CandidateDeclarations = $declarations
        ApiReviewed = $false
    }
}
$index = [ordered]@{
    ExportedAt = (Get-Date).ToString('o')
    SdkRoot = $resolvedSdk
    SourceRoot = $sourceRoot
    Note = 'Candidate declarations only. Read full implementations and callers before approving any API. No SDK source is copied.'
    Files = $files
    ApiApproved = $false
}
$evidenceRoot = Join-Path $repoRoot 'evidence'
New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$outputPath = Join-Path $evidenceRoot 'source-index.json'
[IO.File]::WriteAllText($outputPath, ($index | ConvertTo-Json -Depth 8) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Write-Output "Source index: $outputPath"
Write-Output 'API review is still required. This index does not authorize game API calls.'
