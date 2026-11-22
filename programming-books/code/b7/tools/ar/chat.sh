$ node chat.mjs
> كيف أقرأ ملف JSON في Node؟
استخدم `fs.readFileSync()` لقراءة الملف، ثم استخدم `JSON.parse()` لتحليله.  
مثلاً: `const data = JSON.parse(fs.readFileSync('file.json', 'utf8'));`
[88 tokens]

> وكيف أكتب واحداً؟
استخدم `fs.writeFileSync()` لكتابة البيانات، ثم أرسلها كمصفوفة أو خاصية JSON.  
مثلاً: `fs.writeFileSync('file.json', JSON.stringify(data));`
[149 tokens]

محادثة جديدة، سُئلت السؤال الثاني وحده:
> وكيف أكتب واحداً؟
أكتب `const x = 5;` لتعريف متغير بقيمة.
