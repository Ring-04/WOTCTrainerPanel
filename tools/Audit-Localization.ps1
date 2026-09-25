[CmdletBinding()]
param(
    [string]$RepoRoot
)

# Read-only localization gate. It never writes to the repository: it inspects
# WOTCTrainerText.uc, tools\localization.json, the three generated language files
# and every .uc source file, then exits non-zero if any metric is not zero.
#
# Metrics that must all be 0: missing keys, extra keys, per-language missing /
# extra / empty / duplicate / unquoted values, value drift, key-order drift,
# undeclared code references, hardcoded user-visible labels. Encoding, BOM,
# section header and line endings are checked as booleans.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
$repo = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd('\')
$classDir = Join-Path $repo 'Src\WOTCTrainerPanel\Classes'
$textClass = Join-Path $classDir 'WOTCTrainerText.uc'
$tablePath = Join-Path $repo 'tools\localization.json'
$languages = @('INT', 'CHN', 'CHS')

foreach ($required in @($textClass, $tablePath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Audit input missing: $required" }
}

$failures = @()

# --- declarations ---------------------------------------------------------
$declared = New-Object Collections.Generic.List[string]
$declarationText = [IO.File]::ReadAllText($textClass)
foreach ($match in [regex]::Matches($declarationText, 'var\s+localized\s+string\s+([^;]+);')) {
    foreach ($part in $match.Groups[1].Value.Split(',')) {
        $piece = $part.Trim()
        $array = [regex]::Match($piece, '^([A-Za-z_][A-Za-z0-9_]*)\s*\[\s*(\d+)\s*\]$')
        if ($array.Success) {
            $count = [int]$array.Groups[2].Value
            for ($i = 0; $i -lt $count; $i++) { $declared.Add($array.Groups[1].Value + '[' + $i + ']') }
        } elseif ($piece -match '^[A-Za-z_][A-Za-z0-9_]*$') {
            $declared.Add($piece)
        } else {
            throw "Unparsed localized string declaration: '$piece'"
        }
    }
}

# --- source table ---------------------------------------------------------
$table = [IO.File]::ReadAllText($tablePath) | ConvertFrom-Json
$tableOrder = New-Object Collections.Generic.List[string]
foreach ($property in $table.PSObject.Properties) {
    if ($property.Value.Count -ne 2) { throw "$($property.Name) must hold exactly [English, Chinese]" }
    $tableOrder.Add($property.Name)
}

$declaredSet = New-Object 'Collections.Generic.HashSet[string]'
foreach ($key in $declared) { [void]$declaredSet.Add($key) }
$tableSet = New-Object 'Collections.Generic.HashSet[string]'
foreach ($key in $tableOrder) { [void]$tableSet.Add($key) }

$missing = @($declared | Where-Object { -not $tableSet.Contains($_) })
$extra = @($tableOrder | Where-Object { -not $declaredSet.Contains($_) })

Write-Output '== key coverage =='
Write-Output ("declared in WOTCTrainerText.uc: {0}" -f $declared.Count)
Write-Output ("source table keys:             {0}" -f $tableOrder.Count)
Write-Output ("missing = {0}" -f $missing.Count)
Write-Output ("extra = {0}" -f $extra.Count)
foreach ($key in $missing) { Write-Output "  missing: $key" }
foreach ($key in $extra) { Write-Output "  extra:   $key" }
if ($missing.Count) { $failures += 'missing keys' }
if ($extra.Count) { $failures += 'extra keys' }

# --- language files -------------------------------------------------------
function Read-LanguageFile([string]$Code) {
    $path = Join-Path $repo ('Localization\WOTCTrainerPanel.' + $Code)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Language file missing: $path" }
    $bytes = [IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE
    $text = [Text.Encoding]::Unicode.GetString($bytes)
    if ($text.Length -and [int]$text[0] -eq 0xFEFF) { $text = $text.Substring(1) }
    $entries = @{}
    $order = New-Object Collections.Generic.List[string]
    $duplicates = 0
    $unquoted = 0
    $empty = 0
    foreach ($line in ($text -split "\r\n")) {
        $trimmed = $line.Trim()
        if (-not $trimmed) { continue }
        if ($trimmed -match '^\[.+\]$') { continue }
        $equals = $trimmed.IndexOf('=')
        if ($equals -lt 0) { continue }
        $key = $trimmed.Substring(0, $equals).Trim()
        $value = $trimmed.Substring($equals + 1).Trim()
        if ($value.Length -lt 2 -or -not $value.StartsWith('"') -or -not $value.EndsWith('"')) { $unquoted++; continue }
        $value = $value.Substring(1, $value.Length - 2)
        if ($entries.ContainsKey($key)) { $duplicates++ }
        $entries[$key] = $value
        $order.Add($key)
        if (-not $value.Trim()) { $empty++ }
    }
    [pscustomobject]@{
        Code = $Code
        HasBom = $hasBom
        Section = [bool]($text -match '^\s*\[WOTCTrainerText\]')
        MixedEol = [bool]([regex]::IsMatch($text, '[^\r]\n') -or [regex]::IsMatch($text, '\r[^\n]'))
        Entries = $entries
        Order = $order
        Duplicates = $duplicates
        Unquoted = $unquoted
        Empty = $empty
    }
}

Write-Output ''
Write-Output '== language files =='
foreach ($code in $languages) {
    $language = Read-LanguageFile $code
    $short = @($tableOrder | Where-Object { -not $language.Entries.ContainsKey($_) })
    $surplus = @($language.Order | Where-Object { -not $tableSet.Contains($_) })
    $column = 0
    if ($code -ne 'INT') { $column = 1 }
    $wrong = @($language.Order | Where-Object {
        $tableSet.Contains($_) -and $language.Entries[$_] -ne $table.PSObject.Properties[$_].Value[$column]
    })
    $orderOk = $language.Order.Count -eq $tableOrder.Count
    if ($orderOk) {
        for ($i = 0; $i -lt $tableOrder.Count; $i++) {
            if ($language.Order[$i] -ne $tableOrder[$i]) { $orderOk = $false; break }
        }
    }
    Write-Output ("{0}  keys={1} missing={2} extra={3} empty={4} duplicate={5} unquoted={6} drift={7} UTF-16LE+{8} {9} section={10} order={11}" -f `
        $code, $language.Entries.Count, $short.Count, $surplus.Count, $language.Empty, $language.Duplicates, `
        $language.Unquoted, $wrong.Count, $(if ($language.HasBom) { 'BOM' } else { 'NO-BOM' }), `
        $(if ($language.MixedEol) { 'MIXED-EOL' } else { 'CRLF' }), `
        $(if ($language.Section) { 'WOTCTrainerText' } else { 'MISSING' }), `
        $(if ($orderOk) { 'declaration-order' } else { 'DIFFERENT' }))
    foreach ($key in $short) { Write-Output "  missing: $key" }
    foreach ($key in $surplus) { Write-Output "  extra:   $key" }
    foreach ($key in $wrong) { Write-Output "  drift:   $key" }
    if ($short.Count) { $failures += "$code missing keys" }
    if ($surplus.Count) { $failures += "$code extra keys" }
    if ($language.Empty) { $failures += "$code empty values" }
    if ($language.Duplicates) { $failures += "$code duplicate entries" }
    if ($language.Unquoted) { $failures += "$code unquoted values" }
    if ($wrong.Count) { $failures += "$code value drift" }
    if (-not $orderOk) { $failures += "$code key order" }
    if (-not $language.HasBom) { $failures += "$code UTF-16LE BOM" }
    if ($language.MixedEol) { $failures += "$code mixed line endings" }
    if (-not $language.Section) { $failures += "$code section header" }
}

# --- code references ------------------------------------------------------
$refsChecked = 0
$refsUndeclared = @()
$usedNames = New-Object 'Collections.Generic.HashSet[string]'
$ucFiles = @(Get-ChildItem -LiteralPath $classDir -Filter '*.uc' -File | Sort-Object Name)
foreach ($file in $ucFiles) {
    $text = [IO.File]::ReadAllText($file.FullName)
    $pattern = 'WOTCTrainerText''\.default\.([A-Za-z_][A-Za-z0-9_]*)'
    if ($file.Name -eq 'WOTCTrainerText.uc') { $pattern = 'default\.([A-Za-z_][A-Za-z0-9_]*)' }
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $name = $match.Groups[1].Value
        if ($declaredSet.Contains($name)) { $refsChecked++; [void]$usedNames.Add($name); continue }
        if ($declaredSet.Contains($name + '[0]')) {
            for ($i = 0; $declaredSet.Contains($name + '[' + $i + ']'); $i++) {
                $refsChecked++
                [void]$usedNames.Add($name + '[' + $i + ']')
            }
            continue
        }
        $refsUndeclared += "$($file.Name): $name"
    }
}
$unused = @($declared | Where-Object { -not $usedNames.Contains($_) })
Write-Output ''
Write-Output '== code references =='
Write-Output ("references checked: {0}" -f $refsChecked)
Write-Output ("undeclared references = {0}" -f $refsUndeclared.Count)
foreach ($reference in $refsUndeclared) { Write-Output "  undeclared: $reference" }
Write-Output ("declared but never referenced (informational): {0}" -f $unused.Count)
foreach ($key in $unused) { Write-Output "  unused: $key" }
if ($refsUndeclared.Count) { $failures += 'undeclared code references' }

# --- hardcoded user-visible labels ---------------------------------------
# Comments and `log statements are blanked out with newlines preserved, then a
# quoted literal is flagged only when it carries letters or CJK and sits in an
# assignment statement or in a statement that calls a text sink. Identifier-like
# literals, markup-only literals and [X]-style markers are not labels.
function Remove-NonSourceText([string]$Text) {
    $out = New-Object Text.StringBuilder
    $logsStripped = 0
    $length = $Text.Length
    $index = 0
    while ($index -lt $length) {
        $lineComment = $Text.IndexOf('//', $index)
        $blockComment = $Text.IndexOf('/*', $index)
        $logCall = $Text.IndexOf('`log', $index)
        $candidates = @($lineComment, $blockComment, $logCall) | Where-Object { $_ -ge 0 }
        if (-not $candidates) { [void]$out.Append($Text.Substring($index)); break }
        $next = ($candidates | Measure-Object -Minimum).Minimum
        if ($next -gt $index) { [void]$out.Append($Text.Substring($index, $next - $index)) }
        if ($next -eq $lineComment) {
            $end = $Text.IndexOf("`n", $next)
            if ($end -lt 0) { $end = $length }
            [void]$out.Append(([regex]::Replace($Text.Substring($next, $end - $next), '[^\n]', ' ')))
            $index = $end
        } elseif ($next -eq $blockComment) {
            $end = $Text.IndexOf('*/', $next + 2)
            if ($end -lt 0) { $end = $length } else { $end = $end + 2 }
            [void]$out.Append(([regex]::Replace($Text.Substring($next, $end - $next), '[^\n]', ' ')))
            $index = $end
        } else {
            $cursor = $next + 4
            $depth = 0
            $inString = $false
            $started = $false
            while ($cursor -lt $length) {
                $character = $Text[$cursor]
                if ($inString) {
                    if ($character -eq '"') { $inString = $false }
                    $cursor++
                    continue
                }
                if ($character -eq '"') { $inString = $true; $cursor++; continue }
                if ($character -eq '(') { $depth++; $started = $true; $cursor++; continue }
                if ($character -eq ')') {
                    $depth--
                    $cursor++
                    if ($started -and $depth -eq 0) { break }
                    continue
                }
                if (-not $started -and $character -eq ';') { $cursor++; break }
                $cursor++
            }
            $stop = [Math]::Min($cursor, $length)
            [void]$out.Append(([regex]::Replace($Text.Substring($next, $stop - $next), '[^\n]', ' ')))
            $logsStripped++
            $index = $stop
        }
    }
    [pscustomobject]@{ Text = $out.ToString(); LogsStripped = $logsStripped }
}

$sinks = @('SetText(', 'AddText(', 'AddButton(', 'ShowConfirmation(', 'strTitle', 'strText', 'strBody')
$literalsSeen = 0
$logsSeen = 0
$logsStripped = 0
$flagged = @()
foreach ($file in $ucFiles) {
    $raw = [IO.File]::ReadAllText($file.FullName)
    $logsSeen += [regex]::Matches($raw, '`log\s*\(').Count
    $stripped = Remove-NonSourceText $raw
    $logsStripped += $stripped.LogsStripped
    $text = $stripped.Text
    $offset = 0
    while ($offset -le $text.Length) {
        $semicolon = $text.IndexOf(';', $offset)
        $hasMore = $semicolon -ge 0
        if ($hasMore) { $statement = $text.Substring($offset, $semicolon - $offset) } else { $statement = $text.Substring($offset) }
        $literals = [regex]::Matches($statement, '"([^"\n]*)"')
        if ($literals.Count) {
            $literalsSeen += $literals.Count
            # a statement may begin with the closing brace of the previous block, e.g. "} Result = ..."
            $head = $statement -replace '^[\s}]+', ''
            $isAssignment = [bool]($head -match '^[A-Za-z_][A-Za-z0-9_]*\s*\$?=')
            $isSink = $false
            foreach ($sink in $sinks) { if ($statement.Contains($sink)) { $isSink = $true; break } }
            if ($isAssignment -or $isSink) {
                foreach ($literal in $literals) {
                    $value = $literal.Groups[1].Value
                    if (-not $value.Trim()) { continue }
                    if ($value.Length -le 1) { continue }
                    if ($value.StartsWith('[')) { continue }
                    if ($value -match '^[A-Za-z_][A-Za-z0-9_]*$') { continue }
                    $words = ($value -replace '<[^>]*>', '') -replace '[^A-Za-z\u4e00-\u9fff]+', ' '
                    if (-not $words.Trim()) { continue }
                    $line = ($text.Substring(0, $offset + $literal.Index) -split "\n").Count
                    $flagged += "$($file.Name):$line  `"$value`""
                }
            }
        }
        if (-not $hasMore) { break }
        $offset = $semicolon + 1
    }
}
Write-Output ''
Write-Output '== hardcoded user-visible labels =='
Write-Output ("uc files scanned: {0}" -f $ucFiles.Count)
Write-Output ("string literals examined: {0}" -f $literalsSeen)
Write-Output ("``log calls stripped: {0} of {1}" -f $logsStripped, $logsSeen)
foreach ($label in $flagged) { Write-Output "  label: $label" }
Write-Output ("hardcoded user-visible labels = {0}" -f $flagged.Count)
if ($logsStripped -ne $logsSeen) { $failures += 'log stripping left `log calls behind; the label scan would be wrong' }
if ($flagged.Count) { $failures += 'hardcoded user-visible labels' }
if (-not $literalsSeen) { $failures += 'label scan examined no literals' }

# --- gate -----------------------------------------------------------------
Write-Output ''
if (-not $failures.Count) {
    Write-Output 'localization audit: PASS (all gate metrics are 0)'
    exit 0
}
Write-Output ('localization audit: FAIL -> ' + ($failures -join '; '))
exit 1
