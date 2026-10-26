# Sprint 2, day one: commits the Unity work and the plan's state on a branch, pushes it, opens the pull
# request and asks GitHub to squash-merge it into main once CI is green.
#   powershell -ExecutionPolicy Bypass -File D:\Legends\_fix\publish-sprint2.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot)
$branch = 'sprint-2/unity-day-1'

git checkout -B $branch
if ($LASTEXITCODE) { throw 'git checkout failed' }
# unity/.gitignore keeps Library, Temp, Logs, Builds and UserSettings out.
git add unity CLAUDE.md docs/PLAN.md docs/DONE.md
git status --short
git commit -m 'Sprint 2 (day one): Unity runs the recorded match in the editor and the browser' `
    -m 'U1-U5, U7, U8: build.ps1 finds the editor anywhere and gains where/capture/test/serve/open; Setup survives the reload; URP with Low/Medium/High; broadcast camera and ball; Capture.cs; asmdefs with 12 EditMode and 3 PlayMode tests; the WebGL build. PLAN.md marks the done items and where to resume (B1); DONE.md has the Sprint 2 section.' `
    -m 'Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>' `
    -m 'Claude-Session: https://claude.ai/code/session_01SkCnVqx3aBAsVNvaUhBRja'
if ($LASTEXITCODE) { throw 'git commit failed' }
git push -u origin $branch
if ($LASTEXITCODE) { throw 'git push failed' }

$title = 'Sprint 2 (day one): Unity runs the recorded match in the editor and the browser'
$body = "Sprint 2 day one (docs/PLAN.md, Sprint 2; docs/DONE.md, Sprint 2).`n`n- Done: U1-U5, U7 (EditMode 12, PlayMode 3, all green), U8 (web build plays the match).`n- Left for day two: B1 (GET /matches/{id}/scene), U6 deferred.`n- Captures in unity/Captures/ for review.`n`n🤖 Generated with [Claude Code](https://claude.com/claude-code)`n`nhttps://claude.ai/code/session_01SkCnVqx3aBAsVNvaUhBRja"
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $bodyFile = Join-Path $env:TEMP 'legends-pr-body.md'
    [IO.File]::WriteAllText($bodyFile, $body, (New-Object Text.UTF8Encoding $false))
    gh pr create --base main --head $branch --title $title --body-file $bodyFile
    gh pr merge $branch --squash --auto --delete-branch
    if ($LASTEXITCODE) { Write-Host 'Auto-merge is off in the repo: press "Squash and merge" on the PR page when CI is green.' -ForegroundColor Yellow }
    gh pr view $branch --web
} else {
    Start-Process "https://github.com/smssdev/Legends/compare/main...$branch`?expand=1"
    Write-Host 'Pull request page opened: "Create pull request", then "Squash and merge" when CI is green.' -ForegroundColor Yellow
}
Write-Host 'Done. After the merge: git checkout main; git pull' -ForegroundColor Green
