# The mailer sends the outbox; the mail catcher received it
$ npm run --silent mailer
sent 1 to sara@example.com
$ curl -s localhost:8025/api/v1/messages | jq -c '.messages[] | {To: .To[0].Address, Subject}'
{"To":"sara@example.com","Subject":"Your deposit is received"}
