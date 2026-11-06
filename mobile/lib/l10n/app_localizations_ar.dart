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
  String get gameSounds => 'أصوات اللعبة';

  @override
  String get matchStats => 'إحصائيات المباراة';

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

  @override
  String get market => 'السوق';

  @override
  String get tabBuy => 'شراء';

  @override
  String get tabSell => 'بيع';

  @override
  String get tabOffers => 'العروض';

  @override
  String get marketClosed => 'السوق مغلق الآن';

  @override
  String renewsAt(String time) {
    return 'تتجدد القائمة $time';
  }

  @override
  String get fitsYou => 'يقوّي فريقك';

  @override
  String get sellerWorld => 'من خارج الدوري';

  @override
  String buyFor(String price) {
    return 'اشترِه بـ $price';
  }

  @override
  String regFee(int coins) {
    return 'رسوم التسجيل $coins كوينز';
  }

  @override
  String compensateWith(int coins) {
    return 'أكمل الناقص بـ $coins كوينز';
  }

  @override
  String get bought => 'صار في فريقك';

  @override
  String get price => 'السعر';

  @override
  String listedAt(String price) {
    return 'معروض بـ $price';
  }

  @override
  String sellsIn(String time) {
    return 'يُباع نحو $time';
  }

  @override
  String get listForSale => 'اعرضه للبيع';

  @override
  String get unlist => 'اسحب العرض';

  @override
  String sellNowFor(String pays, String fee) {
    return 'بيع فوري: يدخل $pays، مقابل $fee';
  }

  @override
  String get sellNowConfirm => 'بيعه الآن؟ لا رجوع.';

  @override
  String priceRange(String floor, String cap) {
    return 'بين $floor و$cap';
  }

  @override
  String waitAbout(int hours) {
    return 'مشترٍ خلال $hours ساعة تقريباً';
  }

  @override
  String listingsOf(int listed, int max) {
    return '$listed من $max معروضون';
  }

  @override
  String get noOffers => 'لا عروض الآن';

  @override
  String offerFrom(String club) {
    return 'عرض من $club';
  }

  @override
  String offerTo(String club) {
    return 'عرضك إلى $club';
  }

  @override
  String get theyWant => 'يطلب';

  @override
  String get theyGive => 'ويعطي';

  @override
  String get accept => 'اقبل';

  @override
  String get cancelOffer => 'اسحب العرض';

  @override
  String get offersOnWeb => 'تقديم عرض أو عرض مقابل من الموقع الآن';

  @override
  String coinsWord(int n) {
    return '$n كوينز';
  }

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusOther => 'منتهٍ';

  @override
  String get scout => 'الكشاف';

  @override
  String get scoutLead =>
      'يبحث لك الكشاف عن خمسة لاعبين من خارج الدوري بشروطك، ويحجزهم لك حتى يتجدد السوق.';

  @override
  String get minOverall => 'أقل تقييم';

  @override
  String get maxAge => 'أكبر عمر';

  @override
  String get anyLine => 'أي خط';

  @override
  String get nationality => 'الجنسية';

  @override
  String get fromLeague => 'من دوري';

  @override
  String get any => 'أي';

  @override
  String askScout(String cost, int hours) {
    return 'ابحث ($cost، $hours ساعة)';
  }

  @override
  String searching(String time) {
    return 'يبحث… التقرير $time';
  }

  @override
  String get scoutReports => 'التقارير';

  @override
  String get nobodyFound => 'لم يجد أحداً، وعادت الأموال';

  @override
  String get stateMine => 'في فريقك';

  @override
  String get stateGone => 'ذهب';

  @override
  String get training => 'التدريب';

  @override
  String get trainingLead =>
      'لاعب واحد في كل خط يتدرب، وكل حصة ترفع تقدمه حتى يزيد تقييمه.';

  @override
  String sessionCost(String cost, String time) {
    return 'الحصة $cost كل $time';
  }

  @override
  String get nobodyTraining => 'لا أحد يتدرب';

  @override
  String get pickToTrain => 'اختر من يتدرب';

  @override
  String get recommended => 'المقترح';

  @override
  String nextSession(String time) {
    return 'الحصة التالية $time';
  }

  @override
  String sessionsDone(int n) {
    return '$n حصص';
  }

  @override
  String get stopTraining => 'أوقف';

  @override
  String get maxed => 'بلغ أقصاه';

  @override
  String lineCoach(String name, int stars) {
    return '$name: $stars نجوم';
  }

  @override
  String get specialists => 'الأخصائيون';

  @override
  String specialistsLead(int days) {
    return 'أخصائي لكل خط يسرّع تدريبه، لمدة $days أيام.';
  }

  @override
  String get hire => 'وظّف';

  @override
  String hiredUntil(String time) {
    return 'حتى $time';
  }

  @override
  String hireConfirm(String cost) {
    return 'توظيفه بـ $cost؟';
  }

  @override
  String get spy => 'التجسس';

  @override
  String get spyLead =>
      'يكشف لك جاسوسك تشكيلة خصمك القادم وخطته ولياقته قبل القفل.';

  @override
  String sendSpy(String cost) {
    return 'أرسل الجاسوس ($cost)';
  }

  @override
  String get noNextMatch => 'لا مباراة قادمة';

  @override
  String spyReportOn(String club) {
    return 'تقرير عن $club';
  }

  @override
  String get form => 'الأداء';

  @override
  String get quests => 'المهام';

  @override
  String questsRenew(String time) {
    return 'تتجدد $time';
  }

  @override
  String get questFriendly => 'العب ودية';

  @override
  String get questWins => 'حقق انتصارات';

  @override
  String get questStadium => 'ابنِ جزءاً في الملعب';

  @override
  String get questTraining => 'درّب لاعباً';

  @override
  String get questUnbeaten => 'لا تخسر';

  @override
  String get claim => 'استلم';

  @override
  String get claimed => 'استُلمت';

  @override
  String get honours => 'قاعة الشرف';

  @override
  String seasonN(int n) {
    return 'الموسم $n';
  }

  @override
  String get noTitles => 'لا ألقاب بعد';

  @override
  String get resign => 'استقل من الدوري';

  @override
  String get resignConfirm =>
      'تستقيل من هذا الدوري؟ يعود فريقك للكمبيوتر ولا رجوع.';

  @override
  String get wallet => 'المحفظة';

  @override
  String dailyCoins(int n) {
    return 'كوينز اليوم: $n';
  }

  @override
  String get claimDaily => 'استلم كوينز اليوم';

  @override
  String get dailyClaimed => 'استلمت كوينز اليوم';

  @override
  String get store => 'المتجر';

  @override
  String get buyOnWhatsapp => 'اطلب عبر واتساب';

  @override
  String endsOn(String time) {
    return 'ينتهي $time';
  }

  @override
  String get competitionLeague => 'الدوري';

  @override
  String get coachProfile => 'ملف المدرب';

  @override
  String accountNumber(int n) {
    return 'حساب رقم $n';
  }

  @override
  String get seasonsPlayed => 'المواسم';

  @override
  String get played => 'لعب';

  @override
  String get won => 'فاز';

  @override
  String get drawn => 'تعادل';

  @override
  String get lost => 'خسر';

  @override
  String get titles => 'الألقاب';

  @override
  String objectivesMet(int met, int total) {
    return 'أهداف الإدارة: $met من $total';
  }

  @override
  String get notifications => 'الإشعارات';

  @override
  String get pushReady => 'الإشعارات تصل إلى هذا الجوال';

  @override
  String get pushNotReady =>
      'الإشعارات على الجوال لم تُفعَّل في الخادم بعد، والرسائل كلها في صندوقك';

  @override
  String get kindReferee => 'حكم مباراتك القادمة';

  @override
  String get kindMatchSoon => 'مباراتك بعد قليل وتقديمها';

  @override
  String get kindOffers => 'العروض والبيع والإعارة';

  @override
  String get kindDone => 'اكتمال التدريب والملعب والكشاف';

  @override
  String get kindNews => 'أخبار اللعبة ورسائل المطورين';

  @override
  String get kindAbsence => 'الغياب والإجازات';

  @override
  String get emailMatch => 'ملخص المباراة بالبريد';

  @override
  String get emailOffers => 'عروض المتجر بالبريد';

  @override
  String get emailNeeded => 'يلزم بريد مؤكد في حسابك';

  @override
  String get newOffer => 'عرض جديد';

  @override
  String get counterOffer => 'عرض مقابل';

  @override
  String get pickCoachClub => 'إلى أي نادٍ؟';

  @override
  String get noCoachClubs => 'لا مدربين آخرين في الدوري بعد';

  @override
  String offerTitleTo(String club) {
    return 'عرض إلى $club';
  }

  @override
  String get youWant => 'تطلب من لاعبيه (حتى 5)';

  @override
  String get youGive => 'وتعطي من لاعبيك (اختياري)';

  @override
  String get youPay => 'وتدفع';

  @override
  String offerValues(String want, String give) {
    return 'قيمة ما تطلب $want، وما تعطي $give';
  }

  @override
  String fairHint(int min, int max) {
    return 'الصفقة العادلة بين $min% و$max% من قيمة ما تطلب';
  }

  @override
  String get sendOffer => 'أرسل العرض';

  @override
  String get offerSent => 'وصل العرض إلى مدربه';

  @override
  String get askLoan => 'اطلب إعارته';

  @override
  String loanRounds(int n) {
    return 'جولات الإعارة: $n';
  }

  @override
  String get loanFee => 'رسوم الإعارة';

  @override
  String get loans => 'الإعارات';

  @override
  String loanOf(String player, String owner, String borrower) {
    return '$player: من $owner إلى $borrower';
  }

  @override
  String loanTerms(int rounds, String fee) {
    return '$rounds جولات · $fee';
  }

  @override
  String get loanSent => 'وصل طلب الإعارة';

  @override
  String get academy => 'الأكاديمية';

  @override
  String academyLead(int signed, int per) {
    return 'مواهب شابة لهذه الفترة، والإمكانية مدى حتى تضمه. $signed من $per هذا الموسم.';
  }

  @override
  String signProspect(String price) {
    return 'ضمّه بـ $price';
  }

  @override
  String signProspectConfirm(String name, String price) {
    return 'ضمّ $name بـ $price؟';
  }

  @override
  String potentialRange(int from, int to) {
    return 'الإمكانية $from–$to';
  }

  @override
  String get friendlies => 'الوديات';

  @override
  String friendlyLead(int fit) {
    return 'ودية سريعة ضد أي نادٍ: ترفع اللياقة $fit والانسجام، ولا تحتسب في الجدول.';
  }

  @override
  String friendlyCost(int coins) {
    return 'الودية بـ $coins كوينز';
  }

  @override
  String get friendlyFree => 'الأولى مجانية';

  @override
  String get playFriendly => 'العب';

  @override
  String get suggestedOpponent => 'مقترح';

  @override
  String get playedToday => 'لُعبت اليوم';

  @override
  String get recentFriendlies => 'آخر الوديات';

  @override
  String get skip => 'تخطَّ';

  @override
  String get bestOfMatch => 'الأفضل في المباراة';

  @override
  String get kGoal => 'هدف';

  @override
  String get kSaved => 'تصدٍّ';

  @override
  String get kMissed => 'ضائعة';

  @override
  String get kCorner => 'ركنية';

  @override
  String get kYellow => 'صفراء';

  @override
  String get kRed => 'حمراء';

  @override
  String get kAttack => 'هجمة';

  @override
  String get predictions => 'التوقعات';

  @override
  String predictionsLead(int round, String reward) {
    return 'توقّع نتائج الجولة $round، ولكل توقع صحيح $reward لناديك.';
  }

  @override
  String get draw => 'تعادل';

  @override
  String get predictionClosed => 'أُغلق التوقع';

  @override
  String get newspaper => 'الصحيفة';

  @override
  String get noEdition => 'لا عدد بعد: تصدر الصحيفة بعد أول جولة';

  @override
  String roundResults(int round) {
    return 'نتائج الجولة $round';
  }

  @override
  String get playerOfRound => 'لاعب الجولة';

  @override
  String get coachOfRound => 'مدرب الجولة';

  @override
  String get articles => 'مقالات المدربين';

  @override
  String get writeArticle => 'اكتب مقالاً';

  @override
  String get articleTitle => 'العنوان';

  @override
  String get articleBody => 'المقال';

  @override
  String get articleSent => 'وصل مقالك إلى منشئ الدوري للنشر';

  @override
  String get pendingArticles => 'بانتظار النشر';

  @override
  String get publish => 'انشر';

  @override
  String get groups => 'الجروبات';

  @override
  String get noGroups => 'لا جروبات بعد';

  @override
  String get typeMessage => 'اكتب رسالة';

  @override
  String get messageDeleted => 'حُذفت هذه الرسالة';

  @override
  String get mediaOnWeb => 'صورة أو صوت: افتحه من الموقع';

  @override
  String get profile => 'حسابي';

  @override
  String get displayNameSaved => 'حُفظ';

  @override
  String get coachLook => 'شكلك على الخط';

  @override
  String get changePassword => 'غيّر كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordChanged => 'تغيّرت كلمة المرور';

  @override
  String get inviteFriends => 'ادعُ أصدقاءك';

  @override
  String inviteReward(int coins, int paid, int max) {
    return '$coins كوينز لكل صديق يلعب، دُفع لك $paid من $max';
  }

  @override
  String get achievements => 'الأوسمة';

  @override
  String get tierBeginner => 'المبتدئ';

  @override
  String get tierIntermediate => 'المتوسط';

  @override
  String get tierPro => 'المحترف';

  @override
  String get aFirstWin => 'أول فوز';

  @override
  String aMatches(int n) {
    return '$n مباراة';
  }

  @override
  String aWins(int n) {
    return '$n فوزاً';
  }

  @override
  String get aFirstTitle => 'أول لقب';

  @override
  String get aLeagueTitle => 'بطل الدوري';

  @override
  String get aCupTitle => 'بطل الكأس';

  @override
  String get aProfessional => 'درجة المحترف';

  @override
  String get aLegend => 'درجة الأسطورة';

  @override
  String aFriendlies(int n) {
    return '$n وديات';
  }

  @override
  String get aIdea => 'فكرة اعتُمدت';

  @override
  String aInvites(int n) {
    return '$n أصدقاء';
  }

  @override
  String aTitles(int n) {
    return '$n ألقاب';
  }

  @override
  String get stats => 'الإحصاءات';

  @override
  String get scorers => 'الهدافون';

  @override
  String get assistsTitle => 'صناع الأهداف';

  @override
  String get squadValues => 'قيمة الفرق';

  @override
  String get goalsShort => 'أهداف';

  @override
  String get assistsShort => 'تمريرات';

  @override
  String get noStatsYet => 'تظهر الإحصاءات بعد أول جولة';

  @override
  String get ideas => 'اقتراحاتك للمطورين';

  @override
  String ideasLead(int n) {
    return 'المقبول يأخذ مكافأة كوينز ويدخل صاحبه قائمة الشرف. باقٍ لك اليوم $n.';
  }

  @override
  String get suggest => 'أرسل الاقتراح';

  @override
  String get suggestionSent => 'وصل اقتراحك';

  @override
  String get polls => 'التصويت';

  @override
  String get vote => 'صوّت';

  @override
  String votes(int n) {
    return '$n صوت';
  }

  @override
  String get honourRoll => 'قائمة الشرف';

  @override
  String get statusPending => 'قيد المراجعة';

  @override
  String get statusBuilt => 'بُني';

  @override
  String get support => 'الدعم';

  @override
  String get supportLead => 'اكتب لفريق اللعبة، والرد هنا.';

  @override
  String get fromTeam => 'فريق اللعبة';

  @override
  String get announcements => 'الإعلانات';

  @override
  String get noAnnouncements => 'لا إعلانات';

  @override
  String get guide => 'طريقة اللعب';

  @override
  String get tournaments => 'البطولات';

  @override
  String get noTournaments => 'لا بطولات بعد';

  @override
  String get newTournament => 'بطولة جديدة';

  @override
  String get tplWorldCup => 'كأس العالم (32)';

  @override
  String get tplWorldCup48 => 'كأس العالم (48)';

  @override
  String get tplClubWorldCup => 'كأس العالم للأندية';

  @override
  String get tplAfcon => 'أمم أفريقيا';

  @override
  String get tplEuro => 'أمم أوروبا';

  @override
  String get tplAsianCup => 'كأس آسيا';

  @override
  String get startsOn => 'تبدأ';

  @override
  String get entryPick => 'كل مدرب يختار منتخبه';

  @override
  String get entryDraw => 'القرعة توزع المنتخبات على المدربين';

  @override
  String tournamentCost(int coins) {
    return 'الكلفة $coins كوينز';
  }

  @override
  String get tournamentCode => 'كود الانضمام';

  @override
  String teamsCount(int n) {
    return '$n فريقاً';
  }

  @override
  String get enter => 'سجّل اسمك';

  @override
  String get leaveEntry => 'انسحب';

  @override
  String get watchDraw => 'شاهد القرعة';

  @override
  String drawAt(String time) {
    return 'القرعة $time';
  }

  @override
  String get drawNotSet => 'لم يُحدَّد موعد القرعة';

  @override
  String get scheduleDraw => 'حدّد موعد القرعة';

  @override
  String drawnBalls(int n, int total) {
    return '$n من $total';
  }

  @override
  String groupN(String g) {
    return 'المجموعة $g';
  }

  @override
  String pot(int n) {
    return 'الوعاء $n';
  }

  @override
  String get openLeague => 'افتح الدوري';

  @override
  String get alliance => 'بطولة التحالفات';

  @override
  String get allianceLead =>
      'تحالفان من مدربي الدوري، وكل مواجهة يتأهل منها من يتفق مدرباها عليه.';

  @override
  String get createAlliance => 'أنشئ البطولة';

  @override
  String get captainA => 'قائد التحالف الأول';

  @override
  String get captainB => 'قائد التحالف الثاني';

  @override
  String allianceSize(int n) {
    return 'مدربو كل تحالف: $n';
  }

  @override
  String get firstRound => 'الجولة الأولى';

  @override
  String get goesOn => 'يتأهل';

  @override
  String get noAlliance => 'لا بطولة تحالفات في هذا الدوري';

  @override
  String get newGroup => 'جروب جديد';

  @override
  String get groupName => 'اسم الجروب';

  @override
  String get groupMembers => 'أسماء المستخدمين (مفصولة بفاصلة)';

  @override
  String get joinGroup => 'ادخل بالكود';

  @override
  String get groupCode => 'كود الجروب';

  @override
  String get openIt => 'افتح';

  @override
  String get matchday => 'يوم المباراة';

  @override
  String get referee => 'الحكم';

  @override
  String get moveMatch => 'قدّم المباراة أو أخّرها';

  @override
  String moveLead(int n) {
    return 'في يومها نفسه، بموافقة المدرب الآخر. باقٍ لك $n.';
  }

  @override
  String moveTo(String time) {
    return 'إلى $time';
  }

  @override
  String movePendingMine(String time) {
    return 'طلبت نقلها إلى $time، بانتظار رده';
  }

  @override
  String movePendingTheirs(String time) {
    return 'يطلب نقلها إلى $time';
  }

  @override
  String get moveSent => 'أُرسل طلبك للمدرب الآخر';

  @override
  String hoursEarlier(int n) {
    return 'أبكر $n س';
  }

  @override
  String hoursLater(int n) {
    return 'أبعد $n س';
  }

  @override
  String get press => 'المؤتمر الصحفي';

  @override
  String pressOpensAt(String time) {
    return 'يفتح $time';
  }

  @override
  String chances(int home, int draw, int away) {
    return 'الحظوظ: فوز $home% · تعادل $draw% · خسارة $away%';
  }

  @override
  String stakes(int win, int draw, int loss) {
    return 'الروح المعنوية: فوز $win · تعادل $draw · خسارة $loss';
  }

  @override
  String get youSaid => 'قلتَ';

  @override
  String get integrity => 'ما وراء الكواليس';

  @override
  String bribe(String money, String extra) {
    return 'ادفع للحكم ($money + $extra)';
  }

  @override
  String bribeNote(int pct) {
    return 'الفار يكشفها مرة من كل $pct%';
  }

  @override
  String get bribePaid => 'دفعت للحكم';

  @override
  String securityCheck(String cost) {
    return 'فحص أمني ($cost)';
  }

  @override
  String get spiesOnMe => 'الجواسيس على مباراتك';

  @override
  String get noSpies => 'لا جواسيس حتى الآن';

  @override
  String turnSpy(String cost) {
    return 'اجعله مزدوجاً ($cost)';
  }

  @override
  String get accuse => 'اتهمه';

  @override
  String get contracts => 'العقود';

  @override
  String contractsLead(String wages, String cap) {
    return 'الرواتب $wages كل جولة من سقف $cap';
  }

  @override
  String untilSeason(int n) {
    return 'حتى الموسم $n';
  }

  @override
  String get renew => 'جدّد';

  @override
  String renewSeasons(int n, String cost) {
    return 'جدّد $n مواسم ($cost)';
  }

  @override
  String releasePlayer(String cost) {
    return 'فسخ العقد ($cost)';
  }

  @override
  String releaseConfirm(String name) {
    return 'فسخ عقد $name؟ يخرج من فريقك.';
  }

  @override
  String get renewEnding => 'جدّد كل العقود المنتهية';

  @override
  String get cheerTickets => 'تذاكر التشجيع';

  @override
  String cheerLead(int boost, String price) {
    return 'شجّع فريقاً في مباراة أخرى: +$boost لحماسه، والتذكرة بـ $price.';
  }

  @override
  String get cheer => 'شجّع';

  @override
  String get matchChat => 'الدردشة';

  @override
  String get reactionSent => 'وصل تفاعلك';

  @override
  String missedMatches(int n) {
    return 'فاتتك $n مباريات';
  }

  @override
  String get missedTitle => 'ما فاتك';

  @override
  String get markSeen => 'شاهدتها كلها';

  @override
  String get squadChanges => 'تغيّر في فريقك';

  @override
  String get injured => 'مصاب';

  @override
  String get sentOff => 'طُرد';

  @override
  String unlockSlot(int coins) {
    return 'افتحها الآن ($coins كوينز)';
  }

  @override
  String unlockConfirm(int n, int coins) {
    return 'فتح الفتحة $n الآن بـ $coins كوينز؟ تبقى مفتوحة دائماً.';
  }

  @override
  String starterGift(int coins) {
    return 'هدية البداية: $coins كوينز';
  }

  @override
  String get claimGift => 'استلمها';

  @override
  String get ranking => 'ترتيب المدربين';

  @override
  String trophiesShort(int n) {
    return '$n ألقاب';
  }

  @override
  String get holiday => 'إجازة';

  @override
  String get holidayLeague => 'اطلب إجازة من هذا الدوري';

  @override
  String get holidayAccount => 'إجازة طويلة للحساب كله';

  @override
  String holidayDays(int n) {
    return 'الأيام: $n';
  }

  @override
  String get holidayReason => 'السبب';

  @override
  String get holidaySent => 'وصل طلب الإجازة';

  @override
  String get endHoliday => 'أنهِ الإجازة';

  @override
  String vacationAsk(int days, String reason) {
    return 'يطلب إجازة $days أيام: $reason';
  }

  @override
  String get kick => 'أبعِده';

  @override
  String get kickReason => 'السبب (يراه الجميع)';

  @override
  String verifyAccount(int coins) {
    return 'وثّق حسابك واحصل على $coins كوينز';
  }

  @override
  String get sendCode => 'أرسل الرمز إلى بريدي';

  @override
  String get codeSent => 'أُرسل الرمز';

  @override
  String get verifyCode => 'الرمز';

  @override
  String get verified => 'حسابك موثّق';

  @override
  String get resendEmail => 'أعد إرسال رسالة تأكيد البريد';

  @override
  String get deleteAccount => 'احذف حسابي';

  @override
  String get deleteAccountLead =>
      'تعود فرقك للكمبيوتر ولا رجوع. اكتب «احذف» للتأكيد.';

  @override
  String get startLeague => 'ابدأ الدوري الآن';

  @override
  String get changePhoto => 'غيّر الصورة';

  @override
  String get removePhoto => 'احذف الصورة';

  @override
  String get sendPhoto => 'أرسل صورة';

  @override
  String get leagueSettings => 'إعدادات الدوري';

  @override
  String get settingsLocked => 'الإعدادات مقفلة منذ بداية الدوري';

  @override
  String get customTeams => 'فرق من اختيارك';

  @override
  String get searchClubs => 'ابحث عن نادٍ';

  @override
  String get nationsTab => 'المنتخبات';

  @override
  String get clubsTab => 'الأندية';

  @override
  String chosenTeams(int n) {
    return '$n فريقاً مختاراً';
  }

  @override
  String get formatLeague => 'دوري';

  @override
  String get formatGroups => 'مجموعات';

  @override
  String get formatKnockout => 'خروج المغلوب';

  @override
  String groupsCount(int n) {
    return 'المجموعات: $n';
  }

  @override
  String swapPlayers(int n) {
    return 'بادل لاعبين (حتى $n)';
  }

  @override
  String get swapGive => 'تعطي';

  @override
  String get swapTake => 'تأخذ';

  @override
  String get recordVoice => 'سجّل رسالة صوتية';

  @override
  String get stopAndSend => 'أوقف وأرسل';

  @override
  String voiceNote(int n) {
    return 'رسالة صوتية $n ث';
  }

  @override
  String get micDenied => 'اسمح للتطبيق باستعمال الميكروفون من إعدادات الجوال';

  @override
  String get navClub => 'ناديّ';

  @override
  String get navTeam => 'الفريق';

  @override
  String get navMatches => 'المباريات';

  @override
  String get navMarket => 'السوق';

  @override
  String get navMore => 'المزيد';

  @override
  String get secPlayers => 'اللاعبون';

  @override
  String get secDevelop => 'التطوير';

  @override
  String get secDeals => 'الصفقات';

  @override
  String get secMoney => 'المال والملعب';

  @override
  String get secCompete => 'المنافسة';

  @override
  String get secCommunity => 'المجتمع';

  @override
  String get secLeague => 'الدوري';

  @override
  String get subSquad => 'اللاعبون ولياقتهم وبطاقاتهم';

  @override
  String get subLineup => 'الأحد عشر والدكة';

  @override
  String get subTactics => 'الخطة والضغط والأسلوب';

  @override
  String get subTraining => 'لاعب في كل خط';

  @override
  String get subSpecialists => 'أسرع تدريب لكل خط';

  @override
  String get subContracts => 'التجديد والفسخ';

  @override
  String get subMarket => 'شراء وبيع وعروض وأكاديمية';

  @override
  String get subScout => 'خمسة لاعبين بشروطك';

  @override
  String get subFinance => 'الرصيد والرعاة والتذاكر';

  @override
  String get subStadium => 'المقاعد والأرضية والتدريب';

  @override
  String get subTickets => 'شجّع في مباريات الآخرين';

  @override
  String get subMatchday => 'النقل والمؤتمر والكواليس';

  @override
  String get subFriendlies => 'ودية سريعة لأي نادٍ';

  @override
  String get subQuests => 'مكافآت الأسبوع';

  @override
  String get subSpy => 'اكشف خصمك القادم';

  @override
  String get subNewspaper => 'أخبار الجولة والمقالات';

  @override
  String get subPredictions => 'توقع النتائج واربح';

  @override
  String get subStats => 'الهدافون وقيمة الفرق';

  @override
  String get subGroups => 'دردشة المدربين';

  @override
  String get subHonours => 'أبطال كل موسم';

  @override
  String get subAlliance => 'تحالفان من مدربي الدوري';

  @override
  String get subTournaments => 'بطولات بقرعة مباشرة';

  @override
  String countdownIn(String time) {
    return 'بعد $time';
  }

  @override
  String get liveBadge => 'مباشر الآن';

  @override
  String get navOffice => 'المكتب';

  @override
  String get officeHello => 'مكتب المدرب';

  @override
  String get strengthCompare => 'قوة الفريقين';

  @override
  String get needsYou => 'ينتظرك الآن';

  @override
  String get allClear => 'كل شيء جاهز، استعد للمباراة';

  @override
  String get needWindow => 'نافذة الأوامر مفتوحة في مباراتك';

  @override
  String get needLineup => 'لاعبون غائبون في تشكيلتك';

  @override
  String get needOffers => 'عروض بانتظار ردك';

  @override
  String get needRequests => 'طلبات انضمام للدوري';

  @override
  String get needTrainingEmpty => 'خطوط بلا تدريب';

  @override
  String get needTrainingDone => 'تدريب انتهى وينتظر لاعباً جديداً';

  @override
  String tileSquadSub(int n) {
    return '$n لاعباً';
  }

  @override
  String get tileReady => 'جاهزة';

  @override
  String get tileAuto => 'تلقائية';

  @override
  String get tileFixtures => 'الجدول والنتائج';

  @override
  String get colPos => 'مركز';

  @override
  String get colName => 'اللاعب';

  @override
  String get colAge => 'عمر';

  @override
  String get colOvr => 'تقييم';

  @override
  String get colPot => 'إمكانية';

  @override
  String get colFit => 'لياقة';

  @override
  String get colValue => 'القيمة';

  @override
  String get filterAll => 'الكل';

  @override
  String get dragHint => 'اسحب لاعباً إلى مكانه، أو المس لاعبَين للتبديل';

  @override
  String get leagueTable => 'الترتيب';
}
