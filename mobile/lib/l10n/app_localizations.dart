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

  /// No description provided for @gameSounds.
  ///
  /// In ar, this message translates to:
  /// **'أصوات اللعبة'**
  String get gameSounds;

  /// No description provided for @matchStats.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات المباراة'**
  String get matchStats;

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

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @pushReady.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات تصل إلى هذا الجوال'**
  String get pushReady;

  /// No description provided for @pushNotReady.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات على الجوال لم تُفعَّل في الخادم بعد، والرسائل كلها في صندوقك'**
  String get pushNotReady;

  /// No description provided for @kindReferee.
  ///
  /// In ar, this message translates to:
  /// **'حكم مباراتك القادمة'**
  String get kindReferee;

  /// No description provided for @kindMatchSoon.
  ///
  /// In ar, this message translates to:
  /// **'مباراتك بعد قليل وتقديمها'**
  String get kindMatchSoon;

  /// No description provided for @kindOffers.
  ///
  /// In ar, this message translates to:
  /// **'العروض والبيع والإعارة'**
  String get kindOffers;

  /// No description provided for @kindDone.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال التدريب والملعب والكشاف'**
  String get kindDone;

  /// No description provided for @kindNews.
  ///
  /// In ar, this message translates to:
  /// **'أخبار اللعبة ورسائل المطورين'**
  String get kindNews;

  /// No description provided for @kindAbsence.
  ///
  /// In ar, this message translates to:
  /// **'الغياب والإجازات'**
  String get kindAbsence;

  /// No description provided for @emailMatch.
  ///
  /// In ar, this message translates to:
  /// **'ملخص المباراة بالبريد'**
  String get emailMatch;

  /// No description provided for @emailOffers.
  ///
  /// In ar, this message translates to:
  /// **'عروض المتجر بالبريد'**
  String get emailOffers;

  /// No description provided for @emailNeeded.
  ///
  /// In ar, this message translates to:
  /// **'يلزم بريد مؤكد في حسابك'**
  String get emailNeeded;

  /// No description provided for @newOffer.
  ///
  /// In ar, this message translates to:
  /// **'عرض جديد'**
  String get newOffer;

  /// No description provided for @counterOffer.
  ///
  /// In ar, this message translates to:
  /// **'عرض مقابل'**
  String get counterOffer;

  /// No description provided for @pickCoachClub.
  ///
  /// In ar, this message translates to:
  /// **'إلى أي نادٍ؟'**
  String get pickCoachClub;

  /// No description provided for @noCoachClubs.
  ///
  /// In ar, this message translates to:
  /// **'لا مدربين آخرين في الدوري بعد'**
  String get noCoachClubs;

  /// No description provided for @offerTitleTo.
  ///
  /// In ar, this message translates to:
  /// **'عرض إلى {club}'**
  String offerTitleTo(String club);

  /// No description provided for @youWant.
  ///
  /// In ar, this message translates to:
  /// **'تطلب من لاعبيه (حتى 5)'**
  String get youWant;

  /// No description provided for @youGive.
  ///
  /// In ar, this message translates to:
  /// **'وتعطي من لاعبيك (اختياري)'**
  String get youGive;

  /// No description provided for @youPay.
  ///
  /// In ar, this message translates to:
  /// **'وتدفع'**
  String get youPay;

  /// No description provided for @offerValues.
  ///
  /// In ar, this message translates to:
  /// **'قيمة ما تطلب {want}، وما تعطي {give}'**
  String offerValues(String want, String give);

  /// No description provided for @fairHint.
  ///
  /// In ar, this message translates to:
  /// **'الصفقة العادلة بين {min}% و{max}% من قيمة ما تطلب'**
  String fairHint(int min, int max);

  /// No description provided for @sendOffer.
  ///
  /// In ar, this message translates to:
  /// **'أرسل العرض'**
  String get sendOffer;

  /// No description provided for @offerSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل العرض إلى مدربه'**
  String get offerSent;

  /// No description provided for @askLoan.
  ///
  /// In ar, this message translates to:
  /// **'اطلب إعارته'**
  String get askLoan;

  /// No description provided for @loanRounds.
  ///
  /// In ar, this message translates to:
  /// **'جولات الإعارة: {n}'**
  String loanRounds(int n);

  /// No description provided for @loanFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم الإعارة'**
  String get loanFee;

  /// No description provided for @loans.
  ///
  /// In ar, this message translates to:
  /// **'الإعارات'**
  String get loans;

  /// No description provided for @loanOf.
  ///
  /// In ar, this message translates to:
  /// **'{player}: من {owner} إلى {borrower}'**
  String loanOf(String player, String owner, String borrower);

  /// No description provided for @loanTerms.
  ///
  /// In ar, this message translates to:
  /// **'{rounds} جولات · {fee}'**
  String loanTerms(int rounds, String fee);

  /// No description provided for @loanSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل طلب الإعارة'**
  String get loanSent;

  /// No description provided for @academy.
  ///
  /// In ar, this message translates to:
  /// **'الأكاديمية'**
  String get academy;

  /// No description provided for @academyLead.
  ///
  /// In ar, this message translates to:
  /// **'مواهب شابة لهذه الفترة، والإمكانية مدى حتى تضمه. {signed} من {per} هذا الموسم.'**
  String academyLead(int signed, int per);

  /// No description provided for @signProspect.
  ///
  /// In ar, this message translates to:
  /// **'ضمّه بـ {price}'**
  String signProspect(String price);

  /// No description provided for @signProspectConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ضمّ {name} بـ {price}؟'**
  String signProspectConfirm(String name, String price);

  /// No description provided for @potentialRange.
  ///
  /// In ar, this message translates to:
  /// **'الإمكانية {from}–{to}'**
  String potentialRange(int from, int to);

  /// No description provided for @friendlies.
  ///
  /// In ar, this message translates to:
  /// **'الوديات'**
  String get friendlies;

  /// No description provided for @friendlyLead.
  ///
  /// In ar, this message translates to:
  /// **'ودية سريعة ضد أي نادٍ: ترفع اللياقة {fit} والانسجام، ولا تحتسب في الجدول.'**
  String friendlyLead(int fit);

  /// No description provided for @friendlyCost.
  ///
  /// In ar, this message translates to:
  /// **'الودية بـ {coins} كوينز'**
  String friendlyCost(int coins);

  /// No description provided for @friendlyFree.
  ///
  /// In ar, this message translates to:
  /// **'الأولى مجانية'**
  String get friendlyFree;

  /// No description provided for @playFriendly.
  ///
  /// In ar, this message translates to:
  /// **'العب'**
  String get playFriendly;

  /// No description provided for @suggestedOpponent.
  ///
  /// In ar, this message translates to:
  /// **'مقترح'**
  String get suggestedOpponent;

  /// No description provided for @playedToday.
  ///
  /// In ar, this message translates to:
  /// **'لُعبت اليوم'**
  String get playedToday;

  /// No description provided for @recentFriendlies.
  ///
  /// In ar, this message translates to:
  /// **'آخر الوديات'**
  String get recentFriendlies;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطَّ'**
  String get skip;

  /// No description provided for @bestOfMatch.
  ///
  /// In ar, this message translates to:
  /// **'الأفضل في المباراة'**
  String get bestOfMatch;

  /// No description provided for @kGoal.
  ///
  /// In ar, this message translates to:
  /// **'هدف'**
  String get kGoal;

  /// No description provided for @kSaved.
  ///
  /// In ar, this message translates to:
  /// **'تصدٍّ'**
  String get kSaved;

  /// No description provided for @kMissed.
  ///
  /// In ar, this message translates to:
  /// **'ضائعة'**
  String get kMissed;

  /// No description provided for @kCorner.
  ///
  /// In ar, this message translates to:
  /// **'ركنية'**
  String get kCorner;

  /// No description provided for @kYellow.
  ///
  /// In ar, this message translates to:
  /// **'صفراء'**
  String get kYellow;

  /// No description provided for @kRed.
  ///
  /// In ar, this message translates to:
  /// **'حمراء'**
  String get kRed;

  /// No description provided for @kAttack.
  ///
  /// In ar, this message translates to:
  /// **'هجمة'**
  String get kAttack;

  /// No description provided for @predictions.
  ///
  /// In ar, this message translates to:
  /// **'التوقعات'**
  String get predictions;

  /// No description provided for @predictionsLead.
  ///
  /// In ar, this message translates to:
  /// **'توقّع نتائج الجولة {round}، ولكل توقع صحيح {reward} لناديك.'**
  String predictionsLead(int round, String reward);

  /// No description provided for @draw.
  ///
  /// In ar, this message translates to:
  /// **'تعادل'**
  String get draw;

  /// No description provided for @predictionClosed.
  ///
  /// In ar, this message translates to:
  /// **'أُغلق التوقع'**
  String get predictionClosed;

  /// No description provided for @newspaper.
  ///
  /// In ar, this message translates to:
  /// **'الصحيفة'**
  String get newspaper;

  /// No description provided for @noEdition.
  ///
  /// In ar, this message translates to:
  /// **'لا عدد بعد: تصدر الصحيفة بعد أول جولة'**
  String get noEdition;

  /// No description provided for @roundResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج الجولة {round}'**
  String roundResults(int round);

  /// No description provided for @playerOfRound.
  ///
  /// In ar, this message translates to:
  /// **'لاعب الجولة'**
  String get playerOfRound;

  /// No description provided for @coachOfRound.
  ///
  /// In ar, this message translates to:
  /// **'مدرب الجولة'**
  String get coachOfRound;

  /// No description provided for @articles.
  ///
  /// In ar, this message translates to:
  /// **'مقالات المدربين'**
  String get articles;

  /// No description provided for @writeArticle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مقالاً'**
  String get writeArticle;

  /// No description provided for @articleTitle.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get articleTitle;

  /// No description provided for @articleBody.
  ///
  /// In ar, this message translates to:
  /// **'المقال'**
  String get articleBody;

  /// No description provided for @articleSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل مقالك إلى منشئ الدوري للنشر'**
  String get articleSent;

  /// No description provided for @pendingArticles.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار النشر'**
  String get pendingArticles;

  /// No description provided for @publish.
  ///
  /// In ar, this message translates to:
  /// **'انشر'**
  String get publish;

  /// No description provided for @groups.
  ///
  /// In ar, this message translates to:
  /// **'الجروبات'**
  String get groups;

  /// No description provided for @noGroups.
  ///
  /// In ar, this message translates to:
  /// **'لا جروبات بعد'**
  String get noGroups;

  /// No description provided for @typeMessage.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة'**
  String get typeMessage;

  /// No description provided for @messageDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت هذه الرسالة'**
  String get messageDeleted;

  /// No description provided for @mediaOnWeb.
  ///
  /// In ar, this message translates to:
  /// **'صورة أو صوت: افتحه من الموقع'**
  String get mediaOnWeb;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profile;

  /// No description provided for @displayNameSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ'**
  String get displayNameSaved;

  /// No description provided for @coachLook.
  ///
  /// In ar, this message translates to:
  /// **'شكلك على الخط'**
  String get coachLook;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'غيّر كلمة المرور'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت كلمة المرور'**
  String get passwordChanged;

  /// No description provided for @inviteFriends.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ أصدقاءك'**
  String get inviteFriends;

  /// No description provided for @inviteReward.
  ///
  /// In ar, this message translates to:
  /// **'{coins} كوينز لكل صديق يلعب، دُفع لك {paid} من {max}'**
  String inviteReward(int coins, int paid, int max);

  /// No description provided for @achievements.
  ///
  /// In ar, this message translates to:
  /// **'الأوسمة'**
  String get achievements;

  /// No description provided for @tierBeginner.
  ///
  /// In ar, this message translates to:
  /// **'المبتدئ'**
  String get tierBeginner;

  /// No description provided for @tierIntermediate.
  ///
  /// In ar, this message translates to:
  /// **'المتوسط'**
  String get tierIntermediate;

  /// No description provided for @tierPro.
  ///
  /// In ar, this message translates to:
  /// **'المحترف'**
  String get tierPro;

  /// No description provided for @aFirstWin.
  ///
  /// In ar, this message translates to:
  /// **'أول فوز'**
  String get aFirstWin;

  /// No description provided for @aMatches.
  ///
  /// In ar, this message translates to:
  /// **'{n} مباراة'**
  String aMatches(int n);

  /// No description provided for @aWins.
  ///
  /// In ar, this message translates to:
  /// **'{n} فوزاً'**
  String aWins(int n);

  /// No description provided for @aFirstTitle.
  ///
  /// In ar, this message translates to:
  /// **'أول لقب'**
  String get aFirstTitle;

  /// No description provided for @aLeagueTitle.
  ///
  /// In ar, this message translates to:
  /// **'بطل الدوري'**
  String get aLeagueTitle;

  /// No description provided for @aCupTitle.
  ///
  /// In ar, this message translates to:
  /// **'بطل الكأس'**
  String get aCupTitle;

  /// No description provided for @aProfessional.
  ///
  /// In ar, this message translates to:
  /// **'درجة المحترف'**
  String get aProfessional;

  /// No description provided for @aLegend.
  ///
  /// In ar, this message translates to:
  /// **'درجة الأسطورة'**
  String get aLegend;

  /// No description provided for @aFriendlies.
  ///
  /// In ar, this message translates to:
  /// **'{n} وديات'**
  String aFriendlies(int n);

  /// No description provided for @aIdea.
  ///
  /// In ar, this message translates to:
  /// **'فكرة اعتُمدت'**
  String get aIdea;

  /// No description provided for @aInvites.
  ///
  /// In ar, this message translates to:
  /// **'{n} أصدقاء'**
  String aInvites(int n);

  /// No description provided for @aTitles.
  ///
  /// In ar, this message translates to:
  /// **'{n} ألقاب'**
  String aTitles(int n);

  /// No description provided for @stats.
  ///
  /// In ar, this message translates to:
  /// **'الإحصاءات'**
  String get stats;

  /// No description provided for @scorers.
  ///
  /// In ar, this message translates to:
  /// **'الهدافون'**
  String get scorers;

  /// No description provided for @assistsTitle.
  ///
  /// In ar, this message translates to:
  /// **'صناع الأهداف'**
  String get assistsTitle;

  /// No description provided for @squadValues.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الفرق'**
  String get squadValues;

  /// No description provided for @goalsShort.
  ///
  /// In ar, this message translates to:
  /// **'أهداف'**
  String get goalsShort;

  /// No description provided for @assistsShort.
  ///
  /// In ar, this message translates to:
  /// **'تمريرات'**
  String get assistsShort;

  /// No description provided for @noStatsYet.
  ///
  /// In ar, this message translates to:
  /// **'تظهر الإحصاءات بعد أول جولة'**
  String get noStatsYet;

  /// No description provided for @ideas.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحاتك للمطورين'**
  String get ideas;

  /// No description provided for @ideasLead.
  ///
  /// In ar, this message translates to:
  /// **'المقبول يأخذ مكافأة كوينز ويدخل صاحبه قائمة الشرف. باقٍ لك اليوم {n}.'**
  String ideasLead(int n);

  /// No description provided for @suggest.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الاقتراح'**
  String get suggest;

  /// No description provided for @suggestionSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل اقتراحك'**
  String get suggestionSent;

  /// No description provided for @polls.
  ///
  /// In ar, this message translates to:
  /// **'التصويت'**
  String get polls;

  /// No description provided for @vote.
  ///
  /// In ar, this message translates to:
  /// **'صوّت'**
  String get vote;

  /// No description provided for @votes.
  ///
  /// In ar, this message translates to:
  /// **'{n} صوت'**
  String votes(int n);

  /// No description provided for @honourRoll.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الشرف'**
  String get honourRoll;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get statusPending;

  /// No description provided for @statusBuilt.
  ///
  /// In ar, this message translates to:
  /// **'بُني'**
  String get statusBuilt;

  /// No description provided for @support.
  ///
  /// In ar, this message translates to:
  /// **'الدعم'**
  String get support;

  /// No description provided for @supportLead.
  ///
  /// In ar, this message translates to:
  /// **'اكتب لفريق اللعبة، والرد هنا.'**
  String get supportLead;

  /// No description provided for @fromTeam.
  ///
  /// In ar, this message translates to:
  /// **'فريق اللعبة'**
  String get fromTeam;

  /// No description provided for @announcements.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get announcements;

  /// No description provided for @noAnnouncements.
  ///
  /// In ar, this message translates to:
  /// **'لا إعلانات'**
  String get noAnnouncements;

  /// No description provided for @guide.
  ///
  /// In ar, this message translates to:
  /// **'طريقة اللعب'**
  String get guide;

  /// No description provided for @tournaments.
  ///
  /// In ar, this message translates to:
  /// **'البطولات'**
  String get tournaments;

  /// No description provided for @noTournaments.
  ///
  /// In ar, this message translates to:
  /// **'لا بطولات بعد'**
  String get noTournaments;

  /// No description provided for @newTournament.
  ///
  /// In ar, this message translates to:
  /// **'بطولة جديدة'**
  String get newTournament;

  /// No description provided for @tplWorldCup.
  ///
  /// In ar, this message translates to:
  /// **'كأس العالم (32)'**
  String get tplWorldCup;

  /// No description provided for @tplWorldCup48.
  ///
  /// In ar, this message translates to:
  /// **'كأس العالم (48)'**
  String get tplWorldCup48;

  /// No description provided for @tplClubWorldCup.
  ///
  /// In ar, this message translates to:
  /// **'كأس العالم للأندية'**
  String get tplClubWorldCup;

  /// No description provided for @tplAfcon.
  ///
  /// In ar, this message translates to:
  /// **'أمم أفريقيا'**
  String get tplAfcon;

  /// No description provided for @tplEuro.
  ///
  /// In ar, this message translates to:
  /// **'أمم أوروبا'**
  String get tplEuro;

  /// No description provided for @tplAsianCup.
  ///
  /// In ar, this message translates to:
  /// **'كأس آسيا'**
  String get tplAsianCup;

  /// No description provided for @startsOn.
  ///
  /// In ar, this message translates to:
  /// **'تبدأ'**
  String get startsOn;

  /// No description provided for @entryPick.
  ///
  /// In ar, this message translates to:
  /// **'كل مدرب يختار منتخبه'**
  String get entryPick;

  /// No description provided for @entryDraw.
  ///
  /// In ar, this message translates to:
  /// **'القرعة توزع المنتخبات على المدربين'**
  String get entryDraw;

  /// No description provided for @tournamentCost.
  ///
  /// In ar, this message translates to:
  /// **'الكلفة {coins} كوينز'**
  String tournamentCost(int coins);

  /// No description provided for @tournamentCode.
  ///
  /// In ar, this message translates to:
  /// **'كود الانضمام'**
  String get tournamentCode;

  /// No description provided for @teamsCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} فريقاً'**
  String teamsCount(int n);

  /// No description provided for @enter.
  ///
  /// In ar, this message translates to:
  /// **'سجّل اسمك'**
  String get enter;

  /// No description provided for @leaveEntry.
  ///
  /// In ar, this message translates to:
  /// **'انسحب'**
  String get leaveEntry;

  /// No description provided for @watchDraw.
  ///
  /// In ar, this message translates to:
  /// **'شاهد القرعة'**
  String get watchDraw;

  /// No description provided for @drawAt.
  ///
  /// In ar, this message translates to:
  /// **'القرعة {time}'**
  String drawAt(String time);

  /// No description provided for @drawNotSet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحدَّد موعد القرعة'**
  String get drawNotSet;

  /// No description provided for @scheduleDraw.
  ///
  /// In ar, this message translates to:
  /// **'حدّد موعد القرعة'**
  String get scheduleDraw;

  /// No description provided for @drawnBalls.
  ///
  /// In ar, this message translates to:
  /// **'{n} من {total}'**
  String drawnBalls(int n, int total);

  /// No description provided for @groupN.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة {g}'**
  String groupN(String g);

  /// No description provided for @pot.
  ///
  /// In ar, this message translates to:
  /// **'الوعاء {n}'**
  String pot(int n);

  /// No description provided for @openLeague.
  ///
  /// In ar, this message translates to:
  /// **'افتح الدوري'**
  String get openLeague;

  /// No description provided for @alliance.
  ///
  /// In ar, this message translates to:
  /// **'بطولة التحالفات'**
  String get alliance;

  /// No description provided for @allianceLead.
  ///
  /// In ar, this message translates to:
  /// **'تحالفان من مدربي الدوري، وكل مواجهة يتأهل منها من يتفق مدرباها عليه.'**
  String get allianceLead;

  /// No description provided for @createAlliance.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ البطولة'**
  String get createAlliance;

  /// No description provided for @captainA.
  ///
  /// In ar, this message translates to:
  /// **'قائد التحالف الأول'**
  String get captainA;

  /// No description provided for @captainB.
  ///
  /// In ar, this message translates to:
  /// **'قائد التحالف الثاني'**
  String get captainB;

  /// No description provided for @allianceSize.
  ///
  /// In ar, this message translates to:
  /// **'مدربو كل تحالف: {n}'**
  String allianceSize(int n);

  /// No description provided for @firstRound.
  ///
  /// In ar, this message translates to:
  /// **'الجولة الأولى'**
  String get firstRound;

  /// No description provided for @goesOn.
  ///
  /// In ar, this message translates to:
  /// **'يتأهل'**
  String get goesOn;

  /// No description provided for @noAlliance.
  ///
  /// In ar, this message translates to:
  /// **'لا بطولة تحالفات في هذا الدوري'**
  String get noAlliance;

  /// No description provided for @newGroup.
  ///
  /// In ar, this message translates to:
  /// **'جروب جديد'**
  String get newGroup;

  /// No description provided for @groupName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجروب'**
  String get groupName;

  /// No description provided for @groupMembers.
  ///
  /// In ar, this message translates to:
  /// **'أسماء المستخدمين (مفصولة بفاصلة)'**
  String get groupMembers;

  /// No description provided for @joinGroup.
  ///
  /// In ar, this message translates to:
  /// **'ادخل بالكود'**
  String get joinGroup;

  /// No description provided for @groupCode.
  ///
  /// In ar, this message translates to:
  /// **'كود الجروب'**
  String get groupCode;

  /// No description provided for @openIt.
  ///
  /// In ar, this message translates to:
  /// **'افتح'**
  String get openIt;

  /// No description provided for @matchday.
  ///
  /// In ar, this message translates to:
  /// **'يوم المباراة'**
  String get matchday;

  /// No description provided for @referee.
  ///
  /// In ar, this message translates to:
  /// **'الحكم'**
  String get referee;

  /// No description provided for @moveMatch.
  ///
  /// In ar, this message translates to:
  /// **'قدّم المباراة أو أخّرها'**
  String get moveMatch;

  /// No description provided for @moveLead.
  ///
  /// In ar, this message translates to:
  /// **'في يومها نفسه، بموافقة المدرب الآخر. باقٍ لك {n}.'**
  String moveLead(int n);

  /// No description provided for @moveTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى {time}'**
  String moveTo(String time);

  /// No description provided for @movePendingMine.
  ///
  /// In ar, this message translates to:
  /// **'طلبت نقلها إلى {time}، بانتظار رده'**
  String movePendingMine(String time);

  /// No description provided for @movePendingTheirs.
  ///
  /// In ar, this message translates to:
  /// **'يطلب نقلها إلى {time}'**
  String movePendingTheirs(String time);

  /// No description provided for @moveSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلبك للمدرب الآخر'**
  String get moveSent;

  /// No description provided for @hoursEarlier.
  ///
  /// In ar, this message translates to:
  /// **'أبكر {n} س'**
  String hoursEarlier(int n);

  /// No description provided for @hoursLater.
  ///
  /// In ar, this message translates to:
  /// **'أبعد {n} س'**
  String hoursLater(int n);

  /// No description provided for @press.
  ///
  /// In ar, this message translates to:
  /// **'المؤتمر الصحفي'**
  String get press;

  /// No description provided for @pressOpensAt.
  ///
  /// In ar, this message translates to:
  /// **'يفتح {time}'**
  String pressOpensAt(String time);

  /// No description provided for @chances.
  ///
  /// In ar, this message translates to:
  /// **'الحظوظ: فوز {home}% · تعادل {draw}% · خسارة {away}%'**
  String chances(int home, int draw, int away);

  /// No description provided for @stakes.
  ///
  /// In ar, this message translates to:
  /// **'الروح المعنوية: فوز {win} · تعادل {draw} · خسارة {loss}'**
  String stakes(int win, int draw, int loss);

  /// No description provided for @youSaid.
  ///
  /// In ar, this message translates to:
  /// **'قلتَ'**
  String get youSaid;

  /// No description provided for @integrity.
  ///
  /// In ar, this message translates to:
  /// **'ما وراء الكواليس'**
  String get integrity;

  /// No description provided for @bribe.
  ///
  /// In ar, this message translates to:
  /// **'ادفع للحكم ({money} + {extra})'**
  String bribe(String money, String extra);

  /// No description provided for @bribeNote.
  ///
  /// In ar, this message translates to:
  /// **'الفار يكشفها مرة من كل {pct}%'**
  String bribeNote(int pct);

  /// No description provided for @bribePaid.
  ///
  /// In ar, this message translates to:
  /// **'دفعت للحكم'**
  String get bribePaid;

  /// No description provided for @securityCheck.
  ///
  /// In ar, this message translates to:
  /// **'فحص أمني ({cost})'**
  String securityCheck(String cost);

  /// No description provided for @spiesOnMe.
  ///
  /// In ar, this message translates to:
  /// **'الجواسيس على مباراتك'**
  String get spiesOnMe;

  /// No description provided for @noSpies.
  ///
  /// In ar, this message translates to:
  /// **'لا جواسيس حتى الآن'**
  String get noSpies;

  /// No description provided for @turnSpy.
  ///
  /// In ar, this message translates to:
  /// **'اجعله مزدوجاً ({cost})'**
  String turnSpy(String cost);

  /// No description provided for @accuse.
  ///
  /// In ar, this message translates to:
  /// **'اتهمه'**
  String get accuse;

  /// No description provided for @contracts.
  ///
  /// In ar, this message translates to:
  /// **'العقود'**
  String get contracts;

  /// No description provided for @contractsLead.
  ///
  /// In ar, this message translates to:
  /// **'الرواتب {wages} كل جولة من سقف {cap}'**
  String contractsLead(String wages, String cap);

  /// No description provided for @untilSeason.
  ///
  /// In ar, this message translates to:
  /// **'حتى الموسم {n}'**
  String untilSeason(int n);

  /// No description provided for @renew.
  ///
  /// In ar, this message translates to:
  /// **'جدّد'**
  String get renew;

  /// No description provided for @renewSeasons.
  ///
  /// In ar, this message translates to:
  /// **'جدّد {n} مواسم ({cost})'**
  String renewSeasons(int n, String cost);

  /// No description provided for @releasePlayer.
  ///
  /// In ar, this message translates to:
  /// **'فسخ العقد ({cost})'**
  String releasePlayer(String cost);

  /// No description provided for @releaseConfirm.
  ///
  /// In ar, this message translates to:
  /// **'فسخ عقد {name}؟ يخرج من فريقك.'**
  String releaseConfirm(String name);

  /// No description provided for @renewEnding.
  ///
  /// In ar, this message translates to:
  /// **'جدّد كل العقود المنتهية'**
  String get renewEnding;

  /// No description provided for @cheerTickets.
  ///
  /// In ar, this message translates to:
  /// **'تذاكر التشجيع'**
  String get cheerTickets;

  /// No description provided for @cheerLead.
  ///
  /// In ar, this message translates to:
  /// **'شجّع فريقاً في مباراة أخرى: +{boost} لحماسه، والتذكرة بـ {price}.'**
  String cheerLead(int boost, String price);

  /// No description provided for @cheer.
  ///
  /// In ar, this message translates to:
  /// **'شجّع'**
  String get cheer;

  /// No description provided for @matchChat.
  ///
  /// In ar, this message translates to:
  /// **'الدردشة'**
  String get matchChat;

  /// No description provided for @reactionSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل تفاعلك'**
  String get reactionSent;

  /// No description provided for @missedMatches.
  ///
  /// In ar, this message translates to:
  /// **'فاتتك {n} مباريات'**
  String missedMatches(int n);

  /// No description provided for @missedTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما فاتك'**
  String get missedTitle;

  /// No description provided for @markSeen.
  ///
  /// In ar, this message translates to:
  /// **'شاهدتها كلها'**
  String get markSeen;

  /// No description provided for @squadChanges.
  ///
  /// In ar, this message translates to:
  /// **'تغيّر في فريقك'**
  String get squadChanges;

  /// No description provided for @injured.
  ///
  /// In ar, this message translates to:
  /// **'مصاب'**
  String get injured;

  /// No description provided for @sentOff.
  ///
  /// In ar, this message translates to:
  /// **'طُرد'**
  String get sentOff;

  /// No description provided for @unlockSlot.
  ///
  /// In ar, this message translates to:
  /// **'افتحها الآن ({coins} كوينز)'**
  String unlockSlot(int coins);

  /// No description provided for @unlockConfirm.
  ///
  /// In ar, this message translates to:
  /// **'فتح الفتحة {n} الآن بـ {coins} كوينز؟ تبقى مفتوحة دائماً.'**
  String unlockConfirm(int n, int coins);

  /// No description provided for @starterGift.
  ///
  /// In ar, this message translates to:
  /// **'هدية البداية: {coins} كوينز'**
  String starterGift(int coins);

  /// No description provided for @claimGift.
  ///
  /// In ar, this message translates to:
  /// **'استلمها'**
  String get claimGift;

  /// No description provided for @ranking.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب المدربين'**
  String get ranking;

  /// No description provided for @trophiesShort.
  ///
  /// In ar, this message translates to:
  /// **'{n} ألقاب'**
  String trophiesShort(int n);

  /// No description provided for @holiday.
  ///
  /// In ar, this message translates to:
  /// **'إجازة'**
  String get holiday;

  /// No description provided for @holidayLeague.
  ///
  /// In ar, this message translates to:
  /// **'اطلب إجازة من هذا الدوري'**
  String get holidayLeague;

  /// No description provided for @holidayAccount.
  ///
  /// In ar, this message translates to:
  /// **'إجازة طويلة للحساب كله'**
  String get holidayAccount;

  /// No description provided for @holidayDays.
  ///
  /// In ar, this message translates to:
  /// **'الأيام: {n}'**
  String holidayDays(int n);

  /// No description provided for @holidayReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get holidayReason;

  /// No description provided for @holidaySent.
  ///
  /// In ar, this message translates to:
  /// **'وصل طلب الإجازة'**
  String get holidaySent;

  /// No description provided for @endHoliday.
  ///
  /// In ar, this message translates to:
  /// **'أنهِ الإجازة'**
  String get endHoliday;

  /// No description provided for @vacationAsk.
  ///
  /// In ar, this message translates to:
  /// **'يطلب إجازة {days} أيام: {reason}'**
  String vacationAsk(int days, String reason);

  /// No description provided for @kick.
  ///
  /// In ar, this message translates to:
  /// **'أبعِده'**
  String get kick;

  /// No description provided for @kickReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب (يراه الجميع)'**
  String get kickReason;

  /// No description provided for @verifyAccount.
  ///
  /// In ar, this message translates to:
  /// **'وثّق حسابك واحصل على {coins} كوينز'**
  String verifyAccount(int coins);

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الرمز إلى بريدي'**
  String get sendCode;

  /// No description provided for @codeSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل الرمز'**
  String get codeSent;

  /// No description provided for @verifyCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get verifyCode;

  /// No description provided for @verified.
  ///
  /// In ar, this message translates to:
  /// **'حسابك موثّق'**
  String get verified;

  /// No description provided for @resendEmail.
  ///
  /// In ar, this message translates to:
  /// **'أعد إرسال رسالة تأكيد البريد'**
  String get resendEmail;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'احذف حسابي'**
  String get deleteAccount;

  /// No description provided for @deleteAccountLead.
  ///
  /// In ar, this message translates to:
  /// **'تعود فرقك للكمبيوتر ولا رجوع. اكتب «احذف» للتأكيد.'**
  String get deleteAccountLead;

  /// No description provided for @startLeague.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الدوري الآن'**
  String get startLeague;

  /// No description provided for @changePhoto.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الصورة'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In ar, this message translates to:
  /// **'احذف الصورة'**
  String get removePhoto;

  /// No description provided for @sendPhoto.
  ///
  /// In ar, this message translates to:
  /// **'أرسل صورة'**
  String get sendPhoto;

  /// No description provided for @leagueSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الدوري'**
  String get leagueSettings;

  /// No description provided for @settingsLocked.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات مقفلة منذ بداية الدوري'**
  String get settingsLocked;

  /// No description provided for @customTeams.
  ///
  /// In ar, this message translates to:
  /// **'فرق من اختيارك'**
  String get customTeams;

  /// No description provided for @searchClubs.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن نادٍ'**
  String get searchClubs;

  /// No description provided for @nationsTab.
  ///
  /// In ar, this message translates to:
  /// **'المنتخبات'**
  String get nationsTab;

  /// No description provided for @clubsTab.
  ///
  /// In ar, this message translates to:
  /// **'الأندية'**
  String get clubsTab;

  /// No description provided for @chosenTeams.
  ///
  /// In ar, this message translates to:
  /// **'{n} فريقاً مختاراً'**
  String chosenTeams(int n);

  /// No description provided for @formatLeague.
  ///
  /// In ar, this message translates to:
  /// **'دوري'**
  String get formatLeague;

  /// No description provided for @formatGroups.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات'**
  String get formatGroups;

  /// No description provided for @formatKnockout.
  ///
  /// In ar, this message translates to:
  /// **'خروج المغلوب'**
  String get formatKnockout;

  /// No description provided for @groupsCount.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات: {n}'**
  String groupsCount(int n);

  /// No description provided for @swapPlayers.
  ///
  /// In ar, this message translates to:
  /// **'بادل لاعبين (حتى {n})'**
  String swapPlayers(int n);

  /// No description provided for @swapGive.
  ///
  /// In ar, this message translates to:
  /// **'تعطي'**
  String get swapGive;

  /// No description provided for @swapTake.
  ///
  /// In ar, this message translates to:
  /// **'تأخذ'**
  String get swapTake;

  /// No description provided for @recordVoice.
  ///
  /// In ar, this message translates to:
  /// **'سجّل رسالة صوتية'**
  String get recordVoice;

  /// No description provided for @stopAndSend.
  ///
  /// In ar, this message translates to:
  /// **'أوقف وأرسل'**
  String get stopAndSend;

  /// No description provided for @voiceNote.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية {n} ث'**
  String voiceNote(int n);

  /// No description provided for @micDenied.
  ///
  /// In ar, this message translates to:
  /// **'اسمح للتطبيق باستعمال الميكروفون من إعدادات الجوال'**
  String get micDenied;

  /// No description provided for @navClub.
  ///
  /// In ar, this message translates to:
  /// **'ناديّ'**
  String get navClub;

  /// No description provided for @navTeam.
  ///
  /// In ar, this message translates to:
  /// **'الفريق'**
  String get navTeam;

  /// No description provided for @navMatches.
  ///
  /// In ar, this message translates to:
  /// **'المباريات'**
  String get navMatches;

  /// No description provided for @navMarket.
  ///
  /// In ar, this message translates to:
  /// **'السوق'**
  String get navMarket;

  /// No description provided for @navMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get navMore;

  /// No description provided for @secPlayers.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون'**
  String get secPlayers;

  /// No description provided for @secDevelop.
  ///
  /// In ar, this message translates to:
  /// **'التطوير'**
  String get secDevelop;

  /// No description provided for @secDeals.
  ///
  /// In ar, this message translates to:
  /// **'الصفقات'**
  String get secDeals;

  /// No description provided for @secMoney.
  ///
  /// In ar, this message translates to:
  /// **'المال والملعب'**
  String get secMoney;

  /// No description provided for @secCompete.
  ///
  /// In ar, this message translates to:
  /// **'المنافسة'**
  String get secCompete;

  /// No description provided for @secCommunity.
  ///
  /// In ar, this message translates to:
  /// **'المجتمع'**
  String get secCommunity;

  /// No description provided for @secLeague.
  ///
  /// In ar, this message translates to:
  /// **'الدوري'**
  String get secLeague;

  /// No description provided for @subSquad.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون ولياقتهم وبطاقاتهم'**
  String get subSquad;

  /// No description provided for @subLineup.
  ///
  /// In ar, this message translates to:
  /// **'الأحد عشر والدكة'**
  String get subLineup;

  /// No description provided for @subTactics.
  ///
  /// In ar, this message translates to:
  /// **'الخطة والضغط والأسلوب'**
  String get subTactics;

  /// No description provided for @subTraining.
  ///
  /// In ar, this message translates to:
  /// **'لاعب في كل خط'**
  String get subTraining;

  /// No description provided for @subSpecialists.
  ///
  /// In ar, this message translates to:
  /// **'أسرع تدريب لكل خط'**
  String get subSpecialists;

  /// No description provided for @subContracts.
  ///
  /// In ar, this message translates to:
  /// **'التجديد والفسخ'**
  String get subContracts;

  /// No description provided for @subMarket.
  ///
  /// In ar, this message translates to:
  /// **'شراء وبيع وعروض وأكاديمية'**
  String get subMarket;

  /// No description provided for @subScout.
  ///
  /// In ar, this message translates to:
  /// **'خمسة لاعبين بشروطك'**
  String get subScout;

  /// No description provided for @subFinance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد والرعاة والتذاكر'**
  String get subFinance;

  /// No description provided for @subStadium.
  ///
  /// In ar, this message translates to:
  /// **'المقاعد والأرضية والتدريب'**
  String get subStadium;

  /// No description provided for @subTickets.
  ///
  /// In ar, this message translates to:
  /// **'شجّع في مباريات الآخرين'**
  String get subTickets;

  /// No description provided for @subMatchday.
  ///
  /// In ar, this message translates to:
  /// **'النقل والمؤتمر والكواليس'**
  String get subMatchday;

  /// No description provided for @subFriendlies.
  ///
  /// In ar, this message translates to:
  /// **'ودية سريعة لأي نادٍ'**
  String get subFriendlies;

  /// No description provided for @subQuests.
  ///
  /// In ar, this message translates to:
  /// **'مكافآت الأسبوع'**
  String get subQuests;

  /// No description provided for @subSpy.
  ///
  /// In ar, this message translates to:
  /// **'اكشف خصمك القادم'**
  String get subSpy;

  /// No description provided for @subNewspaper.
  ///
  /// In ar, this message translates to:
  /// **'أخبار الجولة والمقالات'**
  String get subNewspaper;

  /// No description provided for @subPredictions.
  ///
  /// In ar, this message translates to:
  /// **'توقع النتائج واربح'**
  String get subPredictions;

  /// No description provided for @subStats.
  ///
  /// In ar, this message translates to:
  /// **'الهدافون وقيمة الفرق'**
  String get subStats;

  /// No description provided for @subGroups.
  ///
  /// In ar, this message translates to:
  /// **'دردشة المدربين'**
  String get subGroups;

  /// No description provided for @subHonours.
  ///
  /// In ar, this message translates to:
  /// **'أبطال كل موسم'**
  String get subHonours;

  /// No description provided for @subAlliance.
  ///
  /// In ar, this message translates to:
  /// **'تحالفان من مدربي الدوري'**
  String get subAlliance;

  /// No description provided for @subTournaments.
  ///
  /// In ar, this message translates to:
  /// **'بطولات بقرعة مباشرة'**
  String get subTournaments;

  /// No description provided for @countdownIn.
  ///
  /// In ar, this message translates to:
  /// **'بعد {time}'**
  String countdownIn(String time);

  /// No description provided for @liveBadge.
  ///
  /// In ar, this message translates to:
  /// **'مباشر الآن'**
  String get liveBadge;

  /// No description provided for @navOffice.
  ///
  /// In ar, this message translates to:
  /// **'المكتب'**
  String get navOffice;

  /// No description provided for @officeHello.
  ///
  /// In ar, this message translates to:
  /// **'مكتب المدرب'**
  String get officeHello;

  /// No description provided for @strengthCompare.
  ///
  /// In ar, this message translates to:
  /// **'قوة الفريقين'**
  String get strengthCompare;

  /// No description provided for @needsYou.
  ///
  /// In ar, this message translates to:
  /// **'ينتظرك الآن'**
  String get needsYou;

  /// No description provided for @allClear.
  ///
  /// In ar, this message translates to:
  /// **'كل شيء جاهز، استعد للمباراة'**
  String get allClear;

  /// No description provided for @needWindow.
  ///
  /// In ar, this message translates to:
  /// **'نافذة الأوامر مفتوحة في مباراتك'**
  String get needWindow;

  /// No description provided for @needLineup.
  ///
  /// In ar, this message translates to:
  /// **'لاعبون غائبون في تشكيلتك'**
  String get needLineup;

  /// No description provided for @needOffers.
  ///
  /// In ar, this message translates to:
  /// **'عروض بانتظار ردك'**
  String get needOffers;

  /// No description provided for @needRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات انضمام للدوري'**
  String get needRequests;

  /// No description provided for @needTrainingEmpty.
  ///
  /// In ar, this message translates to:
  /// **'خطوط بلا تدريب'**
  String get needTrainingEmpty;

  /// No description provided for @needTrainingDone.
  ///
  /// In ar, this message translates to:
  /// **'تدريب انتهى وينتظر لاعباً جديداً'**
  String get needTrainingDone;

  /// No description provided for @tileSquadSub.
  ///
  /// In ar, this message translates to:
  /// **'{n} لاعباً'**
  String tileSquadSub(int n);

  /// No description provided for @tileReady.
  ///
  /// In ar, this message translates to:
  /// **'جاهزة'**
  String get tileReady;

  /// No description provided for @tileAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائية'**
  String get tileAuto;

  /// No description provided for @tileFixtures.
  ///
  /// In ar, this message translates to:
  /// **'الجدول والنتائج'**
  String get tileFixtures;

  /// No description provided for @colPos.
  ///
  /// In ar, this message translates to:
  /// **'مركز'**
  String get colPos;

  /// No description provided for @colName.
  ///
  /// In ar, this message translates to:
  /// **'اللاعب'**
  String get colName;

  /// No description provided for @colAge.
  ///
  /// In ar, this message translates to:
  /// **'عمر'**
  String get colAge;

  /// No description provided for @colOvr.
  ///
  /// In ar, this message translates to:
  /// **'تقييم'**
  String get colOvr;

  /// No description provided for @colPot.
  ///
  /// In ar, this message translates to:
  /// **'إمكانية'**
  String get colPot;

  /// No description provided for @colFit.
  ///
  /// In ar, this message translates to:
  /// **'لياقة'**
  String get colFit;

  /// No description provided for @colValue.
  ///
  /// In ar, this message translates to:
  /// **'القيمة'**
  String get colValue;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @dragHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لاعباً إلى مكانه، أو المس لاعبَين للتبديل'**
  String get dragHint;

  /// No description provided for @leagueTable.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get leagueTable;
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
