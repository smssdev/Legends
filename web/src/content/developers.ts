// [UP14] The game's developers (the owner's spec 8). [X61] Only what is true: the sample lines are gone, and more
// experience is added here when each of them writes it. No email here:
// the developers' addresses live on the server only (config game.account.official_emails).
export type Developer = { name: string; username: string; role: string; bio: string; skills: string[]; cv: { year: string; title: string; text: string }[]; avatar: string }

export const DEVELOPERS: Developer[] = [
  {
    name: 'سليمان', username: 'Owner-Sliman', role: 'صاحب الفكرة وقائد التطوير', avatar: 'س',
    bio: 'يقود بناء لعبة المدرب الأسطورة من الفكرة إلى الملعب: القواعد، والخادم، والتجربة كلها.',
    skills: ['إدارة المنتج', 'تصميم قواعد اللعبة', 'Laravel', 'Vue', 'Unity'],
    cv: [
      { year: '2026', title: 'لعبة المدرب الأسطورة', text: 'إطلاق اللعبة: دوريات خاصة، ومباريات حية، ومحاكاة ثنائية وثلاثية الأبعاد.' },
    ],
  },
  {
    name: 'حمزة', username: 'Owner-Sizar', role: 'المراجعة والجودة والصوت', avatar: 'ح',
    bio: 'يراجع كل تحديث ويختبره قبل أن يصل إليكم، ويختار أصوات الملعب ويجهز التعليق.',
    skills: ['اختبار الجودة', 'تصميم الصوت', 'مراجعة الكود', 'تجربة اللاعب'],
    cv: [
      { year: '2026', title: 'لعبة المدرب الأسطورة', text: 'مراجعة الإصدارات، وأصوات الملعب الـ44، وتسجيلات المعلقين.' },
    ],
  },
]
