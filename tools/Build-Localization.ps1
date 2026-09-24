$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$strings = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'localization.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$output = Join-Path $repo 'Localization'
New-Item -ItemType Directory -Path $output -Force | Out-Null
foreach ($language in @('INT', 'CHS', 'CHN')) {
    $index = if ($language -eq 'INT') { 0 } else { 1 }
    $lines = @('[WOTCTrainerText]')
    foreach ($property in $strings.PSObject.Properties) {
        $lines += $property.Name + '="' + $property.Value[$index] + '"'
    }
    [IO.File]::WriteAllLines((Join-Path $output ('WOTCTrainerPanel.' + $language)), $lines, [Text.Encoding]::Unicode)
}
Write-Output 'Generated matching INT, CHS and CHN localization files (UTF-16 LE BOM).'
