// [X57] The privacy policy and the terms (the owner's request 2026-10-29), in both languages: what Google AdSense and
// the stores ask of a published game. Written whole per language (not through t()), so each reads as one document.
// A change here moves UPDATED, and anything the game starts collecting is added to the privacy policy first.
import type { Locale } from '../lib/i18n'

export type LegalSection = { h: string; p: string[] }
export type LegalDoc = { title: string; intro: string; sections: LegalSection[] }

export const UPDATED = '2026-11-23'

const PRIVACY: Record<Locale, LegalDoc> = {
  ar: {
    title: 'سياسة الخصوصية',
    intro:
      'تشرح هذه السياسة ما تجمعه لعبة المدرب الأسطورة (GLM) من بيانات، ولماذا، وكيف نحميها، وحقوقك فيها. باستخدامك اللعبة توافق على ما فيها.',
    sections: [
      {
        h: 'من نحن',
        p: [
          'GLM لعبة إدارة كرة قدم على الويب يطوّرها فريق صغير مستقل. وللتواصل معنا في أي شأن يخص بياناتك: صفحة «الدعم» داخل اللعبة، أو أزرار واتساب وتيليجرام أسفل هذه الصفحة.',
        ],
      },
      {
        h: 'ما نجمعه منك',
        p: [
          'بيانات الحساب: الاسم الظاهر، واسم المستخدم، وكلمة المرور (محفوظة مشفرة لا نراها)، والبريد إن أضفته، وصورتك إن رفعتها، ولغتك، وشكل مدربك على الخط الذي تختاره (يراه مدربو دوريك في المباريات).',
          'الدخول بحساب Google: نأخذ من Google اسمك وبريدك ومعرّف حسابك فقط، لتسجيل دخولك، ولا نصل إلى أي شيء آخر في حسابك.',
          'بوت اللعبة على تيليجرام وواتساب (إن ربطته بنفسك من «حسابي»): رقم محادثتك في تيليجرام، أو رقم جوالك في واتساب، ووقت آخر رسالة أرسلتها للبوت، ورسائلك إليه لنجيب عنها. ولا نرسل لك عليه إلا إشعاراتك وأجوبتك، وتفك الربط متى شئت فيُحذف الرقم. وفي جروب تيليجرام يربطه منشئ الدوري تُنشر نتائج الجولات ونجومها وأهداف المباريات واستطلاع قبل كل جولة، وإن ربطه منشئ الدوري بجروب الدوري في اللعبة تظهر رسائل الأعضاء المربوطين في المكانين باسمهم. وفي قناة اللعبة العامة ننشر الإعلانات وترتيب المدربين الأسبوعي باسم المستخدم والنقاط فقط.',
          'اللعب كزائر في التطبيق: حساب بلا بريد ولا كلمة مرور، باسم مؤقت يصنعه الخادم، يدخل به جهازك برمز. وإن لم تحفظه باسم مستخدم وكلمة مرور أو بحساب Google خلال 30 يوماً يُحذف مع كل بياناته.',
          'بيانات اللعب: أنديتك ودورياتك وبطولاتك ومبارياتك وتكتيكاتك وصفقاتك ورسائلك داخل اللعبة وما تكتبه للدعم أو للمدرب المساعد.',
          'اقتراحاتك وأصواتك: ما ترسله في «اقتراحات التطوير» يقرؤه فريق التطوير، وصوتك في كل تصويت (لا يراه غيرنا، وتظهر للجميع الأعداد فقط). وإن أعجبنا اقتراحك يظهر اسمك وصورتك وعنوان اقتراحك في «قائمة الشرف» لكل المسجلين.',
          'رسائل الجروبات: ما تكتبه أو ترسله في جروب من نص وصور ورسائل صوتية يراه أعضاؤه كلهم ويُحفظ على خادمنا. تحذف رسالتك متى شئت فتظهر لهم «حُذفت» وتُمحى صورتها أو صوتها، وتحذف الإدارة الرسائل القديمة تلقائياً بعد مدة تحددها.',
          'البلاغات: إن بلّغت عن رسالة في جروب يصل للإدارة نص الرسالة وكاتبها وسبب بلاغك وتفاصيله إن كتبتها، ولا يعرف الكاتب من بلّغ عنه. وتحذف الإدارة الرسالة المسيئة، وقد توقف كاتبها عن الإرسال في الجروبات حتى تسمح له.',
          'دردشة القرعة المباشرة: ما تكتبه أو تتفاعل به أثناء قرعة بطولة يراه باسمك كل من يشاهدها الآن أو يعيد مشاهدتها لاحقاً، ويُحذف مع رسائل الجروبات بعد المدة نفسها. وإن شاركت في بطولة ظهر اسمك في قائمة مشاركيها لكل اللاعبين.',
          'تقييمك لردود المدرب المساعد: إن ضغطت «أفادني» أو «لم يفدني» نحفظ اختيارك والصفحة التي كنت فيها وملاحظتك إن كتبتها، لنحسّن ردوده. ولا نحفظ معها المحادثة نفسها.',
          'بيانات تقنية: عنوان IP ونوع المتصفح والجهاز وأوقات الدخول، لحماية الحسابات من الاختراق والإساءة ولإصلاح الأعطال.',
        ],
      },
      {
        h: 'لماذا نستخدمها',
        p: [
          'لتشغيل اللعبة: حسابك ودورياتك ومبارياتك الحية وإشعاراتك.',
          'لحماية اللاعبين: منع الغش والحسابات المتعددة والإساءة، والرد على البلاغات.',
          'لتحسين اللعبة: فهم ما يُستخدم وما يتعطل، بأرقام عامة لا تكشف أحداً.',
          'لعرض الإعلانات التي تموّل اللعبة وتبقيها مجانية (القسم التالي).',
          'لا نبيع بياناتك لأحد، ولا نشاركها إلا كما هو مكتوب هنا.',
        ],
      },
      {
        h: 'الإعلانات وGoogle AdSense',
        p: [
          'تعرض اللعبة إعلانات من Google AdSense: في أماكن نحددها، وفي أماكن تختارها Google تلقائياً من صفحات الموقع (الإعلانات التلقائية)، ونطلب منها ألا تضعها داخل المباراة. وفيديوهات بمكافأة تختار مشاهدتها لتقليص وقت التدريب أو البناء.',
          'Google وشركاؤها مزودون من طرف ثالث، ويستخدمون ملفات تعريف الارتباط (الكوكيز) لعرض الإعلانات بناءً على زياراتك السابقة لهذا الموقع ولمواقع أخرى. وتمكّن كوكيز الإعلانات Google وشركاءها من عرض الإعلانات لك بناءً على تلك الزيارات.',
          'يمكنك إيقاف الإعلانات المخصصة من إعدادات إعلانات Google (adssettings.google.com)، أو إيقاف كوكيز مزودي الإعلانات الآخرين من www.aboutads.info. وتشرح Google استخدامها للبيانات في policies.google.com/technologies/partner-sites.',
          'في المنطقة الاقتصادية الأوروبية والمملكة المتحدة وسويسرا تطلب Google موافقتك قبل أي إعلان مخصص، ويمكنك تغيير اختيارك متى شئت.',
          'وفيديوهات المكافأة اختيارية تماماً، واللعبة كاملة بدونها.',
        ],
      },
      {
        h: 'قياس الزيارات (Google Analytics وMeta Pixel)',
        p: [
          'نقيس كيف تُستعمل اللعبة لنحسّنها: الصفحات التي تُفتح، ونوع الجهاز والمتصفح والبلد التقريبي، ولحظات مثل إنشاء حساب أو دوري أو الانضمام إليه. ونستعمل لذلك Google Analytics، وMeta Pixel لقياس إعلاناتنا على فيسبوك وإنستغرام.',
          'لا نرسل إليهما اسمك ولا اسم المستخدم ولا بريدك ولا رسائلك، ولا نقيس شيئاً في لوحة الإدارة.',
          'في المنطقة الاقتصادية الأوروبية والمملكة المتحدة وسويسرا لا يُخزَّن شيء للقياس قبل موافقتك في رسالة Google، ويعمل Meta Pixel هناك فقط بموافقتك.',
          'يمكنك منع القياس بإضافة Google Analytics Opt-out (tools.google.com/dlpage/gaoptout)، وإعداداتك في فيسبوك (facebook.com/adpreferences).',
        ],
      },
      {
        h: 'خطواتك الأولى في اللعبة',
        p: [
          'نحفظ في حسابك وقت بدء مباراتك التعريفية الأولى ووقت انتهائها. ومنهما ومن اللعبة نفسها (أخذ نادٍ، وحفظ تشكيلة، ولعب مباراة) نعدّ في لوحة الإدارة كم من الحسابات الجديدة بلغ كل خطوة، أعداداً فقط لا أسماء، لنعرف أين يتوقف اللاعبون الجدد ونحسّن البداية. ولا يُرسل شيء منها إلى أي جهة.',
        ],
      },
      // [Sprint 66 B2] Before the crash reports were switched on.
      {
        h: 'بيانات الأعطال',
        p: [
          'حين يتعطل شيء في الموقع أو التطبيق على جهازك يرسل إلى خادمنا وحده تقريراً قصيراً: المنصة (ويب أو أندرويد أو آيفون)، ونسخة اللعبة، والشاشة التي كنت فيها بلا أرقامها، ونص الخطأ وأول سطور مكانه في الكود. لا يحمل التقرير حسابك ولا اسمك ولا عنوان جهازك، ونمسح منه أي بريد أو رقم طويل قد يظهر في نص الخطأ. وتُجمع التقارير المتشابهة في سطر واحد بعددها، يقرؤه فريق التطوير في لوحة الإدارة ليصلح العطل، ويُحذف بعد 30 يوماً من آخر مرة ظهر فيها. ولا يُرسل شيء منه إلى أي جهة أخرى.',
          // [Sprint 74 P2] Before the app's frame counts were switched on.
          'ويرسل التطبيق مرة في الجلسة أعداداً عن سلاسته على جوالك: كم إطاراً رسم في كل شاشة وكم منها تأخر، ونسخة التطبيق، ودرجة الجوال (ضعيف أو متوسط أو قوي). أعداد فقط: لا حساب معها ولا عنوان ولا اسم الجهاز، وتُجمع مع أعداد باقي اللاعبين وتُحذف بعد 30 يوماً. نستخدمها لنعرف أي شاشة تتقطع على الجوالات الضعيفة فنصلحها.',
        ],
      },
      {
        h: 'الكوكيز والتخزين في المتصفح',
        p: [
          'نستخدم كوكيز ضرورية لتسجيل دخولك وحماية النماذج (الجلسة وXSRF)، ولا تعمل اللعبة بدونها.',
          'ونحفظ في متصفحك اختياراتك (اللغة والمظهر والصوت) ليبقى شكل اللعبة كما تحب.',
          'وإن ضغطت «احفظ وتابع لاحقاً» في المدرب المساعد تبقى آخر محادثة معه في متصفحك وحده، لا عندنا، حتى تبدأ من جديد.',
          'وكوكيز الإعلانات وقياس الزيارات من Google وMeta كما في القسمين السابقين.',
        ],
      },
      {
        h: 'من يعالج البيانات معنا',
        p: [
          'الاستضافة: خادمنا لدى Hostinger، وعليه قاعدة البيانات ونسخها الاحتياطية.',
          'Google: الدخول بحساب Google، والإعلانات (AdSense)، وقياس الزيارات (Analytics)، والمدرب المساعد (Gemini) الذي يُرسل إليه سؤالك وأرقام فريقك اللازمة للإجابة فقط، بلا اسمك ولا بريدك.',
          'Meta: قياس إعلاناتنا على فيسبوك وإنستغرام (Meta Pixel)، وبموافقتك في أوروبا، وبوت واتساب (WhatsApp Cloud API) إن ربطته.',
          'Telegram: بوت تيليجرام وقناة اللعبة، إن ربطته أو اشتركت فيها.',
          'البريد: خدمة إرسال البريد (Gmail من Google) التي توصل رسائل التوثيق واستعادة كلمة المرور، وملخص مبارياتك بالبريد وعروض المتجر بالبريد إن فعّلت كلاً منهما بنفسك من «حسابي» ← الإشعارات (متوقفان حتى تفعّلهما، وتوقفهما متى شئت).',
        ],
      },
      {
        h: 'مدة الاحتفاظ',
        p: [
          'نحتفظ ببيانات حسابك ما دام قائماً. وحين تحذفه يُحذف معه كل ما هو خاص بك (المحفظة والرسائل والأجهزة والنشاط)، وتعود أنديتك للبوتات، وتبقى نتائج المباريات والألقاب في سجل الدوري بلا اسمك، ورسائلك في الجروبات لأعضائها بلا اسمك (احذفها قبل حذف الحساب إن شئت).',
          // [Sprint 75 W3, WEB-03] The inactivity rule, with config('game.inactivity')'s numbers (PublicGuideTest checks them).
          'والحساب الذي لا يُفتح 14 يوماً متتالية يُحذف نهائياً مع فرقه وكل بياناته كما لو حذفته بنفسك، إلا وهو في إجازة حساب (من «حسابي»). وقبل ذلك، بعد 12 يوماً من الغياب، يصلك تنبيه في «الرسائل» وعلى ما فعّلته من الإشعارات. ويكفي أي دخول أو فتح للعبة على أي جهاز ليبدأ العدّ من جديد. وحساب الزائر الذي لم يُحفظ يُحذف أيضاً بعد 30 يوماً من إنشائه ولو كان يُفتح، كما في أعلاه.',
          'والسجلات التقنية تُحذف تلقائياً بعد مدة قصيرة، والنسخ الاحتياطية تتجدد دورياً.',
        ],
      },
      {
        h: 'حقوقك',
        p: [
          'أن تطلع على بياناتك وتصححها من صفحة «حسابي».',
          'أن تحذف حسابك نهائياً من «حسابي» في أي وقت، بلا سؤال عن السبب.',
          'أن تطلب نسخة من بياناتك أو تعترض على معالجتها، بمراسلتنا من صفحة الدعم، ونرد خلال 30 يوماً.',
        ],
      },
      {
        h: 'الأطفال',
        p: [
          'اللعبة لمن عمره 13 سنة فأكثر (و16 في الاتحاد الأوروبي إلا بموافقة ولي الأمر). ولا نجمع عن قصد بيانات من هم أصغر، وإن علمنا بحساب لطفل حذفناه.',
        ],
      },
      {
        h: 'الحماية',
        p: [
          'الاتصال بالموقع مشفر (HTTPS)، وكلمات المرور مشفرة، والوصول إلى الخادم بمفاتيح خاصة فقط. ومع ذلك لا يوجد نظام آمن 100%، فاختر كلمة مرور لا تستخدمها في مكان آخر.',
        ],
      },
      { h: 'التغييرات', p: ['قد نحدّث هذه السياسة، ونكتب تاريخ آخر تحديث أعلاها، ونعلن أي تغيير مهم داخل اللعبة.'] },
    ],
  },
  en: {
    title: 'Privacy policy',
    intro:
      'This policy explains what data GLM (Game Legend Manager) collects, why, how we protect it, and your rights over it. By using the game you agree to it.',
    sections: [
      {
        h: 'Who we are',
        p: [
          'GLM is a web football management game made by a small independent team. For anything about your data, reach us from the Support page in the game, or the WhatsApp and Telegram buttons at the bottom of this page.',
        ],
      },
      {
        h: 'What we collect',
        p: [
          'Account data: your display name, username, password (stored hashed; we never see it), your email if you add one, your picture if you upload one, your language, and the look you pick for your coach on the touchline (the coaches of your leagues see it in matches).',
          'Google sign-in: we receive only your name, email and account id from Google, to sign you in, and nothing else in your Google account.',
          "The game's bot on Telegram and WhatsApp (only if you link it yourself in My account): your Telegram chat number, or your WhatsApp phone number, the time of your last message to the bot, and your messages to it so we can answer them. We send you there only your notifications and answers, and you can unlink at any time, which deletes the number. In a Telegram group its league's owner links, the rounds' results and stars, the matches' goals and a poll before each round are posted; and if the league's owner joins it to the league's chat in the game, the linked members' messages appear in both places under their names. In the game's public channel we post the announcements and the weekly table of coaches, by username and points only.",
          'Playing as a guest in the app: an account with no email or password, under a temporary name the server makes, signed in on your device by a token. Unless you keep it with a username and password or a Google account within 30 days, it is deleted with all its data.',
          'Game data: your clubs, leagues, tournaments, matches, tactics, transfers, in-game messages, and what you write to support or to the Assistant Coach.',
          'Your suggestions and votes: what you send in «Development ideas» is read by the development team, and your vote in each poll (seen by nobody else; everyone sees only the counts). If we like your suggestion, your name, picture and its title appear on the «Honour roll» for every signed-up player.',
          "Group messages: the text, photos and voice notes you send in a group are seen by all its members and kept on our server. You can delete a message at any time: they then see it as deleted and its photo or sound is erased; and old messages are deleted automatically after a period the game's admins set.",
          'Reports: if you report a message in a group, the admins receive the message, its writer, your reason and any details you add; the writer is not told who reported it. The admins may delete an offending message and may stop its writer from sending in groups until they allow it again.',
          "The live draw chat: what you write or react with during a tournament's draw is seen with your name by everyone watching it now or replaying it later, and is deleted with the group messages after the same period. If you enter a tournament, your name shows in its list of entrants to every player.",
          'Your rating of the Assistant Coach\'s answers: if you tap "helpful" or "not helpful" we keep your choice, the page you were on and your note if you wrote one, to improve his answers. The conversation itself is not kept with it.',
          'Technical data: IP address, browser and device type, and sign-in times, to protect accounts from abuse and to fix problems.',
        ],
      },
      {
        h: 'Why we use it',
        p: [
          'To run the game: your account, leagues, live matches and notifications.',
          'To protect players: stopping cheating, multiple accounts and abuse, and answering reports.',
          'To improve the game: understanding what is used and what breaks, with overall numbers that identify no one.',
          'To show the ads that fund the game and keep it free (next section).',
          'We never sell your data, and share it only as written here.',
        ],
      },
      {
        h: 'Ads and Google AdSense',
        p: [
          "The game shows Google AdSense ads: in places we set, and in places Google picks automatically on the site's pages (Auto ads), which we ask it to keep out of matches. And rewarded videos you may choose to watch to cut training or building time.",
          "Third party vendors, including Google, use cookies to serve ads based on your prior visits to this website or other websites. Google's use of advertising cookies enables it and its partners to serve ads to you based on those visits.",
          "You may opt out of personalised advertising in Google's Ads Settings (adssettings.google.com), and out of other vendors' cookies at www.aboutads.info. Google explains how it uses data at policies.google.com/technologies/partner-sites.",
          'In the European Economic Area, the UK and Switzerland, Google asks for your consent before any personalised ad, and you can change your choice at any time.',
          'Rewarded videos are entirely optional; the whole game works without them.',
        ],
      },
      {
        h: 'Measuring visits (Google Analytics and the Meta Pixel)',
        p: [
          'We measure how the game is used to make it better: the pages opened, the kind of device and browser and the rough country, and moments such as creating an account or a league or joining one. We use Google Analytics for it, and the Meta Pixel to measure our ads on Facebook and Instagram.',
          'We never send them your name, username, email or messages, and we measure nothing in the admin panel.',
          "In the European Economic Area, the UK and Switzerland nothing is stored for measurement until you agree in Google's consent message, and the Meta Pixel runs there only with your consent.",
          'You can block the measurement with the Google Analytics Opt-out add-on (tools.google.com/dlpage/gaoptout), and in your Facebook settings (facebook.com/adpreferences).',
        ],
      },
      {
        h: 'Your first steps in the game',
        p: [
          'We keep in your account when your first intro match started and when it ended. From them and from the game itself (taking a club, saving a lineup, playing a match) the admin panel counts how many new accounts reached each step, as numbers only, never names, so we know where new players stop and can improve the start. None of it is sent anywhere.',
        ],
      },
      {
        h: 'Crash data',
        p: [
          "When something breaks in the site or the app on your device, it sends a short report to our own server only: the platform (web, Android or iPhone), the game's version, the screen you were on without its numbers, and the error's text with the first lines of where it happened in the code. The report carries no account, no name and no device address, and we wipe any email or long number that may appear in the error's text. Similar reports are gathered on one line with their count, read by the development team in the admin panel to fix the fault, and deleted 30 days after it was last seen. None of it is sent anywhere else.",
          "Once a session the app also sends counts of how smoothly it ran on your phone: how many frames each screen drew and how many came late, the app version, and the phone's tier (low, mid or high). Counts only: no account, no address and no device name go with them; they are added to the other players' counts and deleted after 30 days. We use them to find the screens that stutter on weak phones and fix them.",
        ],
      },
      {
        h: 'Cookies and browser storage',
        p: [
          'We use essential cookies to keep you signed in and to protect forms (session and XSRF); the game cannot work without them.',
          'We keep your choices (language, look and sound) in your browser so the game stays the way you like it.',
          'If you tap "Save and continue later" in the Assistant Coach, your last conversation with him stays in your browser only, not with us, until you start again.',
          'And the advertising and measurement cookies of Google and Meta, as in the two previous sections.',
        ],
      },
      {
        h: 'Who processes data with us',
        p: [
          'Hosting: our server at Hostinger, with the database and its backups.',
          'Google: Google sign-in, ads (AdSense), measuring visits (Analytics), and the Assistant Coach (Gemini), which receives your question and only the numbers about your team it needs to answer, without your name or email.',
          'Meta: measuring our ads on Facebook and Instagram (the Meta Pixel), with your consent in Europe, and the WhatsApp bot (the WhatsApp Cloud API) if you link it.',
          "Telegram: the Telegram bot and the game's channel, if you link it or follow it.",
          'Email: the sending service (Gmail, from Google) that delivers verification and password reset emails, and your match summaries and the store offers by email if you turn each on yourself in My account, then Notifications (off until you do, and you can turn them off at any time).',
        ],
      },
      {
        h: 'How long we keep it',
        p: [
          "We keep your account data while your account exists. When you delete it, everything that is only yours goes with it (wallet, messages, devices, activity), your clubs return to the bots, match results and titles stay in the league's history without your name, and your group messages stay for their members without your name (delete them before deleting the account if you wish).",
          'An account that is not opened for 14 days in a row is deleted for good, with its teams and all its data, as if you had deleted it yourself, unless it is on an account holiday (in My account). Before that, after 12 days away, a warning reaches your Messages and the notifications you have turned on. Any sign-in, or opening the game on any device, starts the count again. A guest account that is never kept is also deleted 30 days after it was made, even if it is opened, as above.',
          'Technical logs are deleted automatically after a short time, and backups are rotated.',
        ],
      },
      {
        h: 'Your rights',
        p: [
          'To see and correct your data from "My account".',
          'To delete your account for good from "My account" at any time, without giving a reason.',
          'To ask for a copy of your data or object to its processing, by writing to us from the Support page; we answer within 30 days.',
        ],
      },
      {
        h: 'Children',
        p: [
          "The game is for people aged 13 and over (16 in the European Union without a parent's consent). We do not knowingly collect data from anyone younger, and delete such an account when we learn of it.",
        ],
      },
      {
        h: 'Security',
        p: [
          'The connection is encrypted (HTTPS), passwords are hashed, and the server is reached with private keys only. Still, no system is 100% secure, so pick a password you use nowhere else.',
        ],
      },
      {
        h: 'Changes',
        p: ['We may update this policy; the date of the last update is at its top, and any important change is announced in the game.'],
      },
    ],
  },
}

