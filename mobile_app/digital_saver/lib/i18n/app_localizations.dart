import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('zh'),
    Locale('ja'),
    Locale('ru'),
    Locale('pt'),
    Locale('hi'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'app_name': 'Digital Saver',
      'tagline': 'Your Personal Health Guardian',
      
      // Navigation
      'nav_dashboard': 'Dashboard',
      'nav_heart': 'Heart',
      'nav_bp': 'Blood Pressure',
      'nav_activity': 'Activity',
      'nav_sleep': 'Sleep',
      'nav_settings': 'Settings',
      
      // Health Metrics
      'heart_rate': 'Heart Rate',
      'blood_pressure': 'Blood Pressure',
      'oxygen': 'Oxygen (SpO2)',
      'hrv': 'Heart Rate Variability',
      'afib': 'AFib Detection',
      'arrhythmia': 'Arrhythmia',
      'stress': 'Stress Level',
      'sleep': 'Sleep',
      'activity': 'Activity',
      'steps': 'Steps',
      'calories': 'Calories',
      'distance': 'Distance',
      'resting_hr': 'Resting HR',
      'active_minutes': 'Active Minutes',
      'sleep_score': 'Sleep Score',
      'deep_sleep': 'Deep Sleep',
      'light_sleep': 'Light Sleep',
      'rem_sleep': 'REM Sleep',
      'awake': 'Awake',
      'total_sleep': 'Total Sleep',
      
      // Units
      'bpm': 'BPM',
      'mmhg': 'mmHg',
      'percent': '%',
      'ms': 'ms',
      'steps_unit': 'steps',
      'km': 'km',
      'kcal': 'kcal',
      'minutes': 'min',
      'hours': 'h',
      
      // Status
      'status_normal': 'Normal',
      'status_warning': 'Warning',
      'status_critical': 'Critical',
      'status_excellent': 'Excellent',
      'status_good': 'Good',
      'status_fair': 'Fair',
      'status_poor': 'Poor',
      
      // Connection
      'watch_connected': 'Watch Connected',
      'watch_disconnected': 'Watch Disconnected',
      'scanning': 'Scanning...',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'last_sync': 'Last sync',
      'battery': 'Battery',
      'signal': 'Signal',
      
      // Emergency
      'emergency': 'Emergency',
      'emergency_alert': 'Emergency Alert!',
      'fall_detected': 'Fall Detected',
      'irregular_heartbeat': 'Irregular Heartbeat',
      'high_blood_pressure': 'High Blood Pressure',
      'low_oxygen': 'Low Oxygen',
      'are_you_okay': 'Are you okay?',
      'call_emergency': 'Call Emergency',
      'send_alert': 'Send Alert',
      'cancel_alert': "I'm Okay",
      'emergency_contacts': 'Emergency Contacts',
      
      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'thresholds': 'Alert Thresholds',
      'heart_rate_threshold': 'Heart Rate Alert',
      'bp_threshold': 'BP Alert',
      'about': 'About',
      'version': 'Version',
      
      // Actions
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'done': 'Done',
      'confirm': 'Confirm',
      'retry': 'Retry',
      
      // Health Details
      'health_score': 'Health Score',
      'vascular_age': 'Vascular Age',
      'arterial_stiffness': 'Arterial Stiffness',
      'pulse_pressure': 'Pulse Pressure',
      'augmentation_index': 'Augmentation Index',
      'perfusion_index': 'Perfusion Index',
      'respiration_rate': 'Respiration Rate',
      'confidence': 'Confidence',
      'trend': 'Trend',
      'trend_up': 'Trending Up',
      'trend_down': 'Trending Down',
      'trend_stable': 'Stable',
      
      // HRV Details
      'rmssd': 'RMSSD',
      'sdnn': 'SDNN',
      'pnn50': 'pNN50',
      'rr_intervals': 'RR Intervals',
      'afib_probability': 'AFib Probability',
      
      // Analysis
      'analysis': 'Analysis',
      'recommendations': 'Recommendations',
      'details': 'Details',
      'history': 'History',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'avg': 'Average',
      'min': 'Min',
      'max': 'Max',
      
      // Contact
      'name': 'Name',
      'phone': 'Phone',
      'email': 'Email',
      'relationship': 'Relationship',
      'primary_contact': 'Primary Contact',
      'address': 'Address',
      
      // Misc
      'loading': 'Loading...',
      'no_data': 'No Data',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',
      'medical_disclaimer': 'This app provides wellness estimates and is not a medical device. Always consult healthcare professionals.',
      'select_language': 'Select Language',
      'pm': 'PM',
      'am': 'AM',
    },
    'ar': {
      'app_name': 'الحارس الصحي',
      'tagline': 'حارسك الصحي الشخصي',
      'nav_dashboard': 'لوحة التحكم',
      'nav_heart': 'القلب',
      'nav_bp': 'ضغط الدم',
      'nav_activity': 'النشاط',
      'nav_sleep': 'النوم',
      'nav_settings': 'الإعدادات',
      'heart_rate': 'معدل ضربات القلب',
      'blood_pressure': 'ضغط الدم',
      'oxygen': 'الأكسجين',
      'hrv': 'تغير معدل ضربات',
      'afib': 'كشف الرجفان',
      'arrhythmia': 'عدم انتظام ضربات',
      'stress': 'مستوى التوتر',
      'sleep': 'النوم',
      'activity': 'النشاط',
      'steps': 'الخطوات',
      'calories': 'السعرات',
      'distance': 'المسافة',
      'resting_hr': 'معدل الراحة',
      'active_minutes': 'دقائق النشاط',
      'sleep_score': 'نقاط النوم',
      'deep_sleep': 'نوم عميق',
      'light_sleep': 'نوم خفيف',
      'rem_sleep': 'نوم REM',
      'awake': 'استيقاظ',
      'total_sleep': 'إجمالي النوم',
      'bpm': 'نبضة/د',
      'mmhg': 'مم زئبق',
      'percent': '%',
      'ms': 'مللي ث',
      'steps_unit': 'خطوة',
      'km': 'كم',
      'kcal': 'سعرة',
      'minutes': 'دقيقة',
      'hours': 'ساعة',
      'status_normal': 'طبيعي',
      'status_warning': 'تحذير',
      'status_critical': 'حرج',
      'status_excellent': 'ممتاز',
      'status_good': 'جيد',
      'status_fair': 'مقبول',
      'status_poor': 'ضعيف',
      'watch_connected': 'الساعة متصلة',
      'watch_disconnected': 'الساعة غير متصلة',
      'scanning': 'جاري البحث...',
      'connect': 'اتصال',
      'disconnect': 'قطع الاتصال',
      'last_sync': 'آخر مزامنة',
      'battery': 'البطارية',
      'signal': 'الإشارة',
      'emergency': 'الطوارئ',
      'emergency_alert': 'تنبيه طوارئ!',
      'fall_detected': 'تم اكتشاف سقوط',
      'irregular_heartbeat': 'عدم انتظام ضربات القلب',
      'high_blood_pressure': 'ارتفاع ضغط الدم',
      'low_oxygen': 'انخفاض الأكسجين',
      'are_you_okay': 'هل أنت بخير؟',
      'call_emergency': 'اتصال بالطوارئ',
      'send_alert': 'إرسال تنبيه',
      'cancel_alert': 'أنا بخير',
      'emergency_contacts': 'جهات الاتصال الطارئة',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'dark_mode': 'الوضع الداكن',
      'notifications': 'الإشعارات',
      'thresholds': 'عتبة التنبيهات',
      'heart_rate_threshold': 'تنبيه معدل القلب',
      'bp_threshold': 'تنبيه الضغط',
      'about': 'حول',
      'version': 'الإصدار',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'done': 'تم',
      'confirm': 'تأكيد',
      'retry': 'إعادة المحاولة',
      'health_score': 'النتيجة الصحية',
      'vascular_age': 'العمر الوعائي',
      'arterial_stiffness': 'تصلب الشرايين',
      'pulse_pressure': 'ضغط النبض',
      'augmentation_index': 'مؤشر التضخم',
      'perfusion_index': 'مؤشر التروية',
      'respiration_rate': 'معدل التنفس',
      'confidence': 'الثقة',
      'trend': 'الاتجاه',
      'trend_up': 'يتجه للأعلى',
      'trend_down': 'يتجه للأسفل',
      'trend_stable': 'مستقر',
      'rmssd': 'RMSSD',
      'sdnn': 'SDNN',
      'pnn50': 'pNN50',
      'rr_intervals': 'فترات RR',
      'afib_probability': 'احتمال AFib',
      'analysis': 'التحليل',
      'recommendations': 'التوصيات',
      'details': 'التفاصيل',
      'history': 'السجل',
      'today': 'اليوم',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'avg': 'المتوسط',
      'min': 'الأدنى',
      'max': 'الأقصى',
      'name': 'الاسم',
      'phone': 'الهاتف',
      'email': 'البريد',
      'relationship': 'العلاقة',
      'primary_contact': 'جهة الاتصال الرئيسية',
      'address': 'العنوان',
      'loading': 'جاري التحميل...',
      'no_data': 'لا توجد بيانات',
      'error': 'خطأ',
      'success': 'نجاح',
      'warning': 'تحذير',
      'info': 'معلومات',
      'medical_disclaimer': 'هذا التطبيق يوفر تقديرات صحية وليس جهازًا طبيًا. استشر دائمًا المتخصصين.',
      'select_language': 'اختر اللغة',
      'pm': 'م',
      'am': 'ص',
    },
    'es': {
      'app_name': 'Salvador Digital',
      'tagline': 'Tu Guardián de Salud Personal',
      'nav_dashboard': 'Panel',
      'nav_heart': 'Corazón',
      'nav_bp': 'Presión',
      'nav_activity': 'Actividad',
      'nav_sleep': 'Sueño',
      'nav_settings': 'Ajustes',
      'heart_rate': 'Frecuencia Cardíaca',
      'blood_pressure': 'Presión Arterial',
      'oxygen': 'Oxígeno (SpO2)',
      'hrv': 'Variabilidad HR',
      'afib': 'Detección AFib',
      'arrhythmia': 'Arritmia',
      'stress': 'Nivel de Estrés',
      'sleep': 'Sueño',
      'activity': 'Actividad',
      'steps': 'Pasos',
      'calories': 'Calorías',
      'distance': 'Distancia',
      'resting_hr': 'HR en Reposo',
      'active_minutes': 'Minutos Activos',
      'sleep_score': 'Puntuación Sueño',
      'deep_sleep': 'Sueño Profundo',
      'light_sleep': 'Sueño Ligero',
      'rem_sleep': 'Sueño REM',
      'awake': 'Despierto',
      'total_sleep': 'Sueño Total',
      'bpm': 'LPM',
      'mmhg': 'mmHg',
      'percent': '%',
      'ms': 'ms',
      'steps_unit': 'pasos',
      'km': 'km',
      'kcal': 'kcal',
      'minutes': 'min',
      'hours': 'h',
      'status_normal': 'Normal',
      'status_warning': 'Advertencia',
      'status_critical': 'Crítico',
      'status_excellent': 'Excelente',
      'status_good': 'Bueno',
      'status_fair': 'Regular',
      'status_poor': 'Malo',
      'watch_connected': 'Reloj Conectado',
      'watch_disconnected': 'Reloj Desconectado',
      'scanning': 'Buscando...',
      'connect': 'Conectar',
      'disconnect': 'Desconectar',
      'last_sync': 'Última sincronización',
      'battery': 'Batería',
      'signal': 'Señal',
      'emergency': 'Emergencia',
      'emergency_alert': '¡Alerta de Emergencia!',
      'fall_detected': 'Caída Detectada',
      'irregular_heartbeat': 'Latido Irregular',
      'high_blood_pressure': 'Presión Alta',
      'low_oxygen': 'Oxígeno Bajo',
      'are_you_okay': '¿Estás bien?',
      'call_emergency': 'Llamar a Emergencias',
      'send_alert': 'Enviar Alerta',
      'cancel_alert': 'Estoy Bien',
      'emergency_contacts': 'Contactos de Emergencia',
      'settings': 'Ajustes',
      'language': 'Idioma',
      'dark_mode': 'Modo Oscuro',
      'notifications': 'Notificaciones',
      'thresholds': 'Umbrales de Alerta',
      'heart_rate_threshold': 'Alerta de FC',
      'bp_threshold': 'Alerta de PA',
      'about': 'Acerca de',
      'version': 'Versión',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Añadir',
      'done': 'Hecho',
      'confirm': 'Confirmar',
      'retry': 'Reintentar',
      'health_score': 'Puntuación de Salud',
      'vascular_age': 'Edad Vascular',
      'arterial_stiffness': 'Rigidez Arterial',
      'pulse_pressure': 'Presión de Pulso',
      'augmentation_index': 'Índice de Augmentación',
      'perfusion_index': 'Índice de Perfusión',
      'respiration_rate': 'Frecuencia Respiratoria',
      'confidence': 'Confianza',
      'trend': 'Tendencia',
      'trend_up': 'Subiendo',
      'trend_down': 'Bajando',
      'trend_stable': 'Estable',
      'rmssd': 'RMSSD',
      'sdnn': 'SDNN',
      'pnn50': 'pNN50',
      'rr_intervals': 'Intervalos RR',
      'afib_probability': 'Probabilidad AFib',
      'analysis': 'Análisis',
      'recommendations': 'Recomendaciones',
      'details': 'Detalles',
      'history': 'Historial',
      'today': 'Hoy',
      'this_week': 'Esta Semana',
      'this_month': 'Este Mes',
      'avg': 'Promedio',
      'min': 'Mín',
      'max': 'Máx',
      'name': 'Nombre',
      'phone': 'Teléfono',
      'email': 'Correo',
      'relationship': 'Relación',
      'primary_contact': 'Contacto Principal',
      'address': 'Dirección',
      'loading': 'Cargando...',
      'no_data': 'Sin Datos',
      'error': 'Error',
      'success': 'Éxito',
      'warning': 'Advertencia',
      'info': 'Info',
      'medical_disclaimer': 'Esta app proporciona estimaciones de bienestar y no es un dispositivo médico.',
      'select_language': 'Seleccionar Idioma',
      'pm': 'PM',
      'am': 'AM',
    },
    'fr': {
      'app_name': 'Sauvegarde Numérique',
      'tagline': 'Votre Gardien de Santé Personnel',
      'nav_dashboard': 'Tableau de Bord',
      'nav_heart': 'Cœur',
      'nav_bp': 'Tension',
      'nav_activity': 'Activité',
      'nav_sleep': 'Sommeil',
      'nav_settings': 'Paramètres',
      'heart_rate': 'Fréquence Cardiaque',
      'blood_pressure': 'Tension Artérielle',
      'oxygen': 'Oxygène (SpO2)',
      'hrv': 'Variabilité HR',
      'afib': 'Détection FA',
      'arrhythmia': 'Arythmie',
      'stress': 'Niveau de Stress',
      'sleep': 'Sommeil',
      'activity': 'Activité',
      'steps': 'Pas',
      'calories': 'Calories',
      'distance': 'Distance',
      'resting_hr': 'FC au Repos',
      'active_minutes': 'Minutes Actives',
      'sleep_score': 'Score Sommeil',
      'deep_sleep': 'Sommeil Profond',
      'light_sleep': 'Sommeil Léger',
      'rem_sleep': 'Sommeil REM',
      'awake': 'Éveillé',
      'total_sleep': 'Sommeil Total',
      'bpm': 'BPM',
      'mmhg': 'mmHg',
      'percent': '%',
      'ms': 'ms',
      'steps_unit': 'pas',
      'km': 'km',
      'kcal': 'kcal',
      'minutes': 'min',
      'hours': 'h',
      'status_normal': 'Normal',
      'status_warning': 'Attention',
      'status_critical': 'Critique',
      'status_excellent': 'Excellent',
      'status_good': 'Bon',
      'status_fair': 'Correct',
      'status_poor': 'Mauvais',
      'watch_connected': 'Montre Connectée',
      'watch_disconnected': 'Montre Déconnectée',
      'scanning': 'Recherche...',
      'connect': 'Connecter',
      'disconnect': 'Déconnecter',
      'last_sync': 'Dernière synchro',
      'battery': 'Batterie',
      'signal': 'Signal',
      'emergency': 'Urgence',
      'emergency_alert': 'Alerte d\'Urgence!',
      'fall_detected': 'Chute Détectée',
      'irregular_heartbeat': 'Rythme Irrégulier',
      'high_blood_pressure': 'Hypertension',
      'low_oxygen': 'Oxygène Bas',
      'are_you_okay': 'Ça va?',
      'call_emergency': 'Appeler Urgences',
      'send_alert': 'Envoyer Alerte',
      'cancel_alert': 'Je vais bien',
      'emergency_contacts': 'Contacts d\'Urgence',
      'settings': 'Paramètres',
      'language': 'Langue',
      'dark_mode': 'Mode Sombre',
      'notifications': 'Notifications',
      'thresholds': 'Seuils d\'Alerte',
      'heart_rate_threshold': 'Alerte FC',
      'bp_threshold': 'Alerte TA',
      'about': 'À propos',
      'version': 'Version',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'done': 'Terminé',
      'confirm': 'Confirmer',
      'retry': 'Réessayer',
      'health_score': 'Score de Santé',
      'vascular_age': 'Âge Vasculaire',
      'arterial_stiffness': 'Rigidité Artérielle',
      'pulse_pressure': 'Pression de Pouls',
      'augmentation_index': 'Index d\'Augmentation',
      'perfusion_index': 'Index de Perfusion',
      'respiration_rate': 'Fréquence Respiratoire',
      'confidence': 'Confiance',
      'trend': 'Tendance',
      'trend_up': 'Hausse',
      'trend_down': 'Baisse',
      'trend_stable': 'Stable',
      'rmssd': 'RMSSD',
      'sdnn': 'SDNN',
      'pnn50': 'pNN50',
      'rr_intervals': 'Intervalles RR',
      'afib_probability': 'Probabilité FA',
      'analysis': 'Analyse',
      'recommendations': 'Recommandations',
      'details': 'Détails',
      'history': 'Historique',
      'today': 'Aujourd\'hui',
      'this_week': 'Cette Semaine',
      'this_month': 'Ce Mois',
      'avg': 'Moyenne',
      'min': 'Min',
      'max': 'Max',
      'name': 'Nom',
      'phone': 'Téléphone',
      'email': 'Email',
      'relationship': 'Relation',
      'primary_contact': 'Contact Principal',
      'address': 'Adresse',
      'loading': 'Chargement...',
      'no_data': 'Pas de Données',
      'error': 'Erreur',
      'success': 'Succès',
      'warning': 'Attention',
      'info': 'Info',
      'medical_disclaimer': 'Cette app fournit des estimations de bien-être et n\'est pas un dispositif médical.',
      'select_language': 'Choisir la Langue',
      'pm': 'PM',
      'am': 'AM',
    },
    'de': _translateGerman(),
    'zh': _translateChinese(),
    'ja': _translateJapanese(),
    'ru': _translateRussian(),
    'pt': _translatePortuguese(),
    'hi': _translateHindi(),
  };

  static Map<String, String> _translateGerman() => _generateTranslation('de', 'Digital Retter', 'Dein persönlicher Gesundheitswächter', 'Herz', 'Blutdruck', 'Aktivität', 'Schlaf', 'Einstellungen');
  static Map<String, String> _translateChinese() => _generateTranslation('zh', '数字守护', '您的个人健康守护者', '心脏', '血压', '活动', '睡眠', '设置');
  static Map<String, String> _translateJapanese() => _generateTranslation('ja', 'デジタルセーバー', 'あなたの個人的な健康守護者', '心臓', '血圧', '活動', '睡眠', '設定');
  static Map<String, String> _translateRussian() => _generateTranslation('ru', 'Цифровой Спасатель', 'Ваш личный хранитель здоровья', 'Сердце', 'Давление', 'Активность', 'Сон', 'Настройки');
  static Map<String, String> _translatePortuguese() => _generateTranslation('pt', 'Salvador Digital', 'Seu Guardião de Saúde Pessoal', 'Coração', 'Pressão', 'Atividade', 'Sono', 'Configurações');
  static Map<String, String> _translateHindi() => _generateTranslation('hi', 'डिजिटल सेवर', 'आपका व्यक्तिगत स्वास्थ्य रक्षक', 'हृदय', 'रक्तचाप', 'गतिविधि', 'नींद', 'सेटिंग्स');

  static Map<String, String> _generateTranslation(String code, String appName, String tagline, String heart, String bp, String activity, String sleep, String settings) {
    return {
      'app_name': appName,
      'tagline': tagline,
      'nav_dashboard': 'Dashboard',
      'nav_heart': heart,
      'nav_bp': bp,
      'nav_activity': activity,
      'nav_sleep': sleep,
      'nav_settings': settings,
      'heart_rate': 'Heart Rate',
      'blood_pressure': 'Blood Pressure',
      'oxygen': 'Oxygen (SpO2)',
      'hrv': 'HRV',
      'afib': 'AFib Detection',
      'arrhythmia': 'Arrhythmia',
      'stress': 'Stress Level',
      'sleep': 'Sleep',
      'activity': 'Activity',
      'steps': 'Steps',
      'calories': 'Calories',
      'distance': 'Distance',
      'resting_hr': 'Resting HR',
      'active_minutes': 'Active Minutes',
      'sleep_score': 'Sleep Score',
      'deep_sleep': 'Deep Sleep',
      'light_sleep': 'Light Sleep',
      'rem_sleep': 'REM Sleep',
      'awake': 'Awake',
      'total_sleep': 'Total Sleep',
      'bpm': 'BPM',
      'mmhg': 'mmHg',
      'percent': '%',
      'ms': 'ms',
      'steps_unit': 'steps',
      'km': 'km',
      'kcal': 'kcal',
      'minutes': 'min',
      'hours': 'h',
      'status_normal': 'Normal',
      'status_warning': 'Warning',
      'status_critical': 'Critical',
      'status_excellent': 'Excellent',
      'status_good': 'Good',
      'status_fair': 'Fair',
      'status_poor': 'Poor',
      'watch_connected': 'Watch Connected',
      'watch_disconnected': 'Watch Disconnected',
      'scanning': 'Scanning...',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'last_sync': 'Last sync',
      'battery': 'Battery',
      'signal': 'Signal',
      'emergency': 'Emergency',
      'emergency_alert': 'Emergency Alert!',
      'fall_detected': 'Fall Detected',
      'irregular_heartbeat': 'Irregular Heartbeat',
      'high_blood_pressure': 'High Blood Pressure',
      'low_oxygen': 'Low Oxygen',
      'are_you_okay': 'Are you okay?',
      'call_emergency': 'Call Emergency',
      'send_alert': 'Send Alert',
      'cancel_alert': "I'm Okay",
      'emergency_contacts': 'Emergency Contacts',
      'settings': settings,
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'thresholds': 'Alert Thresholds',
      'heart_rate_threshold': 'HR Alert',
      'bp_threshold': 'BP Alert',
      'about': 'About',
      'version': 'Version',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'done': 'Done',
      'confirm': 'Confirm',
      'retry': 'Retry',
      'health_score': 'Health Score',
      'vascular_age': 'Vascular Age',
      'arterial_stiffness': 'Arterial Stiffness',
      'pulse_pressure': 'Pulse Pressure',
      'augmentation_index': 'Augmentation Index',
      'perfusion_index': 'Perfusion Index',
      'respiration_rate': 'Respiration Rate',
      'confidence': 'Confidence',
      'trend': 'Trend',
      'trend_up': 'Trending Up',
      'trend_down': 'Trending Down',
      'trend_stable': 'Stable',
      'rmssd': 'RMSSD',
      'sdnn': 'SDNN',
      'pnn50': 'pNN50',
      'rr_intervals': 'RR Intervals',
      'afib_probability': 'AFib Probability',
      'analysis': 'Analysis',
      'recommendations': 'Recommendations',
      'details': 'Details',
      'history': 'History',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'avg': 'Average',
      'min': 'Min',
      'max': 'Max',
      'name': 'Name',
      'phone': 'Phone',
      'email': 'Email',
      'relationship': 'Relationship',
      'primary_contact': 'Primary Contact',
      'address': 'Address',
      'loading': 'Loading...',
      'no_data': 'No Data',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',
      'medical_disclaimer': 'This app provides wellness estimates and is not a medical device.',
      'select_language': 'Select Language',
      'pm': 'PM',
      'am': 'AM',
    };
  }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }

  // Shorthand getters
  String get appName => translate('app_name');
  String get tagline => translate('tagline');
  String get heartRate => translate('heart_rate');
  String get bloodPressure => translate('blood_pressure');
  String get oxygen => translate('oxygen');
  String get hrv => translate('hrv');
  String get afib => translate('afib');
  String get arrhythmia => translate('arrhythmia');
  String get stress => translate('stress');
  String get sleep => translate('sleep');
  String get activity => translate('activity');
  String get steps => translate('steps');
  String get calories => translate('calories');
  String get distance => translate('distance');
  String get bpm => translate('bpm');
  String get mmhg => translate('mmhg');
  String get percent => translate('percent');
  String get statusNormal => translate('status_normal');
  String get statusWarning => translate('status_warning');
  String get statusCritical => translate('status_critical');
  String get settings => translate('settings');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get add => translate('add');
  String get delete => translate('delete');
  String get name => translate('name');
  String get phone => translate('phone');
  String get email => translate('email');
  String get relationship => translate('relationship');
  String get primaryContact => translate('primary_contact');
  String get callEmergency => translate('call_emergency');
  String get emergencyAlert => translate('emergency_alert');
  String get fallDetected => translate('fall_detected');
  String get areYouOkay => translate('are_you_okay');
  String get sendAlert => translate('send_alert');
  String get cancelAlert => translate('cancel_alert');
  String get selectLanguage => translate('select_language');
  String get medicalDisclaimer => translate('medical_disclaimer');
  String get connect => translate('connect');
  String get disconnect => translate('disconnect');
  String get scanning => translate('scanning');
  String get watchConnected => translate('watch_connected');
  String get watchDisconnected => translate('watch_disconnected');
  String get noData => translate('no_data');
  String get lastSync => translate('last_sync');
  String get battery => translate('battery');
  String get signal => translate('signal');
  String get navDashboard => translate('nav_dashboard');
  String get navHeart => translate('nav_heart');
  String get navBP => translate('nav_bp');
  String get navActivity => translate('nav_activity');
  String get navSleep => translate('nav_sleep');
  String get navSettings => translate('nav_settings');
  String get healthScore => translate('health_score');
  String get vascularAge => translate('vascular_age');
  String get arterialStiffness => translate('arterial_stiffness');
  String get pulsePressure => translate('pulse_pressure');
  String get confidence => translate('confidence');
  String get trend => translate('trend');
  String get trendUp => translate('trend_up');
  String get trendDown => translate('trend_down');
  String get trendStable => translate('trend_stable');
  String get rmssd => translate('rmssd');
  String get sdnn => translate('sdnn');
  String get pnn50 => translate('pnn50');
  String get afibProbability => translate('afib_probability');
  String get analysis => translate('analysis');
  String get recommendations => translate('recommendations');
  String get details => translate('details');
  String get history => translate('history');
  String get today => translate('today');
  String get thisWeek => translate('this_week');
  String get thisMonth => translate('this_month');
  String get avg => translate('avg');
  String get min => translate('min');
  String get max => translate('max');
  String get emergencyContacts => translate('emergency_contacts');
  String get lowOxygen => translate('low_oxygen');
  String get highBloodPressure => translate('high_blood_pressure');
  String get irregularHeartbeat => translate('irregular_heartbeat');
  String get sleepScore => translate('sleep_score');
  String get deepSleep => translate('deep_sleep');
  String get lightSleep => translate('light_sleep');
  String get remSleep => translate('rem_sleep');
  String get awake => translate('awake');
  String get totalSleep => translate('total_sleep');
  String get restingHR => translate('resting_hr');
  String get activeMinutes => translate('active_minutes');
  String get notifications => translate('notifications');
  String get thresholds => translate('thresholds');
  String get heartRateThreshold => translate('heart_rate_threshold');
  String get bpThreshold => translate('bp_threshold');
  String get about => translate('about');
  String get version => translate('version');
  String get edit => translate('edit');
  String get done => translate('done');
  String get confirm => translate('confirm');
  String get retry => translate('retry');
  String get perfusionIndex => translate('perfusion_index');
  String get respirationRate => translate('respiration_rate');
  String get augmentationIndex => translate('augmentation_index');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get info => translate('info');
  String get rrIntervals => translate('rr_intervals');
  String get hours => translate('hours');
  String get minutes => translate('minutes');
  String get statusExcellent => translate('status_excellent');
  String get statusGood => translate('status_good');
  String get statusFair => translate('status_fair');
  String get statusPoor => translate('status_poor');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'es', 'fr', 'de', 'zh', 'ja', 'ru', 'pt', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this)!;
}
