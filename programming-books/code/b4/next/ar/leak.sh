# مكوّن عميل يستورد قاعدة البيانات
$ npm run build
Error: You're importing a module that depends on "server-only". This API is only available in Server Components in the App Router, but you are using it in the Pages Router.
1 | // server-only: استيراد هذا الملف من مكوّن عميل يُفشل البناء
> 2 | import "server-only";
Client Component Browser:
./lib/db.ts [Client Component Browser]
./app/leak/Leak.tsx [Client Component Browser]
