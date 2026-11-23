# Starts the service, asks one question, and stops the service.
node service.mjs > service.log 2>&1 &
until grep -q listening service.log; do sleep 1; done
node client.mjs "Can I use my loyalty card in both branches?"
kill $!
