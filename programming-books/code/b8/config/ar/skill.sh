$ claude -p "اكتب ملاحظات الإصدار." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  calls  Skill release-notes
  gets   Launching skill: release-notes
  loads  Base directory for this skill: .claude/skills/release-notes /  / اسرد التغييرات تحت أُضيف وتغيّر وأُصلح، سطراً لكل منها، بكلمات يفهمها الزبون. واترك التغييرات التي لا يراها الزبائن. / 
  says   أُضيف / - الإيصالات تُظهر الضريبة. / تغيّر / - الأسعار تُعرض بخانتين عشريتين. / أُصلح / - الفواتير بالقروش تُجمع بشكل صحيح.
  الأدوار: 3، رُفض: 0، التكلفة: $0.1282، success
