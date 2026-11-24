$ node blocks.mjs && cat artifacts/block-1.mmd
حُفظ artifacts/block-1.mmd: 5 سطراً
flowchart RL
  A[الزبون يطلب] --> B[الباريستا يحضّر المشروب]
  B --> C{المشروب صحيح؟}
  C -- نعم --> D[يُقدَّم]
  C -- لا --> B
