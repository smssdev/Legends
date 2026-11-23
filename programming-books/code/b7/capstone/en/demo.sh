$ node demo.mjs && tail -n 3 audit.log
> How do I run the tests?
  To run the tests, use the command `node --test` on the adjacent `.test.mjs` file next to the code [conventions].
  sources: conventions, reviews; checks: ok
> Can I deploy on a Friday?
  No, you cannot deploy on a Friday because deployments are only scheduled on Tuesdays and Thursdays at 11:00 [deploy].
  sources: deploy, oncall; checks: ok
> How many vacation days do we get?
  Not in our documents.
  sources: oncall, deploy; checks: ok
{"user":"f0dbf78531","question":"How do I run the tests?","sources":["conventions","reviews"],"ok":true}
{"user":"f0dbf78531","question":"Can I deploy on a Friday?","sources":["deploy","oncall"],"ok":true}
{"user":"f0dbf78531","question":"How many vacation days do we get?","sources":["oncall","deploy"],"ok":true}
