# The Unity project from the command line, on Sliman's Windows PC (docs/PLAN.md 7.9). Claude runs these.
#
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 install   Unity Hub (winget), then the editor by hand
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 setup     opens the project once and adds the packages
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 demo      builds the Arena and the match scene
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 webgl     the web build in unity\Builds\WebGL
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 android   the test APK in unity\Builds\Android
#
# The log of every step goes to the window and to unity\Logs\<step>.log.
param(
    [Parameter(Position = 0)][ValidateSet('install', 'setup', 'demo', 'webgl', 'android')][string]$Step = 'demo',
    [string]$Unity = ''   # Unity.exe; found under Unity Hub's editors when empty
)
$ErrorActionPreference = 'Stop'
$Project = $PSScriptRoot

if ($Step -eq 'install') {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is missing: install "App Installer" from the Microsoft Store.' }
    winget install --id Unity.UnityHub -e --accept-source-agreements --accept-package-agreements
    Write-Host ''
    Write-Host 'Now in Unity Hub (by hand, once):' -ForegroundColor Yellow
    Write-Host '  1. Sign in with your Unity account and take the free Personal licence.'
    Write-Host '  2. Installs > Install Editor > the newest Unity 6 marked LTS.'
    Write-Host '  3. Tick the modules: WebGL Build Support, Android Build Support (with OpenJDK and Android SDK & NDK).'
    Write-Host 'Then: build.ps1 setup'
    exit 0
}

if (-not $Unity) {
    $editors = Get-ChildItem 'C:\Program Files\Unity\Hub\Editor' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '6000.*' } | Sort-Object { [version]($_.Name -replace '[a-z].*$', '') } -Descending
    if (-not $editors) { throw 'No Unity 6 editor found. Run: build.ps1 install' }
    $Unity = Join-Path $editors[0].FullName 'Editor\Unity.exe'
}
Write-Host "Unity: $Unity"
New-Item -ItemType Directory -Force (Join-Path $Project 'Logs') | Out-Null
$log = Join-Path $Project "Logs\$Step.log"

$method = @{
    setup   = 'Legends.EditorTools.Setup.Run'
    demo    = 'Legends.EditorTools.DemoScene.Build'
    webgl   = 'Legends.EditorTools.Builds.WebGL'
    android = 'Legends.EditorTools.Builds.Android'
}[$Step]
$unityArgs = @('-batchmode', '-projectPath', "`"$Project`"", '-executeMethod', $method, '-logFile', "`"$log`"")
if ($Step -ne 'setup') { $unityArgs += '-quit' }       # setup quits by itself once the packages are in
if ($Step -eq 'webgl') { $unityArgs += @('-buildTarget', 'WebGL') }
if ($Step -eq 'android') { $unityArgs += @('-buildTarget', 'Android') }

Remove-Item $log -ErrorAction SilentlyContinue
$p = Start-Process -FilePath $Unity -ArgumentList $unityArgs -PassThru -NoNewWindow
$null = $p.Handle   # keeps the exit code readable after Unity quits
# show our own lines and the errors from the log while Unity works
$seen = 0
while ($true) {
    $done = $p.HasExited
    if (Test-Path $log) {
        $lines = @(Get-Content $log)
        for ($i = $seen; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'Legends:|error|Exception') { Write-Host $lines[$i] }
        }
        $seen = $lines.Count
    }
    if ($done) { break }
    Start-Sleep -Seconds 1
}
Write-Host "Unity exited with $($p.ExitCode). Full log: $log"
exit $p.ExitCode
