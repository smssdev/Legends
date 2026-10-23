# Legends home server setup for Windows 10/11 (PLAN 2.19, docs/HOME_SERVER.md).
# Run once, in PowerShell opened as Administrator:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
# It installs PHP 8.4, Composer, Node, Git and Tailscale, downloads the game,
# builds it, starts it with Windows (and again if it stops), schedules the daily
# database backup, keeps the PC awake on mains power, and opens a public HTTPS
# link through Tailscale Funnel, with the live connection (Reverb) on the same link.
# Running it again is safe: it never deletes data.

param(
    [string]$Root = 'C:\Legends',
    [string]$PhpDir = 'C:\php84',
    [int]$Port = 8000,
    [int]$ReverbPort = 8080,
    [string]$Repo = 'https://github.com/smssdev/Legends.git'
)

$ErrorActionPreference = 'Stop'
function Step($text) { Write-Host "`n==> $text" -ForegroundColor Yellow }
function Refresh-Path { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'Open PowerShell as Administrator (right click > Run as administrator) and run this again.' }

Step 'Installing Git, Node.js, Tailscale and the Visual C++ runtime (winget)'
foreach ($id in 'Git.Git', 'OpenJS.NodeJS.LTS', 'Tailscale.Tailscale', 'Microsoft.VCRedist.2015+.x64') {
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) { Write-Host "  ($($id) is already installed or was skipped)" }
}
Refresh-Path

Step "Installing PHP 8.4 in $PhpDir"
if (-not (Test-Path "$PhpDir\php.exe")) {
    $zip = "$env:TEMP\php84.zip"
    Invoke-WebRequest 'https://windows.php.net/downloads/releases/latest/php-8.4-nts-Win32-vs17-x64-latest.zip' -OutFile $zip
    Expand-Archive $zip -DestinationPath $PhpDir -Force
    Remove-Item $zip
}
$ini = "$PhpDir\php.ini"
if (-not (Test-Path $ini)) {
    $text = Get-Content "$PhpDir\php.ini-production" -Raw
    $text = $text -replace ';extension_dir = "ext"', 'extension_dir = "ext"'
    foreach ($ext in 'curl', 'fileinfo', 'intl', 'mbstring', 'openssl', 'pdo_sqlite', 'sqlite3', 'zip') {
        $text = $text -replace ";extension=$ext\b", "extension=$ext"
    }
    $text = $text -replace 'memory_limit = 128M', 'memory_limit = 512M'
    Set-Content $ini $text -Encoding ASCII
}
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
if ($machinePath -notlike "*$PhpDir*") { [Environment]::SetEnvironmentVariable('Path', "$machinePath;$PhpDir", 'Machine') }
Refresh-Path

