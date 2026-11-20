$ curl -sN localhost:3000/orders/1001/events
: متصل بـ server 3000

id: 1
event: status
data: {"order":1001,"status":"paid","by":"server 3000"}

id: 2
event: status
data: {"order":1001,"status":"shipped","by":"server 3000"}
