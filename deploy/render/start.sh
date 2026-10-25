#!/bin/sh
# The container's start on Render (Dockerfile CMD). Render gives the service's public address at run time
# (RENDER_EXTERNAL_URL), so the settings that depend on it are made here, not when the image is built.
# Exported variables win over backend/.env (Laravel never overwrites a variable that is already set).
set -e
cd /app/backend

if [ -n "${RENDER_EXTERNAL_URL:-}" ]; then
  host="${RENDER_EXTERNAL_HOSTNAME:-${RENDER_EXTERNAL_URL#https://}}"
  export APP_URL="$RENDER_EXTERNAL_URL"
  export FRONTEND_URL="$APP_URL"
  export GOOGLE_REDIRECT_URI="$APP_URL/auth/google/callback"
  # Sign-in: the session cookie counts only for these hosts (without it the web signs in, then is a guest).
  export SANCTUM_STATEFUL_DOMAINS="${host},localhost,localhost:8000,127.0.0.1,127.0.0.1:8000"
  export SESSION_SECURE_COOKIE=true
  # Only Render's proxy reaches the container: trust its X-Forwarded-* headers (https and the public host).
  export TRUSTED_PROXIES='*'
fi

# Real emails [X8]. Render's free plan blocks the SMTP ports (25, 465, 587), so Gmail's SMTP cannot work here:
# the emails go over HTTPS instead. BREVO_API_KEY (free, 300 a day; MAIL_FROM_ADDRESS is the sender verified in
# Brevo, a Gmail address works) or RESEND_API_KEY (free, needs a domain of ours). Gmail's SMTP is kept for hosts
# that allow it (the home server, Codespaces). Without any of them the emails go to the log.
if [ -n "${BREVO_API_KEY:-}" ]; then
  export MAIL_MAILER=brevo MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-${GMAIL_ADDRESS:-}}"
elif [ -n "${RESEND_API_KEY:-}" ]; then
  export MAIL_MAILER=resend MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-onboarding@resend.dev}"
elif [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  echo "Emails: Gmail SMTP is blocked on Render's free plan; set BREVO_API_KEY instead (docs/PLAN.md 8.1)"
  export MAIL_MAILER=smtp MAIL_HOST=smtp.gmail.com MAIL_PORT=587
  export MAIL_USERNAME="$GMAIL_ADDRESS" MAIL_FROM_ADDRESS="$GMAIL_ADDRESS"
  MAIL_PASSWORD=$(printf '%s' "$GMAIL_APP_PASSWORD" | tr -d ' ')
  export MAIL_PASSWORD
fi

if [ -n "${APP_KEY_SEED:-}" ]; then
  APP_KEY=$(php -r 'echo "base64:".base64_encode(hash("sha256", getenv("APP_KEY_SEED"), true));')
  export APP_KEY
fi

saved=
if [ -n "${B2_BUCKET:-}" ] && [ -n "${B2_ENDPOINT:-}" ] && [ -n "${B2_KEY_ID:-}" ] && [ -n "${B2_APPLICATION_KEY:-}" ]; then
  endpoint="${B2_ENDPOINT#https://}"
  endpoint="${endpoint%/}"
  export LITESTREAM_BUCKET="$B2_BUCKET" LITESTREAM_ENDPOINT="https://$endpoint"
  region=$(printf '%s' "$endpoint" | sed -n 's/^s3\.\([^.]*\)\.backblazeb2\.com$/\1/p')
  export LITESTREAM_REGION="${region:-us-east-1}"
  export LITESTREAM_ACCESS_KEY_ID="$B2_KEY_ID" LITESTREAM_SECRET_ACCESS_KEY="$B2_APPLICATION_KEY"
  
  at=
  if [ -n "${RESTORE_AT:-}" ]; then
    at="-timestamp $RESTORE_AT"
    echo "Saved game: going back to $RESTORE_AT"
  fi
  
  # علم (Flag) لمتابعة إذا واجهنا خطأ في الحساب
  b2_failed=0
  
  for db in legends queue; do
    file="database/$db.sqlite"
    rm -f "$file.restore"
    if ! litestream restore -config /app/litestream.yml -if-replica-exists $at -o "$file.restore" "/app/backend/$file" 2> /tmp/restore.err; then
      cat /tmp/restore.err
      if grep -q "cap exceeded" /tmp/restore.err; then
        echo "Saved game: B2 refused (its daily cap). Bypassing Litestream to allow Demo mode..."
        b2_failed=1
        break
      fi
      exit 1
    fi
    if [ -f "$file.restore" ]; then
      rm -f "$file" "$file-wal" "$file-shm" "$file.restore.tmp"*
      mv "$file.restore" "$file"
      echo "Saved game: $db.sqlite brought back from B2"
    fi
  done
  
  # إذا نجح الاتصال ولم يستهلك الـ Cap نعتبر اللعبة محفوظة ومربوطة
  if [ "$b2_failed" -eq 0 ]; then
    saved=1
  fi
fi

mkdir -p storage/logs

if [ -n "$saved" ]; then 
  php artisan db:backup --keep=5 || echo "Backup before migrating: failed, continuing"
fi

# الهجرة والاستيراد ستعمل بكل الأحوال سواء من البيانات المسترجعة أو كبيانات ديمو جديدة
php artisan migrate --force
php artisan data:import --add
php artisan config:cache

php artisan queue:work --tries=1 --sleep=1 >> storage/logs/queue.log 2>&1 &
php artisan schedule:work >> storage/logs/schedule.log 2>&1 &
php artisan matches:run >> storage/logs/matches.log 2>&1 &

echo "Legends: ${APP_URL:-http://localhost:${PORT}}"
case "${MAIL_MAILER:-log}" in
  brevo|resend) echo "Emails: through ${MAIL_MAILER} (HTTPS) from ${MAIL_FROM_ADDRESS}" ;;
  smtp) echo "Emails: through Gmail SMTP from ${MAIL_FROM_ADDRESS}" ;;
  *) echo "Emails: to storage/logs/laravel.log" ;;
esac
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then echo "Google sign-in: on"; else echo "Google sign-in: off"; fi

# تشغيل السيرفر بناءً على حالة اتصال Backblaze B2
if [ -n "$saved" ]; then
  echo "Saved game: every change copied to B2 ($LITESTREAM_BUCKET)"
  exec litestream replicate -config /app/litestream.yml -exec "php artisan serve --host=0.0.0.0 --port=${PORT} --no-reload"
else
  echo "Saved game: OFF (Demo Local Mode). Data will reset on next Render restart."
  exec php artisan serve --host=0.0.0.0 --port="${PORT}" --no-reload
fi
