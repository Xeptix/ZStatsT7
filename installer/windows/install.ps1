<##>
# ZStats T7 script installer. The Workshop/mod route remains Steam-owned.
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Find,
    [switch]$Verify,
    [switch]$Configure,
    [ValidateSet('Auto', 'BOIII', 'AppData', 'T7x', 'Compiler', 'All')]
    [string]$Route = 'Auto',
    [string]$To = '',
    [string]$AppDataRoot = '',
    [string]$CompilerRoot = '',
    [string]$LogRoot = '',
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

function Join-ZPath([string]$A, [string]$B) {
    return [IO.Path]::Combine($A, $B)
}

function Find-Payload {
    $at = $PSScriptRoot
    for ($n = 0; $n -lt 4; $n++) {
        if (Test-Path -LiteralPath (Join-ZPath $at 'zstats.release') -PathType Leaf) { return $at }
        $at = Split-Path -Parent $at
    }
    throw 'ZStats T7 payload not found. Extract the complete script ZIP.'
}

function Find-Game {
    if ($To) {
        $candidate = [IO.Path]::GetFullPath($To)
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
            throw "Game folder does not exist: $candidate"
        }
        return $candidate
    }
    $roots = @()
    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        try {
            $item = Get-ItemProperty -Path $key -ErrorAction Stop
            $steam = if ($item.SteamPath) { $item.SteamPath } else { $item.InstallPath }
            if (-not $steam) { continue }
            $roots += $steam
            $vdf = Join-ZPath $steam 'steamapps\libraryfolders.vdf'
            if (Test-Path -LiteralPath $vdf -PathType Leaf) {
                $raw = Get-Content -LiteralPath $vdf -Raw
                foreach ($match in [regex]::Matches($raw, '"path"\s*"([^"]+)"')) {
                    $roots += $match.Groups[1].Value.Replace('\\', '\')
                }
            }
        } catch { continue }
    }
    foreach ($root in @($roots | Select-Object -Unique)) {
        $common = Join-ZPath $root 'steamapps\common'
        if (-not (Test-Path -LiteralPath $common -PathType Container)) { continue }
        foreach ($folder in @(Get-ChildItem -LiteralPath $common -Directory -ErrorAction SilentlyContinue)) {
            if ($folder.Name -notlike '*Black Ops III*' -or $folder.Name -like '*455130*') { continue }
            foreach ($exe in @('BlackOps3.exe', 'boiii.exe', 't7x.exe')) {
                if (Test-Path -LiteralPath (Join-ZPath $folder.FullName $exe) -PathType Leaf) {
                    return $folder.FullName
                }
            }
        }
    }
    return $null
}

function Hash-ZFile([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Confirm-ZAction([string]$Text) {
    if ($Yes) { return $true }
    try { $answer = Read-Host "$Text [y/N]" } catch { return $false }
    return $answer -match '^(?i:y(?:es)?)$'
}

function Is-ZOwned([string]$Path) {
    $marker = "$Path.zstats.sha256"
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf) -or
        -not (Test-Path -LiteralPath $marker -PathType Leaf)) { return $false }
    return (Hash-ZFile $Path) -eq (Get-Content -LiteralPath $marker -Raw).Trim().ToLowerInvariant()
}

function Log-ZAction([string]$Text) {
    Add-Content -LiteralPath $script:LogPath -Value "$(Get-Date -Format o) $Text"
}

function Prepare-ZLog {
    $state = if ($LogRoot) { [IO.Path]::GetFullPath($LogRoot) }
             elseif ($env:LOCALAPPDATA) { Join-ZPath $env:LOCALAPPDATA 'ZStatsInstaller' }
             else { throw 'LOCALAPPDATA is unavailable; supply -LogRoot.' }
    New-Item -ItemType Directory -Path $state -Force | Out-Null
    $script:LogPath = Join-ZPath $state 'install.log'
    # Check logging before modifying any installed file.
    Add-Content -LiteralPath $script:LogPath -Value "$(Get-Date -Format o) plan $Route"
}

$payload = Find-Payload
$game = Find-Game
$app = if ($AppDataRoot) { [IO.Path]::GetFullPath($AppDataRoot) }
       elseif ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { $null }
$compiler = if ($CompilerRoot) { [IO.Path]::GetFullPath($CompilerRoot) } else { $null }
if ($compiler -and -not (Test-Path -LiteralPath $compiler -PathType Container)) {
    throw "Compiler project folder does not exist: $compiler"
}

if ($Configure) {
    Write-Host 'BOIII and T7x: open ZSTATS SETTINGS in the Zombies lobby or pause menu.'
    Write-Host 't7-compiler injection has no ui_scripts menu; use the zs_* console dvars.'
    Write-Host 'Saved career PBs require the Lua settings menu and are unavailable on the compiler-only route.'
    exit 0
}

