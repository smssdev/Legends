import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'المدرب الأسطورة'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'لعبة إدارة كرة قدم عربية مجانية'**
  String get tagline;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signIn;

  /// No description provided for @signInTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك'**
  String get signInTitle;

  /// No description provided for @signInLead.
  ///
  /// In ar, this message translates to:
  /// **'ادخل لتكمل موسمك'**
  String get signInLead;

  /// No description provided for @emailOrUsername.
  ///
  /// In ar, this message translates to:
  /// **'البريد أو اسم المستخدم'**
  String get emailOrUsername;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيتها؟'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب؟'**
  String get haveAccount;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابك الجديد'**
  String get registerTitle;

  /// No description provided for @registerLead.
  ///
  /// In ar, this message translates to:
  /// **'ثلاث خانات وتبدأ: اسمك، واسم المستخدم، وكلمة المرور'**
  String get registerLead;

  /// No description provided for @displayName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك الظاهر'**
  String get displayName;

  /// No description provided for @username.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In ar, this message translates to:
  /// **'حروف إنجليزية وأرقام، 3 إلى 20'**
  String get usernameHint;

  /// No description provided for @emailOptional.
  ///
  /// In ar, this message translates to:
  /// **'البريد (اختياري، لاستعادة كلمة المرور)'**
  String get emailOptional;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'8 أحرف على الأقل'**
  String get passwordHint;

  /// No description provided for @acceptTerms.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على الشروط وسياسة الخصوصية'**
  String get acceptTerms;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الشروط وسياسة الخصوصية'**
  String get termsAndPrivacy;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In ar, this message translates to:
  /// **'وافق على الشروط وسياسة الخصوصية أولاً'**
  String get mustAcceptTerms;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get register;

  /// No description provided for @forgotTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotTitle;

  /// No description provided for @forgotLead.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريد حسابك ونرسل لك رابطاً لكلمة مرور جديدة'**
  String get forgotLead;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @sendLink.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الرابط'**
  String get sendLink;

  /// No description provided for @linkSent.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا الرابط إن كان البريد لحساب عندنا. افتحه من بريدك.'**
  String get linkSent;

  /// No description provided for @required.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get required;

  /// No description provided for @google.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة بحساب Google'**
  String get google;

  /// No description provided for @googleSoon.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بجوجل قريباً في التطبيق'**
  String get googleSoon;

  /// No description provided for @orByEmail.
  ///
  /// In ar, this message translates to:
  /// **'أو بالبريد'**
  String get orByEmail;

  /// No description provided for @updateTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدّث التطبيق'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In ar, this message translates to:
  /// **'نسخة جديدة من اللعبة متاحة، ولا تعمل هذه النسخة معها. حدّث التطبيق لتكمل.'**
  String get updateBody;

  /// No description provided for @update.
  ///
  /// In ar, this message translates to:
  /// **'حدّث الآن'**
  String get update;

  /// No description provided for @offlineTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا اتصال'**
  String get offlineTitle;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير يا كوتش'**
  String get greetingMorning;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير يا كوتش'**
  String get greetingEvening;

  /// No description provided for @coins.
  ///
  /// In ar, this message translates to:
  /// **'كوينز'**
  String get coins;

  /// No description provided for @myTeams.
  ///
  /// In ar, this message translates to:
  /// **'فرقي'**
  String get myTeams;

  /// No description provided for @slotsOpen.
  ///
  /// In ar, this message translates to:
  /// **'{open} من {total}'**
  String slotsOpen(int open, int total);

  /// No description provided for @slotFree.
  ///
  /// In ar, this message translates to:
  /// **'فتحة فارغة'**
  String get slotFree;

  /// No description provided for @slotWaiting.
  ///
  /// In ar, this message translates to:
  /// **'طلب انضمام ينتظر الرد'**
  String get slotWaiting;

  /// No description provided for @slotLocked.
  ///
  /// In ar, this message translates to:
  /// **'مقفلة'**
  String get slotLocked;

  /// No description provided for @slotOpensIn.
  ///
  /// In ar, this message translates to:
  /// **'تُفتح مجاناً بعد {time}'**
  String slotOpensIn(String time);

  /// No description provided for @createLeague.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ دورياً'**
  String get createLeague;

  /// No description provided for @joinByCode.
  ///
  /// In ar, this message translates to:
  /// **'انضم بكود'**
  String get joinByCode;

  /// No description provided for @openClub.
  ///
  /// In ar, this message translates to:
  /// **'ادخل النادي'**
  String get openClub;

  /// No description provided for @nextMatch.
  ///
  /// In ar, this message translates to:
  /// **'المباراة القادمة'**
  String get nextMatch;

  /// No description provided for @vs.
  ///
  /// In ar, this message translates to:
  /// **'ضد {club}'**
  String vs(String club);

  /// No description provided for @position.
  ///
  /// In ar, this message translates to:
  /// **'المركز {n} من {of}'**
  String position(int n, int of);

  /// No description provided for @waitsForYou.
  ///
  /// In ar, this message translates to:
  /// **'{n} ينتظرك'**
  String waitsForYou(int n);

  /// No description provided for @record.
  ///
  /// In ar, this message translates to:
  /// **'{w} فوز · {d} تعادل · {l} خسارة'**
  String record(int w, int d, int l);

  /// No description provided for @onWebForNow.
  ///
  /// In ar, this message translates to:
  /// **'تُفتح في الموقع حتى تصل إلى التطبيق'**
  String get onWebForNow;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @look.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get look;

  /// No description provided for @lookAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get lookAuto;

  /// No description provided for @lookNight.
  ///
  /// In ar, this message translates to:
  /// **'ليلي'**
  String get lookNight;

  /// No description provided for @lookDay.
  ///
  /// In ar, this message translates to:
  /// **'نهاري'**
  String get lookDay;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج من هذا الجوال؟'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @accountNo.
  ///
  /// In ar, this message translates to:
  /// **'رقم حسابك {n}'**
  String accountNo(int n);

  /// No description provided for @days.
  ///
  /// In ar, this message translates to:
  /// **'{n} يوم'**
  String days(int n);

  /// No description provided for @hours.
  ///
  /// In ar, this message translates to:
  /// **'{n} ساعة'**
  String hours(int n);

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'{n} دقيقة'**
  String minutes(int n);

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'النسخة {v}'**
  String version(String v);

  /// No description provided for @tierProspect.
  ///
  /// In ar, this message translates to:
  /// **'الواعد'**
  String get tierProspect;

  /// No description provided for @tierTactician.
  ///
  /// In ar, this message translates to:
  /// **'التكتيكي'**
  String get tierTactician;

  /// No description provided for @tierProfessional.
  ///
  /// In ar, this message translates to:
  /// **'المحترف'**
  String get tierProfessional;

  /// No description provided for @tierElite.
  ///
  /// In ar, this message translates to:
  /// **'النخبة'**
  String get tierElite;

  /// No description provided for @tierMastermind.
  ///
  /// In ar, this message translates to:
  /// **'العقل المدبر'**
  String get tierMastermind;

  /// No description provided for @tierIcon.
  ///
  /// In ar, this message translates to:
  /// **'الأيقونة'**
  String get tierIcon;

  /// No description provided for @tierLegend.
  ///
  /// In ar, this message translates to:
  /// **'الأسطورة'**
  String get tierLegend;

  /// No description provided for @myLeagues.
  ///
  /// In ar, this message translates to:
  /// **'دورياتي'**
  String get myLeagues;

  /// No description provided for @noLeagues.
  ///
  /// In ar, this message translates to:
  /// **'لا دوري لك بعد. أنشئ دورياً لأصحابك أو انضم بكود.'**
  String get noLeagues;

  /// No description provided for @newLeague.
  ///
  /// In ar, this message translates to:
  /// **'دوري جديد'**
  String get newLeague;

  /// No description provided for @freeLeagueLead.
  ///
  /// In ar, this message translates to:
  /// **'الدوري المجاني: كل أندية الدوري، جولة كل يوم الساعة 9 مساءً، ويومان للتحضير. والخيارات المدفوعة من الموقع.'**
  String get freeLeagueLead;

  /// No description provided for @pickTemplate.
  ///
  /// In ar, this message translates to:
  /// **'اختر الدوري'**
  String get pickTemplate;

  /// No description provided for @pickClub.
  ///
  /// In ar, this message translates to:
  /// **'اختر فريقك'**
  String get pickClub;

  /// No description provided for @leagueName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدوري (اختياري)'**
  String get leagueName;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ الدوري'**
  String get create;

  /// No description provided for @clubsCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} نادٍ'**
  String clubsCount(int n);

  /// No description provided for @joinTitle.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى دوري'**
  String get joinTitle;

  /// No description provided for @joinLead.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من صاحبك كود دوريه واكتبه هنا، ثم ينتظر طلبك موافقة المنشئ.'**
  String get joinLead;

  /// No description provided for @code.
  ///
  /// In ar, this message translates to:
  /// **'كود الدوري'**
  String get code;

  /// No description provided for @sendRequest.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الطلب'**
  String get sendRequest;

  /// No description provided for @requestPending.
  ///
  /// In ar, this message translates to:
  /// **'طلبك ينتظر موافقة المنشئ.'**
  String get requestPending;

  /// No description provided for @requestApproved.
  ///
  /// In ar, this message translates to:
  /// **'وافق المنشئ. اختر فريقك الآن.'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In ar, this message translates to:
  /// **'رفض المنشئ طلبك.'**
  String get requestRejected;

  /// No description provided for @cancelRequest.
  ///
  /// In ar, this message translates to:
  /// **'ألغِ الطلب'**
  String get cancelRequest;

  /// No description provided for @takeClub.
  ///
  /// In ar, this message translates to:
  /// **'خذ هذا الفريق'**
  String get takeClub;

  /// No description provided for @goalTitle.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: اللقب'**
  String get goalTitle;

  /// No description provided for @goalPlace.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: المركز {n} أو أفضل'**
  String goalPlace(int n);

  /// No description provided for @goalSurvive.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: البقاء في المركز {n} أو أفضل'**
  String goalSurvive(int n);

  /// No description provided for @strength.
  ///
  /// In ar, this message translates to:
  /// **'القوة {n}'**
  String strength(int n);

  /// No description provided for @tabClub.
  ///
  /// In ar, this message translates to:
  /// **'النادي'**
  String get tabClub;

  /// No description provided for @tabTable.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get tabTable;

  /// No description provided for @tabFixtures.
  ///
  /// In ar, this message translates to:
  /// **'المباريات'**
  String get tabFixtures;

  /// No description provided for @tabCoaches.
  ///
  /// In ar, this message translates to:
  /// **'المدربون'**
  String get tabCoaches;

  /// No description provided for @waitingStart.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ الدوري {when}'**
  String waitingStart(String when);

  /// No description provided for @round.
  ///
  /// In ar, this message translates to:
  /// **'الجولة {n}'**
  String round(int n);

  /// No description provided for @cup.
  ///
  /// In ar, this message translates to:
  /// **'الكأس'**
  String get cup;

  /// No description provided for @invite.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ أصحابك'**
  String get invite;

  /// No description provided for @inviteText.
  ///
  /// In ar, this message translates to:
  /// **'انضم لدوري «{name}» في لعبة المدرب الأسطورة واختر ناديك: {url}'**
  String inviteText(String name, String url);

  /// No description provided for @requests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الانضمام'**
  String get requests;

  /// No description provided for @approve.
  ///
  /// In ar, this message translates to:
  /// **'وافق'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'ارفض'**
  String get reject;

  /// No description provided for @creator.
  ///
  /// In ar, this message translates to:
  /// **'المنشئ'**
  String get creator;

  /// No description provided for @onHoliday.
  ///
  /// In ar, this message translates to:
  /// **'في إجازة'**
  String get onHoliday;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'على أرضك'**
  String get home;

  /// No description provided for @away.
  ///
  /// In ar, this message translates to:
  /// **'خارج أرضك'**
  String get away;

  /// No description provided for @nextMatchShort.
  ///
  /// In ar, this message translates to:
  /// **'مباراتك القادمة'**
  String get nextMatchShort;

  /// No description provided for @lineupReady.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة جاهزة'**
  String get lineupReady;

  /// No description provided for @lineupAuto.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة تلقائية'**
  String get lineupAuto;

  /// No description provided for @board.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get board;

  /// No description provided for @noMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا مباريات بعد.'**
  String get noMatches;

  /// No description provided for @openOnSite.
  ///
  /// In ar, this message translates to:
  /// **'افتح في الموقع'**
  String get openOnSite;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'شارك'**
  String get share;

  /// No description provided for @pts.
  ///
  /// In ar, this message translates to:
  /// **'ن'**
  String get pts;

  /// No description provided for @sign.
  ///
  /// In ar, this message translates to:
  /// **'وقّع'**
  String get sign;

  /// No description provided for @squad.
  ///
  /// In ar, this message translates to:
  /// **'الفريق'**
  String get squad;

  /// No description provided for @lineup.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة'**
  String get lineup;

  /// No description provided for @tactics.
  ///
  /// In ar, this message translates to:
  /// **'التكتيك'**
  String get tactics;

  /// No description provided for @lineGk.
  ///
  /// In ar, this message translates to:
  /// **'حراسة المرمى'**
  String get lineGk;

  /// No description provided for @lineDef.
  ///
  /// In ar, this message translates to:
  /// **'الدفاع'**
  String get lineDef;

  /// No description provided for @lineMid.
  ///
  /// In ar, this message translates to:
  /// **'الوسط'**
  String get lineMid;

  /// No description provided for @lineAtt.
  ///
  /// In ar, this message translates to:
  /// **'الهجوم'**
  String get lineAtt;

  /// No description provided for @starter.
  ///
  /// In ar, this message translates to:
  /// **'أساسي'**
  String get starter;

  /// No description provided for @bench.
  ///
  /// In ar, this message translates to:
  /// **'احتياط'**
  String get bench;

  /// No description provided for @reserve.
  ///
  /// In ar, this message translates to:
  /// **'خارج القائمة'**
  String get reserve;

  /// No description provided for @injuredFor.
  ///
  /// In ar, this message translates to:
  /// **'مصاب {n} مباراة'**
  String injuredFor(int n);

  /// No description provided for @suspendedFor.
  ///
  /// In ar, this message translates to:
  /// **'موقوف {n} مباراة'**
  String suspendedFor(int n);

  /// No description provided for @age.
  ///
  /// In ar, this message translates to:
  /// **'العمر {n}'**
  String age(int n);

  /// No description provided for @potential.
  ///
  /// In ar, this message translates to:
  /// **'الإمكانية {n}'**
  String potential(int n);

  /// No description provided for @fitness.
  ///
  /// In ar, this message translates to:
  /// **'اللياقة'**
  String get fitness;

  /// No description provided for @morale.
  ///
  /// In ar, this message translates to:
  /// **'المعنويات {n}'**
  String morale(int n);

  /// No description provided for @squadValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الفريق'**
  String get squadValue;

  /// No description provided for @formation.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get formation;

  /// No description provided for @autoLineup.
  ///
  /// In ar, this message translates to:
  /// **'تلقائية'**
  String get autoLineup;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ'**
  String get saved;

  /// No description provided for @swapWith.
  ///
  /// In ar, this message translates to:
  /// **'بدّله مع'**
  String get swapWith;

  /// No description provided for @tapToSwap.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لاعباً في الملعب ثم بديله'**
  String get tapToSwap;

  /// No description provided for @plan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة الهجومية'**
  String get plan;

  /// No description provided for @tackling.
  ///
  /// In ar, this message translates to:
  /// **'قطع الكرة'**
  String get tackling;

  /// No description provided for @pressing.
  ///
  /// In ar, this message translates to:
  /// **'الضغط على الخصم'**
  String get pressing;

  /// No description provided for @style.
  ///
  /// In ar, this message translates to:
  /// **'الأسلوب'**
  String get style;

  /// No description provided for @tempo.
  ///
  /// In ar, this message translates to:
  /// **'إيقاع اللعب'**
  String get tempo;

  /// No description provided for @trap.
  ///
  /// In ar, this message translates to:
  /// **'مصيدة التسلل'**
  String get trap;

  /// No description provided for @marking.
  ///
  /// In ar, this message translates to:
  /// **'الرقابة'**
  String get marking;

  /// No description provided for @markZone.
  ///
  /// In ar, this message translates to:
  /// **'دفاع المنطقة'**
  String get markZone;

  /// No description provided for @markMan.
  ///
  /// In ar, this message translates to:
  /// **'رجل لرجل'**
  String get markMan;

  /// No description provided for @planCounter.
  ///
  /// In ar, this message translates to:
  /// **'هجوم مرتد'**
  String get planCounter;

  /// No description provided for @planShots.
  ///
  /// In ar, this message translates to:
  /// **'تسديد عن بعد'**
  String get planShots;

  /// No description provided for @planLong.
  ///
  /// In ar, this message translates to:
  /// **'كرات طويلة'**
  String get planLong;

  /// No description provided for @planPassing.
  ///
  /// In ar, this message translates to:
  /// **'تمريرات'**
  String get planPassing;

  /// No description provided for @planWings.
  ///
  /// In ar, this message translates to:
  /// **'لعب على الأجنحة'**
  String get planWings;

  /// No description provided for @tackle0.
  ///
  /// In ar, this message translates to:
  /// **'قانوني'**
  String get tackle0;

  /// No description provided for @tackle1.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get tackle1;

  /// No description provided for @tackle2.
  ///
  /// In ar, this message translates to:
  /// **'حماس'**
  String get tackle2;

  /// No description provided for @tackle3.
  ///
  /// In ar, this message translates to:
  /// **'خشونة'**
  String get tackle3;

  /// No description provided for @attBack.
  ///
  /// In ar, this message translates to:
  /// **'ارتداد'**
  String get attBack;

  /// No description provided for @attSupport.
  ///
  /// In ar, this message translates to:
  /// **'مساندة الوسط'**
  String get attSupport;

  /// No description provided for @attOnly.
  ///
  /// In ar, this message translates to:
  /// **'هجوم فقط'**
  String get attOnly;

  /// No description provided for @midDef.
  ///
  /// In ar, this message translates to:
  /// **'مساندة الدفاع'**
  String get midDef;

  /// No description provided for @midStay.
  ///
  /// In ar, this message translates to:
  /// **'بقاء'**
  String get midStay;

  /// No description provided for @midPush.
  ///
  /// In ar, this message translates to:
  /// **'اندفاع'**
  String get midPush;

  /// No description provided for @defStay.
  ///
  /// In ar, this message translates to:
  /// **'بقاء'**
  String get defStay;

  /// No description provided for @defFullbacks.
  ///
  /// In ar, this message translates to:
  /// **'هجوم الظهيرين'**
  String get defFullbacks;

  /// No description provided for @defMid.
  ///
  /// In ar, this message translates to:
  /// **'مساندة الوسط'**
  String get defMid;

  /// No description provided for @low.
  ///
  /// In ar, this message translates to:
  /// **'منخفض'**
  String get low;

  /// No description provided for @high.
  ///
  /// In ar, this message translates to:
  /// **'عالٍ'**
  String get high;

  /// No description provided for @defensive.
  ///
  /// In ar, this message translates to:
  /// **'دفاعي'**
  String get defensive;

  /// No description provided for @attacking.
  ///
  /// In ar, this message translates to:
  /// **'هجومي'**
  String get attacking;

  /// No description provided for @calm.
  ///
  /// In ar, this message translates to:
  /// **'هادئ'**
  String get calm;

  /// No description provided for @fast.
  ///
  /// In ar, this message translates to:
  /// **'سريع'**
  String get fast;

  /// No description provided for @savesItself.
  ///
  /// In ar, this message translates to:
  /// **'يُحفظ وحده مع كل تغيير'**
  String get savesItself;

  /// No description provided for @attributes.
  ///
  /// In ar, this message translates to:
  /// **'المهارات'**
  String get attributes;

  /// No description provided for @value.
  ///
  /// In ar, this message translates to:
  /// **'القيمة'**
  String get value;

  /// No description provided for @ratingWord.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get ratingWord;

  /// No description provided for @potentialWord.
  ///
  /// In ar, this message translates to:
  /// **'الإمكانية'**
  String get potentialWord;

  /// No description provided for @watchLive.
  ///
  /// In ar, this message translates to:
  /// **'شاهد المباراة'**
  String get watchLive;

  /// No description provided for @liveNow.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get liveNow;

  /// No description provided for @fullTime.
  ///
  /// In ar, this message translates to:
  /// **'نهاية المباراة'**
  String get fullTime;

  /// No description provided for @notStarted.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ بعد'**
  String get notStarted;

  /// No description provided for @matchReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المباراة'**
  String get matchReport;

  /// No description provided for @commentary.
  ///
  /// In ar, this message translates to:
  /// **'التعليق'**
  String get commentary;

  /// No description provided for @assistantNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات مساعدك'**
  String get assistantNotes;

  /// No description provided for @substitute.
  ///
  /// In ar, this message translates to:
  /// **'تبديل'**
  String get substitute;

  /// No description provided for @subOut.
  ///
  /// In ar, this message translates to:
  /// **'يخرج'**
  String get subOut;

  /// No description provided for @subIn.
  ///
  /// In ar, this message translates to:
  /// **'يدخل'**
  String get subIn;

  /// No description provided for @subsLeft.
  ///
  /// In ar, this message translates to:
  /// **'{used} من {max} تبديلات'**
  String subsLeft(int used, int max);

  /// No description provided for @ordersHint.
  ///
  /// In ar, this message translates to:
  /// **'الأوامر تُنفَّذ في النوافذ: قبل البداية وبين الشوطين وبعد الدقائق 15 و30 و60 و75.'**
  String get ordersHint;

  /// No description provided for @windowOpen.
  ///
  /// In ar, this message translates to:
  /// **'النافذة مفتوحة: أوامرك الآن'**
  String get windowOpen;

  /// No description provided for @imReady.
  ///
  /// In ar, this message translates to:
  /// **'أنا مستعد'**
  String get imReady;

  /// No description provided for @readyWaiting.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار المدرب الآخر'**
  String get readyWaiting;

  /// No description provided for @breakTime.
  ///
  /// In ar, this message translates to:
  /// **'استراحة'**
  String get breakTime;

  /// No description provided for @orderSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل الأمر، يُنفَّذ في الدقيقة التالية'**
  String get orderSent;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'أرسل'**
  String get send;

  /// No description provided for @possession.
  ///
  /// In ar, this message translates to:
  /// **'الاستحواذ'**
  String get possession;

  /// No description provided for @shots.
  ///
  /// In ar, this message translates to:
  /// **'التسديدات'**
  String get shots;

  /// No description provided for @onTarget.
  ///
  /// In ar, this message translates to:
  /// **'على المرمى'**
  String get onTarget;

  /// No description provided for @corners.
  ///
  /// In ar, this message translates to:
  /// **'الركنيات'**
  String get corners;

  /// No description provided for @fouls.
  ///
  /// In ar, this message translates to:
  /// **'الأخطاء'**
  String get fouls;

  /// No description provided for @saves.
  ///
  /// In ar, this message translates to:
  /// **'التصديات'**
  String get saves;

  /// No description provided for @manOfMatch.
  ///
  /// In ar, this message translates to:
  /// **'رجل المباراة'**
  String get manOfMatch;

  /// No description provided for @toImprove.
  ///
  /// In ar, this message translates to:
  /// **'ما يُحسَّن'**
  String get toImprove;

  /// No description provided for @whyResult.
  ///
  /// In ar, this message translates to:
  /// **'لماذا هذه النتيجة'**
  String get whyResult;

  /// No description provided for @keyMoments.
  ///
  /// In ar, this message translates to:
  /// **'أهم اللحظات'**
  String get keyMoments;

  /// No description provided for @bestPlayers.
  ///
  /// In ar, this message translates to:
  /// **'الأفضل'**
  String get bestPlayers;

  /// No description provided for @resultWin.
  ///
  /// In ar, this message translates to:
  /// **'فوز'**
  String get resultWin;

  /// No description provided for @resultDraw.
  ///
  /// In ar, this message translates to:
  /// **'تعادل'**
  String get resultDraw;

  /// No description provided for @resultLoss.
  ///
  /// In ar, this message translates to:
  /// **'خسارة'**
  String get resultLoss;

  /// No description provided for @pitchView.
  ///
  /// In ar, this message translates to:
  /// **'الملعب'**
  String get pitchView;

  /// No description provided for @kickoffAt.
  ///
  /// In ar, this message translates to:
  /// **'البداية {time}'**
  String kickoffAt(String time);

  /// No description provided for @inbox.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get inbox;

  /// No description provided for @noMessages.
  ///
  /// In ar, this message translates to:
  /// **'لا رسائل بعد'**
  String get noMessages;

  /// No description provided for @readAll.
  ///
  /// In ar, this message translates to:
  /// **'قرأتها كلها'**
  String get readAll;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @finance.
  ///
  /// In ar, this message translates to:
  /// **'المالية'**
  String get finance;

  /// No description provided for @balance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد'**
  String get balance;

  /// No description provided for @seasonIncome.
  ///
  /// In ar, this message translates to:
  /// **'دخل الموسم'**
  String get seasonIncome;

  /// No description provided for @seasonExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصروفات الموسم'**
  String get seasonExpenses;

  /// No description provided for @wagesPerRound.
  ///
  /// In ar, this message translates to:
  /// **'الرواتب كل جولة'**
  String get wagesPerRound;

  /// No description provided for @inDebt.
  ///
  /// In ar, this message translates to:
  /// **'النادي مدين: لا شراء ولا بناء حتى يعود الرصيد موجباً ({rounds} من {limit} جولات)'**
  String inDebt(int rounds, int limit);

  /// No description provided for @ticketPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر التذاكر'**
  String get ticketPrice;

  /// No description provided for @perMatch.
  ///
  /// In ar, this message translates to:
  /// **'{amount} في المباراة'**
  String perMatch(String amount);

  /// No description provided for @attendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور {pct}%'**
  String attendance(int pct);

  /// No description provided for @sponsors.
  ///
  /// In ar, this message translates to:
  /// **'الرعاة'**
  String get sponsors;

  /// No description provided for @perWin.
  ///
  /// In ar, this message translates to:
  /// **'+{amount} للفوز'**
  String perWin(String amount);

  /// No description provided for @signSponsorConfirm.
  ///
  /// In ar, this message translates to:
  /// **'توقيع هذا العرض للموسم كله؟'**
  String get signSponsorConfirm;

  /// No description provided for @signed.
  ///
  /// In ar, this message translates to:
  /// **'موقَّع'**
  String get signed;

  /// No description provided for @transactions.
  ///
  /// In ar, this message translates to:
  /// **'الحركات'**
  String get transactions;

  /// No description provided for @stadium.
  ///
  /// In ar, this message translates to:
  /// **'الملعب'**
  String get stadium;

  /// No description provided for @stadiumProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total} أجزاء'**
  String stadiumProgress(int done, int total);

  /// No description provided for @capacity.
  ///
  /// In ar, this message translates to:
  /// **'السعة'**
  String get capacity;

  /// No description provided for @homeAdvantage.
  ///
  /// In ar, this message translates to:
  /// **'أفضلية الأرض'**
  String get homeAdvantage;

  /// No description provided for @sectionSeats.
  ///
  /// In ar, this message translates to:
  /// **'التذاكر والمقاعد'**
  String get sectionSeats;

  /// No description provided for @sectionPitch.
  ///
  /// In ar, this message translates to:
  /// **'أرضية الملعب'**
  String get sectionPitch;

  /// No description provided for @sectionTraining.
  ///
  /// In ar, this message translates to:
  /// **'مركز التدريب'**
  String get sectionTraining;

  /// No description provided for @stageOf.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {stage} من 3'**
  String stageOf(int stage);

  /// No description provided for @partOf.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {part} من 5'**
  String partOf(int part);

  /// No description provided for @buildPart.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ ({cost})'**
  String buildPart(String cost);

  /// No description provided for @sectionDone.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get sectionDone;

  /// No description provided for @buildingNow.
  ///
  /// In ar, this message translates to:
  /// **'يُبنى الآن: {section}'**
  String buildingNow(String section);

  /// No description provided for @endsIn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {time}'**
  String endsIn(String time);

  /// No description provided for @finishNow.
  ///
  /// In ar, this message translates to:
  /// **'أنهِه الآن ({coins} كوينز)'**
  String finishNow(int coins);

  /// No description provided for @finishNowConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الجزء الآن مقابل {coins} كوينز؟'**
  String finishNowConfirm(int coins);

  /// No description provided for @partTime.
  ///
  /// In ar, this message translates to:
  /// **'كل جزء يأخذ {time}'**
  String partTime(String time);

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @market.
  ///
  /// In ar, this message translates to:
  /// **'السوق'**
  String get market;

  /// No description provided for @tabBuy.
  ///
  /// In ar, this message translates to:
  /// **'شراء'**
  String get tabBuy;

  /// No description provided for @tabSell.
  ///
  /// In ar, this message translates to:
  /// **'بيع'**
  String get tabSell;

  /// No description provided for @tabOffers.
  ///
  /// In ar, this message translates to:
  /// **'العروض'**
  String get tabOffers;

  /// No description provided for @marketClosed.
  ///
  /// In ar, this message translates to:
  /// **'السوق مغلق الآن'**
  String get marketClosed;

  /// No description provided for @renewsAt.
  ///
  /// In ar, this message translates to:
  /// **'تتجدد القائمة {time}'**
  String renewsAt(String time);

  /// No description provided for @fitsYou.
  ///
  /// In ar, this message translates to:
  /// **'يقوّي فريقك'**
  String get fitsYou;

  /// No description provided for @sellerWorld.
  ///
  /// In ar, this message translates to:
  /// **'من خارج الدوري'**
  String get sellerWorld;

  /// No description provided for @buyFor.
  ///
  /// In ar, this message translates to:
  /// **'اشترِه بـ {price}'**
  String buyFor(String price);

  /// No description provided for @regFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التسجيل {coins} كوينز'**
  String regFee(int coins);

  /// No description provided for @compensateWith.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الناقص بـ {coins} كوينز'**
  String compensateWith(int coins);

  /// No description provided for @bought.
  ///
  /// In ar, this message translates to:
  /// **'صار في فريقك'**
  String get bought;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get price;

  /// No description provided for @listedAt.
  ///
  /// In ar, this message translates to:
  /// **'معروض بـ {price}'**
  String listedAt(String price);

  /// No description provided for @sellsIn.
  ///
  /// In ar, this message translates to:
  /// **'يُباع نحو {time}'**
  String sellsIn(String time);

  /// No description provided for @listForSale.
  ///
  /// In ar, this message translates to:
  /// **'اعرضه للبيع'**
  String get listForSale;

  /// No description provided for @unlist.
  ///
  /// In ar, this message translates to:
  /// **'اسحب العرض'**
  String get unlist;

  /// No description provided for @sellNowFor.
  ///
  /// In ar, this message translates to:
  /// **'بيع فوري: يدخل {pays}، مقابل {fee}'**
  String sellNowFor(String pays, String fee);

  /// No description provided for @sellNowConfirm.
  ///
  /// In ar, this message translates to:
  /// **'بيعه الآن؟ لا رجوع.'**
  String get sellNowConfirm;

  /// No description provided for @priceRange.
  ///
  /// In ar, this message translates to:
  /// **'بين {floor} و{cap}'**
  String priceRange(String floor, String cap);

  /// No description provided for @waitAbout.
  ///
  /// In ar, this message translates to:
  /// **'مشترٍ خلال {hours} ساعة تقريباً'**
  String waitAbout(int hours);

  /// No description provided for @listingsOf.
  ///
  /// In ar, this message translates to:
  /// **'{listed} من {max} معروضون'**
  String listingsOf(int listed, int max);

  /// No description provided for @noOffers.
  ///
  /// In ar, this message translates to:
  /// **'لا عروض الآن'**
  String get noOffers;

  /// No description provided for @offerFrom.
  ///
  /// In ar, this message translates to:
  /// **'عرض من {club}'**
  String offerFrom(String club);

  /// No description provided for @offerTo.
  ///
  /// In ar, this message translates to:
  /// **'عرضك إلى {club}'**
  String offerTo(String club);

  /// No description provided for @theyWant.
  ///
  /// In ar, this message translates to:
  /// **'يطلب'**
  String get theyWant;

  /// No description provided for @theyGive.
  ///
  /// In ar, this message translates to:
  /// **'ويعطي'**
  String get theyGive;

  /// No description provided for @accept.
  ///
  /// In ar, this message translates to:
  /// **'اقبل'**
  String get accept;

  /// No description provided for @cancelOffer.
  ///
  /// In ar, this message translates to:
  /// **'اسحب العرض'**
  String get cancelOffer;

  /// No description provided for @offersOnWeb.
  ///
  /// In ar, this message translates to:
  /// **'تقديم عرض أو عرض مقابل من الموقع الآن'**
  String get offersOnWeb;

  /// No description provided for @coinsWord.
  ///
  /// In ar, this message translates to:
  /// **'{n} كوينز'**
  String coinsWord(int n);

  /// No description provided for @statusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get statusRejected;

  /// No description provided for @statusOther.
  ///
  /// In ar, this message translates to:
  /// **'منتهٍ'**
  String get statusOther;

  /// No description provided for @scout.
  ///
  /// In ar, this message translates to:
  /// **'الكشاف'**
  String get scout;

  /// No description provided for @scoutLead.
  ///
  /// In ar, this message translates to:
  /// **'يبحث لك الكشاف عن خمسة لاعبين من خارج الدوري بشروطك، ويحجزهم لك حتى يتجدد السوق.'**
  String get scoutLead;

  /// No description provided for @minOverall.
  ///
  /// In ar, this message translates to:
  /// **'أقل تقييم'**
  String get minOverall;

  /// No description provided for @maxAge.
  ///
  /// In ar, this message translates to:
  /// **'أكبر عمر'**
  String get maxAge;

  /// No description provided for @anyLine.
  ///
  /// In ar, this message translates to:
  /// **'أي خط'**
  String get anyLine;

  /// No description provided for @nationality.
  ///
  /// In ar, this message translates to:
  /// **'الجنسية'**
  String get nationality;

  /// No description provided for @fromLeague.
  ///
  /// In ar, this message translates to:
  /// **'من دوري'**
  String get fromLeague;

  /// No description provided for @any.
  ///
  /// In ar, this message translates to:
  /// **'أي'**
  String get any;

  /// No description provided for @askScout.
  ///
  /// In ar, this message translates to:
  /// **'ابحث ({cost}، {hours} ساعة)'**
  String askScout(String cost, int hours);

  /// No description provided for @searching.
  ///
  /// In ar, this message translates to:
  /// **'يبحث… التقرير {time}'**
  String searching(String time);

  /// No description provided for @scoutReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get scoutReports;

  /// No description provided for @nobodyFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يجد أحداً، وعادت الأموال'**
  String get nobodyFound;

  /// No description provided for @stateMine.
  ///
  /// In ar, this message translates to:
  /// **'في فريقك'**
  String get stateMine;

  /// No description provided for @stateGone.
  ///
  /// In ar, this message translates to:
  /// **'ذهب'**
  String get stateGone;

  /// No description provided for @training.
  ///
  /// In ar, this message translates to:
  /// **'التدريب'**
  String get training;

  /// No description provided for @trainingLead.
  ///
  /// In ar, this message translates to:
  /// **'لاعب واحد في كل خط يتدرب، وكل حصة ترفع تقدمه حتى يزيد تقييمه.'**
  String get trainingLead;

  /// No description provided for @sessionCost.
  ///
  /// In ar, this message translates to:
  /// **'الحصة {cost} كل {time}'**
  String sessionCost(String cost, String time);

  /// No description provided for @nobodyTraining.
  ///
  /// In ar, this message translates to:
  /// **'لا أحد يتدرب'**
  String get nobodyTraining;

  /// No description provided for @pickToTrain.
  ///
  /// In ar, this message translates to:
  /// **'اختر من يتدرب'**
  String get pickToTrain;

  /// No description provided for @recommended.
  ///
  /// In ar, this message translates to:
  /// **'المقترح'**
  String get recommended;

  /// No description provided for @nextSession.
  ///
  /// In ar, this message translates to:
  /// **'الحصة التالية {time}'**
  String nextSession(String time);

  /// No description provided for @sessionsDone.
  ///
  /// In ar, this message translates to:
  /// **'{n} حصص'**
  String sessionsDone(int n);

  /// No description provided for @stopTraining.
  ///
  /// In ar, this message translates to:
  /// **'أوقف'**
  String get stopTraining;

  /// No description provided for @maxed.
  ///
  /// In ar, this message translates to:
  /// **'بلغ أقصاه'**
  String get maxed;

  /// No description provided for @lineCoach.
  ///
  /// In ar, this message translates to:
  /// **'{name}: {stars} نجوم'**
  String lineCoach(String name, int stars);

  /// No description provided for @specialists.
  ///
  /// In ar, this message translates to:
  /// **'الأخصائيون'**
  String get specialists;

  /// No description provided for @specialistsLead.
  ///
  /// In ar, this message translates to:
  /// **'أخصائي لكل خط يسرّع تدريبه، لمدة {days} أيام.'**
  String specialistsLead(int days);

  /// No description provided for @hire.
  ///
  /// In ar, this message translates to:
  /// **'وظّف'**
  String get hire;

  /// No description provided for @hiredUntil.
  ///
  /// In ar, this message translates to:
  /// **'حتى {time}'**
  String hiredUntil(String time);

  /// No description provided for @hireConfirm.
  ///
  /// In ar, this message translates to:
  /// **'توظيفه بـ {cost}؟'**
  String hireConfirm(String cost);

  /// No description provided for @spy.
  ///
  /// In ar, this message translates to:
  /// **'التجسس'**
  String get spy;

  /// No description provided for @spyLead.
  ///
  /// In ar, this message translates to:
  /// **'يكشف لك جاسوسك تشكيلة خصمك القادم وخطته ولياقته قبل القفل.'**
  String get spyLead;

  /// No description provided for @sendSpy.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الجاسوس ({cost})'**
  String sendSpy(String cost);

  /// No description provided for @noNextMatch.
  ///
  /// In ar, this message translates to:
  /// **'لا مباراة قادمة'**
  String get noNextMatch;

  /// No description provided for @spyReportOn.
  ///
  /// In ar, this message translates to:
  /// **'تقرير عن {club}'**
  String spyReportOn(String club);

  /// No description provided for @form.
  ///
  /// In ar, this message translates to:
  /// **'الأداء'**
  String get form;

  /// No description provided for @quests.
  ///
  /// In ar, this message translates to:
  /// **'المهام'**
  String get quests;

  /// No description provided for @questsRenew.
  ///
  /// In ar, this message translates to:
  /// **'تتجدد {time}'**
  String questsRenew(String time);

  /// No description provided for @questFriendly.
  ///
  /// In ar, this message translates to:
  /// **'العب ودية'**
  String get questFriendly;

  /// No description provided for @questWins.
  ///
  /// In ar, this message translates to:
  /// **'حقق انتصارات'**
  String get questWins;

  /// No description provided for @questStadium.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ جزءاً في الملعب'**
  String get questStadium;

  /// No description provided for @questTraining.
  ///
  /// In ar, this message translates to:
  /// **'درّب لاعباً'**
  String get questTraining;

  /// No description provided for @questUnbeaten.
  ///
  /// In ar, this message translates to:
  /// **'لا تخسر'**
  String get questUnbeaten;

  /// No description provided for @claim.
  ///
  /// In ar, this message translates to:
  /// **'استلم'**
  String get claim;

  /// No description provided for @claimed.
  ///
  /// In ar, this message translates to:
  /// **'استُلمت'**
  String get claimed;

  /// No description provided for @honours.
  ///
  /// In ar, this message translates to:
  /// **'قاعة الشرف'**
  String get honours;

  /// No description provided for @seasonN.
  ///
  /// In ar, this message translates to:
  /// **'الموسم {n}'**
  String seasonN(int n);

  /// No description provided for @noTitles.
  ///
  /// In ar, this message translates to:
  /// **'لا ألقاب بعد'**
  String get noTitles;

  /// No description provided for @resign.
  ///
  /// In ar, this message translates to:
  /// **'استقل من الدوري'**
  String get resign;

  /// No description provided for @resignConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تستقيل من هذا الدوري؟ يعود فريقك للكمبيوتر ولا رجوع.'**
  String get resignConfirm;

  /// No description provided for @wallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get wallet;

  /// No description provided for @dailyCoins.
  ///
  /// In ar, this message translates to:
  /// **'كوينز اليوم: {n}'**
  String dailyCoins(int n);

  /// No description provided for @claimDaily.
  ///
  /// In ar, this message translates to:
  /// **'استلم كوينز اليوم'**
  String get claimDaily;

  /// No description provided for @dailyClaimed.
  ///
  /// In ar, this message translates to:
  /// **'استلمت كوينز اليوم'**
  String get dailyClaimed;

  /// No description provided for @store.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get store;

  /// No description provided for @buyOnWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'اطلب عبر واتساب'**
  String get buyOnWhatsapp;

  /// No description provided for @endsOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي {time}'**
  String endsOn(String time);

  /// No description provided for @competitionLeague.
  ///
  /// In ar, this message translates to:
  /// **'الدوري'**
  String get competitionLeague;

  /// No description provided for @coachProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملف المدرب'**
  String get coachProfile;

  /// No description provided for @accountNumber.
  ///
  /// In ar, this message translates to:
  /// **'حساب رقم {n}'**
  String accountNumber(int n);

  /// No description provided for @seasonsPlayed.
  ///
  /// In ar, this message translates to:
  /// **'المواسم'**
  String get seasonsPlayed;

  /// No description provided for @played.
  ///
  /// In ar, this message translates to:
  /// **'لعب'**
  String get played;

  /// No description provided for @won.
  ///
  /// In ar, this message translates to:
  /// **'فاز'**
  String get won;

  /// No description provided for @drawn.
  ///
  /// In ar, this message translates to:
  /// **'تعادل'**
  String get drawn;

  /// No description provided for @lost.
  ///
  /// In ar, this message translates to:
  /// **'خسر'**
  String get lost;

  /// No description provided for @titles.
  ///
  /// In ar, this message translates to:
  /// **'الألقاب'**
  String get titles;

  /// No description provided for @objectivesMet.
  ///
  /// In ar, this message translates to:
  /// **'أهداف الإدارة: {met} من {total}'**
  String objectivesMet(int met, int total);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
