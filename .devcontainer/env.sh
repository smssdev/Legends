# Sourced by start.sh: the settings that differ in a Codespace. Exported variables win over backend/.env
# (Laravel never overwrites a variable that is already set), so .env stays as it is.
#
# Sign-in needs the Codespace's public address: the session cookie (Sanctum), the links in the emails
# and Google's return address all use it. Without it the web signs in but the next request is a guest.
if [ -n "${CODESPACE_NAME:-}" ]; then
  host="${CODESPACE_NAME}-8000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  export APP_URL="https://${host}"
  export FRONTEND_URL="$APP_URL"
  export GOOGLE_REDIRECT_URI="$APP_URL/auth/google/callback"
  export SANCTUM_STATEFUL_DOMAINS="${host},localhost,localhost:5173,localhost:8000,127.0.0.1,127.0.0.1:5173,127.0.0.1:8000,::1"
  export SESSION_SECURE_COOKIE=true
  # Only GitHub's port forwarding reaches the game in a Codespace: trust its X-Forwarded-* headers, so the
  # game sees https and its public address (signed email links are checked against it).
  export TRUSTED_PROXIES='*'
  # No Reverb in a Codespace: broadcasting to it would fail every live minute of matches:run.
  export BROADCAST_CONNECTION="${BROADCAST_CONNECTION:-log}"
fi

# Real emails through Gmail (free): two Codespaces secrets, GMAIL_ADDRESS and GMAIL_APP_PASSWORD (an app
# password from myaccount.google.com/apppasswords, not the Gmail password). Without them the emails go to
# backend/storage/logs/laravel.log as before.
# Or the BREVO_API_KEY secret: the same HTTPS way as on Render [X8].
if [ -n "${BREVO_API_KEY:-}" ]; then
  export MAIL_MAILER=brevo MAIL_HOST=api.brevo.com MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-${GMAIL_ADDRESS:-}}"
elif [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  export MAIL_MAILER=smtp
  export MAIL_HOST=smtp.gmail.com
  export MAIL_PORT=587
  export MAIL_USERNAME="$GMAIL_ADDRESS"
  export MAIL_PASSWORD="${GMAIL_APP_PASSWORD// /}"
  export MAIL_FROM_ADDRESS="$GMAIL_ADDRESS"
fi

# Google sign-in: the Codespaces secrets GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are read as they are.
