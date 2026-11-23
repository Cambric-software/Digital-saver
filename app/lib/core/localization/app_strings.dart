import 'package:flutter/material.dart';

/// The words shown by the app, in the languages the app actually speaks.
///
/// Two languages are shipped: English and Arabic. The Arabic here covers the
/// navigation and the appearance controls in Settings. It does **not** cover
/// the rest of Settings or the long-form content on the app's screens, which is
/// still English in this release. The appearance section says so rather than
/// letting a person discover it halfway through a task.
///
/// Keys are grouped by screen so a missing key is obvious. [text] falls back to
/// English and then to the key itself, which makes a gap visible instead of
/// blank.
class AppStrings {
  const AppStrings._(this.languageCode, this._values);

  /// `en` or `ar`.
  final String languageCode;

  final Map<String, String> _values;

  /// English strings.
  static const AppStrings english = AppStrings._('en', _en);

  /// Arabic strings.
  static const AppStrings arabic = AppStrings._('ar', _ar);

  /// The strings for a language code, falling back to English.
  static AppStrings forLanguage(String? code) =>
      code == 'ar' ? arabic : english;

  /// The strings for the language the app is currently rendered in.
  static AppStrings of(BuildContext context) =>
      forLanguage(Localizations.localeOf(context).languageCode);

  /// Whether these strings are Arabic.
  bool get isArabic => languageCode == 'ar';

  /// Look up one key.
  String text(String key) => _values[key] ?? _en[key] ?? key;

  /// Look up one key and fill `{name}` placeholders.
  String withValues(String key, Map<String, String> values) {
    String result = text(key);
    values.forEach((String name, String value) {
      result = result.replaceAll('{$name}', value);
    });
    return result;
  }

  static const Map<String, String> _en = <String, String>{
    // Navigation.
    'nav.today': 'Today',
    'nav.vitals': 'Vitals',
    'nav.insights': 'Insights',
    'nav.coach': 'Coach',
    'nav.hub': 'Health hub',
    'nav.watch': 'Watch',
    'nav.settings': 'Settings',
    'nav.more': 'More',
    'nav.watch_connected': 'Watch connected',
    'nav.no_watch': 'No watch connected',
    'nav.searching': 'Searching for a watch...',
    'nav.readings_unavailable':
        'Readings are unavailable until a watch connects.',
    'nav.battery': '{percent}% battery',
    'nav.tagline': 'Health companion',

    // Settings.
    'settings.title': 'Settings',
    'settings.people_title': 'People',
    'settings.people_body':
        'Each person keeps their own theme, accent, text size, contrast and '
            'language. A new person starts from the defaults, not from the '
            'settings of whoever is using the app now.',
    'settings.active': 'Active',
    'settings.add_person': 'Add person',
    'settings.add_person_title': 'Add a person',
    'settings.rename_person_title': 'Rename this person',
    'settings.person_name_label': 'Name',
    'settings.person_hint': 'Their name',
    'settings.delete_person_title': 'Delete this person?',
    'settings.delete_person_body':
        'Their appearance and language settings are removed. Health records, '
            'the watch and your history are not deleted.',
    'settings.keep_one_person': 'At least one person must remain.',
    'settings.appearance_title': 'Appearance & language',
    'settings.appearance_body':
        'How the app looks and which language it asks for',
    'settings.dark_theme_title': 'Dark theme',
    'settings.dark_theme_on': 'Dark surfaces and lifted text colours.',
    'settings.dark_theme_off': 'Light surfaces for daytime use.',
    'settings.dim_after_dark_title': 'Dim after dark',
    'settings.dim_on':
        'On. The dark theme is used from {start} to {end}. {state}',
    'settings.dim_state_now':
        'It is after dark now, so the dark theme is active.',
    'settings.dim_state_day':
        'It is daytime now, so the theme you picked is used.',
    'settings.dim_off':
        'Off. The theme you picked is used all day. When on, the dark theme is '
            'used from {start} to {end}.',
    'settings.language_title': 'App language',
    'settings.language_english': 'English (US / UK)',
    'settings.language_arabic': 'العربية (مصر / الفصحى)',
    'settings.language_note':
        'Arabic covers the navigation and these appearance controls. The rest '
            'of Settings and the app’s screen content are still English in '
            'this release.',
    'settings.accent_title': 'Accent colour',
    'settings.accent_help':
        'Used for buttons, links and highlights. Surfaces and warning colours '
            'stay the same.',
    'settings.text_size_title': 'Text size',
    'settings.text_size_help':
        'Scales text on top of your system setting. The app can be set between '
            '90% and 160%.',
    'settings.text_size_value': '{percent}%',
    'settings.text_size_preview': 'This is how body text looks.',
    'settings.high_contrast_title': 'High contrast',
    'settings.high_contrast_subtitle': 'Stronger borders and contrast.',
    'settings.restore_title': 'Restore default settings',
    'settings.restore_subtitle':
        'Returns this person’s appearance to the defaults. Health records, the '
            'watch and your history are untouched.',
    'settings.restore_dialog_title': 'Restore default settings?',
    'settings.restore_dialog_body':
        'This person’s appearance goes back to the light theme, blue accent, '
            '100% text and English. Health records, the watch and your history '
            'are untouched.',
    'settings.restore_done': 'Default settings restored.',

    // Accents.
    'accent_blue': 'Blue',
    'accent_teal': 'Teal',
    'accent_purple': 'Purple',
    'accent_green': 'Green',
    'accent_amber': 'Amber',

    // Shared actions.
    'common.cancel': 'Cancel',
    'common.save': 'Save',
    'common.add': 'Add',
    'common.delete': 'Delete',
    'common.rename': 'Rename',
    'common.restore': 'Restore',
  };

