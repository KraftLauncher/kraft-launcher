// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settings => 'الإعدادات';

  @override
  String get home => 'الرئيسية';

  @override
  String get profiles => 'الملفات الشخصية';

  @override
  String get accounts => 'الحسابات';

  @override
  String get about => 'حول';

  @override
  String get switchAccount => 'تبديل الحساب';

  @override
  String get play => 'تشغيل';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get microsoft => 'مايكروسوفت';

  @override
  String get offline => 'بدون اتصال';

  @override
  String get signInWithMicrosoft => 'تسجيل الدخول باستخدام مايكروسوفت';

  @override
  String get addMicrosoftAccount => 'إضافة حساب مايكروسوفت';

  @override
  String get useDeviceCodeMethod => 'بدلاً من ذلك، استخدم طريقة رمز الجهاز';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get deviceCodeStepVisit => '1. قم بزيارة';

  @override
  String get deviceCodeStepEnter => '2. أدخل الرمز أدناه:';

  @override
  String get deviceCodeQrInstruction =>
      'امسح لفتح الرابط على جهاز آخر.\nستحتاج إلى إدخال الرمز أعلاه أيضاً.';

  @override
  String get loggingInWithMicrosoftAccount =>
      'جاري تسجيل الدخول بحساب مايكروسوفت';

  @override
  String get authProgressWaitingForUserLogin => 'بانتظار مصادقة المستخدم...';

  @override
  String get authProgressExchangingAuthCode => 'جارٍ استبدال رمز التفويض...';

  @override
  String get authProgressRequestingXboxLiveToken =>
      'طلب الوصول إلى Xbox Live...';

  @override
  String get authProgressRequestingXstsToken => 'تفويض جلسة Xbox Live...';

  @override
  String get authProgressLoggingIntoMinecraft =>
      'تسجيل الدخول إلى خدمات Minecraft...';

  @override
  String get authProgressFetchingMinecraftProfile =>
      'جلب ملف Minecraft الشخصي...';

  @override
  String loginSuccessAccountAddedMessage(String username) {
    return 'مرحباً، $username! لقد سجلت الدخول إلى Minecraft بنجاح.';
  }

  @override
  String loginSuccessAccountUpdatedMessage(String username) {
    return 'مرحباً مجدداً، $username! تم تحديث تفاصيل حسابك.';
  }

  @override
  String get username => 'اسم المستخدم';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get removeAccount => 'إزالة الحساب';

  @override
  String unexpectedError(String message) {
    return 'خطأ غير متوقع: $message.';
  }

  @override
  String get missingAuthCodeError =>
      'لم يتم توفير رمز التفويض. يجب إعادة بدء تسجيل الدخول.';

  @override
  String get expiredAuthCodeError =>
      'انتهت صلاحية رمز التفويض. يرجى إعادة بدء عملية تسجيل الدخول.';

  @override
  String get expiredMicrosoftAccessTokenError =>
      'انتهت صلاحية رمز وصول OAuth لمايكروسوفت. يجب تسجيل الدخول من جديد.';

  @override
  String get unauthorizedMinecraftAccessError =>
      'وصول غير مصرح به إلى Minecraft. انتهت صلاحية التفويض أو أنه غير صالح.';

  @override
  String get createOfflineAccount => 'إنشاء حساب بدون اتصال';

  @override
  String get updateOfflineAccount => 'تحديث حساب بدون اتصال';

  @override
  String get offlineMinecraftAccountCreationNotice =>
      'أدخل اسم مستخدم Minecraft الذي ترغب به. يتم تخزين الحسابات غير المتصلة محليًا ولا يمكنها الوصول إلى الخوادم أو العوالم عبر الإنترنت.';

  @override
  String get create => 'إنشاء';

  @override
  String get minecraftUsernameHint => 'مثال: Steve';

  @override
  String get usernameEmptyError => 'لا يمكن أن يكون اسم المستخدم فارغًا';

  @override
  String get usernameTooShortError =>
      'يجب أن يحتوي اسم المستخدم على 3 أحرف على الأقل';

  @override
  String get usernameTooLongError => 'يجب ألا يتجاوز اسم المستخدم 16 حرفًا';

  @override
  String get usernameInvalidCharactersError =>
      'يمكن أن يحتوي اسم المستخدم على أحرف وأرقام وعلامات underscore (_) فقط.';

  @override
  String get usernameContainsWhitespacesError =>
      'لا يمكن أن يحتوي اسم المستخدم على مسافات.';

  @override
  String get update => 'تحديث';

  @override
  String get minecraftId => 'معرّف Minecraft';

  @override
  String get removeAccountConfirmation => 'هل تريد إزالة الحساب؟';

  @override
  String get removeAccountConfirmationNotice =>
      'سيتم إزالة هذا الحساب من المشغل.\nستحتاج إلى إضافته مرة أخرى لاستخدامه في اللعب.';

  @override
  String get remove => 'إزالة';

  @override
  String get chooseYourPreferredLanguage => 'اختر لغتك المفضلة';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get system => 'النظام';

  @override
  String get themeMode => 'وضع المظهر';

  @override
  String get selectDarkLightOrSystemTheme =>
      'اختر بين الوضع الداكن أو الفاتح أو نظام الجهاز';

  @override
  String get classicMaterialDesign => 'تصميم Material الكلاسيكي';

  @override
  String get useClassicMaterialDesignTheme => 'استخدم تصميم Material الكلاسيكي';

  @override
  String get dynamicColor => 'ألوان ديناميكية';

  @override
  String get automaticallyAdaptToSystemColors =>
      'التكيّف التلقائي مع ألوان النظام';

  @override
  String get general => 'عام';

  @override
  String get java => 'جافا';

  @override
  String get launcher => 'المشغل';

  @override
  String get advanced => 'متقدم';

  @override
  String get appearance => 'المظهر';

  @override
  String get dark => 'داكن';

  @override
  String get light => 'فاتح';

  @override
  String get customAccentColor => 'لون التمييز المخصص';

  @override
  String get customizeAccentColor => 'قم بتخصيص لون التمييز لمظهر التطبيق.';

  @override
  String get pickAColor => 'اختر لونًا';

  @override
  String get close => 'إغلاق';

  @override
  String get authProgressExchangingDeviceCode => 'جاري تبادل رمز الجهاز...';

  @override
  String get authProgressRequestingDeviceCode => 'جاري طلب رمز الجهاز...';

  @override
  String get or => 'أو';

  @override
  String get loginCodeExpired => 'انتهت صلاحية رمز الدخول';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get uiPreferences => 'تفضيلات الواجهة';

  @override
  String get defaultTab => 'علامة التبويب الافتراضية';

  @override
  String get initialTabSelectionDescription =>
      'اختر علامة التبويب التي تظهر أولاً عند فتح التطبيق';

  @override
  String get search => 'بحث';

  @override
  String get refreshAccount => 'تحديث الحساب';

  @override
  String get sessionExpiredOrAccessRevoked =>
      'انتهت جلسة الحساب أو تم إلغاء الوصول. يرجى تسجيل الدخول مرة أخرى للاستمرار.';

  @override
  String accountRefreshedMessage(String username) {
    return 'تم تحديث الحساب لـ $username بنجاح.';
  }

  @override
  String get revokeAccess => 'إلغاء الوصول';

  @override
  String get microsoftRequestLimitError =>
      'تم الوصول إلى حد الطلبات أثناء الاتصال بخوادم مصادقة Microsoft. يرجى المحاولة مرة أخرى بعد قليل.';

  @override
  String get authProgressRefreshingMicrosoftTokens =>
      'جارٍ تحديث رموز Microsoft...';

  @override
  String get authProgressCheckingMinecraftJavaOwnership =>
      'جارٍ التحقق من ملكية Minecraft Java...';

  @override
  String get waitForOngoingTask => 'يرجى الانتظار حتى ينتهي المهمة الحالية.';

  @override
  String get accountsEmptyTitle => 'إدارة حسابات Minecraft';

  @override
  String get accountsEmptySubtitle =>
      'أضف حسابات Minecraft للتبديل السلس. يتم تخزين الحسابات بأمان على هذا الجهاز.';

  @override
  String get authCodeRedirectPageLoginSuccessTitle => 'تم تسجيل الدخول';

  @override
  String authCodeRedirectPageLoginSuccessMessage(String launcherName) {
    return 'لقد قمت بتسجيل الدخول بنجاح إلى $launcherName باستخدام حساب Microsoft الخاص بك. يمكنك الآن إغلاق هذه النافذة.';
  }

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get reportBug => 'الإبلاغ عن خطأ';

  @override
  String get unknownErrorWhileLoadingAccounts =>
      'حدث خطأ غير معروف أثناء تحميل الحسابات. يرجى المحاولة لاحقًا.';

  @override
  String get minecraftRequestLimitError =>
      'Request limit reached while communicating with Minecraft servers. Please try again shortly.';

  @override
  String unexpectedMinecraftApiError(Object message) {
    return 'Unexpected error while communicating with Minecraft servers: $message. Please try again later.';
  }

  @override
  String unexpectedMicrosoftApiError(Object message) {
    return 'Unexpected error while communicating with Microsoft servers: $message. Please try again later.';
  }

  @override
  String errorLoadingNetworkImage(Object message) {
    return 'An error occurred while loading the image: $message';
  }

  @override
  String get skinModelClassic => 'Classic';

  @override
  String get skinModelSlim => 'Slim';

  @override
  String get skinModel => 'Skin Model';

  @override
  String get updateSkin => 'Update Skin';

  @override
  String get featureUnsupportedYet =>
      'This feature is not supported yet. Stay tuned for future updates!';

  @override
  String get news => 'News';
}
