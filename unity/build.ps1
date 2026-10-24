# The Unity project from the command line, on Sliman's Windows PC (docs/PLAN.md 7.9). Claude runs these.
#
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 install   Unity Hub (winget), then the editor by hand
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 where     shows which Unity.exe the other steps will use
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 setup     opens the project once and adds the packages
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 demo      builds the Arena and the match scene
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 webgl     the web build in unity\Builds\WebGL
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 android   the test APK in unity\Builds\Android
#
# The log of every step goes to the window and to unity\Logs\<step>.log.
param(
    [Parameter(Position = 0)][ValidateSet('install', 'where', 'setup', 'demo', 'webgl', 'android')][string]$Step = 'demo',
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
    # Every place Unity Hub may have put an editor: the default folder, the "Installs location" chosen in
    # Hub's settings (e.g. on D:), and the editors Hub lists in its own files.
    $hubData = Join-Path $env:APPDATA 'UnityHub'
    $roots = @('C:\Program Files\Unity\Hub\Editor')
    $custom = Join-Path $hubData 'secondaryInstallPath.json'
    if (Test-Path $custom) {
        $path = (Get-Content $custom -Raw).Trim().Trim('"') -replace '\\\\', '\'
        if ($path) { $roots += $path }
    }
    $exes = @()
    foreach ($root in $roots) {
        $exes += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'Editor\Unity.exe' }
    }
    foreach ($list in @('editors-v2.json', 'editors.json')) {
        $file = Join-Path $hubData $list
        if (Test-Path $file) {
            # pull every "...Unity.exe" path out of the file without depending on its exact shape
            $exes += [regex]::Matches((Get-Content $file -Raw), '"([^"]*?Unity\.exe)"') |
                ForEach-Object { $_.Groups[1].Value -replace '\\\\', '\' }
        }
    }
    $editors = $exes | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique |
        ForEach-Object { [pscustomobject]@{ Exe = $_; Name = Split-Path (Split-Path (Split-Path $_)) -Leaf } } |
        Where-Object { $_.Name -like '6000.*' } |
        Sort-Object { [version]($_.Name -replace '[a-z].*$', '') } -Descending
    if (-not $editors) {
        throw "No Unity 6 editor found (looked in: $($roots -join ', ')). Run: build.ps1 install, or pass -Unity 'D:\...\Editor\Unity.exe'"
    }
    $Unity = $editors[0].Exe
}
if (-not (Test-Path $Unity)) { throw "Unity.exe not found: $Unity" }
Write-Host "Unity: $Unity"
if ($Step -eq 'where') { exit 0 }
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
