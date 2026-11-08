# Publishes a new client version to the EffyUO repo (run from a clone of the repo).
#   powershell -ExecutionPolicy Bypass -File tools\publish.ps1 -Build <cuo build folder> -Launcher <bootstrap build folder> -Message "novita'"
# Copies the build into client\ (no .pdb, only Windows runtimes), keeps the launchers and
# settings.default.json, rewrites manifest.json, commits and pushes.

param(
    [Parameter(Mandatory = $true)][string]$Build,
    [string]$Launcher = "",
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$client = Join-Path $root "client"
$keep = @("Avvia - Assistant interno.bat", "Avvia - ClassicAssist.bat", "settings.default.json")

function Wanted([string]$rel) {
    if ($rel -like "*.pdb") { return $false }
    $parts = $rel -split "\\"
    if ($parts[0] -eq "runtimes" -and $parts.Count -gt 1 -and -not $parts[1].StartsWith("win")) { return $false }
    return $true
}

$Build = (Resolve-Path $Build).Path
$new = @{}

Get-ChildItem -LiteralPath $Build -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Build.Length + 1)
    if (Wanted $rel) { $new[$rel] = $_.FullName }
}

if ($Launcher -and (Test-Path -LiteralPath $Launcher)) {
    $Launcher = (Resolve-Path $Launcher).Path
    Get-ChildItem -LiteralPath $Launcher -File | Where-Object { $_.Extension -ne ".pdb" } | ForEach-Object {
        $new["Launcher\" + $_.Name] = $_.FullName
    }
}

# Copy new/changed files.
$copied = 0
foreach ($rel in $new.Keys) {
    $dest = Join-Path $client $rel
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $dest) -or (Get-FileHash -LiteralPath $dest).Hash -ne (Get-FileHash -LiteralPath $new[$rel]).Hash) {
        Copy-Item -LiteralPath $new[$rel] -Destination $dest -Force
        $copied++
    }
}

# Remove files that are no longer in the build (except the kept ones).
$removed = 0
Get-ChildItem -LiteralPath $client -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($client.Length + 1)
    if (-not $new.ContainsKey($rel) -and $keep -notcontains $rel) {
        Remove-Item -LiteralPath $_.FullName -Force
        $removed++
    }
}

Write-Host "Copiati/aggiornati: $copied, rimossi: $removed"
& (Join-Path $PSScriptRoot "make-manifest.ps1") -Message $Message

Push-Location $root
try {
    git add -A
    git commit -m ("Client " + (Get-Content manifest.json -Raw | ConvertFrom-Json).version + $(if ($Message) { " - $Message" } else { "" }))
    git push origin HEAD:main
}
finally {
    Pop-Location
}
