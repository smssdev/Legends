# المرسِل يرسل الصندوق الصادر؛ وصلت الرسالة إلى ملتقط البريد
$ npm run --silent mailer
sent 1 to sara@example.com
$ curl -s localhost:8025/api/v1/messages | jq -c '.messages[] | {To: .To[0].Address, Subject}'
{"To":"sara@example.com","Subject":"وصل عربونك"}
