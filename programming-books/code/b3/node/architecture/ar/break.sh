# أحدهم يستورد قاعدة البيانات في المجال
$ npm test -- test/architecture.test.ts
✖ each layer imports only what it may
AssertionError [ERR_ASSERTION]: order.ts must not import ../db.ts
