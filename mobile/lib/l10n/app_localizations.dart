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