$routes = @(
    @{ Key = 'BOIII'; Base = if ($game) { Join-ZPath $game 'boiii' }; Source = 'Black Ops III\boiii'; Ready = [bool]($game -and ((Test-Path -LiteralPath (Join-ZPath $game 'boiii') -PathType Container) -or (Test-Path -LiteralPath (Join-ZPath $game 'boiii.exe') -PathType Leaf))) },
    @{ Key = 'AppData'; Base = if ($app) { Join-ZPath $app 'boiii\data' }; Source = 'AppData\boiii\data'; Ready = [bool]($app -and (Test-Path -LiteralPath (Join-ZPath $app 'boiii\data') -PathType Container)) },
    @{ Key = 'T7x'; Base = if ($game) { Join-ZPath $game 't7x' }; Source = 't7x'; Ready = [bool]($game -and ((Test-Path -LiteralPath (Join-ZPath $game 't7x') -PathType Container) -or (Test-Path -LiteralPath (Join-ZPath $game 't7x.exe') -PathType Leaf))) },
    @{ Key = 'Compiler'; Base = $compiler; Source = 't7-compiler'; Ready = [bool]$compiler }
)

$selected = @($routes | Where-Object {
    if ($Route -eq 'All') { return $true }
    if ($Route -eq 'Auto') { return $_.Key -in @('BOIII', 'T7x') }
    return $_.Key -eq $Route
})
if ($Route -eq 'AppData' -and -not $AppDataRoot) {
    Write-Warning 'Use -AppDataRoot to select the original BOIII data folder. Ezz BOIII may remove files there on launch.'
}
$plan = @()
foreach ($routeRow in $selected) {
    $source = Join-ZPath $payload $routeRow.Source
    if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Missing payload route: $source" }
    foreach ($file in @(Get-ChildItem -LiteralPath $source -File -Recurse)) {
        $relative = $file.FullName.Substring($source.Length).TrimStart('\', '/')
        $target = if ($routeRow.Base) { Join-ZPath $routeRow.Base $relative } else { $null }
        $shared = $routeRow.Key -eq 'Compiler' -and $relative -in @('gsc.conf', 'README.md')
        $plan += [pscustomobject]@{ Route = $routeRow.Key; Ready = $routeRow.Ready; From = $file.FullName; To = $target; Shared = $shared }
    }
}
foreach ($row in $plan) {
    $state = if (-not $row.Ready) { 'not found' }
             elseif (-not (Test-Path -LiteralPath $row.To -PathType Leaf)) { 'absent' }
             elseif ((Hash-ZFile $row.From) -eq (Hash-ZFile $row.To)) { 'current' }
             else { 'different' }
    Write-Host "$($row.Route): $state - $($row.To)"
}
if ($Find) { exit 0 }
$ready = @($plan | Where-Object Ready)
if (-not $ready.Count) { throw 'No selected script route was found. Use -To, -AppDataRoot, or -CompilerRoot.' }
if ($Verify) {
    $bad = @($ready | Where-Object { -not (Test-Path -LiteralPath $_.To -PathType Leaf) -or (Hash-ZFile $_.To) -ne (Hash-ZFile $_.From) })
    if ($bad.Count) { Write-Error "$($bad.Count) script file(s) are absent or differ"; exit 1 }
    Write-Host "Verified $($ready.Count) ZStats script file(s)."
    exit 0
}
if ($Uninstall) {
    if (-not (Confirm-ZAction "Remove ZStats files from $($ready.Count) route entries?")) { exit 0 }
    Prepare-ZLog
    foreach ($row in $ready) {
        if ($row.Shared) { continue }
        if (-not (Is-ZOwned $row.To)) { Write-Warning "Modified or unowned file left alone: $($row.To)"; continue }
        Remove-Item -LiteralPath $row.To -Force
        $backup = "$($row.To).zstats-backup"
        if (Test-Path -LiteralPath $backup -PathType Leaf) { Move-Item -LiteralPath $backup -Destination $row.To -Force }
        Remove-Item -LiteralPath "$($row.To).zstats.sha256" -Force
        Log-ZAction "removed $($row.To)"
    }
    exit 0
}
if (-not (Confirm-ZAction "Install $($ready.Count) ZStats script file(s)?")) { exit 0 }
Prepare-ZLog
foreach ($row in $ready) {
    if ($row.Shared) {
        if ((Test-Path -LiteralPath $row.To -PathType Leaf) -and
            (Hash-ZFile $row.To) -ne (Hash-ZFile $row.From)) {
            throw "Shared compiler infrastructure differs; merge refused: $($row.To)"
        }
        continue
    }
    $backup = "$($row.To).zstats-backup"
    if ((Test-Path -LiteralPath $row.To -PathType Leaf) -and -not (Is-ZOwned $row.To) -and
        (Test-Path -LiteralPath $backup -PathType Leaf)) {
        throw "Cannot replace changed file while its backup already exists: $($row.To)"
    }
}
foreach ($row in $ready) {
    $folder = Split-Path -Parent $row.To
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    if ($row.Shared) {
        if (-not (Test-Path -LiteralPath $row.To -PathType Leaf)) {
            Copy-Item -LiteralPath $row.From -Destination $row.To
            Log-ZAction "installed shared compiler infrastructure $($row.To)"
        }
        continue
    }
    $backup = "$($row.To).zstats-backup"
    if ((Test-Path -LiteralPath $row.To -PathType Leaf) -and -not (Is-ZOwned $row.To) -and
        -not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        Copy-Item -LiteralPath $row.To -Destination $backup
    }
    Copy-Item -LiteralPath $row.From -Destination $row.To -Force
    Set-Content -LiteralPath "$($row.To).zstats.sha256" -Value (Hash-ZFile $row.To) -NoNewline
    Log-ZAction "installed $($row.To)"
}
Write-Host "Installed $($ready.Count) ZStats T7 script file(s). Start a new Zombies match."
