// [X57] The privacy policy and the terms (the owner's request 2026-10-29), in both languages: what Google AdSense and
// the stores ask of a published game. Written whole per language (not through t()), so each reads as one document.
// A change here moves UPDATED, and anything the game starts collecting is added to the privacy policy first.
import type { Locale } from '../lib/i18n'

export type LegalSection = { h: string; p: string[] }
export type LegalDoc = { title: string; intro: string; sections: LegalSection[] }

export const UPDATED = '2026-10-30'

const PRIVACY: Record<Locale, LegalDoc> = {
  ar: {
    title: 'سياسة الخصوصية',
    intro: 'تشرح هذه السياسة ما تجمعه لعبة المدرب الأسطورة (GLM) من بيانات، ولماذا، وكيف نحميها، وحقوقك فيها. باستخدامك اللعبة توافق على ما فيها.',
    sections: [
      { h: 'من نحن', p: ['GLM لعبة إدارة كرة قدم على الويب يطوّرها فريق صغير مستقل. وللتواصل معنا في أي شأن يخص بياناتك: صفحة «الدعم» داخل اللعبة، أو أزرار واتساب وتيليجرام أسفل هذه الصفحة.'] },
      { h: 'ما نجمعه منك', p: [
        'بيانات الحساب: الاسم الظاهر، واسم المستخدم، وكلمة المرور (محفوظة مشفرة لا نراها)، والبريد إن أضفته، وصورتك إن رفعتها، ولغتك، وشكل مدربك على الخط الذي تختاره (يراه مدربو دوريك في المباريات).',
        'الدخول بحساب Google: نأخذ من Google اسمك وبريدك ومعرّف حسابك فقط، لتسجيل دخولك، ولا نصل إلى أي شيء آخر في حسابك.',
        'بيانات اللعب: أنديتك ودورياتك وبطولاتك ومبارياتك وتكتيكاتك وصفقاتك ورسائلك داخل اللعبة وما تكتبه للدعم أو للمدرب المساعد.',
        'اقتراحاتك وأصواتك: ما ترسله في «اقتراحات التطوير» يقرؤه فريق التطوير، وصوتك في كل تصويت (لا يراه غيرنا، وتظهر للجميع الأعداد فقط). وإن أعجبنا اقتراحك يظهر اسمك وصورتك وعنوان اقتراحك في «قائمة الشرف» لكل المسجلين.',
        'رسائل الجروبات: ما تكتبه أو ترسله في جروب من نص وصور ورسائل صوتية يراه أعضاؤه كلهم ويُحفظ على خادمنا. تحذف رسالتك متى شئت فتظهر لهم «حُذفت» وتُمحى صورتها أو صوتها، وتحذف الإدارة الرسائل القديمة تلقائياً بعد مدة تحددها.',
        'تقييمك لردود المدرب المساعد: إن ضغطت «أفادني» أو «لم يفدني» نحفظ اختيارك والصفحة التي كنت فيها وملاحظتك إن كتبتها، لنحسّن ردوده. ولا نحفظ معها المحادثة نفسها.',
        'بيانات تقنية: عنوان IP ونوع المتصفح والجهاز وأوقات الدخول، لحماية الحسابات من الاختراق والإساءة ولإصلاح الأعطال.',
      ] },
      { h: 'لماذا نستخدمها', p: [
        'لتشغيل اللعبة: حسابك ودورياتك ومبارياتك الحية وإشعاراتك.',
        'لحماية اللاعبين: منع الغش والحسابات المتعددة والإساءة، والرد على البلاغات.',
        'لتحسين اللعبة: فهم ما يُستخدم وما يتعطل، بأرقام عامة لا تكشف أحداً.',
        'لعرض الإعلانات التي تموّل اللعبة وتبقيها مجانية (القسم التالي).',
        'لا نبيع بياناتك لأحد، ولا نشاركها إلا كما هو مكتوب هنا.',
      ] },
      { h: 'الإعلانات وGoogle AdSense', p: [
        'تعرض اللعبة إعلانات من Google AdSense في أماكن محددة (لا داخل المباراة)، وفيديوهات بمكافأة تختار مشاهدتها لتقليص وقت التدريب أو البناء.',
        'Google وشركاؤها مزودون من طرف ثالث، ويستخدمون ملفات تعريف الارتباط (الكوكيز) لعرض الإعلانات بناءً على زياراتك السابقة لهذا الموقع ولمواقع أخرى. وتمكّن كوكيز الإعلانات Google وشركاءها من عرض الإعلانات لك بناءً على تلك الزيارات.',
        'يمكنك إيقاف الإعلانات المخصصة من إعدادات إعلانات Google (adssettings.google.com)، أو إيقاف كوكيز مزودي الإعلانات الآخرين من www.aboutads.info. وتشرح Google استخدامها للبيانات في policies.google.com/technologies/partner-sites.',
        'في المنطقة الاقتصادية الأوروبية والمملكة المتحدة وسويسرا تطلب Google موافقتك قبل أي إعلان مخصص، ويمكنك تغيير اختيارك متى شئت.',
        'وفيديوهات المكافأة اختيارية تماماً، واللعبة كاملة بدونها.',
      ] },
      { h: 'الكوكيز والتخزين في المتصفح', p: [
        'نستخدم كوكيز ضرورية لتسجيل دخولك وحماية النماذج (الجلسة وXSRF)، ولا تعمل اللعبة بدونها.',
        'ونحفظ في متصفحك اختياراتك (اللغة والمظهر والصوت) ليبقى شكل اللعبة كما تحب.',
        'وإن ضغطت «احفظ وتابع لاحقاً» في المدرب المساعد تبقى آخر محادثة معه في متصفحك وحده، لا عندنا، حتى تبدأ من جديد.',
        'وكوكيز الإعلانات من Google كما في القسم السابق.',
      ] },
      { h: 'من يعالج البيانات معنا', p: [
        'الاستضافة: خادمنا لدى Hostinger، وعليه قاعدة البيانات ونسخها الاحتياطية.',
        'Google: الدخول بحساب Google، والإعلانات (AdSense)، والمدرب المساعد (Gemini) الذي يُرسل إليه سؤالك وأرقام فريقك اللازمة للإجابة فقط، بلا اسمك ولا بريدك.',
        'البريد: خدمة إرسال البريد التي توصل رسائل التوثيق واستعادة كلمة المرور.',
      ] },
      { h: 'مدة الاحتفاظ', p: [
        'نحتفظ ببيانات حسابك ما دام قائماً. وحين تحذفه يُحذف معه كل ما هو خاص بك (المحفظة والرسائل والأجهزة والنشاط)، وتعود أنديتك للبوتات، وتبقى نتائج المباريات والألقاب في سجل الدوري بلا اسمك، ورسائلك في الجروبات لأعضائها بلا اسمك (احذفها قبل حذف الحساب إن شئت).',
        'والسجلات التقنية تُحذف تلقائياً بعد مدة قصيرة، والنسخ الاحتياطية تتجدد دورياً.',
      ] },
      { h: 'حقوقك', p: [
        'أن تطلع على بياناتك وتصححها من صفحة «حسابي».',
        'أن تحذف حسابك نهائياً من «حسابي» في أي وقت، بلا سؤال عن السبب.',
        'أن تطلب نسخة من بياناتك أو تعترض على معالجتها، بمراسلتنا من صفحة الدعم، ونرد خلال 30 يوماً.',
      ] },
      { h: 'الأطفال', p: ['اللعبة لمن عمره 13 سنة فأكثر (و16 في الاتحاد الأوروبي إلا بموافقة ولي الأمر). ولا نجمع عن قصد بيانات من هم أصغر، وإن علمنا بحساب لطفل حذفناه.'] },
      { h: 'الحماية', p: ['الاتصال بالموقع مشفر (HTTPS)، وكلمات المرور مشفرة، والوصول إلى الخادم بمفاتيح خاصة فقط. ومع ذلك لا يوجد نظام آمن 100%، فاختر كلمة مرور لا تستخدمها في مكان آخر.'] },
      { h: 'التغييرات', p: ['قد نحدّث هذه السياسة، ونكتب تاريخ آخر تحديث أعلاها، ونعلن أي تغيير مهم داخل اللعبة.'] },
    ],
  },
  en: {
    title: 'Privacy policy',
    intro: 'This policy explains what data GLM (Game Legend Manager) collects, why, how we protect it, and your rights over it. By using the game you agree to it.',
    sections: [
      { h: 'Who we are', p: ['GLM is a web football management game made by a small independent team. For anything about your data, reach us from the Support page in the game, or the WhatsApp and Telegram buttons at the bottom of this page.'] },
      { h: 'What we collect', p: [
        'Account data: your display name, username, password (stored hashed; we never see it), your email if you add one, your picture if you upload one, your language, and the look you pick for your coach on the touchline (the coaches of your leagues see it in matches).',
        'Google sign-in: we receive only your name, email and account id from Google, to sign you in, and nothing else in your Google account.',
        'Game data: your clubs, leagues, tournaments, matches, tactics, transfers, in-game messages, and what you write to support or to the Assistant Coach.',
        'Your suggestions and votes: what you send in «Development ideas» is read by the development team, and your vote in each poll (seen by nobody else; everyone sees only the counts). If we like your suggestion, your name, picture and its title appear on the «Honour roll» for every signed-up player.',
        'Group messages: the text, photos and voice notes you send in a group are seen by all its members and kept on our server. You can delete a message at any time: they then see it as deleted and its photo or sound is erased; and old messages are deleted automatically after a period the game\'s admins set.',
        'Your rating of the Assistant Coach\'s answers: if you tap "helpful" or "not helpful" we keep your choice, the page you were on and your note if you wrote one, to improve his answers. The conversation itself is not kept with it.',
        'Technical data: IP address, browser and device type, and sign-in times, to protect accounts from abuse and to fix problems.',
      ] },
      { h: 'Why we use it', p: [
        'To run the game: your account, leagues, live matches and notifications.',
        'To protect players: stopping cheating, multiple accounts and abuse, and answering reports.',
        'To improve the game: understanding what is used and what breaks, with overall numbers that identify no one.',
        'To show the ads that fund the game and keep it free (next section).',
        'We never sell your data, and share it only as written here.',
      ] },
      { h: 'Ads and Google AdSense', p: [
        'The game shows Google AdSense ads in a few set places (never inside a match), and rewarded videos you may choose to watch to cut training or building time.',
        'Third party vendors, including Google, use cookies to serve ads based on your prior visits to this website or other websites. Google\'s use of advertising cookies enables it and its partners to serve ads to you based on those visits.',
        'You may opt out of personalised advertising in Google\'s Ads Settings (adssettings.google.com), and out of other vendors\' cookies at www.aboutads.info. Google explains how it uses data at policies.google.com/technologies/partner-sites.',
        'In the European Economic Area, the UK and Switzerland, Google asks for your consent before any personalised ad, and you can change your choice at any time.',
        'Rewarded videos are entirely optional; the whole game works without them.',
      ] },
      { h: 'Cookies and browser storage', p: [
        'We use essential cookies to keep you signed in and to protect forms (session and XSRF); the game cannot work without them.',
        'We keep your choices (language, look and sound) in your browser so the game stays the way you like it.',
        'If you tap "Save and continue later" in the Assistant Coach, your last conversation with him stays in your browser only, not with us, until you start again.',
        'And Google\'s advertising cookies, as in the previous section.',
      ] },
      { h: 'Who processes data with us', p: [
        'Hosting: our server at Hostinger, with the database and its backups.',
        'Google: Google sign-in, ads (AdSense), and the Assistant Coach (Gemini), which receives your question and only the numbers about your team it needs to answer, without your name or email.',
        'Email: the sending service that delivers verification and password reset emails.',
      ] },
      { h: 'How long we keep it', p: [
        'We keep your account data while your account exists. When you delete it, everything that is only yours goes with it (wallet, messages, devices, activity), your clubs return to the bots, match results and titles stay in the league\'s history without your name, and your group messages stay for their members without your name (delete them before deleting the account if you wish).',
        'Technical logs are deleted automatically after a short time, and backups are rotated.',
      ] },
      { h: 'Your rights', p: [
        'To see and correct your data from "My account".',
        'To delete your account for good from "My account" at any time, without giving a reason.',
        'To ask for a copy of your data or object to its processing, by writing to us from the Support page; we answer within 30 days.',
      ] },
      { h: 'Children', p: ['The game is for people aged 13 and over (16 in the European Union without a parent\'s consent). We do not knowingly collect data from anyone younger, and delete such an account when we learn of it.'] },
      { h: 'Security', p: ['The connection is encrypted (HTTPS), passwords are hashed, and the server is reached with private keys only. Still, no system is 100% secure, so pick a password you use nowhere else.'] },
      { h: 'Changes', p: ['We may update this policy; the date of the last update is at its top, and any important change is announced in the game.'] },
    ],
  },
}