Step 'Installing Composer'
if (-not (Test-Path "$PhpDir\composer.phar")) {
    Invoke-WebRequest 'https://getcomposer.org/download/latest-stable/composer.phar' -OutFile "$PhpDir\composer.phar"
    Set-Content "$PhpDir\composer.bat" "@php `"%~dp0composer.phar`" %*" -Encoding ASCII
}

Step "Downloading the game into $Root (a GitHub sign-in window may open: sign in as smssdev)"
if (-not (Test-Path "$Root\.git")) { git clone $Repo $Root } else { git -C $Root pull --ff-only }

Step 'Preparing the server'
Set-Location "$Root\backend"
composer install --no-dev --optimize-autoloader --no-interaction
if (-not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    (Get-Content '.env') -replace '^APP_ENV=.*', 'APP_ENV=production' -replace '^APP_DEBUG=.*', 'APP_DEBUG=false' | Set-Content '.env'
    Add-Content '.env' 'SIMULATOR_ENABLED=true'
    Add-Content '.env' 'GAME_NIGHTLY_BALANCE=true'
    php artisan key:generate --force
}
# Reverb listens on this machine only, with its own secret (also for installs made before it).
if (-not (Select-String -Path '.env' -Pattern '^REVERB_SERVER_HOST=' -Quiet)) {
    (Get-Content '.env') -replace '^REVERB_APP_SECRET=legends-dev-secret$', ('REVERB_APP_SECRET=' + [guid]::NewGuid().ToString('N')) -replace '^REVERB_HOST=.*', 'REVERB_HOST=127.0.0.1' | Set-Content '.env'
    Add-Content '.env' 'REVERB_SERVER_HOST=127.0.0.1'
}
php artisan migrate --force
$clubs = php artisan tinker --execute="echo App\Models\MasterClub::count();" 2>$null
if ("$clubs".Trim() -eq '0' -or -not "$clubs".Trim()) { php artisan data:import }

Step 'Building the web app'
Set-Location "$Root\web"
npm ci
npm run build
Set-Location "$Root\backend"
php artisan web:publish

Step 'Starting with Windows (scheduled tasks as SYSTEM)'
$php = "$PhpDir\php.exe"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
    -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
$system = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$web = New-ScheduledTaskAction -Execute $php -Argument "artisan serve --host=127.0.0.1 --port=$Port" -WorkingDirectory "$Root\backend"
Register-ScheduledTask -TaskName 'Legends Web' -Action $web -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $settings -Principal $system -Force | Out-Null
$sched = New-ScheduledTaskAction -Execute $php -Argument 'artisan schedule:run' -WorkingDirectory "$Root\backend"
$every = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'Legends Scheduler' -Action $sched -Trigger $every -Settings $settings -Principal $system -Force | Out-Null
# Live updates (Reverb, PLAN 2.19): on this machine only; the public link reaches it on /app (below).
$reverb = New-ScheduledTaskAction -Execute $php -Argument "artisan reverb:start --host=127.0.0.1 --port=$ReverbPort" -WorkingDirectory "$Root\backend"
Register-ScheduledTask -TaskName 'Legends Live' -Action $reverb -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $settings -Principal $system -Force | Out-Null
# The queue: emails (confirmation, password) and later the match jobs.
$queue = New-ScheduledTaskAction -Execute $php -Argument 'artisan queue:work --sleep=1 --tries=3 --max-time=3600' -WorkingDirectory "$Root\backend"
Register-ScheduledTask -TaskName 'Legends Queue' -Action $queue -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $settings -Principal $system -Force | Out-Null
# The match runner (PLAN 2.12): plays the live matches minute by minute; it resumes where it stopped.
$runner = New-ScheduledTaskAction -Execute $php -Argument 'artisan matches:run' -WorkingDirectory "$Root\backend"
Register-ScheduledTask -TaskName 'Legends Matches' -Action $runner -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $settings -Principal $system -Force | Out-Null
# The watchdog (Sprint 21): every minute it starts any task that stopped and runs the health check,
# which alerts the phones by ntfy (deploy/windows/watchdog.ps1).
$watch = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Root\deploy\windows\watchdog.ps1`" -Root `"$Root`" -PhpDir `"$PhpDir`"" -WorkingDirectory "$Root\backend"
Register-ScheduledTask -TaskName 'Legends Watchdog' -Action $watch -Trigger $every -Settings $settings -Principal $system -Force | Out-Null
foreach ($task in 'Legends Web', 'Legends Live', 'Legends Queue', 'Legends Matches') { Start-ScheduledTask -TaskName $task }

Step 'Continuous copy to the second disk (Litestream) [Sprint 37]'
# Set LITESTREAM_REPLICA_DIR in backend\.env to a folder on the second disk (e.g. D:\LegendsReplica) and run setup again.
Set-Location "$Root\backend"
$replica = (Select-String -Path '.env' -Pattern '^LITESTREAM_REPLICA_DIR=(.+)$' -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($replica) {
    $replicaDir = $replica.Matches[0].Groups[1].Value.Trim()
    $ls = "$Root\tools\litestream"
    if (-not (Test-Path "$ls\litestream.exe")) {
        New-Item -ItemType Directory -Force -Path $ls | Out-Null
        Invoke-WebRequest 'https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-windows-amd64.zip' -OutFile "$ls\litestream.zip"
        Expand-Archive "$ls\litestream.zip" -DestinationPath $ls -Force
    }
    New-Item -ItemType Directory -Force -Path $replicaDir | Out-Null
    $db = "$Root\backend\database\legends.sqlite"
    @"
dbs:
  - path: $db
    replicas:
      - type: file
        path: $replicaDir\legends
        retention: 72h
"@ | Set-Content "$ls\litestream.yml" -Encoding UTF8
    $copy = New-ScheduledTaskAction -Execute "$ls\litestream.exe" -Argument "replicate -config `"$ls\litestream.yml`"" -WorkingDirectory $ls
    Register-ScheduledTask -TaskName 'Legends Replica' -Action $copy -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $settings -Principal $system -Force | Out-Null
    Start-ScheduledTask -TaskName 'Legends Replica'
    Write-Host "  Litestream copies the game's data to $replicaDir continuously." -ForegroundColor Green
} else {
    Write-Host '  No second disk set (LITESTREAM_REPLICA_DIR in backend\.env): skipped.' -ForegroundColor Yellow
}

Step 'Alerts on the phones (ntfy)'
# A topic name nobody can guess: each phone subscribes to it in the free ntfy app.
Set-Location "$Root\backend"
# Web Push keys for the game's notifications [Sprint 36]: made once and kept.
if (-not (Select-String -Path '.env' -Pattern '^WEBPUSH_VAPID_PUBLIC=.+' -Quiet)) {
    (Get-Content '.env') | Where-Object { $_ -notmatch '^WEBPUSH_VAPID_(PUBLIC|PRIVATE)=' } | Set-Content '.env'
    php artisan push:keys | Where-Object { $_ -match '^WEBPUSH_' } | Add-Content '.env'
}
if (-not (Select-String -Path '.env' -Pattern '^NTFY_TOPIC=.+' -Quiet)) {
    Add-Content '.env' ('NTFY_TOPIC=legends-' + [guid]::NewGuid().ToString('N').Substring(0, 16))
    php artisan config:clear
}
$topic = ((Select-String -Path '.env' -Pattern '^NTFY_TOPIC=(.+)$').Matches[0].Groups[1].Value).Trim()

Step 'Keeping the PC awake on mains power'
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

Step 'Public link with Tailscale Funnel (a sign-in page opens the first time)'
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
& $ts up
& $ts funnel --bg $Port
# The live connection on the same address: wss://<name>.ts.net/app/... goes to Reverb (web/src/lib/echo.ts
# connects to the page's own host on 443 when no VITE_REVERB_* is set).
& $ts funnel --bg --set-path /app "http://127.0.0.1:$ReverbPort/app"
Write-Host ''
& $ts funnel status

# Links in emails and the invite card use the public address.
$name = ((& $ts status --json | ConvertFrom-Json).Self.DNSName).TrimEnd('.')
if ($name) {
    Set-Location "$Root\backend"
    (Get-Content '.env') -replace '^APP_URL=.*', "APP_URL=https://$name" | Set-Content '.env'
    php artisan config:clear
    Stop-ScheduledTask -TaskName 'Legends Web'
    Start-ScheduledTask -TaskName 'Legends Web'
}

Write-Host "`nDone. Open the https://...ts.net link above and add /sim" -ForegroundColor Green
Write-Host "Local check: http://127.0.0.1:$Port/sim" -ForegroundColor Green
Write-Host "Alerts: install the ntfy app on each phone and subscribe to the topic: $topic" -ForegroundColor Green
Write-Host "Update later with: powershell -ExecutionPolicy Bypass -File $Root\deploy\windows\update.ps1" -ForegroundColor Green
