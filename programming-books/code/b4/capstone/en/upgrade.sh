# The provider says A paid; a forged or repeated event changes nothing
$ EVENT='{"id":"evt_1","type":"subscription.updated","salon":1,"plan":"pro"}'
$ ./deliver "$EVENT" forged
{"message":"Invalid signature"}
$ ./deliver "$EVENT"
{"applied":true}
$ ./deliver "$EVENT"
{"applied":false}
$ ./book key_a 12:00
{"id":"8"}
