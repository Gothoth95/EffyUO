# EffyUO updater: downloads only the files that changed (manifest.json + SHA256).
# Started by "Aggiorna EffyUO.bat", which always fetches the latest version of this script.

param(
    [string]$Dir = (Get-Location).Path,
    [string]$Repo = "Gothoth95/EffyUO",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Dir = (Resolve-Path $Dir).Path
$raw = "https://raw.githubusercontent.com/$Repo/$Branch"
$stateDir = Join-Path $Dir ".effyuo"
$statePath = Join-Path $stateDir "installed.json"
$web = New-Object Net.WebClient
$web.Headers.Add("User-Agent", "EffyUO-Updater")

function Say($text, $color = "Gray") { Write-Host $text -ForegroundColor $color }

function Url($path) {
    $parts = $path -split "/" | ForEach-Object { [Uri]::EscapeDataString($_) }
    return "$raw/client/" + ($parts -join "/")
}

Say ""
Say "==============================================" Cyan
Say "  EffyUO - aggiornamento client" Cyan
Say "==============================================" Cyan
Say "Cartella: $Dir"
Say ""

# --- client aperto? ------------------------------------------------------------
$running = Get-Process -Name "cuo", "ClassicUO" -ErrorAction SilentlyContinue | Where-Object {
    try { $_.Path -and $_.Path.StartsWith($Dir, [StringComparison]::OrdinalIgnoreCase) } catch { $false }
}
if ($running) {
    Say "Il client e' aperto: chiudilo e rilancia l'aggiornamento." Red
    exit 1
}

# --- manifest ------------------------------------------------------------------
try {
    $json = $web.DownloadString("$raw/manifest.json?t=" + [DateTime]::UtcNow.Ticks).TrimStart([char]0xFEFF)
    $manifest = $json | ConvertFrom-Json
}
catch {
    Say "Impossibile scaricare la lista dei file: $($_.Exception.Message)" Red
    exit 1
}

Say "Versione disponibile: $($manifest.version)" White
if ($manifest.message) { Say "Novita': $($manifest.message)" White }
Say ""

# --- confronto -----------------------------------------------------------------
$toDownload = New-Object System.Collections.Generic.List[object]
$remotePaths = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

foreach ($f in $manifest.files) {
    [void]$remotePaths.Add($f.path)
    $local = Join-Path $Dir ($f.path -replace "/", "\")

    if (Test-Path -LiteralPath $local) {
        $item = Get-Item -LiteralPath $local
        if ($item.Length -eq [long]$f.size) {
            $hash = (Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash
            if ($hash -ieq $f.sha256) { continue }
        }
    }

    $toDownload.Add($f)
}

# --- download ------------------------------------------------------------------
if ($toDownload.Count -eq 0) {
    Say "Il client e' gia' aggiornato." Green
}
else {
    $total = ($toDownload | Measure-Object -Property size -Sum).Sum
    Say ("Da scaricare: {0} file ({1:N1} MB)" -f $toDownload.Count, ($total / 1MB)) Yellow
    $i = 0

    foreach ($f in $toDownload) {
        $i++
        $local = Join-Path $Dir ($f.path -replace "/", "\")
        $folder = Split-Path -Parent $local
        if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }

        $tmp = "$local.download"
        Write-Host ("[{0}/{1}] {2}" -f $i, $toDownload.Count, $f.path)

        $ok = $false
        for ($try = 1; $try -le 3 -and -not $ok; $try++) {
            try {
                $web.DownloadFile((Url $f.path) + "?t=" + [DateTime]::UtcNow.Ticks, $tmp)
                $hash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash
                if ($hash -ine $f.sha256) { throw "file corrotto (hash diverso)" }
                Move-Item -LiteralPath $tmp -Destination $local -Force
                $ok = $true
            }
            catch {
                if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
                if ($try -eq 3) {
                    Say "   ERRORE: $($_.Exception.Message)" Red
                    Say "Aggiornamento interrotto. Rilancialo tra qualche minuto." Red
                    exit 1
                }
                Start-Sleep -Seconds 2
            }
        }
    }
}

# --- file non piu' usati (solo quelli installati dall'updater) -------------------
if (Test-Path -LiteralPath $statePath) {
    try {
        $old = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        foreach ($p in $old.files) {
            if (-not $remotePaths.Contains($p)) {
                $local = Join-Path $Dir ($p -replace "/", "\")
                if (Test-Path -LiteralPath $local) {
                    Remove-Item -LiteralPath $local -Force
                    Say "Rimosso (non piu' usato): $p" DarkGray
                }
            }
        }
    }
    catch { }
}

if (-not (Test-Path -LiteralPath $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
@{ version = $manifest.version; files = @($manifest.files | ForEach-Object { $_.path }) } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $statePath -Encoding UTF8

# --- prima installazione: impostazioni di base --------------------------------------
$settings = Join-Path $Dir "settings.json"
$defaults = Join-Path $Dir "settings.default.json"
if (-not (Test-Path -LiteralPath $settings) -and (Test-Path -LiteralPath $defaults)) {
    Copy-Item -LiteralPath $defaults -Destination $settings
    Say "Creato settings.json (server UODreams). Al primo avvio controlla la cartella di Ultima Online." Yellow
}

# --- .NET 10 ---------------------------------------------------------------------
$hasRuntime = $false
try { $hasRuntime = [bool](& dotnet --list-runtimes 2>$null | Select-String "^Microsoft\.NETCore\.App 10\.") } catch { }
if (-not $hasRuntime) {
    Say ""
    Say "ATTENZIONE: manca il .NET 10 Runtime, serve per avviare il client." Red
    Say "Installa '.NET Desktop Runtime 10 (x64)' da: https://dotnet.microsoft.com/download/dotnet/10.0" Red
    Start-Process "https://dotnet.microsoft.com/download/dotnet/10.0"
}

Say ""
Say "Fatto. Avvia il client con:" Green
Say "  'Avvia - Assistant interno.bat'   (assistant integrato)" Green
Say "  'Avvia - ClassicAssist.bat'       (con ClassicAssist come plugin)" Green
