# Checks that relative Markdown links and #anchors in tracked documentation resolve.
param()
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
function Get-Anchors([string]$File) {
    $inFence = $false
    foreach ($line in Get-Content -LiteralPath $File) {
        if ($line -match '^\s*```') { $inFence = !$inFence; continue }
        if (!$inFence -and $line -match '^#{1,6}\s+(.+?)\s*$') {
            $text = $Matches[1] -replace '`', ''
            ($text.ToLowerInvariant() -replace '[^\p{L}\p{Nd}\s_-]', '' -replace '\s', '-')
        }
    }
}
$files = @(git -C $repoRoot ls-files '*.md') + @(git -C $repoRoot ls-files --others --exclude-standard '*.md') | Sort-Object -Unique
$broken = [Collections.Generic.List[string]]::new()
foreach ($relative in $files) {
    $file = Join-Path $repoRoot $relative
    if (!(Test-Path -LiteralPath $file)) { continue }
    $content = (Get-Content -LiteralPath $file -Raw) -replace '(?s)```.*?```', ''
    foreach ($match in [regex]::Matches($content, '\]\(([^)\s]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?:|mailto:)') { continue }
        $path, $anchor = $target.Split('#', 2)
        $resolved = if ($path) { [IO.Path]::GetFullPath((Join-Path (Split-Path $file) $path)) } else { $file }
        if (!(Test-Path -LiteralPath $resolved)) { $broken.Add("${relative}: missing $target"); continue }
        if ($anchor -and $resolved.EndsWith('.md') -and $anchor -notin @(Get-Anchors $resolved)) { $broken.Add("${relative}: missing anchor $target") }
    }
}
if ($broken.Count) { $broken | ForEach-Object { Write-Host $_ }; throw "$($broken.Count) broken documentation link(s)." }
Write-Host "Documentation links OK ($($files.Count) Markdown files)."
