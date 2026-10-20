# Legends home server setup for Windows 10/11 (PLAN 2.19, docs/HOME_SERVER.md).
# Run once, in PowerShell opened as Administrator:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
# It installs PHP 8.4, Composer, Node, Git and Tailscale, downloads the game,
# builds it, starts it with Windows (and again if it stops), schedules the daily
# database backup, keeps the PC awake on mains power, and opens a public HTTPS
# link through Tailscale Funnel. Running it again is safe: it never deletes data.

param(
    [string]$Root = 'C:\Legends',
    [string]$PhpDir = 'C:\php84',
    [int]$Port = 8000,
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
Start-ScheduledTask -TaskName 'Legends Web'

Step 'Keeping the PC awake on mains power'
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

Step 'Public link with Tailscale Funnel (a sign-in page opens the first time)'
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
& $ts up
& $ts funnel --bg $Port
Write-Host ''
& $ts funnel status

Write-Host "`nDone. Open the https://...ts.net link above and add /sim" -ForegroundColor Green
Write-Host "Local check: http://127.0.0.1:$Port/sim" -ForegroundColor Green
Write-Host "Update later with: powershell -ExecutionPolicy Bypass -File $Root\deploy\windows\update.ps1" -ForegroundColor Green
