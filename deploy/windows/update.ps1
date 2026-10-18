# Legends home server update (docs/HOME_SERVER.md). Safe for the data:
# it backs up the databases first, only runs forward migrations, and never
# wipes anything. Run in PowerShell as Administrator, when no match is live:
#   powershell -ExecutionPolicy Bypass -File C:\Legends\deploy\windows\update.ps1

param([string]$Root = 'C:\Legends')
$ErrorActionPreference = 'Stop'
function Step($text) { Write-Host "`n==> $text" -ForegroundColor Yellow }

Set-Location "$Root\backend"
Step 'Backing up the databases'
php artisan db:backup

Step 'Stopping the game'
Stop-ScheduledTask -TaskName 'Legends Web' -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name = 'php.exe'" | Where-Object { $_.CommandLine -like '*artisan serve*' -or $_.CommandLine -like '*server.php*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Step 'Getting the latest version'
git -C $Root pull --ff-only
composer install --no-dev --optimize-autoloader --no-interaction
php artisan migrate --force

Step 'Building the web app'
Set-Location "$Root\web"
npm ci
npm run build
Set-Location "$Root\backend"
php artisan web:publish

Step 'Starting the game'
Start-ScheduledTask -TaskName 'Legends Web'
Write-Host "`nUpdated. Your link is the same as before." -ForegroundColor Green
