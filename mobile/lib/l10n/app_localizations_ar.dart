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
}
