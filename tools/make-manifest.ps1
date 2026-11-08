# Writes manifest.json for the files in client\ (path, size, sha256) - same format as make-manifest.py.
param([string]$Message = "")
$root = Split-Path -Parent $PSScriptRoot
$client = Join-Path $root "client"
$files = Get-ChildItem -LiteralPath $client -Recurse -File | ForEach-Object {
    [ordered]@{
        path   = $_.FullName.Substring($client.Length + 1).Replace("\", "/")
        size   = $_.Length
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
} | Sort-Object { $_.path.ToLowerInvariant() }
$manifest = [ordered]@{ version = (Get-Date -Format "yyyy.MM.dd-HHmm"); message = $Message; files = @($files) }
$json = $manifest | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText((Join-Path $root "manifest.json"), $json, (New-Object Text.UTF8Encoding $false))
Write-Host ("{0} file -> versione {1}" -f $files.Count, $manifest.version)
