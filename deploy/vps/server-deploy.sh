#!/bin/sh
# [X64] Deploys the latest main from GitHub, run on the server itself, so a phone is enough: hPanel → VPS → Web console,
#   legends-deploy
# Installed as legends-deploy by deploy.sh. The server reads the private repository with its own read-only deploy key
# (~/.ssh/legends_github, its public half in GitHub → Settings → Deploy keys), then runs deploy.sh against itself over
# SSH to 127.0.0.1 with that same key, so the checks are the same as Deploy-GLM.cmd's (no live match, the disk).
set -e
KEY="$HOME/.ssh/legends_github"
[ -f "$KEY" ] || {
  ssh-keygen -q -t ed25519 -N "" -C "glm-server-deploy" -f "$KEY"
  echo "Made a key. Add this line in GitHub → Settings → Deploy keys (read only), then run legends-deploy again:"
  cat "$KEY.pub"; exit 1; }
export GIT_SSH_COMMAND="ssh -i $KEY -o StrictHostKeyChecking=accept-new"
cd /opt/legends
[ -d repo ] || git clone -q --depth 1 --filter=blob:none git@github.com:smssdev/Legends.git repo
cd repo && git fetch -q --depth 1 origin main && git checkout -q -B main FETCH_HEAD
echo "Deploying: $(git log --oneline -1)"
grep -qF "$(cat "$KEY.pub")" "$HOME/.ssh/authorized_keys" 2>/dev/null || cat "$KEY.pub" >> "$HOME/.ssh/authorized_keys"
ssh-keygen -F 127.0.0.1 > /dev/null || ssh-keyscan 127.0.0.1 2> /dev/null >> "$HOME/.ssh/known_hosts"
# exec: deploy.sh reinstalls this file, and sh must not read on in a file being replaced.
LEGENDS_HOST=root@127.0.0.1 LEGENDS_KEY="$KEY" exec sh deploy/vps/deploy.sh
