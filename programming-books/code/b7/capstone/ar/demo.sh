$ node demo.mjs && tail -n 3 audit.log
> كيف أشغّل الاختبارات؟
  باستخدام الأمر: node --test. [conventions]
  sources: conventions, reviews; checks: ok
> هل أستطيع النشر يوم الجمعة؟
  لا، لا يمكنك النشر يوم الجمعة لأننا لا ننشر يوم الجمعة أبداً. [deploy]
  sources: deploy, oncall; checks: ok
> كم يوم إجازة لدينا؟
  ليس في مستنداتنا.
  sources: oncall, deploy; checks: ok
{"user":"f0dbf78531","question":"كيف أشغّل الاختبارات؟","sources":["conventions","reviews"],"ok":true}
{"user":"f0dbf78531","question":"هل أستطيع النشر يوم الجمعة؟","sources":["deploy","oncall"],"ok":true}
{"user":"f0dbf78531","question":"كم يوم إجازة لدينا؟","sources":["oncall","deploy"],"ok":true}