const TERMS: Record<Locale, LegalDoc> = {
  ar: {
    title: 'الشروط والأحكام',
    intro: 'هذه الشروط اتفاق بينك وبين فريق GLM حين تستخدم اللعبة. بإنشائك حساباً أو لعبك فأنت توافق عليها وعلى سياسة الخصوصية.',
    sections: [
      { h: 'الحساب', p: [
        'يجب أن يكون عمرك 13 سنة فأكثر (و16 في الاتحاد الأوروبي إلا بموافقة ولي الأمر).',
        'حساب واحد لكل شخص، وأنت مسؤول عن كل ما يجري فيه، فاحفظ كلمة مرورك.',
        'اسم المستخدم والصورة لا يسيئان لأحد، ولا ينتحلان شخصية المطورين أو غيرهم.',
      ] },
      { h: 'اللعب النظيف', p: [
        'ممنوع: الحسابات المتعددة لنفع نفسك، والاتفاق على صفقات تنقل المال بين الأندية بغير وجه حق، واستخدام البرامج أو السكربتات أو الثغرات، والضغط المتعمد على الخادم.',
        'ممنوع السب والتحرش والتمييز والمحتوى غير اللائق في الأسماء والرسائل والدوريات.',
        'لنا أن نلغي ما نتج عن مخالفة، أو نوقف الحساب مؤقتاً أو نهائياً، مع إخبارك بالسبب، ولك أن تراجعنا من صفحة الدعم.',
      ] },
      { h: 'الكوينز والمحتوى الافتراضي', p: [
        'الكوينز وأموال النادي واللاعبون والأندية داخل اللعبة افتراضية: لا قيمة نقدية لها، ولا تُستبدل بمال، ولا تُباع ولا تُنقل خارج اللعبة.',
        'نملك حق تعديل الأسعار والمكافآت والتوازن متى احتاجت اللعبة، ولا يُعد ذلك خسارة تستحق التعويض.',
        'لا تُباع الكوينز بمال حقيقي حالياً. وإن بدأنا ذلك يوماً فستُكتب شروط الشراء والاسترداد هنا قبله.',
      ] },
      { h: 'الإعلانات', p: [
        'اللعبة مجانية ويموّلها الإعلان. يُمنع النقر المتعمد على الإعلانات أو دعوة غيرك للنقر عليها أو استخدام أي وسيلة آلية لمشاهدتها، فهذا يضر اللعبة ويخالف سياسات Google، وقد يوقف الحساب.',
        'مكافآت الفيديو (تقليص الوقت) محددة بعدد لكل مهمة، وقد تتوقف إن لم يتوفر إعلان.',
      ] },
      { h: 'الأسماء والعلامات', p: [
        'GLM لعبة مستقلة، وغير تابعة لأي نادٍ أو دوري أو اتحاد كرة قدم أو لاعب، ولا يرعاها أي منهم. وأي أسماء حقيقية فيها لأغراض اللعب فقط، وعلاماتها ملك أصحابها.',
        'شعار GLM ورسومها وكودها ونصوصها ملك فريق التطوير، ولا يجوز نسخها أو إعادة نشرها دون إذن.',
      ] },
      { h: 'الخدمة كما هي', p: [
        'نقدم اللعبة «كما هي» ونعمل على أن تبقى متاحة، لكن قد تتوقف للصيانة أو للأعطال، وقد تتغير مزاياها أو تُحذف.',
        'لا نتحمل أي خسارة غير مباشرة من استخدام اللعبة أو تعذره، وفي حدود ما يسمح به القانون.',
      ] },
      { h: 'إنهاء الحساب', p: ['لك أن تحذف حسابك متى شئت من «حسابي». ولنا أن ننهي حساباً خالف هذه الشروط مخالفة جسيمة أو متكررة.'] },
      { h: 'التغييرات والتواصل', p: [
        'قد نحدّث هذه الشروط، ونعلن أي تغيير مهم داخل اللعبة. واستمرارك في اللعب بعده موافقة عليه.',
        'لأي سؤال أو اعتراض: صفحة «الدعم» داخل اللعبة، أو أزرار واتساب وتيليجرام أسفل هذه الصفحة.',
      ] },
    ],
  },
  en: {
    title: 'Terms and conditions',
    intro: 'These terms are an agreement between you and the GLM team when you use the game. By creating an account or playing you accept them and the privacy policy.',
    sections: [
      { h: 'Your account', p: [
        'You must be 13 or older (16 in the European Union without a parent\'s consent).',
        'One account per person, and you are responsible for everything done with it, so keep your password safe.',
        'Usernames and pictures must not offend anyone, nor impersonate the developers or anyone else.',
      ] },
      { h: 'Fair play', p: [
        'Not allowed: multiple accounts for your own gain, arranged transfers that move money between clubs unfairly, bots, scripts or exploits, and deliberately loading the server.',
        'Not allowed: insults, harassment, discrimination and inappropriate content in names, messages and leagues.',
        'We may undo what a violation produced, or suspend an account for a while or for good, telling you why; you may appeal from the Support page.',
      ] },
      { h: 'Coins and virtual items', p: [
        'Coins, club money, players and clubs in the game are virtual: they have no cash value, cannot be exchanged for money, and cannot be sold or transferred outside the game.',
        'We may change prices, rewards and balance whenever the game needs it, and this is not a loss owed compensation.',
        'Coins are not sold for real money at present. If that ever starts, the purchase and refund terms will be written here first.',
      ] },
      { h: 'Ads', p: [
        'The game is free and funded by ads. Clicking ads on purpose, asking others to click them, or watching them by any automated means is forbidden: it harms the game, breaks Google\'s policies, and may suspend the account.',
        'Video rewards (time cuts) are limited per task, and may pause when no ad is available.',
      ] },
      { h: 'Names and trademarks', p: [
        'GLM is an independent game, not affiliated with or endorsed by any football club, league, federation or player. Any real names in it are for play only, and their trademarks belong to their owners.',
        'The GLM logo, art, code and texts belong to the development team and may not be copied or republished without permission.',
      ] },
      { h: 'The service as it is', p: [
        'We provide the game "as is" and work to keep it available, but it may stop for maintenance or faults, and its features may change or be removed.',
        'We are not liable for any indirect loss from using or being unable to use the game, to the extent the law allows.',
      ] },
      { h: 'Ending your account', p: ['You may delete your account whenever you like from "My account". We may end an account that seriously or repeatedly breaks these terms.'] },
      { h: 'Changes and contact', p: [
        'We may update these terms, and announce any important change in the game. Playing on after it means you accept it.',
        'For any question or objection: the Support page in the game, or the WhatsApp and Telegram buttons at the bottom of this page.',
      ] },
    ],
  },
}

export const LEGAL = { privacy: PRIVACY, terms: TERMS }
export type LegalKind = keyof typeof LEGAL
