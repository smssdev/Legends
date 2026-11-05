// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'المدرب الأسطورة';

  @override
  String get tagline => 'لعبة إدارة كرة قدم عربية مجانية';

  @override
  String get signIn => 'دخول';

  @override
  String get signInTitle => 'أهلاً بعودتك';

  @override
  String get signInLead => 'ادخل لتكمل موسمك';

  @override
  String get emailOrUsername => 'البريد أو اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيتها؟';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'أنشئ حساباً';

  @override
  String get haveAccount => 'عندك حساب؟';

  @override
  String get registerTitle => 'حسابك الجديد';

  @override
  String get registerLead =>
      'ثلاث خانات وتبدأ: اسمك، واسم المستخدم، وكلمة المرور';

  @override
  String get displayName => 'اسمك الظاهر';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'حروف إنجليزية وأرقام، 3 إلى 20';

  @override
  String get emailOptional => 'البريد (اختياري، لاستعادة كلمة المرور)';

  @override
  String get passwordHint => '8 أحرف على الأقل';

  @override
  String get acceptTerms => 'أوافق على الشروط وسياسة الخصوصية';

  @override
  String get termsAndPrivacy => 'الشروط وسياسة الخصوصية';

  @override
  String get mustAcceptTerms => 'وافق على الشروط وسياسة الخصوصية أولاً';

  @override
  String get register => 'إنشاء الحساب';

  @override
  String get forgotTitle => 'استعادة كلمة المرور';

  @override
  String get forgotLead => 'اكتب بريد حسابك ونرسل لك رابطاً لكلمة مرور جديدة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get sendLink => 'أرسل الرابط';

  @override
  String get linkSent =>
      'أرسلنا الرابط إن كان البريد لحساب عندنا. افتحه من بريدك.';

  @override
  String get required => 'مطلوب';

  @override
  String get google => 'المتابعة بحساب Google';

  @override
  String get googleSoon => 'الدخول بجوجل قريباً في التطبيق';

  @override
  String get orByEmail => 'أو بالبريد';

  @override
  String get updateTitle => 'حدّث التطبيق';

  @override
  String get updateBody =>
      'نسخة جديدة من اللعبة متاحة، ولا تعمل هذه النسخة معها. حدّث التطبيق لتكمل.';

  @override
  String get update => 'حدّث الآن';

  @override
  String get offlineTitle => 'لا اتصال';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get greetingMorning => 'صباح الخير يا كوتش';

  @override
  String get greetingEvening => 'مساء الخير يا كوتش';

  @override
  String get coins => 'كوينز';

  @override
  String get myTeams => 'فرقي';

  @override
  String slotsOpen(int open, int total) {
    return '$open من $total';
  }

  @override
  String get slotFree => 'فتحة فارغة';

  @override
  String get slotWaiting => 'طلب انضمام ينتظر الرد';

  @override
  String get slotLocked => 'مقفلة';

  @override
  String slotOpensIn(String time) {
    return 'تُفتح مجاناً بعد $time';
  }

  @override
  String get createLeague => 'أنشئ دورياً';

  @override
  String get joinByCode => 'انضم بكود';

  @override
  String get openClub => 'ادخل النادي';

  @override
  String get nextMatch => 'المباراة القادمة';

  @override
  String vs(String club) {
    return 'ضد $club';
  }

  @override
  String position(int n, int of) {
    return 'المركز $n من $of';
  }

  @override
  String waitsForYou(int n) {
    return '$n ينتظرك';
  }

  @override
  String record(int w, int d, int l) {
    return '$w فوز · $d تعادل · $l خسارة';
  }

  @override
  String get onWebForNow => 'تُفتح في الموقع حتى تصل إلى التطبيق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get look => 'المظهر';

  @override
  String get lookAuto => 'تلقائي';

  @override
  String get lookNight => 'ليلي';

  @override
  String get lookDay => 'نهاري';

  @override
  String get language => 'اللغة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'تسجيل الخروج من هذا الجوال؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String accountNo(int n) {
    return 'رقم حسابك $n';
  }

  @override
  String days(int n) {
    return '$n يوم';
  }

  @override
  String hours(int n) {
    return '$n ساعة';
  }

  @override
  String minutes(int n) {
    return '$n دقيقة';
  }

  @override
  String version(String v) {
    return 'النسخة $v';
  }

  @override
  String get tierProspect => 'الواعد';

  @override
  String get tierTactician => 'التكتيكي';

  @override
  String get tierProfessional => 'المحترف';

  @override
  String get tierElite => 'النخبة';

  @override
  String get tierMastermind => 'العقل المدبر';

  @override
  String get tierIcon => 'الأيقونة';

  @override
  String get tierLegend => 'الأسطورة';

  @override
  String get myLeagues => 'دورياتي';

  @override
  String get noLeagues => 'لا دوري لك بعد. أنشئ دورياً لأصحابك أو انضم بكود.';

  @override
  String get newLeague => 'دوري جديد';

  @override
  String get freeLeagueLead =>
      'الدوري المجاني: كل أندية الدوري، جولة كل يوم الساعة 9 مساءً، ويومان للتحضير. والخيارات المدفوعة من الموقع.';

  @override
  String get pickTemplate => 'اختر الدوري';

  @override
  String get pickClub => 'اختر فريقك';

  @override
  String get leagueName => 'اسم الدوري (اختياري)';

  @override
  String get create => 'أنشئ الدوري';

  @override
  String clubsCount(int n) {
    return '$n نادٍ';
  }

  @override
  String get joinTitle => 'انضم إلى دوري';

  @override
  String get joinLead =>
      'اطلب من صاحبك كود دوريه واكتبه هنا، ثم ينتظر طلبك موافقة المنشئ.';

  @override
  String get code => 'كود الدوري';

  @override
  String get sendRequest => 'أرسل الطلب';

  @override
  String get requestPending => 'طلبك ينتظر موافقة المنشئ.';

  @override
  String get requestApproved => 'وافق المنشئ. اختر فريقك الآن.';

  @override
  String get requestRejected => 'رفض المنشئ طلبك.';

  @override
  String get cancelRequest => 'ألغِ الطلب';

  @override
  String get takeClub => 'خذ هذا الفريق';

  @override
  String get goalTitle => 'الهدف: اللقب';

  @override
  String goalPlace(int n) {
    return 'الهدف: المركز $n أو أفضل';
  }

  @override
  String goalSurvive(int n) {
    return 'الهدف: البقاء في المركز $n أو أفضل';
  }

  @override
  String strength(int n) {
    return 'القوة $n';
  }

  @override
  String get tabClub => 'النادي';

  @override
  String get tabTable => 'الترتيب';

  @override
  String get tabFixtures => 'المباريات';

  @override
  String get tabCoaches => 'المدربون';

  @override
  String waitingStart(String when) {
    return 'يبدأ الدوري $when';
  }

  @override
  String round(int n) {
    return 'الجولة $n';
  }

  @override
  String get cup => 'الكأس';

  @override
  String get invite => 'ادعُ أصحابك';

  @override
  String inviteText(String name, String url) {
    return 'انضم لدوري «$name» في لعبة المدرب الأسطورة واختر ناديك: $url';
  }

  @override
  String get requests => 'طلبات الانضمام';

  @override
  String get approve => 'وافق';

  @override
  String get reject => 'ارفض';

  @override
  String get creator => 'المنشئ';

  @override
  String get onHoliday => 'في إجازة';

  @override
  String get home => 'على أرضك';

  @override
  String get away => 'خارج أرضك';

  @override
  String get nextMatchShort => 'مباراتك القادمة';

  @override
  String get lineupReady => 'التشكيلة جاهزة';

  @override
  String get lineupAuto => 'التشكيلة تلقائية';

  @override
  String get board => 'الإدارة';

  @override
  String get noMatches => 'لا مباريات بعد.';

  @override
  String get openOnSite => 'افتح في الموقع';

  @override
  String get copied => 'نُسخ';

  @override
  String get share => 'شارك';

  @override
  String get pts => 'ن';

  @override
  String get sign => 'وقّع';

  @override
  String get squad => 'الفريق';

  @override
  String get lineup => 'التشكيلة';

  @override
  String get tactics => 'التكتيك';

  @override
  String get lineGk => 'حراسة المرمى';

  @override
  String get lineDef => 'الدفاع';

  @override
  String get lineMid => 'الوسط';

  @override
  String get lineAtt => 'الهجوم';

  @override
  String get starter => 'أساسي';

  @override
  String get bench => 'احتياط';

  @override
  String get reserve => 'خارج القائمة';

  @override
  String injuredFor(int n) {
    return 'مصاب $n مباراة';
  }

  @override
  String suspendedFor(int n) {
    return 'موقوف $n مباراة';
  }

  @override
  String age(int n) {
    return 'العمر $n';
  }

  @override
  String potential(int n) {
    return 'الإمكانية $n';
  }

  @override
  String get fitness => 'اللياقة';

  @override
  String morale(int n) {
    return 'المعنويات $n';
  }

  @override
  String get squadValue => 'قيمة الفريق';

  @override
  String get formation => 'الخطة';

  @override
  String get autoLineup => 'تلقائية';

  @override
  String get save => 'احفظ';

  @override
  String get saved => 'حُفظ';

  @override
  String get swapWith => 'بدّله مع';

  @override
  String get tapToSwap => 'اضغط لاعباً في الملعب ثم بديله';

  @override
  String get plan => 'الخطة الهجومية';

  @override
  String get tackling => 'قطع الكرة';

  @override
  String get pressing => 'الضغط على الخصم';

  @override
  String get style => 'الأسلوب';

  @override
  String get tempo => 'إيقاع اللعب';

  @override
  String get trap => 'مصيدة التسلل';

  @override
  String get marking => 'الرقابة';

  @override
  String get markZone => 'دفاع المنطقة';

  @override
  String get markMan => 'رجل لرجل';

  @override
  String get planCounter => 'هجوم مرتد';

  @override
  String get planShots => 'تسديد عن بعد';

  @override
  String get planLong => 'كرات طويلة';

  @override
  String get planPassing => 'تمريرات';

  @override
  String get planWings => 'لعب على الأجنحة';

  @override
  String get tackle0 => 'قانوني';

  @override
  String get tackle1 => 'عادي';

  @override
  String get tackle2 => 'حماس';

  @override
  String get tackle3 => 'خشونة';

  @override
  String get attBack => 'ارتداد';

  @override
  String get attSupport => 'مساندة الوسط';

  @override
  String get attOnly => 'هجوم فقط';

  @override
  String get midDef => 'مساندة الدفاع';

  @override
  String get midStay => 'بقاء';

  @override
  String get midPush => 'اندفاع';

  @override
  String get defStay => 'بقاء';

  @override
  String get defFullbacks => 'هجوم الظهيرين';

  @override
  String get defMid => 'مساندة الوسط';

  @override
  String get low => 'منخفض';

  @override
  String get high => 'عالٍ';

  @override
  String get defensive => 'دفاعي';

  @override
  String get attacking => 'هجومي';

  @override
  String get calm => 'هادئ';

  @override
  String get fast => 'سريع';

  @override
  String get savesItself => 'يُحفظ وحده مع كل تغيير';

  @override
  String get attributes => 'المهارات';

  @override
  String get value => 'القيمة';

  @override
  String get ratingWord => 'التقييم';

  @override
  String get potentialWord => 'الإمكانية';

  @override
  String get watchLive => 'شاهد المباراة';

  @override
  String get liveNow => 'مباشر';

  @override
  String get fullTime => 'نهاية المباراة';

  @override
  String get notStarted => 'لم تبدأ بعد';

  @override
  String get matchReport => 'تقرير المباراة';

  @override
  String get commentary => 'التعليق';

  @override
  String get assistantNotes => 'ملاحظات مساعدك';

  @override
  String get substitute => 'تبديل';

  @override
  String get subOut => 'يخرج';

  @override
  String get subIn => 'يدخل';

  @override
  String subsLeft(int used, int max) {
    return '$used من $max تبديلات';
  }

  @override
  String get ordersHint =>
      'الأوامر تُنفَّذ في النوافذ: قبل البداية وبين الشوطين وبعد الدقائق 15 و30 و60 و75.';

  @override
  String get windowOpen => 'النافذة مفتوحة: أوامرك الآن';

  @override
  String get imReady => 'أنا مستعد';

  @override
  String get readyWaiting => 'في انتظار المدرب الآخر';

  @override
  String get breakTime => 'استراحة';

  @override
  String get orderSent => 'وصل الأمر، يُنفَّذ في الدقيقة التالية';

  @override
  String get send => 'أرسل';

  @override
  String get possession => 'الاستحواذ';

  @override
  String get shots => 'التسديدات';

  @override
  String get onTarget => 'على المرمى';

  @override
  String get corners => 'الركنيات';

  @override
  String get fouls => 'الأخطاء';

  @override
  String get saves => 'التصديات';

  @override
  String get manOfMatch => 'رجل المباراة';

  @override
  String get toImprove => 'ما يُحسَّن';

  @override
  String get whyResult => 'لماذا هذه النتيجة';

  @override
  String get keyMoments => 'أهم اللحظات';

  @override
  String get bestPlayers => 'الأفضل';

  @override
  String get resultWin => 'فوز';

  @override
  String get resultDraw => 'تعادل';

  @override
  String get resultLoss => 'خسارة';

  @override
  String get pitchView => 'الملعب';

  @override
  String kickoffAt(String time) {
    return 'البداية $time';
  }

  @override
  String get inbox => 'الرسائل';

  @override
  String get noMessages => 'لا رسائل بعد';

  @override
  String get readAll => 'قرأتها كلها';

  @override
  String get more => 'المزيد';

  @override
  String get finance => 'المالية';

  @override
  String get balance => 'الرصيد';

  @override
  String get seasonIncome => 'دخل الموسم';

  @override
  String get seasonExpenses => 'مصروفات الموسم';

  @override
  String get wagesPerRound => 'الرواتب كل جولة';

  @override
  String inDebt(int rounds, int limit) {
    return 'النادي مدين: لا شراء ولا بناء حتى يعود الرصيد موجباً ($rounds من $limit جولات)';
  }

  @override
  String get ticketPrice => 'سعر التذاكر';

  @override
  String perMatch(String amount) {
    return '$amount في المباراة';
  }

  @override
  String attendance(int pct) {
    return 'الحضور $pct%';
  }

  @override
  String get sponsors => 'الرعاة';

  @override
  String perWin(String amount) {
    return '+$amount للفوز';
  }

  @override
  String get signSponsorConfirm => 'توقيع هذا العرض للموسم كله؟';

  @override
  String get signed => 'موقَّع';

  @override
  String get transactions => 'الحركات';

  @override
  String get stadium => 'الملعب';

  @override
  String stadiumProgress(int done, int total) {
    return '$done من $total أجزاء';
  }

  @override
  String get capacity => 'السعة';

  @override
  String get homeAdvantage => 'أفضلية الأرض';

  @override
  String get sectionSeats => 'التذاكر والمقاعد';

  @override
  String get sectionPitch => 'أرضية الملعب';

  @override
  String get sectionTraining => 'مركز التدريب';

  @override
  String stageOf(int stage) {
    return 'المرحلة $stage من 3';
  }

  @override
  String partOf(int part) {
    return 'الجزء $part من 5';
  }

  @override
  String buildPart(String cost) {
    return 'ابنِ ($cost)';
  }

  @override
  String get sectionDone => 'مكتمل';

  @override
  String buildingNow(String section) {
    return 'يُبنى الآن: $section';
  }

  @override
  String endsIn(String time) {
    return 'ينتهي بعد $time';
  }

  @override
  String finishNow(int coins) {
    return 'أنهِه الآن ($coins كوينز)';
  }

  @override
  String finishNowConfirm(int coins) {
    return 'إنهاء الجزء الآن مقابل $coins كوينز؟';
  }

  @override
  String partTime(String time) {
    return 'كل جزء يأخذ $time';
  }

  @override
  String get confirm => 'تأكيد';
}
