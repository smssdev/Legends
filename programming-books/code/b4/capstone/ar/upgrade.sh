# يقول المزوّد إن A دفع؛ والحدث المزوّر أو المكرر لا يغيّر شيئاً
$ EVENT='{"id":"evt_1","type":"subscription.updated","salon":1,"plan":"pro"}'
$ ./deliver "$EVENT" forged
{"message":"توقيع غير صالح"}
$ ./deliver "$EVENT"
{"applied":true}
$ ./deliver "$EVENT"
{"applied":false}
$ ./book key_a 12:00
{"id":"8"}