const TERMS: Record<Locale, LegalDoc> = {
  ar: {
    title: 'الشروط والأحكام',
    intro: 'هذه الشروط اتفاق بينك وبين فريق GLM حين تستخدم اللعبة. بإنشائك حساباً أو لعبك فأنت توافق عليها وعلى سياسة الخصوصية.',
    sections: [
      {
        h: 'الحساب',
        p: [
          'يجب أن يكون عمرك 13 سنة فأكثر (و16 في الاتحاد الأوروبي إلا بموافقة ولي الأمر).',
          'حساب واحد لكل شخص، وأنت مسؤول عن كل ما يجري فيه، فاحفظ كلمة مرورك.',
          'اسم المستخدم والصورة لا يسيئان لأحد، ولا ينتحلان شخصية المطورين أو غيرهم.',
        ],
      },
      {
        h: 'اللعب النظيف',
        p: [
          'ممنوع: الحسابات المتعددة لنفع نفسك، والاتفاق على صفقات تنقل المال بين الأندية بغير وجه حق، واستخدام البرامج أو السكربتات أو الثغرات، والضغط المتعمد على الخادم.',
          'ممنوع السب والتحرش والتمييز والمحتوى غير اللائق في الأسماء والرسائل والدوريات.',
          'لنا أن نلغي ما نتج عن مخالفة، أو نوقف الحساب مؤقتاً أو نهائياً، مع إخبارك بالسبب، ولك أن تراجعنا من صفحة الدعم.',
        ],
      },
      {
        h: 'الكوينز والمحتوى الافتراضي',
        p: [
          'الكوينز وأموال النادي واللاعبون والأندية داخل اللعبة افتراضية: لا قيمة نقدية لها، ولا تُستبدل بمال، ولا تُباع ولا تُنقل خارج اللعبة.',
          'نملك حق تعديل الأسعار والمكافآت والتوازن متى احتاجت اللعبة، ولا يُعد ذلك خسارة تستحق التعويض.',
          'لا تُباع الكوينز بمال حقيقي حالياً. وإن بدأنا ذلك يوماً فستُكتب شروط الشراء والاسترداد هنا قبله.',
        ],
      },
      {
        h: 'الإعلانات',
        p: [
          'اللعبة مجانية ويموّلها الإعلان. يُمنع النقر المتعمد على الإعلانات أو دعوة غيرك للنقر عليها أو استخدام أي وسيلة آلية لمشاهدتها، فهذا يضر اللعبة ويخالف سياسات Google، وقد يوقف الحساب.',
          'مكافآت الفيديو (تقليص الوقت) محددة بعدد لكل مهمة، وقد تتوقف إن لم يتوفر إعلان.',
        ],
      },
      {
        h: 'الأسماء والعلامات',
        p: [
          'GLM لعبة مستقلة، وغير تابعة لأي نادٍ أو دوري أو اتحاد كرة قدم أو لاعب، ولا يرعاها أي منهم. وأي أسماء حقيقية فيها لأغراض اللعب فقط، وعلاماتها ملك أصحابها.',
          'شعار GLM ورسومها وكودها ونصوصها ملك فريق التطوير، ولا يجوز نسخها أو إعادة نشرها دون إذن.',
        ],
      },
      {
        h: 'الخدمة كما هي',
        p: [
          'نقدم اللعبة «كما هي» ونعمل على أن تبقى متاحة، لكن قد تتوقف للصيانة أو للأعطال، وقد تتغير مزاياها أو تُحذف.',
          'لا نتحمل أي خسارة غير مباشرة من استخدام اللعبة أو تعذره، وفي حدود ما يسمح به القانون.',
        ],
      },
      {
        h: 'إنهاء الحساب',
        p: [
          'لك أن تحذف حسابك متى شئت من «حسابي». ولنا أن ننهي حساباً خالف هذه الشروط مخالفة جسيمة أو متكررة.',
          'والحساب الذي لا يُفتح 14 يوماً متتالية بلا إجازة حساب يُحذف نهائياً مع فرقه، بعد تنبيه في «الرسائل» بعد 12 يوماً من الغياب (التفاصيل في «سياسة الخصوصية» ← مدة الاحتفاظ).',
        ],
      },
      {
        h: 'التغييرات والتواصل',
        p: [
          'قد نحدّث هذه الشروط، ونعلن أي تغيير مهم داخل اللعبة. واستمرارك في اللعب بعده موافقة عليه.',
          'لأي سؤال أو اعتراض: صفحة «الدعم» داخل اللعبة، أو أزرار واتساب وتيليجرام أسفل هذه الصفحة.',
        ],
      },
    ],
  },
  en: {
    title: 'Terms and conditions',
    intro:
      'These terms are an agreement between you and the GLM team when you use the game. By creating an account or playing you accept them and the privacy policy.',
    sections: [
      {
        h: 'Your account',
        p: [
          "You must be 13 or older (16 in the European Union without a parent's consent).",
          'One account per person, and you are responsible for everything done with it, so keep your password safe.',
          'Usernames and pictures must not offend anyone, nor impersonate the developers or anyone else.',
        ],
      },
      {
        h: 'Fair play',
        p: [
          'Not allowed: multiple accounts for your own gain, arranged transfers that move money between clubs unfairly, bots, scripts or exploits, and deliberately loading the server.',
          'Not allowed: insults, harassment, discrimination and inappropriate content in names, messages and leagues.',
          'We may undo what a violation produced, or suspend an account for a while or for good, telling you why; you may appeal from the Support page.',
        ],
      },
      {
        h: 'Coins and virtual items',
        p: [
          'Coins, club money, players and clubs in the game are virtual: they have no cash value, cannot be exchanged for money, and cannot be sold or transferred outside the game.',
          'We may change prices, rewards and balance whenever the game needs it, and this is not a loss owed compensation.',
          'Coins are not sold for real money at present. If that ever starts, the purchase and refund terms will be written here first.',
        ],
      },
      {
        h: 'Ads',
        p: [
          "The game is free and funded by ads. Clicking ads on purpose, asking others to click them, or watching them by any automated means is forbidden: it harms the game, breaks Google's policies, and may suspend the account.",
          'Video rewards (time cuts) are limited per task, and may pause when no ad is available.',
        ],
      },
      {
        h: 'Names and trademarks',
        p: [
          'GLM is an independent game, not affiliated with or endorsed by any football club, league, federation or player. Any real names in it are for play only, and their trademarks belong to their owners.',
          'The GLM logo, art, code and texts belong to the development team and may not be copied or republished without permission.',
        ],
      },
      {
        h: 'The service as it is',
        p: [
          'We provide the game "as is" and work to keep it available, but it may stop for maintenance or faults, and its features may change or be removed.',
          'We are not liable for any indirect loss from using or being unable to use the game, to the extent the law allows.',
        ],
      },
      {
        h: 'Ending your account',
        p: [
          'You may delete your account whenever you like from "My account". We may end an account that seriously or repeatedly breaks these terms.',
          'An account that is not opened for 14 days in a row, with no account holiday, is deleted for good with its teams, after a warning in your Messages at 12 days away (the details are in the Privacy policy, How long we keep it).',
        ],
      },
      {
        h: 'Changes and contact',
        p: [
          'We may update these terms, and announce any important change in the game. Playing on after it means you accept it.',
          'For any question or objection: the Support page in the game, or the WhatsApp and Telegram buttons at the bottom of this page.',
        ],
      },
    ],
  },
}

export const LEGAL = { privacy: PRIVACY, terms: TERMS }
export type LegalKind = keyof typeof LEGAL