  static const Map<String, String> _ar = <String, String>{
    // Navigation.
    'nav.today': 'اليوم',
    'nav.vitals': 'المؤشرات',
    'nav.insights': 'الرؤى',
    'nav.coach': 'المدرّب',
    'nav.hub': 'مركز الصحة',
    'nav.watch': 'الساعة',
    'nav.settings': 'الإعدادات',
    'nav.more': 'المزيد',
    'nav.watch_connected': 'الساعة متصلة',
    'nav.no_watch': 'لا توجد ساعة متصلة',
    'nav.searching': 'جاري البحث عن ساعة...',
    'nav.readings_unavailable': 'القراءات غير متاحة حتى تتصل الساعة.',
    'nav.battery': 'البطارية {percent}٪',
    'nav.tagline': 'رفيق الصحة',

    // Settings.
    'settings.title': 'الإعدادات',
    'settings.people_title': 'الأشخاص',
    'settings.people_body':
        'يحتفظ كل شخص بمظهره ولون تمييزه وحجم نصه وتباينه ولغته. يبدأ الشخص '
            'الجديد من الإعدادات الافتراضية، لا من إعدادات من يستخدم التطبيق الآن.',
    'settings.active': 'نشط',
    'settings.add_person': 'إضافة شخص',
    'settings.add_person_title': 'إضافة شخص',
    'settings.rename_person_title': 'إعادة تسمية هذا الشخص',
    'settings.person_name_label': 'الاسم',
    'settings.person_hint': 'اسم الشخص',
    'settings.delete_person_title': 'حذف هذا الشخص؟',
    'settings.delete_person_body':
        'تُحذف إعدادات مظهره ولغته. لا تُحذف السجلات الصحية ولا الساعة ولا سجلك.',
    'settings.keep_one_person': 'يجب أن يبقى شخص واحد على الأقل.',
    'settings.appearance_title': 'المظهر واللغة',
    'settings.appearance_body': 'شكل التطبيق واللغة التي يطلبها',
    'settings.dark_theme_title': 'السمة الداكنة',
    'settings.dark_theme_on': 'أسطح داكنة وألوان نص مرفوعة.',
    'settings.dark_theme_off': 'أسطح فاتحة للاستخدام نهارًا.',
    'settings.dim_after_dark_title': 'التعتيم بعد حلول الظلام',
    'settings.dim_on':
        'مفعّل. تُستخدم السمة الداكنة من {start} إلى {end}. {state}',
    'settings.dim_state_now': 'حان وقت الظلام الآن، لذا السمة الداكنة نشطة.',
    'settings.dim_state_day': 'الوقت نهار الآن، لذا تُستخدم السمة التي اخترتها.',
    'settings.dim_off':
        'معطّل. تُستخدم السمة التي اخترتها طوال اليوم. عند التفعيل، تُستخدم '
            'السمة الداكنة من {start} إلى {end}.',
    'settings.language_title': 'لغة التطبيق',
    'settings.language_english': 'English (US / UK)',
    'settings.language_arabic': 'العربية (مصر / الفصحى)',
    'settings.language_note':
        'تغطي العربية التنقل وأدوات المظهر هذه. بقية الإعدادات ومحتوى شاشات '
            'التطبيق ما زالت بالإنجليزية في هذا الإصدار.',
    'settings.accent_title': 'لون التمييز',
    'settings.accent_help':
        'يُستخدم للأزرار والروابط والإبرازات. تبقى الأسطح وألوان التحذير كما هي.',
    'settings.text_size_title': 'حجم النص',
    'settings.text_size_help':
        'يكبّر النص فوق إعداد نظامك. يمكن ضبط التطبيق بين ٩٠٪ و١٦٠٪.',
    'settings.text_size_value': '{percent}٪',
    'settings.text_size_preview': 'هكذا يبدو نص المتن.',
    'settings.high_contrast_title': 'تباين عالٍ',
    'settings.high_contrast_subtitle': 'حدود وتباين أقوى.',
    'settings.restore_title': 'استعادة الإعدادات الافتراضية',
    'settings.restore_subtitle':
        'يعيد مظهر هذا الشخص إلى الإعدادات الافتراضية. السجلات الصحية والساعة '
            'وسجلك لا تتأثر.',
    'settings.restore_dialog_title': 'استعادة الإعدادات الافتراضية؟',
    'settings.restore_dialog_body':
        'يعود مظهر هذا الشخص إلى السمة الفاتحة ولون التمييز الأزرق ونص ١٠٠٪ '
            'واللغة الإنجليزية. السجلات الصحية والساعة وسجلك لا تتأثر.',
    'settings.restore_done': 'تمت استعادة الإعدادات الافتراضية.',

    // Accents.
    'accent_blue': 'أزرق',
    'accent_teal': 'أخضر مزرق',
    'accent_purple': 'بنفسجي',
    'accent_green': 'أخضر',
    'accent_amber': 'كهرماني',

    // Shared actions.
    'common.cancel': 'إلغاء',
    'common.save': 'حفظ',
    'common.add': 'إضافة',
    'common.delete': 'حذف',
    'common.rename': 'إعادة تسمية',
    'common.restore': 'استعادة',
  };
}
