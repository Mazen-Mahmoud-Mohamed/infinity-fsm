// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'INFINITY';

  @override
  String get companyName => 'Total-Com Solutions';

  @override
  String get splashLoading => 'جاري التحميل...';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'الوصول إلى مساحة عمل الخدمة الميدانية';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signingIn => 'جاري تسجيل الدخول...';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب.';

  @override
  String get emailInvalid => 'أدخل بريداً إلكترونياً صالحاً.';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة.';

  @override
  String get passwordMinLength => 'يجب أن تكون كلمة المرور 8 أحرف على الأقل.';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get roleLabel => 'الدور';

  @override
  String get companyLabel => 'الشركة';

  @override
  String get departmentLabel => 'القسم';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get attendance => 'الحضور';

  @override
  String get overtime => 'العمل الإضافي';

  @override
  String get workOrders => 'أوامر العمل';

  @override
  String get assets => 'الأصول';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsLoading => 'جاري تحميل الإشعارات...';

  @override
  String get notificationsLoadFailed => 'تعذر تحميل الإشعارات.';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد.';

  @override
  String get notificationsSearchHint => 'بحث في الإشعارات';

  @override
  String get notificationsSearchEmpty => 'لا توجد إشعارات مطابقة لبحثك.';

  @override
  String get notificationsMarkAllRead => 'تعيين الكل كمقروء';

  @override
  String get notificationsUnread => 'غير مقروء';

  @override
  String get notificationsRead => 'مقروء';

  @override
  String get notificationsFilterAll => 'الكل';

  @override
  String get notificationsCategoryGeneral => 'عام';

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار غير مقروء',
      many: '$count إشعارًا غير مقروء',
      few: '$count إشعارات غير مقروءة',
      two: 'إشعاران غير مقروءين',
      one: 'إشعار واحد غير مقروء',
      zero: 'لا إشعارات غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get globalSearch => 'بحث';

  @override
  String get globalSearchHint => 'ابحث في المستخدمين وأوامر العمل والأصول…';

  @override
  String get globalSearchPrompt => 'اكتب حرفين على الأقل للبحث عبر الوحدات.';

  @override
  String get globalSearchEmpty => 'لا توجد نتائج.';

  @override
  String get globalSearchFailed => 'تعذر تنفيذ البحث حالياً.';

  @override
  String get globalSearchShortcutHint => 'Ctrl+K';

  @override
  String get reportsCenter => 'مركز التقارير';

  @override
  String get reportsCenterSearchHint => 'بحث في سجلات التقارير';

  @override
  String get reportsCenterFilters => 'عوامل التصفية';

  @override
  String get reportsCenterApplyFilters => 'تطبيق عوامل التصفية';

  @override
  String get reportsCenterStatusFilter => 'الحالة';

  @override
  String get reportsCenterFilterAll => 'الكل';

  @override
  String get reportsCenterDateRange => 'نطاق التاريخ';

  @override
  String get reportsCenterCustomRange => 'نطاق مخصص';

  @override
  String get reportsCenterClearDates => 'مسح التواريخ';

  @override
  String get reportsCenterEmployee => 'الموظف';

  @override
  String get reportsCenterDepartment => 'القسم';

  @override
  String get reportsCenterSort => 'ترتيب';

  @override
  String get reportsCenterSortTitleAsc => 'العنوان أ–ي';

  @override
  String get reportsCenterSortTitleDesc => 'العنوان ي–أ';

  @override
  String get reportsCenterSortDateAsc => 'الأقدم تاريخاً';

  @override
  String get reportsCenterSortDateDesc => 'الأحدث تاريخاً';

  @override
  String get reportsCenterSortStatusAsc => 'الحالة أ–ي';

  @override
  String get reportsCenterSortStatusDesc => 'الحالة ي–أ';

  @override
  String get reportsCenterExport => 'تصدير';

  @override
  String get reportsCenterExportUnavailable => 'التصدير غير متاح حالياً.';

  @override
  String get reportsCenterFilterUnavailable =>
      'عامل التصفية هذا غير مدعوم في واجهة البرمجة الحالية.';

  @override
  String get reportsCenterEmpty =>
      'لا توجد سجلات مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyAttendance =>
      'لا توجد سجلات حضور مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyOvertime =>
      'لا توجد جلسات عمل إضافي مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyWorkOrders =>
      'لا توجد أوامر عمل مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyAssets =>
      'لا توجد أصول مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyInventory =>
      'لا توجد قطع مخزون مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyPm =>
      'لا توجد خطط صيانة مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterEmptyServiceReports =>
      'لا توجد تقارير خدمة مطابقة لعوامل التصفية المحددة.';

  @override
  String get reportsCenterLoadFailed => 'تعذر تحميل بيانات التقارير.';

  @override
  String get reportsCenterNoAccess =>
      'ليس لديك صلاحية الوصول إلى أي وحدة تقارير.';

  @override
  String get reportsCenterColTitle => 'العنوان';

  @override
  String get reportsCenterColSubtitle => 'المرجع';

  @override
  String get reportsCenterColDate => 'التاريخ';

  @override
  String get reportsCenterColMeta => 'التفاصيل';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get settings => 'الإعدادات';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get create => 'إنشاء';

  @override
  String get add => 'إضافة';

  @override
  String get back => 'رجوع';

  @override
  String get update => 'تحديث';

  @override
  String get reject => 'رفض';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get errorGeneric => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get sessionExpired => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get workOrderCreate => 'إنشاء';

  @override
  String get workOrderEdit => 'تعديل أمر العمل';

  @override
  String get workOrderDetails => 'تفاصيل أمر العمل';

  @override
  String get workOrderSearchHint => 'ابحث عن المهمة أو العميل أو الموقع';

  @override
  String get workOrderFilterAll => 'الكل';

  @override
  String get workOrderEmpty => 'لا توجد أوامر عمل';

  @override
  String get workOrderLoadFailed => 'فشل تحميل أوامر العمل';

  @override
  String get workOrderLoading => 'جاري تحميل أوامر العمل...';

  @override
  String get workOrderJobTitle => 'عنوان أمر العمل';

  @override
  String get workOrderCustomer => 'العميل';

  @override
  String get workOrderLocation => 'الموقع';

  @override
  String get workOrderDescription => 'وصف المشكلة';

  @override
  String get workOrderNotes => 'ملاحظات';

  @override
  String get workOrderPriority => 'الأولوية';

  @override
  String get workOrderScheduledDate => 'التاريخ المجدول';

  @override
  String get workOrderTechnician => 'الفني';

  @override
  String get workOrderAttachments => 'المرفقات';

  @override
  String get workOrderSave => 'حفظ';

  @override
  String get workOrderAccept => 'قبول';

  @override
  String get workOrderReject => 'رفض';

  @override
  String get workOrderStart => 'بدء العمل';

  @override
  String get workOrderComplete => 'إكمال';

  @override
  String get workOrderCancel => 'إلغاء الأمر';

  @override
  String get workOrderDelete => 'حذف';

  @override
  String get workOrderAssign => 'تعيين فني';

  @override
  String get workOrderUnassigned => 'غير معيّن';

  @override
  String get workOrderSelectTechnician => 'اختر الفني';

  @override
  String get workOrderAddPhoto => 'إضافة صورة';

  @override
  String get inventory => 'المخزون';

  @override
  String get inventoryManage => 'إدارة';

  @override
  String get inventoryLoading => 'جاري تحميل المخزون...';

  @override
  String get inventoryLoadFailed => 'فشل تحميل المخزون';

  @override
  String get inventoryTotalParts => 'إجمالي القطع';

  @override
  String get inventoryLowStock => 'مخزون منخفض';

  @override
  String get inventoryOutOfStock => 'نفد المخزون';

  @override
  String get inventoryInStock => 'متوفر';

  @override
  String get inventoryWarehouses => 'المستودعات';

  @override
  String get inventorySpareParts => 'قطع الغيار';

  @override
  String get inventoryStockHistory => 'سجل المخزون';

  @override
  String get inventoryRecentMovements => 'أحدث الحركات';

  @override
  String get inventoryMovementsEmpty => 'لا توجد حركات مخزون بعد';

  @override
  String get inventoryWarehousesEmpty => 'لا توجد مستودعات';

  @override
  String get inventoryPartsEmpty => 'لا توجد قطع غيار';

  @override
  String get inventoryCreateWarehouse => 'إضافة مستودع';

  @override
  String get inventoryEditWarehouse => 'تعديل المستودع';

  @override
  String get inventoryCreatePart => 'إضافة قطعة غيار';

  @override
  String get inventoryEditPart => 'تعديل قطعة الغيار';

  @override
  String get inventoryPartDetails => 'تفاصيل القطعة';

  @override
  String get inventorySearchWarehouses => 'ابحث في المستودعات';

  @override
  String get inventorySearchParts => 'ابحث بالاسم أو الرقم أو الباركود';

  @override
  String get inventorySearchMovements => 'ابحث بالسبب أو الملاحظات أو المستخدم';

  @override
  String get inventoryFilterAll => 'الكل';

  @override
  String get inventoryName => 'الاسم';

  @override
  String get inventoryCode => 'الرمز';

  @override
  String get inventoryAddress => 'العنوان';

  @override
  String get inventoryDescription => 'الوصف';

  @override
  String get inventoryActive => 'نشط';

  @override
  String get inventoryInactive => 'غير نشط';

  @override
  String get inventoryPartNumber => 'رقم القطعة';

  @override
  String get inventoryCategory => 'التصنيف';

  @override
  String get inventoryUnit => 'الوحدة';

  @override
  String get inventoryCurrentQuantity => 'الكمية الحالية';

  @override
  String get inventoryMinimumQuantity => 'الحد الأدنى';

  @override
  String get inventoryAvailableQuantity => 'الكمية المتاحة';

  @override
  String get inventoryBarcode => 'الباركود / QR';

  @override
  String get inventoryImage => 'الصورة';

  @override
  String get inventoryAddPhoto => 'إضافة صورة';

  @override
  String get inventoryRemovePhoto => 'إزالة الصورة';

  @override
  String get inventoryStockIn => 'إدخال مخزون';

  @override
  String get inventoryStockOut => 'إخراج مخزون';

  @override
  String get inventoryTransfer => 'تحويل';

  @override
  String get inventoryAdjustment => 'تسوية';

  @override
  String get inventoryQuantity => 'الكمية';

  @override
  String get inventoryReason => 'السبب';

  @override
  String get inventoryNotes => 'ملاحظات';

  @override
  String get inventoryWarehouse => 'المستودع';

  @override
  String get inventoryFromWarehouse => 'من مستودع';

  @override
  String get inventoryToWarehouse => 'إلى مستودع';

  @override
  String get inventoryDirection => 'الاتجاه';

  @override
  String get inventoryIncrease => 'زيادة';

  @override
  String get inventoryDecrease => 'نقصان';

  @override
  String get inventoryNoWarehouses => 'أنشئ مستودعاً قبل إدارة المخزون';

  @override
  String get inventoryNeedTwoWarehouses => 'التحويل يتطلب مستودعين على الأقل';

  @override
  String get inventoryCancel => 'إلغاء';

  @override
  String get inventorySave => 'حفظ';

  @override
  String get inventoryRequired => 'هذا الحقل مطلوب';

  @override
  String get assetsLoading => 'جاري تحميل الأصول...';

  @override
  String get assetsLoadFailed => 'فشل تحميل الأصول';

  @override
  String get assetsTotal => 'إجمالي الأصول';

  @override
  String get assetsList => 'قائمة الأصول';

  @override
  String get assetsCategories => 'التصنيفات';

  @override
  String get assetsHistory => 'سجل الأصل';

  @override
  String get assetsCreate => 'إضافة أصل';

  @override
  String get assetsEdit => 'تعديل الأصل';

  @override
  String get assetsDetails => 'تفاصيل الأصل';

  @override
  String get assetsEmpty => 'لا توجد أصول';

  @override
  String get assetsCategoriesEmpty => 'لا توجد تصنيفات';

  @override
  String get assetsHistoryEmpty => 'لا توجد أحداث بعد';

  @override
  String get assetsCreateCategory => 'إضافة تصنيف';

  @override
  String get assetsEditCategory => 'تعديل التصنيف';

  @override
  String get assetsSearchCategories => 'ابحث في التصنيفات';

  @override
  String get assetsSearchHint => 'ابحث بالرقم أو الاسم أو التسلسل أو الباركود';

  @override
  String get assetsSearchHistory => 'ابحث بعنوان السجل أو الملاحظات';

  @override
  String get assetsFilterAll => 'الكل';

  @override
  String get assetsStatusActive => 'نشط';

  @override
  String get assetsStatusMaintenance => 'صيانة';

  @override
  String get assetsStatusOffline => 'غير متصل';

  @override
  String get assetsStatusRetired => 'متقاعد';

  @override
  String get assetsWarrantyExpiringSoon => 'ضمان ينتهي قريباً';

  @override
  String get assetsName => 'الاسم';

  @override
  String get assetsCode => 'الرمز';

  @override
  String get assetsIcon => 'الأيقونة';

  @override
  String get assetsDescription => 'الوصف';

  @override
  String get assetsActive => 'نشط';

  @override
  String get assetsInactive => 'غير نشط';

  @override
  String get assetsNumber => 'رقم الأصل';

  @override
  String get assetsCategory => 'التصنيف';

  @override
  String get assetsStatus => 'الحالة';

  @override
  String get assetsSerialNumber => 'الرقم التسلسلي';

  @override
  String get assetsManufacturer => 'الشركة المصنعة';

  @override
  String get assetsModel => 'الموديل';

  @override
  String get assetsCustomer => 'العميل';

  @override
  String get assetsInstallationDate => 'تاريخ التركيب';

  @override
  String get assetsWarrantyExpiry => 'انتهاء الضمان';

  @override
  String get assetsLocation => 'الموقع';

  @override
  String get assetsNoLocation => 'لم يتم تحديد موقع';

  @override
  String get assetsBranch => 'الفرع';

  @override
  String get assetsRegion => 'المنطقة';

  @override
  String get assetsCity => 'المدينة';

  @override
  String get assetsLatitude => 'خط العرض';

  @override
  String get assetsLongitude => 'خط الطول';

  @override
  String get assetsQrCode => 'رمز QR';

  @override
  String get assetsBarcode => 'الباركود';

  @override
  String get assetsNotes => 'ملاحظات';

  @override
  String get assetsTitle => 'العنوان';

  @override
  String get assetsAddPhoto => 'إضافة صورة';

  @override
  String get assetsRemovePhoto => 'إزالة الصورة';

  @override
  String get assetsAddHistory => 'إضافة سجل';

  @override
  String get assetsHistoryType => 'نوع السجل';

  @override
  String get assetsHistoryInstallation => 'تركيب';

  @override
  String get assetsHistoryMaintenance => 'صيانة';

  @override
  String get assetsHistoryRepair => 'إصلاح';

  @override
  String get assetsHistoryInspection => 'فحص';

  @override
  String get assetsHistoryStatusChange => 'تغيير الحالة';

  @override
  String get assetsHistoryCreated => 'إنشاء';

  @override
  String get assetsHistoryUpdated => 'تحديث';

  @override
  String get assetsViewFullHistory => 'عرض السجل الكامل';

  @override
  String get assetsScanQr => 'مسح QR';

  @override
  String get assetsCancel => 'إلغاء';

  @override
  String get assetsSave => 'حفظ';

  @override
  String get assetsRequired => 'هذا الحقل مطلوب';

  @override
  String get pmTitle => 'الصيانة الوقائية';

  @override
  String get pmLoading => 'جاري تحميل الصيانة الوقائية...';

  @override
  String get pmLoadFailed => 'فشل تحميل الصيانة الوقائية';

  @override
  String get pmPlans => 'الخطط';

  @override
  String get pmSchedules => 'الجداول';

  @override
  String get pmHistory => 'السجل';

  @override
  String get pmChecklist => 'قائمة الفحص';

  @override
  String get pmChecklistBuilder => 'منشئ قائمة الفحص';

  @override
  String get pmPlanDetails => 'تفاصيل الخطة';

  @override
  String get pmCreatePlan => 'إنشاء خطة';

  @override
  String get pmEditPlan => 'تعديل الخطة';

  @override
  String get pmDeletePlan => 'حذف الخطة';

  @override
  String get pmDeletePlanConfirm => 'هل أنت متأكد من حذف خطة الصيانة هذه؟';

  @override
  String get pmPlansEmpty => 'لا توجد خطط صيانة';

  @override
  String get pmSchedulesEmpty => 'لا توجد جداول';

  @override
  String get pmHistoryEmpty => 'لا يوجد سجل صيانة بعد';

  @override
  String get pmChecklistEmpty => 'لا توجد عناصر فحص بعد';

  @override
  String get pmSearchPlansHint => 'بحث في الخطط';

  @override
  String get pmSearchSchedulesHint => 'بحث في الجداول';

  @override
  String get pmFilterAll => 'الكل';

  @override
  String get pmUpcoming => 'قادمة';

  @override
  String get pmOverdue => 'متأخرة';

  @override
  String get pmCompleted => 'مكتملة';

  @override
  String get pmCancelled => 'ملغاة';

  @override
  String get pmActivePlans => 'الخطط النشطة';

  @override
  String get pmRecentSchedules => 'الجداول الأخيرة';

  @override
  String get pmName => 'الاسم';

  @override
  String get pmCode => 'الرمز';

  @override
  String get pmDescription => 'الوصف';

  @override
  String get pmFrequency => 'التكرار';

  @override
  String get pmTrigger => 'المشغل';

  @override
  String get pmNextDueDate => 'تاريخ الاستحقاق التالي';

  @override
  String get pmPriority => 'الأولوية';

  @override
  String get pmStatus => 'الحالة';

  @override
  String get pmEstimatedDuration => 'المدة التقديرية (دقائق)';

  @override
  String get pmAssignedTeam => 'الفريق المكلف';

  @override
  String get pmAssignedTechnician => 'الفني المكلف';

  @override
  String get pmLinkedAsset => 'الأصل المرتبط';

  @override
  String get pmMeterThreshold => 'حد العداد';

  @override
  String get pmCurrentMeterReading => 'قراءة العداد الحالية';

  @override
  String get pmScheduledDate => 'تاريخ الجدولة';

  @override
  String get pmNotes => 'ملاحظات';

  @override
  String get pmNone => 'لا يوجد';

  @override
  String get pmCancel => 'إلغاء';

  @override
  String get pmSave => 'حفظ';

  @override
  String get pmRequired => 'هذا الحقل مطلوب';

  @override
  String get pmStatusActive => 'نشط';

  @override
  String get pmStatusInactive => 'غير نشط';

  @override
  String get pmPriorityLow => 'منخفضة';

  @override
  String get pmPriorityMedium => 'متوسطة';

  @override
  String get pmPriorityHigh => 'عالية';

  @override
  String get pmPriorityCritical => 'حرجة';

  @override
  String get pmFrequencyDaily => 'يومي';

  @override
  String get pmFrequencyWeekly => 'أسبوعي';

  @override
  String get pmFrequencyMonthly => 'شهري';

  @override
  String get pmFrequencyQuarterly => 'ربع سنوي';

  @override
  String get pmFrequencySemiAnnual => 'نصف سنوي';

  @override
  String get pmFrequencyAnnual => 'سنوي';

  @override
  String get pmTriggerTimeBased => 'حسب الوقت';

  @override
  String get pmTriggerMeterBased => 'حسب العداد';

  @override
  String get pmScheduleScheduled => 'مجدول';

  @override
  String get pmScheduleOverdue => 'متأخر';

  @override
  String get pmScheduleCompleted => 'مكتمل';

  @override
  String get pmScheduleCancelled => 'ملغى';

  @override
  String get pmGenerateSchedules => 'توليد الجداول';

  @override
  String pmSchedulesGenerated(int count) {
    return 'تم توليد $count جداول';
  }

  @override
  String pmMinutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get pmAddChecklistItem => 'إضافة عنصر';

  @override
  String get pmEditChecklistItem => 'تعديل العنصر';

  @override
  String get pmChecklistItemTitle => 'عنصر الفحص';

  @override
  String get pmChecklistItemDescription => 'الوصف';

  @override
  String get pmRequiresPassFail => 'نجاح / فشل';

  @override
  String get pmRequiresNotes => 'ملاحظات';

  @override
  String get pmPhotoRequired => 'صورة مطلوبة';

  @override
  String get pmCompleteSchedule => 'إكمال';

  @override
  String get pmCancelSchedule => 'إلغاء الجدول';

  @override
  String get reportsTitle => 'تقارير الخدمة';

  @override
  String get reportsLoading => 'جاري تحميل تقارير الخدمة...';

  @override
  String get reportsLoadFailed => 'فشل تحميل تقارير الخدمة';

  @override
  String get reportsEmpty => 'لا توجد تقارير خدمة بعد';

  @override
  String get reportsList => 'التقارير';

  @override
  String get reportsTotal => 'إجمالي التقارير';

  @override
  String get reportsSignatures => 'التوقيعات';

  @override
  String get reportsCaptureSignature => 'توقيع العميل';

  @override
  String get reportsGenerate => 'إنشاء تقرير';

  @override
  String get reportsPreview => 'معاينة التقرير';

  @override
  String get reportsDetails => 'تفاصيل التقرير';

  @override
  String get reportsDownload => 'تنزيل التقرير';

  @override
  String get reportsSearchHint => 'بحث في التقارير';

  @override
  String get reportsFilterAll => 'الكل';

  @override
  String get reportsStatusDraft => 'مسودة';

  @override
  String get reportsStatusGenerated => 'تم الإنشاء';

  @override
  String get reportsStatusDownloaded => 'تم التنزيل';

  @override
  String get reportsWorkOrderInfo => 'معلومات أمر العمل';

  @override
  String get reportsAssetInfo => 'معلومات الأصل';

  @override
  String get reportsTechnician => 'الفني';

  @override
  String get reportsJobNumber => 'رقم المهمة';

  @override
  String get reportsJobTitle => 'عنوان المهمة';

  @override
  String get reportsCustomerName => 'اسم العميل';

  @override
  String get reportsCustomerPosition => 'منصب العميل';

  @override
  String get reportsCustomerAddress => 'عنوان العميل';

  @override
  String get reportsAssetNumber => 'رقم الأصل';

  @override
  String get reportsAssetName => 'اسم الأصل';

  @override
  String get reportsSerialNumber => 'الرقم التسلسلي';

  @override
  String get reportsTechnicianName => 'اسم الفني';

  @override
  String get reportsStartTime => 'وقت البدء';

  @override
  String get reportsEndTime => 'وقت الانتهاء';

  @override
  String get reportsTotalDuration => 'المدة الإجمالية (دقائق)';

  @override
  String get reportsTechnicianNotes => 'ملاحظات الفني';

  @override
  String get reportsCustomerNotes => 'ملاحظات العميل';

  @override
  String get reportsCustomerSignature => 'توقيع العميل';

  @override
  String get reportsBeforePhotos => 'صور قبل';

  @override
  String get reportsProgressPhotos => 'صور التقدم';

  @override
  String get reportsAfterPhotos => 'صور بعد';

  @override
  String get reportsQrCode => 'رمز QR للتقرير';

  @override
  String get reportsNotes => 'ملاحظات';

  @override
  String get reportsWorkOrderNumberOptional => 'رقم أمر العمل (اختياري)';

  @override
  String get reportsSignHere => 'وقّع هنا';

  @override
  String get reportsClearSignature => 'مسح';

  @override
  String get reportsSaveSignature => 'حفظ التوقيع';

  @override
  String get reportsSignatureRequired => 'يرجى تقديم التوقيع';

  @override
  String get reportsSignatureSaved => 'تم حفظ التوقيع';

  @override
  String get reportsSignatureUnavailable => 'التوقيع غير متاح';

  @override
  String get reportsGeneratedSuccess => 'تم إنشاء تقرير الخدمة';

  @override
  String get reportsNone => 'لا يوجد';

  @override
  String get reportsRequired => 'هذا الحقل مطلوب';

  @override
  String reportsMinutes(int count) {
    return '$count دقيقة';
  }

  @override
  String reportsDownloaded(String fileName) {
    return 'تم تنزيل $fileName';
  }

  @override
  String get usersTitle => 'إدارة المستخدمين';

  @override
  String get usersLoading => 'جاري تحميل المستخدمين...';

  @override
  String get usersLoadFailed => 'فشل تحميل المستخدمين';

  @override
  String get usersEmpty => 'لا يوجد مستخدمون';

  @override
  String get usersList => 'المستخدمون';

  @override
  String get usersTotal => 'إجمالي المستخدمين';

  @override
  String get usersCreate => 'إنشاء مستخدم';

  @override
  String get usersEdit => 'تعديل المستخدم';

  @override
  String get usersDetails => 'تفاصيل المستخدم';

  @override
  String get usersDelete => 'حذف المستخدم';

  @override
  String get usersDeleteConfirm => 'هل أنت متأكد من حذف هذا المستخدم؟';

  @override
  String get usersSearchHint => 'بحث عن المستخدمين';

  @override
  String get usersFilterAll => 'الكل';

  @override
  String get usersStatusActive => 'نشط';

  @override
  String get usersStatusDisabled => 'معطل';

  @override
  String get usersStatusLocked => 'مقفل';

  @override
  String get usersStatus => 'الحالة';

  @override
  String get usersFirstName => 'الاسم الأول';

  @override
  String get usersLastName => 'اسم العائلة';

  @override
  String get usersUsername => 'اسم المستخدم';

  @override
  String get usersEmail => 'البريد الإلكتروني';

  @override
  String get usersPhone => 'رقم الهاتف';

  @override
  String get usersJobTitle => 'المسمى الوظيفي';

  @override
  String get usersEmployeeId => 'الرقم الوظيفي';

  @override
  String get usersPassword => 'كلمة المرور';

  @override
  String get usersRole => 'الدور';

  @override
  String get usersDepartment => 'القسم';

  @override
  String get usersBranch => 'الفرع';

  @override
  String get usersLastLogin => 'آخر تسجيل دخول';

  @override
  String get usersLastActive => 'آخر نشاط';

  @override
  String get usersCreatedBy => 'أنشئ بواسطة';

  @override
  String get usersUpdatedBy => 'حدّث بواسطة';

  @override
  String get usersActivity => 'النشاط الأخير';

  @override
  String get usersEnable => 'تفعيل';

  @override
  String get usersDisable => 'تعطيل';

  @override
  String get usersLock => 'قفل';

  @override
  String get usersChangePassword => 'تغيير كلمة المرور';

  @override
  String get usersResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get usersCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get usersNewPassword => 'كلمة المرور الجديدة';

  @override
  String get usersConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get usersPasswordMin => 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';

  @override
  String get usersPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get usersPasswordChanged => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get usersPasswordResetSuccess => 'تمت إعادة تعيين كلمة المرور بنجاح';

  @override
  String get usersOrgRefsRequired =>
      'يجب أن يتضمن القسم المحدد المنطقة والمدينة';

  @override
  String get usersCancel => 'إلغاء';

  @override
  String get usersSave => 'حفظ';

  @override
  String get usersRequired => 'هذا الحقل مطلوب';

  @override
  String get rolesTitle => 'الأدوار والصلاحيات';

  @override
  String get rolesLoading => 'جاري تحميل الأدوار...';

  @override
  String get rolesLoadFailed => 'فشل تحميل الأدوار';

  @override
  String get rolesEmpty => 'لا توجد أدوار';

  @override
  String get rolesList => 'الأدوار';

  @override
  String get rolesTotal => 'إجمالي الأدوار';

  @override
  String get rolesActive => 'الأدوار النشطة';

  @override
  String get rolesSystem => 'أدوار النظام';

  @override
  String get rolesCustom => 'أدوار مخصصة';

  @override
  String get rolesCreate => 'إنشاء دور';

  @override
  String get rolesEdit => 'تعديل الدور';

  @override
  String get rolesDetails => 'تفاصيل الدور';

  @override
  String get rolesDelete => 'حذف الدور';

  @override
  String get rolesDeleteConfirm => 'هل أنت متأكد من حذف هذا الدور؟';

  @override
  String get rolesDeleted => 'تم حذف الدور';

  @override
  String get rolesCreated => 'تم إنشاء الدور';

  @override
  String get rolesUpdated => 'تم تحديث الدور';

  @override
  String get rolesCloned => 'تم استنساخ الدور';

  @override
  String get rolesClone => 'استنساخ الدور';

  @override
  String get rolesActivate => 'تفعيل';

  @override
  String get rolesDeactivate => 'تعطيل';

  @override
  String get rolesAssignUsers => 'تعيين مستخدمين';

  @override
  String get rolesAssign => 'تعيين';

  @override
  String get rolesAssigned => 'تم تعيين المستخدمين بنجاح';

  @override
  String get rolesSearchHint => 'بحث عن الأدوار';

  @override
  String get rolesSearchUsersHint => 'بحث عن المستخدمين';

  @override
  String get rolesSearchPermissions => 'بحث عن الصلاحيات';

  @override
  String get rolesName => 'اسم الدور';

  @override
  String get rolesNameRequired => 'اسم الدور مطلوب';

  @override
  String get rolesDescription => 'الوصف';

  @override
  String get rolesColor => 'اللون';

  @override
  String get rolesPermissions => 'الصلاحيات';

  @override
  String get rolesNoPermissions => 'لا توجد صلاحيات محددة';

  @override
  String get rolesPermissionsSearchEmpty =>
      'لا توجد صلاحيات مطابقة لبحثك. جرّب عنواناً أو وصفاً مختلفاً.';

  @override
  String get rolesPermissionsCatalogEmpty =>
      'لا توجد صلاحيات متاحة في الكتالوج.';

  @override
  String get rolesSave => 'حفظ الدور';

  @override
  String get rolesCancel => 'إلغاء';

  @override
  String get rolesSystemBadge => 'نظام';

  @override
  String get rolesStatusActive => 'نشط';

  @override
  String get rolesStatusInactive => 'غير نشط';

  @override
  String get rolesAssignedUsersTitle => 'المستخدمون المعيّنون';

  @override
  String get rolesNoAssignedUsers => 'لا يوجد مستخدمون معيّنون لهذا الدور';

  @override
  String get rolesNoUsersFound => 'لا يوجد مستخدمون';

  @override
  String rolesAssignedUsers(int count) {
    return '$count مستخدمون';
  }

  @override
  String rolesPermissionCount(int count) {
    return '$count صلاحيات';
  }

  @override
  String rolesSelectedPermissions(int count) {
    return '$count محددة';
  }

  @override
  String get dashboardLoadFailed => 'تعذر تحميل لوحة التحكم.';

  @override
  String get dashboardLoading => 'جاري تحميل لوحة التحكم...';

  @override
  String get dashboardOverview => 'نظرة تشغيلية';

  @override
  String get dashboardTodayAttendance => 'حضور اليوم';

  @override
  String get dashboardTodayWorkOrders => 'أوامر العمل اليوم';

  @override
  String get dashboardUpcomingPm => 'صيانة وقائية قادمة';

  @override
  String get dashboardLowStock => 'تنبيهات انخفاض المخزون';

  @override
  String get dashboardRecentNotifications => 'أحدث الإشعارات';

  @override
  String get dashboardNoNotifications => 'لا توجد إشعارات حديثة';

  @override
  String get dashboardQuickActions => 'إجراءات سريعة';

  @override
  String get dashboardQuickCreateWorkOrder => 'إنشاء أمر عمل';

  @override
  String get dashboardQuickStartOvertime => 'بدء العمل الإضافي';

  @override
  String get dashboardPeriodToday => 'اليوم';

  @override
  String get dashboardPeriodWeek => 'هذا الأسبوع';

  @override
  String get dashboardPeriodMonth => 'هذا الشهر';

  @override
  String get dashboardPeriodYear => 'هذه السنة';

  @override
  String get dashboardPeriodCustom => 'مخصص';

  @override
  String get dashboardPeriodFrom => 'من تاريخ';

  @override
  String get dashboardPeriodTo => 'إلى تاريخ';

  @override
  String get dashboardPeriodApply => 'تطبيق';

  @override
  String get dashboardRangeUntilNow => 'حتى الآن';

  @override
  String dashboardRangeSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String dashboardReportLine(String range) {
    return 'التقرير: $range';
  }

  @override
  String get dashboardSectionKpis => 'المؤشرات الرئيسية';

  @override
  String get dashboardSectionAttendance => 'الحضور';

  @override
  String get dashboardSectionOvertime => 'العمل الإضافي';

  @override
  String get dashboardSectionWorkOrders => 'أوامر العمل';

  @override
  String get dashboardSectionPm => 'الصيانة الوقائية';

  @override
  String get dashboardSectionInventory => 'المخزون';

  @override
  String get dashboardSectionAssets => 'الأصول';

  @override
  String get dashboardSectionLiveActivity => 'النشاط المباشر';

  @override
  String get dashboardSectionCharts => 'الاتجاهات';

  @override
  String get dashboardSectionTeamOverview => 'نظرة على الفريق';

  @override
  String get dashboardSectionTeamAttendance => 'حضور الفريق';

  @override
  String get dashboardSectionTeamOvertime => 'عمل إضافي للفريق';

  @override
  String get dashboardSectionTeamWorkOrders => 'أوامر عمل الفريق';

  @override
  String get dashboardSectionTeamPm => 'صيانة الفريق';

  @override
  String get dashboardSectionTeamInventory => 'تنبيهات مخزون الفريق';

  @override
  String get dashboardSectionTeamActivity => 'نشاط الفريق';

  @override
  String get dashboardSectionTeamPerformance => 'أداء الفريق';

  @override
  String get dashboardSectionLocation => 'الموقع';

  @override
  String get dashboardSectionPerformance => 'الأداء';

  @override
  String get dashboardKpiTotalEmployees => 'إجمالي الموظفين';

  @override
  String get dashboardKpiActiveEmployees => 'الموظفون النشطون';

  @override
  String get dashboardKpiCurrentlyWorking => 'يعملون حالياً';

  @override
  String get dashboardKpiOnOvertime => 'في عمل إضافي';

  @override
  String get dashboardKpiOnTravelOt => 'في وقت سفر';

  @override
  String get dashboardKpiTotalWorkingHours => 'إجمالي ساعات العمل';

  @override
  String get dashboardKpiAverageWorkingHours => 'متوسط ساعات العمل';

  @override
  String get dashboardKpiAttendanceRate => 'نسبة الحضور';

  @override
  String get dashboardKpiOtHours => 'ساعات العمل الإضافي';

  @override
  String get dashboardKpiTravelOtHours => 'ساعات وقت السفر';

  @override
  String get dashboardKpiTotalApprovedHours => 'إجمالي الساعات المعتمدة';

  @override
  String get dashboardKpiTotalOvertimeHours => 'إجمالي الساعات';

  @override
  String get dashboardKpiTotalTrips => 'إجمالي الرحلات';

  @override
  String get dashboardKpiOvernightTrips => 'رحلات المبيت';

  @override
  String get dashboardKpiOtTechnicians => 'إجمالي الفنيين';

  @override
  String get dashboardKpiAvgHoursPerTrip => 'متوسط الساعات لكل رحلة';

  @override
  String get dashboardOvertimeAnalytics => 'تحليلات العمل الإضافي';

  @override
  String get dashboardTechnicianSummary => 'ملخص الفنيين';

  @override
  String get dashboardChartHoursPerTechnician => 'الساعات لكل فني';

  @override
  String get dashboardChartTripsPerTechnician => 'الرحلات لكل فني';

  @override
  String get dashboardChartHoursOverTime => 'الساعات عبر الزمن';

  @override
  String get dashboardKpiAvgOtPerEmployee => 'متوسط العمل الإضافي للموظف';

  @override
  String get dashboardKpiWoTotal => 'إجمالي أوامر العمل';

  @override
  String get dashboardKpiWoPending => 'قيد الانتظار';

  @override
  String get dashboardKpiWoAssigned => 'مُسندة';

  @override
  String get dashboardKpiWoInProgress => 'قيد التنفيذ';

  @override
  String get dashboardKpiWoCompleted => 'مكتملة';

  @override
  String get dashboardKpiWoCancelled => 'ملغاة';

  @override
  String get dashboardKpiPmDue => 'مستحقة';

  @override
  String get dashboardKpiPmOverdue => 'متأخرة';

  @override
  String get dashboardKpiPmCompleted => 'مكتملة';

  @override
  String get dashboardKpiPmAssigned => 'مهام مسندة';

  @override
  String get dashboardKpiOutOfStock => 'نفد المخزون';

  @override
  String get dashboardKpiAssetsTotal => 'إجمالي الأصول';

  @override
  String get dashboardKpiAssetsActive => 'نشطة';

  @override
  String get dashboardKpiAssetsMaintenance => 'تحت الصيانة';

  @override
  String get dashboardKpiAssetsRetired => 'متقاعدة';

  @override
  String get dashboardKpiTeamSize => 'حجم الفريق';

  @override
  String get dashboardKpiMembersPresent => 'الأعضاء الحاضرون';

  @override
  String get dashboardKpiCompletionRate => 'نسبة الإنجاز';

  @override
  String get dashboardKpiTodayWorkingHours => 'ساعات عمل اليوم';

  @override
  String get dashboardKpiMonthlyWorkingHours => 'ساعات العمل للفترة';

  @override
  String get dashboardKpiMonthlyOtHours => 'ساعات العمل الإضافي للفترة';

  @override
  String get dashboardKpiMonthlyTravelOt => 'ساعات وقت السفر للفترة';

  @override
  String get dashboardKpiCompletedJobs => 'أوامر العمل المكتملة';

  @override
  String get dashboardKpiAvgCompletionHours => 'متوسط ساعات الإنجاز';

  @override
  String get dashboardNoLiveActivity => 'لا يوجد نشاط حديث';

  @override
  String get dashboardSystemActor => 'النظام';

  @override
  String get dashboardLocationUnknown => 'الموقع غير متاح';

  @override
  String dashboardLastSync(String date) {
    return 'آخر مزامنة: $date';
  }

  @override
  String dashboardHoursValue(String value) {
    return '$value س';
  }

  @override
  String dashboardPercentValue(String value) {
    return '$value%';
  }

  @override
  String get dashboardChartAttendance => 'اتجاه الحضور';

  @override
  String get dashboardChartOvertime => 'اتجاه العمل الإضافي';

  @override
  String get dashboardChartWorkOrders => 'اتجاه أوامر العمل';

  @override
  String get dashboardChartPm => 'اتجاه الصيانة الوقائية';

  @override
  String get dashboardChartEmpty => 'لا توجد بيانات للرسم';

  @override
  String get dashboardViewAll => 'عرض الكل';

  @override
  String dashboardChartWindowDays(int days) {
    return '$daysي';
  }

  @override
  String get dashboardTrends => 'الاتجاهات';

  @override
  String get dashboardWorkforce => 'القوى العاملة';

  @override
  String get dashboardOperations => 'العمليات';

  @override
  String get dashboardResources => 'الموارد';

  @override
  String get dashboardKeyMetrics => 'المؤشرات الرئيسية';

  @override
  String get settingsSearchHint => 'بحث في الإعدادات';

  @override
  String get settingsEmptySearch => 'لا توجد إعدادات مطابقة';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionOrganization => 'الشركة';

  @override
  String get settingsSectionAdministration => 'الإدارة';

  @override
  String get settingsSectionSystem => 'النظام';

  @override
  String get settingsSectionAbout => 'حول';

  @override
  String get settingsMyProfile => 'ملفي الشخصي';

  @override
  String get settingsChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSystem => 'افتراضي النظام';

  @override
  String get settingsLanguageEnglish => 'الإنجليزية';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeSystem => 'افتراضي النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsNotificationPreferences => 'تفضيلات الإشعارات';

  @override
  String get settingsPushNotifications => 'إشعارات الدفع';

  @override
  String get settingsEmailNotifications => 'إشعارات البريد';

  @override
  String get settingsCompanyInformation => 'معلومات الشركة';

  @override
  String get settingsTechnicianInterfaceTitle => 'إدارة واجهة الفني';

  @override
  String get settingsTechnicianInterfaceDescription =>
      'تحكم في الأقسام التي يمكن للفني رؤيتها واستخدامها في التطبيق.';

  @override
  String get settingsTechnicianNoSectionsTitle => 'لا توجد أقسام متاحة حاليًا';

  @override
  String get settingsTechnicianNoSectionsBody =>
      'لا توجد أقسام مفعّلة حاليًا لحسابك. يرجى التواصل مع المسؤول.';

  @override
  String get settingsOvertimeTitle => 'إعدادات العمل الإضافي';

  @override
  String get settingsOvertimeVoiceNotesTitle => 'الملاحظات الصوتية';

  @override
  String get settingsOvertimeVoiceNotesSubtitle =>
      'تهيئة الملاحظات الصوتية الاختيارية لمراحل رحلة العمل الإضافي.';

  @override
  String get settingsOvertimeVoiceMaxDurationTitle =>
      'الحد الأقصى لمدة التسجيل الصوتي';

  @override
  String get settingsOvertimeVoiceMaxDurationSubtitle =>
      'الحد الأقصى المسموح به لكل ملاحظة صوتية تُسجَّل أثناء مرحلة عمل إضافي.';

  @override
  String settingsOvertimeVoiceDurationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String settingsOvertimeVoiceCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String get settingsOvertimeVoiceQualityTitle => 'جودة التسجيل الصوتي';

  @override
  String get settingsOvertimeVoiceQualitySubtitle =>
      'جودة الصوت المستخدمة عند تسجيل الملاحظات الصوتية أثناء العمل الإضافي.';

  @override
  String get settingsOvertimeVoiceQualityHigh => 'عالية';

  @override
  String get settingsOvertimeVoiceQualityMedium => 'متوسطة';

  @override
  String get settingsOvertimeVoiceQualityLow => 'منخفضة';

  @override
  String get settingsOvertimeMaxPhotoSizeTitle =>
      'الحد الأقصى لحجم الصورة المرفوعة';

  @override
  String get settingsOvertimeMaxPhotoSizeSubtitle =>
      'تُضغط الصور قبل الرفع للبقاء ضمن هذا الحد قدر الإمكان.';

  @override
  String settingsOvertimeMaxPhotoSizeMb(int size) {
    return '$size ميغابايت';
  }

  @override
  String get settingsOvertimeMaxPhotoSizeOriginal => 'الأصل';

  @override
  String get settingsOvertimeUploadPolicyTitle => 'سياسة الرفع';

  @override
  String get settingsOvertimeUploadPolicyImmediately => 'فوراً';

  @override
  String get settingsOvertimeUploadPolicyImmediatelyHint =>
      'رفع نقاط التفتيش فور توفر اتصال بالشبكة.';

  @override
  String get settingsOvertimeUploadPolicyWifiPreferred => 'يفضّل Wi-Fi';

  @override
  String get settingsOvertimeUploadPolicyWifiPreferredHint =>
      'الرفع فوراً عبر Wi-Fi. على بيانات الجوال، تُوضَع في قائمة الانتظار حتى يتوفر Wi-Fi. يمكن للفني فرض الرفع يدوياً.';

  @override
  String get settingsOvertimeUploadPolicyManual => 'يدوي';

  @override
  String get settingsOvertimeUploadPolicyManualHint =>
      'دائماً تُوضَع الرفوعات في قائمة الانتظار. تحدث المزامنة فقط عند ضغط الفني على «مزامنة الآن».';

  @override
  String get settingsOvertimeUploadPolicyWifiOnly => 'Wi-Fi فقط';

  @override
  String get settingsOvertimeUploadPolicyWifiOnlyHint =>
      'عدم الرفع عبر بيانات الجوال أبداً. تُوضَع في قائمة الانتظار حتى يتوفر Wi-Fi.';

  @override
  String get settingsOvertimeUploadPolicyAskEveryTime => 'اسأل في كل مرة';

  @override
  String get settingsOvertimeUploadPolicyAskEveryTimeHint =>
      'عند الرفع عبر بيانات الجوال، يُسأل الفني في كل مرة.';

  @override
  String settingsOvertimeQualityEstimatePerMinute(String size) {
    return '≈ $size / دقيقة';
  }

  @override
  String settingsOvertimeEstimatedMaxFileSize(String size) {
    return 'الحد الأقصى التقديري لحجم الملف: ≈ $size';
  }

  @override
  String settingsOvertimeEstimateKb(int size) {
    return '≈ $size ك.ب';
  }

  @override
  String settingsOvertimeEstimateMb(String size) {
    return '≈ $size م.ب';
  }

  @override
  String settingsOvertimeEstimateTotalMb(String size) {
    return '≈ $size م.ب';
  }

  @override
  String settingsOvertimeFileSizeKb(int size) {
    return '$size ك.ب';
  }

  @override
  String settingsOvertimeFileSizeMb(String size) {
    return '$size م.ب';
  }

  @override
  String settingsOvertimeFileSizeBytes(int size) {
    return '$size بايت';
  }

  @override
  String get settingsOvertimeLargeRecordingWarning =>
      'قد تزيد التسجيلات الكبيرة من وقت الرفع واستخدام بيانات الجوال.';

  @override
  String get settingsOvertimePresetTitle => 'الإعداد المسبق';

  @override
  String get settingsOvertimePresetSubtitle =>
      'طبّق ملفاً موصى به أو خصّص الإعدادات يدوياً.';

  @override
  String get settingsOvertimePresetOffice => 'مكتب';

  @override
  String get settingsOvertimePresetFieldService => 'خدمة ميدانية';

  @override
  String get settingsOvertimePresetHeavyMaintenance => 'صيانة ثقيلة';

  @override
  String get settingsOvertimePresetCustom => 'مخصص';

  @override
  String get settingsOvertimeRestoreDefaults => 'استعادة الافتراضي';

  @override
  String get settingsOvertimeRestoreDialogTitle => 'استعادة إعدادات الصوت؟';

  @override
  String get settingsOvertimeRestoreDialogBody =>
      'سيتم استعادة:\n• مدة التسجيل: 5 دقائق\n• جودة التسجيل: متوسطة\n• الحد الأقصى للصورة: 2 م.ب\n• سياسة الرفع: فوراً';

  @override
  String get settingsOvertimeRestoreConfirm => 'استعادة';

  @override
  String get settingsOvertimeConfigTestingTitle => 'اختبار الإعدادات';

  @override
  String get settingsOvertimeConfigTestingSubtitle =>
      'معاينة تأثير الإعدادات الحالية. لا يتم الرفع أو الحفظ.';

  @override
  String get settingsOvertimeVoiceTestTitle => 'اختبار التسجيل الصوتي';

  @override
  String get settingsOvertimeVoiceTestRecord => 'اختبار التسجيل الصوتي';

  @override
  String get settingsOvertimeVoiceTestPlay => 'تشغيل';

  @override
  String get settingsOvertimeVoiceTestDelete => 'حذف';

  @override
  String get settingsOvertimeVoiceTestRecordAgain => 'تسجيل مجدداً';

  @override
  String settingsOvertimeVoiceTestTimer(String elapsed, String max) {
    return '$elapsed / $max';
  }

  @override
  String get settingsOvertimeVoiceTestDuration => 'مدة التسجيل';

  @override
  String get settingsOvertimeVoiceTestEstimatedSize => 'الحجم التقديري';

  @override
  String get settingsOvertimeVoiceTestActualSize => 'الحجم الفعلي';

  @override
  String get settingsOvertimeVoiceTestEncoding => 'تنسيق الترميز';

  @override
  String get settingsOvertimeVoiceTestBitrate => 'معدل البت';

  @override
  String get settingsOvertimeVoiceTestSampleRate => 'معدل العيّنة';

  @override
  String settingsOvertimeVoiceTestBitrateKbps(int rate) {
    return '$rate kbps';
  }

  @override
  String settingsOvertimeVoiceTestSampleRateKhz(int rate) {
    return '$rate kHz';
  }

  @override
  String get settingsOvertimePhotoTestTitle => 'اختبار ضغط الصور';

  @override
  String get settingsOvertimePhotoTestCamera => 'التقاط صورة';

  @override
  String get settingsOvertimePhotoTestGallery => 'اختيار من المعرض';

  @override
  String get settingsOvertimePhotoTestOriginal => 'الأصل';

  @override
  String get settingsOvertimePhotoTestCompressed => 'مضغوط';

  @override
  String get settingsOvertimePhotoTestSplit => 'عرض مقسم';

  @override
  String get settingsOvertimePhotoTestCompare => 'مقارنة';

  @override
  String get settingsOvertimePhotoTestCompareShort => 'مقارنة';

  @override
  String get settingsOvertimePhotoTestOriginalShort => 'الأصل';

  @override
  String get settingsOvertimePhotoTestCompressedShort => 'مضغوط';

  @override
  String get settingsOvertimePhotoTestMobileStackHint =>
      'مرّر لمقارنة الأصل والمضغوط.';

  @override
  String get settingsOvertimePhotoTestFullscreenSwipeHint =>
      'اسحب بين الأصل والمضغوط والمقارنة المقسمة.';

  @override
  String get settingsOvertimePhotoTestNoCompressionApplied =>
      'لم يتم تطبيق ضغط (سياسة الأصل)';

  @override
  String settingsOvertimePhotoTestResolution(int width, int height) {
    return 'الدقة: $width × $height';
  }

  @override
  String settingsOvertimePhotoTestCompressionRatio(int percent) {
    return 'نسبة الضغط: $percent%';
  }

  @override
  String settingsOvertimePhotoTestEstimatedUpload(String size) {
    return 'حجم الرفع التقديري: $size';
  }

  @override
  String get settingsOvertimePhotoTestChooseAnother => 'اختيار صورة أخرى';

  @override
  String get settingsOvertimePhotoTestRetest => 'إعادة الاختبار';

  @override
  String get settingsOvertimePhotoTestDeletePreview => 'حذف المعاينة';

  @override
  String get settingsOvertimePhotoTestOriginalSize => 'حجم الأصل';

  @override
  String get settingsOvertimePhotoTestCompressedSize => 'حجم المضغوط';

  @override
  String get settingsOvertimePhotoTestEstimatedCloudinaryUsage =>
      'تخزين Cloudinary التقديري';

  @override
  String get settingsOvertimePhotoTestEstimatedUploadTime =>
      'زمن الرفع التقديري';

  @override
  String get settingsOvertimePhotoTestOriginalResolution => 'دقة الأصل';

  @override
  String get settingsOvertimePhotoTestCompressedResolution => 'دقة المضغوط';

  @override
  String get settingsOvertimePhotoTestJpegQuality => 'جودة JPEG';

  @override
  String settingsOvertimePhotoTestJpegQualityValue(int quality) {
    return '$quality٪';
  }

  @override
  String get settingsOvertimePhotoTestNoCompression => 'بدون ضغط (سياسة الأصل)';

  @override
  String get settingsOvertimePhotoTestUnderPolicyLimit => 'أقل من حد السياسة';

  @override
  String get settingsOvertimePhotoTestSplitHint =>
      'اسحب المنزلق للمقارنة. اقرص أو انقر مرتين للتكبير.';

  @override
  String get settingsOvertimePhotoTestOpenFullscreen => 'فتح ملء الشاشة';

  @override
  String get settingsOvertimePhotoTestEstimatedUploadSize =>
      'حجم الرفع التقديري';

  @override
  String get settingsOvertimePerformanceInfoTitle => 'معلومات الأداء';

  @override
  String get settingsOvertimePerformanceVoiceMaxDuration => 'الحد الأقصى للمدة';

  @override
  String get settingsOvertimePerformanceVoiceMaxSize =>
      'الحد الأقصى التقديري للحجم';

  @override
  String get settingsOvertimePerformancePhotoMaxSize =>
      'متوسط الحد الأقصى للحجم';

  @override
  String settingsOvertimePerformancePhotoAverageMb(int size) {
    return '$size م.ب';
  }

  @override
  String get settingsOvertimePerformanceTotalUpload => 'إجمالي الرفع التقديري';

  @override
  String get settingsOvertimePerformanceCompression => 'الضغط';

  @override
  String get settingsOvertimeStorageCalculatorTitle => 'حاسبة التخزين';

  @override
  String get settingsOvertimeStorageEstimatedVoiceSize =>
      'الحجم التقديري للصوت';

  @override
  String get settingsOvertimeStorageEstimatedImageSize =>
      'الحجم التقديري للصور';

  @override
  String get settingsOvertimeStorageEstimatedUploadPerSession =>
      'إجمالي الرفع لكل جلسة';

  @override
  String get settingsOvertimeStorageEstimatedUploadPerTechnician =>
      'إجمالي الرفع لكل فني';

  @override
  String get settingsOvertimeStorageEstimatedDailyUsage =>
      'الاستخدام اليومي التقديري';

  @override
  String get settingsOvertimeStorageEstimatedMonthlyUsage =>
      'الاستخدام الشهري التقديري';

  @override
  String get settingsOvertimeStorageEstimatedCloudinaryStorage =>
      'تخزين Cloudinary التقديري';

  @override
  String get settingsOvertimeStorageEstimatedBandwidth =>
      'نطاق البيانات (Bandwidth) التقديري';

  @override
  String get overtimeVoiceSettingsInfoTitle => 'إعدادات التسجيل الصوتي';

  @override
  String get overtimeCellularUploadTitle => 'رفع الآن؟';

  @override
  String get overtimeCellularUploadMessage =>
      'أنت تستخدم بيانات الجوال. كيف تريد رفع نقطة التفتيش هذه؟';

  @override
  String get overtimeCellularUploadWifiOnly => 'Wi-Fi فقط';

  @override
  String get overtimeCellularUploadMobileData => 'بيانات الجوال';

  @override
  String get overtimeCellularUploadLater => 'لاحقاً';

  @override
  String auditOvertimeVoiceDurationChanged(String before, String after) {
    return 'تم تغيير مدة التسجيل الصوتي من $before إلى $after';
  }

  @override
  String auditOvertimeVoiceQualityChanged(String before, String after) {
    return 'تم تغيير جودة التسجيل من $before إلى $after';
  }

  @override
  String auditOvertimeUploadPolicyChanged(String before, String after) {
    return 'تم تغيير سياسة الرفع من $before إلى $after';
  }

  @override
  String auditOvertimeMaxPhotoSizeChanged(String before, String after) {
    return 'تم تغيير الحد الأقصى لحجم الصورة من $before إلى $after';
  }

  @override
  String auditOvertimePresetApplied(String preset) {
    return 'تم تطبيق الإعداد المسبق: $preset';
  }

  @override
  String get auditOvertimeRestoredDefaults =>
      'تمت استعادة إعدادات الصوت الافتراضية';

  @override
  String get auditOvertimeVoiceDurationChangedGeneric =>
      'تم تغيير مدة التسجيل الصوتي';

  @override
  String get auditOvertimeVoiceQualityChangedGeneric =>
      'تم تغيير جودة التسجيل الصوتي';

  @override
  String get auditOvertimeUploadPolicyChangedGeneric => 'تم تغيير سياسة الرفع';

  @override
  String get auditOvertimeMaxPhotoSizeChangedGeneric =>
      'تم تغيير الحد الأقصى لحجم الصورة';

  @override
  String get auditOvertimePresetAppliedGeneric => 'تم تطبيق إعداد مسبق';

  @override
  String get settingsCompanyLogo => 'شعار الشركة';

  @override
  String get settingsCompanyName => 'اسم الشركة';

  @override
  String get settingsContactEmail => 'البريد للتواصل';

  @override
  String get settingsContactPhone => 'هاتف التواصل';

  @override
  String get settingsAddress => 'العنوان';

  @override
  String get settingsAddressLine1 => 'سطر العنوان 1';

  @override
  String get settingsAddressLine2 => 'سطر العنوان 2';

  @override
  String get settingsCity => 'المدينة';

  @override
  String get settingsGovernorate => 'المحافظة';

  @override
  String get settingsCountry => 'الدولة';

  @override
  String get settingsPostalCode => 'الرمز البريدي';

  @override
  String get settingsWorkingHours => 'ساعات العمل';

  @override
  String get settingsWorkingHoursStart => 'وقت البدء';

  @override
  String get settingsWorkingHoursEnd => 'وقت الانتهاء';

  @override
  String get settingsTimezone => 'المنطقة الزمنية';

  @override
  String get settingsBackupRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get settingsCacheManagement => 'إدارة التخزين المؤقت';

  @override
  String get settingsSystemStatus => 'حالة النظام';

  @override
  String get settingsApiStatus => 'حالة واجهة البرمجة';

  @override
  String get settingsDatabaseStatus => 'حالة قاعدة البيانات';

  @override
  String get settingsStorageUsage => 'استخدام التخزين';

  @override
  String get settingsApiVersion => 'إصدار واجهة البرمجة';

  @override
  String get settingsBackendVersion => 'إصدار الخادم';

  @override
  String get settingsAppVersion => 'إصدار التطبيق';

  @override
  String get settingsUptime => 'مدة التشغيل';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsTermsOfService => 'شروط الخدمة';

  @override
  String get settingsOpenSourceLicenses => 'تراخيص المصادر المفتوحة';

  @override
  String get settingsPrivacyBody =>
      'يعالج INFINITY بيانات الخدمة الميدانية لدعم عمليات Total-Com Solutions. تُستخدم البيانات الشخصية فقط للمصادقة والحضور وتنفيذ العمل.';

  @override
  String get settingsTermsBody =>
      'استخدام INFINITY مقصور على الموظفين المصرح لهم. يُحظر الوصول غير المصرح به أو إساءة استخدام البيانات أو إعادة توزيع معلومات الشركة.';

  @override
  String get settingsUiOnly => 'واجهة فقط في هذا الإصدار';

  @override
  String get settingsComingSoonAction => 'سيتاح هذا الإجراء في إصدار لاحق';

  @override
  String get settingsCacheCleared => 'تم تأكيد مسح التخزين المؤقت المحلي';

  @override
  String get settingsLoading => 'جاري تحميل الإعدادات...';

  @override
  String get settingsLoadFailed => 'فشل تحميل الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get settingsLogoUpdated => 'تم تحديث شعار الشركة';

  @override
  String get settingsSave => 'حفظ الإعدادات';

  @override
  String get serverMgmtTitle => 'إدارة الخادم';

  @override
  String get serverMgmtAccessDenied =>
      'يمكن للمسؤولين فقط إدارة خادم الواجهة الخلفية.';

  @override
  String get serverMgmtConnectionSettings => 'إعدادات الاتصال';

  @override
  String get serverMgmtBackendUrl => 'عنوان خادم الواجهة الخلفية';

  @override
  String get serverMgmtUrlHelper =>
      'يقبل https://host أو https://host/api/v1 — يُضاف /api/v1 تلقائياً.';

  @override
  String get serverMgmtInvalidUrl =>
      'أدخل عنوان URL صالحاً يبدأ بـ http:// أو https://.';

  @override
  String get serverMgmtTestConnection => 'اختبار الاتصال';

  @override
  String get serverMgmtPingServer => 'فحص الخادم';

  @override
  String get serverMgmtSave => 'حفظ';

  @override
  String get serverMgmtRestoreDefault => 'استعادة الافتراضي';

  @override
  String get serverMgmtServerInformation => 'معلومات الخادم';

  @override
  String get serverMgmtCurrentServer => 'الخادم الحالي';

  @override
  String get serverMgmtStatus => 'الحالة';

  @override
  String get serverMgmtStatusConnected => 'متصل';

  @override
  String get serverMgmtStatusFailed => 'فشل الاتصال';

  @override
  String get serverMgmtStatusUnknown => 'لم يُختبر بعد';

  @override
  String get serverMgmtBackendVersion => 'إصدار الخادم';

  @override
  String get serverMgmtEnvironment => 'البيئة';

  @override
  String get serverMgmtResponseTime => 'زمن الاستجابة';

  @override
  String get serverMgmtConnectionQuality => 'جودة الاتصال';

  @override
  String get serverMgmtLastSuccessful => 'آخر اتصال ناجح';

  @override
  String get serverMgmtQualityExcellent => 'ممتاز (<100 مللي ثانية)';

  @override
  String get serverMgmtQualityGood => 'جيد (100–250 مللي ثانية)';

  @override
  String get serverMgmtQualityFair => 'مقبول (250–500 مللي ثانية)';

  @override
  String get serverMgmtQualityPoor => 'ضعيف (>1000 مللي ثانية)';

  @override
  String get serverMgmtQualityUnreachable => 'الخادم غير متاح';

  @override
  String get serverMgmtAdvancedDiagnostics => 'تشخيص متقدم';

  @override
  String get serverMgmtAppVersion => 'إصدار التطبيق';

  @override
  String get serverMgmtBuildNumber => 'رقم البناء';

  @override
  String get serverMgmtPlatform => 'المنصة';

  @override
  String get serverMgmtCurrentApiUrl => 'عنوان واجهة البرمجة الحالي';

  @override
  String get serverMgmtDeviceLocalTime => 'الوقت المحلي للجهاز';

  @override
  String get serverMgmtServerTime => 'وقت الخادم';

  @override
  String get serverMgmtClockDifference => 'فرق الساعة';

  @override
  String get serverMgmtOnlineStatus => 'حالة الاتصال';

  @override
  String get serverMgmtOnline => 'متصل';

  @override
  String get serverMgmtOffline => 'غير متصل';

  @override
  String get serverMgmtUserRole => 'دور المستخدم الحالي';

  @override
  String get serverMgmtLastSuccessfulSync => 'آخر مزامنة ناجحة';

  @override
  String get serverMgmtPendingSyncQueue => 'طابور المزامنة المعلقة';

  @override
  String get serverMgmtNetworkType => 'نوع الشبكة';

  @override
  String get serverMgmtBackendReachable => 'الخادم قابل للوصول';

  @override
  String get serverMgmtApiHealth => 'صحة واجهة البرمجة';

  @override
  String get serverMgmtDatabaseConnectivity => 'اتصال قاعدة البيانات';

  @override
  String get serverMgmtAvgLatency => 'متوسط زمن الاستجابة';

  @override
  String get serverMgmtMinLatency => 'أقل زمن استجابة';

  @override
  String get serverMgmtMaxLatency => 'أعلى زمن استجابة';

  @override
  String get serverMgmtRequestTimeout => 'مهلة الطلب';

  @override
  String get serverMgmtAppUptime => 'مدة تشغيل التطبيق';

  @override
  String get serverMgmtDeviceTimezone => 'المنطقة الزمنية للجهاز';

  @override
  String get serverMgmtServerTimezone => 'المنطقة الزمنية للخادم';

  @override
  String get serverMgmtHealthHealthy => 'سليم';

  @override
  String get serverMgmtHealthWarning => 'تحذير';

  @override
  String get serverMgmtHealthError => 'خطأ';

  @override
  String get serverMgmtTestSuccess => 'تم الاتصال بالخادم بنجاح.';

  @override
  String get serverMgmtTestFailed => 'فشل الاتصال. تحقق من العنوان والشبكة.';

  @override
  String get serverMgmtPingSuccess => 'اكتمل فحص الخادم.';

  @override
  String get serverMgmtPingFailed => 'الخادم غير متاح.';

  @override
  String get serverMgmtSaveSuccess =>
      'تم حفظ عنوان الخادم. ستستخدم الطلبات الجديدة هذا الخادم فوراً.';

  @override
  String get serverMgmtSaveFailed => 'تعذر حفظ عنوان الخادم.';

  @override
  String get serverMgmtRestoreSuccess => 'تمت استعادة خادم الإنتاج الافتراضي.';

  @override
  String get serverMgmtFutureHint =>
      'هذه الصفحة جاهزة لإعدادات مستقبلية مثل المهلات وإعادة المحاولة والتحويل التلقائي وميزات التجربة.';

  @override
  String get serverMgmtUnlockHint => 'تم فتح أدوات المسؤول';

  @override
  String get serverMgmtBiometricReason => 'قم بالمصادقة لفتح إدارة الخادم';

  @override
  String get serverMgmtBiometricUnavailable =>
      'المصادقة على الجهاز غير متاحة على هذا الجهاز.';

  @override
  String get serverMgmtTimeout => 'انتهت مهلة الاتصال. حاول مرة أخرى.';

  @override
  String get serverMgmtExportSuccess => 'تم تصدير التشخيص.';

  @override
  String get serverMgmtExportFailed => 'تعذر تصدير التشخيص.';

  @override
  String get serverMgmtCopySuccess => 'تم نسخ معلومات الخادم.';

  @override
  String get serverMgmtExportDiagnostics => 'تصدير التشخيص';

  @override
  String get serverMgmtCopyServerInfo => 'نسخ معلومات الخادم';

  @override
  String get serverMgmtClearUrl => 'مسح';

  @override
  String get serverMgmtPasteUrl => 'لصق';

  @override
  String get serverMgmtCopyUrl => 'نسخ';

  @override
  String get serverMgmtRetry => 'إعادة المحاولة';

  @override
  String get serverMgmtServerUnreachable => 'الخادم غير متاح';

  @override
  String get serverMgmtUnknown => 'غير معروف';

  @override
  String get serverMgmtQualitySlow => 'بطيء (500–1000 مللي ثانية)';

  @override
  String get serverMgmtRegion => 'المنطقة';

  @override
  String get serverMgmtServerUptime => 'مدة التشغيل';

  @override
  String get serverMgmtDatabase => 'قاعدة البيانات';

  @override
  String get serverMgmtApiUrlLabel => 'عنوان واجهة البرمجة';

  @override
  String get serverMgmtLatency => 'زمن الاستجابة';

  @override
  String get serverMgmtVersion => 'الإصدار';

  @override
  String get serverMgmtHealth => 'الصحة';

  @override
  String get serverMgmtDeviceModel => 'طراز الجهاز';

  @override
  String get serverMgmtAndroidVersion => 'إصدار Android / النظام';

  @override
  String get serverMgmtLastSuccessfulPing => 'آخر فحص ناجح';

  @override
  String get serverMgmtConnectedBadge => 'متصل';

  @override
  String serverMgmtVersionLabel(String version, String build) {
    return 'الإصدار $version ($build)';
  }

  @override
  String get livePhotoRequired => 'يلزم التقاط صورة مباشرة.';

  @override
  String get deviceTimeIncorrect => 'يبدو أن وقت الجهاز غير صحيح.';

  @override
  String get gpsAccuracyTooLow =>
      'دقة الموقع منخفضة جداً. انتقل إلى منطقة مفتوحة ثم أعد المحاولة.';

  @override
  String get attendanceUpdated => 'تم تحديث الحضور بنجاح.';

  @override
  String get attendanceLoading => 'جاري تحميل الحضور...';

  @override
  String get attendanceHistoryLoading => 'جاري تحميل السجل...';

  @override
  String get attendanceHistoryEmpty => 'لا يوجد سجل حضور بعد';

  @override
  String get attendanceTimeline => 'الجدول الزمني';

  @override
  String get attendanceHistoryTooltip => 'السجل';

  @override
  String get overtimeEnded =>
      'انتهى العمل الإضافي. تم احتساب العمل الإضافي المؤهل تلقائياً.';

  @override
  String get normalOvertimeStarted => 'بدأ العمل الإضافي العادي.';

  @override
  String get travelOvertimeStarted => 'بدأ العمل الإضافي للسفر.';

  @override
  String get overtimeLoading => 'جاري تحميل العمل الإضافي...';

  @override
  String get overtimeLoadFailed => 'تعذر تحميل العمل الإضافي.';

  @override
  String get overtimeMyTooltip => 'وقتي الإضافي';

  @override
  String get overtimeManageTooltip => 'إدارة العمل الإضافي';

  @override
  String get attendanceClockIn => 'تسجيل حضور';

  @override
  String get attendanceClockOut => 'تسجيل انصراف';

  @override
  String get attendanceStartBreak => 'بدء استراحة';

  @override
  String get attendanceEndBreak => 'إنهاء استراحة';

  @override
  String get attendanceShiftCompleted => 'لقد أكملت ورديتك لليوم.';

  @override
  String get attendanceTodayStatus => 'حالة اليوم';

  @override
  String get attendanceWorkingHours => 'ساعات العمل';

  @override
  String get attendanceBreaks => 'الاستراحات';

  @override
  String get attendanceTimelineEmpty => 'لا يوجد نشاط حضور مسجل اليوم بعد.';

  @override
  String get attendanceEventClockedIn => 'تم تسجيل الحضور';

  @override
  String get attendanceEventClockedOut => 'تم تسجيل الانصراف';

  @override
  String get attendanceEventBreakStarted => 'بدأت الاستراحة';

  @override
  String get attendanceEventBreakEnded => 'انتهت الاستراحة';

  @override
  String get attendanceSyncedOffline => 'تمت المزامنة من سجل دون اتصال';

  @override
  String get attendanceHistoryTitle => 'سجل الحضور';

  @override
  String get attendanceStatusNotStarted => 'لم يبدأ';

  @override
  String get attendanceStatusWorking => 'يعمل';

  @override
  String get attendanceStatusOnBreak => 'في استراحة';

  @override
  String get attendanceStatusClockedOut => 'انتهى الدوام';

  @override
  String get attendanceStatusPresent => 'حاضر';

  @override
  String get attendanceStatusCheckedOut => 'تم الانصراف';

  @override
  String get attendanceManagement => 'إدارة الحضور';

  @override
  String get attendanceManageTooltip => 'إدارة الحضور';

  @override
  String get attendanceSearchEmployee => 'البحث باسم الموظف أو البريد';

  @override
  String get attendanceAdminEmpty => 'لا توجد سجلات حضور.';

  @override
  String get attendanceAdminLoadFailed => 'فشل تحميل سجلات الحضور.';

  @override
  String get attendanceDetails => 'تفاصيل الحضور';

  @override
  String get attendanceDetailsLoading => 'جاري تحميل تفاصيل الحضور...';

  @override
  String get attendanceDetailsLoadFailed => 'فشل تحميل تفاصيل الحضور.';

  @override
  String get attendanceEmployeeInfo => 'معلومات الموظف';

  @override
  String get attendanceSessionInfo => 'معلومات الجلسة';

  @override
  String get attendanceDeviceInfo => 'معلومات الجهاز';

  @override
  String get attendanceLocation => 'الموقع';

  @override
  String get attendanceDevice => 'الجهاز';

  @override
  String get attendanceSyncSource => 'مصدر المزامنة';

  @override
  String get attendanceLastUpdated => 'آخر تحديث';

  @override
  String get attendanceSelfie => 'صورة سيلفي';

  @override
  String get attendanceDate => 'التاريخ';

  @override
  String get attendanceOvertimeHours => 'ساعات العمل الإضافي';

  @override
  String get attendanceRoleAll => 'كل الأدوار';

  @override
  String get overtimeStartTitle => 'بدء رحلة العمل الإضافي';

  @override
  String get overtimeStartHint =>
      'ساعات العمل الرسمية من 09:00 صباحاً إلى 05:00 مساءً. يُحتسب الوقت خارج هذه الفترة تلقائياً. الجلسات الجديدة تتضمن أربع نقاط تحقق؛ المدة تُحسب من بدء الرحلة إلى إنهاء الرحلة.';

  @override
  String get overtimeStartNormal => 'بدء الرحلة — عادي';

  @override
  String get overtimeStartTravel => 'بدء الرحلة — سفر';

  @override
  String get overtimeStart => 'بدء العمل الإضافي';

  @override
  String get overtimeTravel => 'سفر';

  @override
  String get overtimeOvernightStay => 'مبيت ليلي';

  @override
  String get overtimeOvernight => 'البيات';

  @override
  String get overtimeOvernightShort => 'بيات';

  @override
  String get overtimeEnd => 'إنهاء الرحلة';

  @override
  String get overtimeArrivedAtWorkSite => 'الوصول لموقع العمل';

  @override
  String get overtimeFinishedWork => 'إنهاء العمل';

  @override
  String get overtimeStageStartJourney => 'بدء الرحلة';

  @override
  String get overtimeStageArrivedAtWorkSite => 'الوصول لموقع العمل';

  @override
  String get overtimeStageFinishedWork => 'إنهاء العمل';

  @override
  String get overtimeStageEndJourney => 'إنهاء الرحلة';

  @override
  String get overtimeCheckpointCompleted => 'مكتمل';

  @override
  String get overtimeCheckpointNext => 'التالي';

  @override
  String get overtimeCheckpointPending => 'قيد الانتظار';

  @override
  String get overtimeJourneyTimeline => 'الجدول الزمني للرحلة';

  @override
  String get overtimeJourneyOverview => 'نظرة عامة على الرحلة';

  @override
  String get overtimeArrivedAtWorkSiteRecorded =>
      'تم تسجيل الوصول لموقع العمل.';

  @override
  String get overtimeFinishedWorkRecorded => 'تم تسجيل إنهاء العمل.';

  @override
  String get overtimeCompletePriorCheckpoints =>
      'أكمل نقاط التحقق السابقة قبل إنهاء الرحلة.';

  @override
  String get overtimeGpsAccuracy => 'دقة GPS';

  @override
  String get overtimeDeviceId => 'معرف الجهاز';

  @override
  String get overtimeBatteryLevel => 'البطارية';

  @override
  String get overtimeNetworkStatus => 'الشبكة';

  @override
  String get overtimeNotes => 'ملاحظات';

  @override
  String get overtimeNotesOptionalHint => 'ملاحظات اختيارية لهذه النقطة';

  @override
  String get overtimeVoiceNote => 'ملاحظة صوتية';

  @override
  String get overtimeVoiceRecord => 'تسجيل صوت';

  @override
  String get overtimeVoiceStop => 'إيقاف';

  @override
  String get overtimeVoicePlay => 'تشغيل';

  @override
  String get overtimeVoicePause => 'إيقاف مؤقت';

  @override
  String get overtimeVoiceDelete => 'حذف';

  @override
  String get overtimeVoiceRerecord => 'إعادة التسجيل';

  @override
  String overtimeVoiceMaxDurationHint(int minutes) {
    return 'اختياري. الحد الأقصى $minutes دقيقة.';
  }

  @override
  String get overtimeVoiceLimitWarning => 'سيتوقف التسجيل خلال 30 ثانية.';

  @override
  String overtimeVoiceMaxRecordingInfo(int minutes) {
    return 'الحد الأقصى للتسجيل: $minutes دقيقة';
  }

  @override
  String get overtimeVoicePermissionDenied =>
      'يلزم إذن الميكروفون لتسجيل ملاحظة صوتية.';

  @override
  String get overtimeVoiceRecording => 'جاري التسجيل...';

  @override
  String get overtimeVoiceRecorded => 'تم تسجيل الصوت';

  @override
  String get overtimeVoiceMaxReached => 'تم بلوغ الحد الأقصى لمدة التسجيل.';

  @override
  String get overtimeVoiceUploaded => 'تم الرفع';

  @override
  String get overtimeVoiceWaitingSync => 'في انتظار المزامنة';

  @override
  String get overtimeVoiceUploading => 'جاري رفع الملاحظة الصوتية…';

  @override
  String get overtimeVoicePlaybackFailed => 'تعذر تشغيل هذا التسجيل.';

  @override
  String get overtimeExportExcel => 'تصدير Excel';

  @override
  String get overtimeExportDenied =>
      'يمكن للمسؤولين والمشرفين فقط تصدير تقارير العمل الإضافي.';

  @override
  String get overtimeExportFiltersHint =>
      'مرشحات اختيارية لتقرير Excel. اتركها فارغة لتصدير جميع الجلسات المتاحة.';

  @override
  String get overtimeExportStartDate => 'تاريخ البدء';

  @override
  String get overtimeExportEndDate => 'تاريخ الانتهاء';

  @override
  String get overtimeExportAll => 'الكل';

  @override
  String get overtimeExportEmployeeId => 'معرّف المستخدم للموظف';

  @override
  String get overtimeExportOptionalIdHint => 'معرّف MongoDB اختياري';

  @override
  String get overtimeExportModeLabel => 'نوع التصدير';

  @override
  String get overtimeExportReportLanguage => 'لغة التقرير';

  @override
  String get overtimeExportLanguageEnglish => 'English';

  @override
  String get overtimeExportLanguageArabic => 'العربية';

  @override
  String get overtimeExportModeSummary => 'تصدير الملخص';

  @override
  String get overtimeExportModeSummaryHint =>
      'إحصائيات فقط — بدون GPS أو صور أو صوت أو تفاصيل الرحلة.';

  @override
  String get overtimeExportModeDetailed => 'تصدير التقرير التفصيلي';

  @override
  String get overtimeExportModeDetailedHint =>
      'مجموعة بيانات العمل الإضافي الكاملة مع الخرائط والصوت والصور ومعلومات الجهاز.';

  @override
  String get overtimeExportGenerate => 'إنشاء Excel';

  @override
  String get overtimeExportPreparing => 'جاري التحضير للتصدير…';

  @override
  String get overtimeExportDownloading => 'جاري إنشاء تقرير Excel…';

  @override
  String get overtimeExportSaving => 'جاري حفظ الملف…';

  @override
  String get overtimeExportReady => 'التصدير جاهز';

  @override
  String overtimeExportRowCount(int count) {
    return 'تم تصدير $count جلسة';
  }

  @override
  String get overtimeExportOpen => 'فتح';

  @override
  String get overtimeExportOpenFile => 'فتح الملف';

  @override
  String get overtimeExportOpenFolder => 'فتح المجلد المحتوي';

  @override
  String get overtimeExportSaveAs => 'حفظ باسم';

  @override
  String get overtimeExportSave => 'حفظ';

  @override
  String get overtimeExportShare => 'مشاركة';

  @override
  String overtimeExportSavedTo(String path) {
    return 'تم الحفظ في $path';
  }

  @override
  String get overtimeExportSaveFailed =>
      'تعذر حفظ ملف Excel. يرجى المحاولة مرة أخرى.';

  @override
  String get overtimeExportOpenFailed =>
      'تعذر فتح الملف. يرجى المحاولة مرة أخرى.';

  @override
  String get overtimeExportOpenFolderFailed => 'تعذر فتح المجلد المحتوي.';

  @override
  String get overtimeRequiresManualReview => 'يتطلب مراجعة يدوية';

  @override
  String get overtimeProgress => 'التقدم';

  @override
  String get overtimeStatusLabel => 'الحالة';

  @override
  String get overtimeStartTime => 'وقت البدء';

  @override
  String get overtimeLocation => 'الموقع';

  @override
  String get overtimeRunningTimer => 'المؤقت الجاري';

  @override
  String get overtimeLastSessionSummary => 'ملخص آخر جلسة';

  @override
  String get overtimeEligible => 'ساعات الإضافي';

  @override
  String get overtimeWorkedHours => 'ساعات العمل';

  @override
  String get overtimeApprovedHours => 'عدد الساعات المقبولة';

  @override
  String get overtimeApprovePartial => 'اعتماد جزئي';

  @override
  String get overtimeApprovePartialTitle => 'اعتماد ساعات جزئية';

  @override
  String get overtimeApprovedHoursHint => '14:30';

  @override
  String get overtimeApprovedHoursHelper => 'مثال: 14 ساعة و30 دقيقة';

  @override
  String get overtimeApprovedHoursInvalid =>
      'أدخل مدة بصيغة سس:دد (الدقائق 0–59) لا تتجاوز ساعات العمل.';

  @override
  String get overtimeTypeNormal => 'عمل إضافي عادي';

  @override
  String get overtimeTypeTravel => 'عمل إضافي للسفر';

  @override
  String get overtimeContinueExistingSession =>
      'لديك بالفعل جلسة عمل إضافي قيد التشغيل.';

  @override
  String get overtimeContinueSession => 'متابعة الجلسة الحالية';

  @override
  String get overtimeActiveSessionReminder =>
      'جلسة العمل الإضافي ما زالت قيد التشغيل. لا تنسَ إنهاءها عند الانتهاء.';

  @override
  String overtimeProgressOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get overtimeSyncPending => 'بانتظار المزامنة';

  @override
  String get overtimeSyncSynced => 'تمت المزامنة';

  @override
  String get overtimeSyncFailed => 'فشلت المزامنة';

  @override
  String get overtimeSyncOffline => 'غير متصل — في قائمة الانتظار';

  @override
  String get overtimeShowMap => 'عرض الخريطة';

  @override
  String get overtimeHideMap => 'إخفاء الخريطة';

  @override
  String get overtimeReviewNotes => 'ملاحظات المراجعة';

  @override
  String get overtimeReviewNotesHint => 'ملاحظات اختيارية لهذا القرار';

  @override
  String get overtimeGpsStatus => 'حالة GPS';

  @override
  String get overtimeSyncStatus => 'حالة المزامنة';

  @override
  String get overtimeCurrentStage => 'المرحلة الحالية';

  @override
  String get overtimeLiveCameraRequired =>
      'التقاط الصورة عبر الكاميرا المباشرة مطلوب — اختيار الصور من المعرض معطّل.';

  @override
  String get offlineMode => 'وضع دون اتصال';

  @override
  String get loadingGeneric => 'جاري التحميل...';

  @override
  String get confirm => 'تأكيد';

  @override
  String get close => 'إغلاق';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get labelType => 'النوع';

  @override
  String get labelName => 'الاسم';

  @override
  String get labelStart => 'البدء';

  @override
  String get labelEnd => 'الانتهاء';

  @override
  String get labelCreated => 'تاريخ الإنشاء';

  @override
  String get filterPending => 'قيد المراجعة';

  @override
  String get filterApproved => 'معتمد';

  @override
  String get filterRejected => 'مرفوض';

  @override
  String get approve => 'اعتماد';

  @override
  String get deviceRegistrationFailed => 'فشل تسجيل الجهاز. أعد تشغيل التطبيق.';

  @override
  String get firstSignInRequiresInternet =>
      'يلزم الاتصال بالإنترنت لتسجيل الدخول لأول مرة.';

  @override
  String get attendanceOfflineCachedData =>
      'وضع دون اتصال — عرض بيانات الحضور المخزنة.';

  @override
  String attendancePendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجلات حضور بانتظار المزامنة.',
      one: 'سجل حضور واحد بانتظار المزامنة.',
    );
    return '$_temp0';
  }

  @override
  String attendancePendingOfflineRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجلات بانتظار المزامنة دون اتصال',
      one: 'سجل واحد بانتظار المزامنة دون اتصال',
    );
    return '$_temp0';
  }

  @override
  String get profileLoading => 'جاري تحميل الملف الشخصي...';

  @override
  String get profilePhone => 'الهاتف';

  @override
  String get profilePosition => 'المنصب';

  @override
  String get profileNoPermissions => 'لا توجد صلاحيات معينة';

  @override
  String get orgTitle => 'المؤسسة';

  @override
  String get orgCompanies => 'الشركات';

  @override
  String get orgCompaniesSubtitle => 'ملف الشركة';

  @override
  String get orgSearchCompanies => 'بحث في الشركات';

  @override
  String get orgBranches => 'الفروع';

  @override
  String get orgBranchesSubtitle => 'مواقع الفروع';

  @override
  String get orgSearchBranches => 'بحث في الفروع';

  @override
  String get orgDepartments => 'الأقسام';

  @override
  String get orgDepartmentsSubtitle => 'هيكل الأقسام';

  @override
  String get orgSearchDepartments => 'بحث في الأقسام';

  @override
  String get orgTeams => 'الفرق';

  @override
  String get orgTeamsSubtitle => 'الفرق التشغيلية';

  @override
  String get orgSearchTeams => 'بحث في الفرق';

  @override
  String get orgPositions => 'المناصب';

  @override
  String get orgPositionsSubtitle => 'المناصب الوظيفية';

  @override
  String get orgSearchPositions => 'بحث في المناصب';

  @override
  String get orgUserDirectory => 'دليل المستخدمين';

  @override
  String get orgUserDirectorySubtitle => 'الموظفون والأدوار';

  @override
  String get orgSearchUsers => 'بحث في المستخدمين';

  @override
  String get orgSearch => 'بحث';

  @override
  String get orgEmpty => 'لا توجد سجلات';

  @override
  String get orgNoCachedData => 'لا توجد بيانات مخزنة بعد.';

  @override
  String get usersRoleAdmin => 'مدير النظام';

  @override
  String get usersRoleSupervisor => 'مشرف';

  @override
  String get usersRoleTechnician => 'فني';

  @override
  String get usersRoleHr => 'موارد بشرية';

  @override
  String get usersRoleWarehouse => 'المخازن';

  @override
  String get usersRoleViewer => 'مشاهد';

  @override
  String get usersRoleManager => 'مدير';

  @override
  String get permGroupDashboard => 'لوحة التحكم';

  @override
  String get permGroupUsers => 'المستخدمون';

  @override
  String get permGroupRoles => 'الأدوار والصلاحيات';

  @override
  String get permGroupAttendance => 'الحضور';

  @override
  String get permGroupOvertime => 'العمل الإضافي';

  @override
  String get permGroupInventory => 'المخزون';

  @override
  String get permGroupAssets => 'الأصول';

  @override
  String get permGroupMaintenance => 'الصيانة';

  @override
  String get permGroupServiceReports => 'تقارير الخدمة';

  @override
  String get permGroupWorkOrders => 'أوامر العمل';

  @override
  String get permGroupSettings => 'الإعدادات';

  @override
  String get permGroupProfile => 'الملف الشخصي';

  @override
  String get permGroupNotifications => 'الإشعارات';

  @override
  String get permGroupOrganization => 'المؤسسة';

  @override
  String get permGroupAudit => 'التدقيق';

  @override
  String get permGroupGeneral => 'عام';

  @override
  String get rolesNotLoaded => 'لم يتم تحميل الدور';

  @override
  String get rolesSelectAtLeastOneUser => 'اختر مستخدماً واحداً على الأقل';

  @override
  String get overtimeMyHistory => 'وقتي الإضافي';

  @override
  String get overtimeManagement => 'إدارة العمل الإضافي';

  @override
  String get overtimeDetails => 'تفاصيل العمل الإضافي';

  @override
  String get overtimeDetailsLoading => 'جاري تحميل التفاصيل...';

  @override
  String get overtimeDetailsLoadFailed => 'تعذر تحميل تفاصيل العمل الإضافي.';

  @override
  String get overtimeHistoryLoadFailed => 'تعذر تحميل سجل العمل الإضافي.';

  @override
  String get overtimeHistoryEmpty => 'لا يوجد سجل عمل إضافي بعد.';

  @override
  String get overtimeAdminEmpty => 'لم يتم العثور على جلسات عمل إضافي.';

  @override
  String get overtimeSearchTechnician => 'بحث باسم الفني أو البريد الإلكتروني';

  @override
  String get overtimeTechnicianInfo => 'معلومات الفني';

  @override
  String get overtimeSessionInfo => 'معلومات الجلسة';

  @override
  String get overtimeEndTime => 'وقت الانتهاء';

  @override
  String get overtimeTotalDuration => 'إجمالي ساعات العمل';

  @override
  String get overtimeWorkingDuration => 'ساعات العمل الرسمية';

  @override
  String get overtimeRejectionReason => 'سبب الرفض';

  @override
  String overtimeRejectionReasonLine(String reason) {
    return 'سبب الرفض: $reason';
  }

  @override
  String get overtimeApprovedBy => 'وافق عليه';

  @override
  String get overtimeApprovedAt => 'تاريخ الموافقة';

  @override
  String get overtimeRejectedBy => 'رفضه';

  @override
  String get overtimeRejectedAt => 'تاريخ الرفض';

  @override
  String get overtimeImages => 'الصور';

  @override
  String get overtimeStartPhoto => 'صورة البداية';

  @override
  String get overtimeEndPhoto => 'صورة النهاية';

  @override
  String get overtimeDeviceInfo => 'معلومات الجهاز';

  @override
  String get overtimeStartDevice => 'جهاز البداية';

  @override
  String get overtimeEndDevice => 'جهاز النهاية';

  @override
  String get overtimeNoPhotoAvailable => 'لا توجد صورة';

  @override
  String get overtimeRejectDialogTitle => 'رفض العمل الإضافي';

  @override
  String get overtimeRejectReasonHint => 'سبب الرفض (اختياري)';

  @override
  String get overtimeApprovedMessage => 'تمت الموافقة على العمل الإضافي.';

  @override
  String get overtimeRejectedMessage => 'تم رفض العمل الإضافي.';

  @override
  String overtimeDurationLine(String duration) {
    return 'المدة: $duration';
  }

  @override
  String get overtimeStatusRunning => 'جاري';

  @override
  String get overtimeStatusPendingReview => 'قيد المراجعة';

  @override
  String get overtimeStatusPendingSync => 'بانتظار المزامنة';

  @override
  String get overtimeStatusSynced => 'تمت المزامنة';

  @override
  String get overtimeStatusApproved => 'معتمد';

  @override
  String get overtimeStatusRejected => 'مرفوض';

  @override
  String get overtimeStatusCancelled => 'ملغى';

  @override
  String get overtimeStartLocation => 'موقع البداية';

  @override
  String get overtimeEndLocation => 'موقع النهاية';

  @override
  String get overtimeRoute => 'المسار';

  @override
  String get overtimeStartAddress => 'عنوان البداية';

  @override
  String get overtimeEndAddress => 'عنوان النهاية';

  @override
  String get overtimeMapLoadFailed => 'تعذر تحميل خريطة البلاط';

  @override
  String get overtimeMapCheckConnection => 'تحقق من اتصالك وأعد المحاولة.';

  @override
  String get overtimeOpenInGoogleMaps => 'فتح في خرائط Google';

  @override
  String get overtimeOpenLiveLocation => 'فتح الموقع المباشر';

  @override
  String get overtimeLocationUnavailable => 'الموقع غير متاح';

  @override
  String get overtimeUnableOpenGoogleMaps => 'تعذر فتح خرائط Google.';

  @override
  String get workOrderSaved => 'تم الحفظ';

  @override
  String get workOrderJobTitleRequired => 'عنوان المهمة مطلوب';

  @override
  String get workOrderJobTitleMaxLength =>
      'يجب ألا يتجاوز عنوان المهمة 200 حرف';

  @override
  String get workOrderUpdated => 'تم تحديث أمر العمل';

  @override
  String get workOrderCreated => 'تم إنشاء أمر العمل';

  @override
  String get workOrderNoPermission => 'ليس لديك صلاحية لإدارة أوامر العمل.';

  @override
  String get workOrderOverview => 'نظرة عامة';

  @override
  String get workOrderOverviewSubtitle => 'العميل والموقع وتفاصيل المهمة';

  @override
  String get workOrderViewOnMap => 'عرض على الخريطة';

  @override
  String get workOrderCouldNotOpenMaps => 'تعذر فتح الخرائط';

  @override
  String get workOrderWorkDescription => 'وصف العمل';

  @override
  String get workOrderInternalNotes => 'ملاحظات داخلية';

  @override
  String get workOrderDocument => 'مستند';

  @override
  String get workOrderBeforeWork => 'قبل العمل';

  @override
  String get workOrderBeforeWorkSubtitleEdit =>
      'التقط صور الموقع وملاحظات اختيارية';

  @override
  String get workOrderBeforeWorkSubtitleView => 'أدلة ما قبل العمل';

  @override
  String get workOrderBeforePhotos => 'صور قبل العمل';

  @override
  String get workOrderSavedBeforeNotes => 'ملاحظات قبل العمل المحفوظة';

  @override
  String get workOrderBeforeNotes => 'ملاحظات قبل العمل';

  @override
  String get workOrderBeforeNotesHint => 'ملاحظات اختيارية قبل بدء العمل';

  @override
  String get workOrderInProgress => 'قيد التنفيذ';

  @override
  String get workOrderInProgressSubtitle => 'صور التقدم وملاحظات الميدان';

  @override
  String get workOrderProgressPhotos => 'صور التقدم';

  @override
  String get workOrderProgressNotes => 'ملاحظات التقدم';

  @override
  String get workOrderNoProgressNotes => 'لا توجد ملاحظات تقدم بعد';

  @override
  String get workOrderAddProgressNote => 'إضافة ملاحظة تقدم';

  @override
  String get workOrderProgressNoteHint => 'ما التقدم الذي تم إحرازه؟';

  @override
  String get workOrderCompleteWork => 'إكمال العمل';

  @override
  String get workOrderCompleteWorkSubtitleEdit =>
      'يلزم صورة واحدة على الأقل بعد العمل';

  @override
  String get workOrderCompleteWorkSubtitleView => 'أدلة الإكمال';

  @override
  String get workOrderCompletionNotes => 'ملاحظات الإكمال';

  @override
  String get workOrderCompletionNotesHint => 'ملاحظات اختيارية عند الإكمال';

  @override
  String get workOrderCompletionNotesOptional => 'ملاحظات الإكمال (اختياري)';

  @override
  String get workOrderAfterPhotos => 'صور بعد العمل';

  @override
  String get workOrderAfterPhotoRequired =>
      'أضف صورة واحدة على الأقل بعد العمل قبل الإكمال.';

  @override
  String get workOrderAfterPhotoRequiredSnackbar =>
      'أضف صورة واحدة على الأقل بعد العمل قبل الإكمال';

  @override
  String get workOrderCapturedLocations => 'المواقع المسجلة';

  @override
  String get workOrderCapturedLocationsSubtitle => 'نقاط GPS من الميدان';

  @override
  String get workOrderLocationStarted => 'بدء';

  @override
  String get workOrderLocationCompleted => 'اكتمل';

  @override
  String get workOrderOpenMap => 'فتح الخريطة';

  @override
  String get workOrderSaveNotes => 'حفظ الملاحظات';

  @override
  String get workOrderTakePhoto => 'التقاط صورة';

  @override
  String get workOrderChooseFromGallery => 'اختيار من المعرض';

  @override
  String workOrderHideNote(String title) {
    return 'إخفاء $title';
  }

  @override
  String get workOrderTimeline => 'الجدول الزمني';

  @override
  String get workOrderTimelineSubtitle => 'سجل النشاط (للقراءة فقط)';

  @override
  String get workOrderTimelineEmpty => 'سيظهر النشاط مع تقدم أمر العمل.';

  @override
  String get workOrderSystem => 'النظام';

  @override
  String get workOrderNoPhotosYet => 'لا توجد صور بعد';

  @override
  String get workOrderDeleteConfirm =>
      'هل أنت متأكد أنك تريد حذف أمر العمل هذا؟';

  @override
  String get workOrderRejectionReason => 'سبب الرفض';

  @override
  String get workOrderReasonOptional => 'السبب (اختياري)';

  @override
  String get workOrderNoTechnicians => 'لا يوجد فنيون متاحون';

  @override
  String get workOrderAccepted => 'تم قبول أمر العمل';

  @override
  String get workOrderRejected => 'تم رفض أمر العمل';

  @override
  String get workOrderStarted => 'بدأ العمل';

  @override
  String get workOrderCompletedMessage => 'تم إكمال أمر العمل';

  @override
  String get workOrderCancelledMessage => 'تم إلغاء أمر العمل';

  @override
  String get workOrderTechnicianAssigned => 'تم تعيين الفني';

  @override
  String get workOrderDeleted => 'تم حذف أمر العمل';

  @override
  String get workOrderBeforeWorkSaved => 'تم حفظ تفاصيل ما قبل العمل';

  @override
  String get workOrderProgressNoteAdded => 'تمت إضافة ملاحظة التقدم';

  @override
  String get workOrderProgressPhotoUploaded => 'تم رفع صورة التقدم';

  @override
  String get workOrderAfterPhotoUploaded => 'تم رفع صورة ما بعد العمل';

  @override
  String get workOrderPhotoRemoved => 'تمت إزالة الصورة';

  @override
  String get workOrderStatusPending => 'معلق';

  @override
  String get workOrderStatusAssigned => 'معين';

  @override
  String get workOrderStatusAccepted => 'مقبول';

  @override
  String get workOrderStatusRejected => 'مرفوض';

  @override
  String get workOrderStatusInProgress => 'قيد التنفيذ';

  @override
  String get workOrderStatusCompleted => 'مكتمل';

  @override
  String get workOrderStatusCancelled => 'ملغى';

  @override
  String get workOrderPriorityLow => 'منخفض';

  @override
  String get workOrderPriorityMedium => 'متوسط';

  @override
  String get workOrderPriorityHigh => 'مرتفع';

  @override
  String get workOrderPriorityCritical => 'حرج';

  @override
  String get workOrderTimelineCreated => 'تم الإنشاء';

  @override
  String get workOrderTimelineAssigned => 'تم التعيين';

  @override
  String get workOrderTimelineAccepted => 'تم القبول';

  @override
  String get workOrderTimelineRejected => 'تم الرفض';

  @override
  String get workOrderTimelineStarted => 'بدأ';

  @override
  String get workOrderTimelineCompleted => 'اكتمل';

  @override
  String get workOrderTimelineCancelled => 'ألغي';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errorForbidden => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get errorServer => 'خطأ في الخادم. يرجى المحاولة لاحقًا.';

  @override
  String get errorRequestTimeout => 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String get errorUnableToReachServer => 'تعذر الوصول إلى الخادم.';

  @override
  String get errorNoInternet =>
      'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';

  @override
  String get errorSecureConnectionFailed =>
      'فشل الاتصال الآمن. يرجى المحاولة مرة أخرى.';

  @override
  String get errorRequestFailed => 'فشل الطلب';

  @override
  String get errorUnexpectedNetworkError =>
      'خطأ غير متوقع في الشبكة. يرجى المحاولة مرة أخرى.';

  @override
  String get attendanceAlreadyClockedIn =>
      'لقد قمت بتسجيل الحضور اليوم بالفعل.';

  @override
  String get attendanceMustClockInBeforeOut =>
      'يجب تسجيل الحضور قبل تسجيل الانصراف.';

  @override
  String get attendanceEndBreakBeforeOut =>
      'أنهِ الاستراحة الحالية قبل تسجيل الانصراف.';

  @override
  String get attendanceAlreadyClockedOut =>
      'لقد قمت بتسجيل الانصراف اليوم بالفعل.';

  @override
  String get attendanceMustClockInBeforeBreak =>
      'يجب تسجيل الحضور قبل بدء الاستراحة.';

  @override
  String get attendanceBreakAlreadyInProgress =>
      'هناك استراحة قيد التقدم بالفعل.';

  @override
  String get attendanceNoActiveBreak => 'لا توجد استراحة نشطة لإنهائها.';

  @override
  String attendanceGpsAccuracyExceeded(String accuracy, String threshold) {
    return 'دقة الموقع ($accuracyم) تتجاوز الحد المسموح ($thresholdم). انتقل إلى منطقة مفتوحة وحاول مرة أخرى.';
  }

  @override
  String get attendanceWebOfflinePhotoRequired =>
      'حضور الصور يتطلب اتصالًا بالإنترنت على الويب. أعد الاتصال وحاول مرة أخرى.';

  @override
  String get locationServicesDisabled =>
      'خدمات الموقع معطلة. فعّل GPS للمتابعة.';

  @override
  String get locationPermissionRequired =>
      'إذن الموقع مطلوب لتسجيل الحضور أو الانصراف.';

  @override
  String get locationPermissionDeniedForever =>
      'تم رفض إذن الموقع بشكل دائم. فعّله من إعدادات الجهاز.';

  @override
  String get locationTimeout =>
      'تعذر تحديد موقعك في الوقت المحدد. حاول مرة أخرى.';

  @override
  String get cameraUnavailable =>
      'الكاميرا غير متاحة. مطلوب التقاط صورة مباشرة.';

  @override
  String get authNoActiveSession => 'لا توجد جلسة نشطة.';

  @override
  String get authOfflineRestoreProfile =>
      'وضع عدم الاتصال. اتصل مرة واحدة لاستعادة ملفك الشخصي.';

  @override
  String get overtimeNoRunningSession =>
      'لا توجد جلسة عمل إضافي قيد التشغيل لإنهائها.';

  @override
  String get assetsQrScannerNotReady =>
      'مسح رمز QR سيكون متاحًا في إصدار لاحق.';

  @override
  String get orgStatusActive => 'نشط';

  @override
  String get orgStatusInactive => 'غير نشط';

  @override
  String get errorInvalidEmail => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errorInvalidPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get errorUserDisabled => 'هذا الحساب معطل. تواصل مع المسؤول.';

  @override
  String get errorClockSkew =>
      'يبدو أن وقت الجهاز غير صحيح. زامن الساعة وحاول مرة أخرى.';

  @override
  String get errorGpsRequired => 'الموقع مطلوب للمتابعة.';

  @override
  String get errorLivePhotoRequired => 'مطلوب التقاط صورة مباشرة.';

  @override
  String get errorWorkOrderNotFound => 'أمر العمل غير موجود.';

  @override
  String get errorNotFound => 'العنصر المطلوب غير موجود.';

  @override
  String get errorUnauthorized => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorValidation => 'يرجى التحقق من المدخلات والمحاولة مرة أخرى.';

  @override
  String get errorGpsAccuracyTooLow =>
      'دقة الموقع منخفضة جدًا. انتقل إلى منطقة مفتوحة وحاول مرة أخرى.';

  @override
  String get errorDeviceRequired => 'معرف الجهاز مطلوب.';

  @override
  String get errorClientRequestRequired => 'معرف الطلب مطلوب.';

  @override
  String get errorInvalidTimestamp => 'تاريخ أو وقت غير صالح.';

  @override
  String get errorConflict => 'هذا الإجراء يتعارض مع الحالة الحالية.';

  @override
  String get errorUserNotFound => 'المستخدم غير موجود.';

  @override
  String get errorOvertimeNotFound => 'جلسة العمل الإضافي غير موجودة.';

  @override
  String get errorTitleRequired => 'العنوان مطلوب.';

  @override
  String get errorInvalidPriority => 'قيمة الأولوية غير صالحة.';

  @override
  String get errorInvalidDate => 'قيمة التاريخ غير صالحة.';

  @override
  String get errorInvalidStatus => 'قيمة الحالة غير صالحة.';

  @override
  String get errorAvatarRequired => 'صورة الملف الشخصي مطلوبة.';

  @override
  String get errorUploadFailed => 'فشل الرفع. يرجى المحاولة مرة أخرى.';

  @override
  String get valueNotSet => 'غير محدد';

  @override
  String get workOrderAttachmentFallback => 'مرفق';

  @override
  String durationMinutesOnly(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String durationHoursOnly(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      one: 'ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String durationHoursAndMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة و $minutes دقيقة',
      one: 'ساعة واحدة و $minutes دقيقة',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours:$minutes ساعة';
  }

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navAttendance => 'الحضور';

  @override
  String get navWorkOrders => 'أوامر العمل';

  @override
  String get navOvertime => 'العمل الإضافي';

  @override
  String get navProfile => 'أنا';

  @override
  String get eventAuthLogin => 'تم تسجيل الدخول بنجاح';

  @override
  String get eventAuthLoginFailed => 'فشل محاولة تسجيل الدخول';

  @override
  String get eventAuthLogout => 'تم تسجيل الخروج';

  @override
  String get eventAuthTokenRefreshed => 'تم تحديث الجلسة';

  @override
  String get eventAuthGeneric => 'نشاط الحساب';

  @override
  String get eventAttendanceGeneric => 'تحديث الحضور';

  @override
  String get eventOvertimeGeneric => 'تحديث العمل الإضافي';

  @override
  String get eventWorkOrderGeneric => 'تحديث أمر العمل';

  @override
  String get eventInventoryGeneric => 'تحديث المخزون';

  @override
  String get eventAssetsGeneric => 'تحديث الأصل';

  @override
  String get eventPmGeneric => 'تحديث الصيانة';

  @override
  String get eventReportsGeneric => 'تحديث التقرير';

  @override
  String get eventUsersGeneric => 'تحديث المستخدم';

  @override
  String get eventOrganizationGeneric => 'تحديث المؤسسة';

  @override
  String get eventSecurityGeneric => 'حدث أمني';

  @override
  String get eventGenericActivity => 'نشاط النظام';

  @override
  String eventFeedActorLine(String module, String actor) {
    return '$module · $actor';
  }

  @override
  String get settingsAccountOverview => 'الحساب';

  @override
  String get settingsChangePhoto => 'تغيير الصورة';

  @override
  String get settingsPhotoPreview => 'معاينة الصورة';

  @override
  String get settingsPhotoPreviewHint => 'سيتم حفظ صورتك كصورة ملف شخصي مربعة.';

  @override
  String get settingsPhotoUpdated => 'تم تحديث صورة الملف الشخصي';

  @override
  String get settingsPhotoUnsupportedFormat =>
      'يرجى اختيار صورة JPG أو PNG أو WebP.';

  @override
  String get settingsPhotoDecodeFailed => 'تعذر قراءة الصورة المحددة.';

  @override
  String get settingsEmployeeId => 'الرقم الوظيفي';

  @override
  String get settingsBranch => 'الفرع';

  @override
  String get settingsDepartment => 'القسم';

  @override
  String get settingsAccountCreated => 'تاريخ إنشاء الحساب';

  @override
  String get settingsLastLogin => 'آخر تسجيل دخول';

  @override
  String get settingsNotAvailable => 'غير متاح';

  @override
  String get settingsEditablePrefs => 'تفضيلات قابلة للتعديل';

  @override
  String get settingsSyncTitle => 'المزامنة';

  @override
  String get settingsLastSuccessfulSync => 'آخر مزامنة ناجحة';

  @override
  String get settingsPendingUploads => 'عمليات الرفع المعلقة';

  @override
  String get settingsPendingDownloads => 'عمليات التنزيل المعلقة';

  @override
  String get settingsSyncStatus => 'حالة المزامنة';

  @override
  String get settingsAutoSync => 'مزامنة تلقائية';

  @override
  String get settingsWifiOnlySync => 'Wi‑Fi فقط';

  @override
  String get settingsSyncInterval => 'فاصل المزامنة';

  @override
  String get settingsManualSync => 'مزامنة الآن';

  @override
  String get settingsManualSyncDone => 'تم طلب المزامنة';

  @override
  String get settingsNetworkRequirement => 'متطلبات الشبكة';

  @override
  String get settingsStorageTitle => 'التخزين';

  @override
  String get settingsCacheSize => 'حجم التخزين المؤقت';

  @override
  String get settingsImagesSize => 'ذاكرة الصور';

  @override
  String get settingsTempFiles => 'الملفات المؤقتة';

  @override
  String get settingsManagedByOs => 'يديرها النظام';

  @override
  String get settingsClearCache => 'مسح التخزين المؤقت';

  @override
  String get settingsSupportTitle => 'الدعم';

  @override
  String get settingsContactSupport => 'التواصل مع الدعم';

  @override
  String get settingsReportBug => 'الإبلاغ عن خطأ';

  @override
  String get settingsRequestFeature => 'طلب ميزة';

  @override
  String get settingsFaq => 'الأسئلة الشائعة';

  @override
  String get settingsSecurityTitle => 'الأمان';

  @override
  String get settingsCurrentSession => 'الجلسة الحالية';

  @override
  String get settingsDeviceName => 'اسم الجهاز';

  @override
  String get settingsBiometricStatus => 'تسجيل الدخول البيومتري';

  @override
  String get settingsBiometricAvailable => 'متاح على هذا الجهاز';

  @override
  String get settingsBiometricUnavailable => 'غير متاح';

  @override
  String get settingsLogoutAllDevices => 'تسجيل الخروج من كل الأجهزة';

  @override
  String get settingsApplicationTitle => 'التطبيق';

  @override
  String get settingsPerformanceTitle => 'الأداء';

  @override
  String get settingsMemoryUsage => 'استخدام الذاكرة';

  @override
  String get settingsCacheUsage => 'استخدام التخزين المؤقت';

  @override
  String get settingsNetworkLatency => 'زمن استجابة الشبكة';

  @override
  String get settingsDatabaseConnection => 'اتصال قاعدة البيانات';

  @override
  String get settingsServerHealth => 'صحة الخادم';

  @override
  String get settingsUseServerMgmt => 'راجع إدارة الخادم';

  @override
  String get settingsAccessibilityTitle => 'إمكانية الوصول';

  @override
  String get settingsLargeText => 'نص كبير';

  @override
  String get settingsReduceAnimations => 'تقليل الحركات';

  @override
  String get settingsHighContrast => 'تباين عالٍ';

  @override
  String get settingsBackupUnavailable => 'النسخ الاحتياطي غير متاح بعد.';

  @override
  String get settingsRestoreUnavailable => 'الاستعادة غير متاحة بعد.';

  @override
  String get settingsDangerZone => 'منطقة الخطر';

  @override
  String get settingsDangerZoneHint =>
      'هذه الإجراءات تعيد ضبط التفضيلات المحلية والتخزين المؤقت فقط. لا يتم حذف بيانات العمل.';

  @override
  String get settingsResetPreferences => 'إعادة ضبط التفضيلات';

  @override
  String get settingsResetPreferencesConfirm =>
      'إعادة ضبط اللغة والمظهر والإشعارات والمزامنة وإمكانية الوصول؟';

  @override
  String get settingsClearCacheConfirm =>
      'مسح ذاكرة الصور المحلية؟ لن يتم حذف بيانات المستخدم.';

  @override
  String get settingsRestoreDefaults => 'استعادة الإعدادات الافتراضية';

  @override
  String get settingsRestoreDefaultsConfirm =>
      'استعادة كل التفضيلات الافتراضية ومسح التخزين المؤقت المحلي؟';

  @override
  String get settingsPrefsRestored => 'تمت استعادة التفضيلات';

  @override
  String get settingsConfirm => 'تأكيد';

  @override
  String get settingsUpdateCenter => 'مركز التحديثات';

  @override
  String get settingsLatestVersion => 'أحدث إصدار متاح';

  @override
  String get settingsReleaseChannel => 'قناة الإصدار';

  @override
  String get settingsReleaseDate => 'تاريخ الإصدار';

  @override
  String get settingsUpdateStatus => 'حالة التحديث';

  @override
  String get settingsUpdateIdle => 'لم يتم الفحص بعد';

  @override
  String get settingsUpdateChecking => 'جارٍ الفحص…';

  @override
  String get settingsUpdateUpToDate => 'محدَّث';

  @override
  String get settingsUpdateAvailable => 'يتوفر تحديث';

  @override
  String get settingsUpdateFailed => 'تعذر الفحص';

  @override
  String get settingsCheckForUpdates => 'التحقق من التحديثات';

  @override
  String get settingsViewReleaseNotes => 'عرض ملاحظات الإصدار';

  @override
  String get settingsDownloadUpdate => 'تنزيل التحديث';

  @override
  String get settingsDownloadUpdateSoon => 'سيتم توفير التنزيل لاحقاً.';

  @override
  String get settingsAdminLogs => 'سجلات التطبيق';

  @override
  String get settingsSearchLogs => 'بحث في السجلات';

  @override
  String get settingsLogAll => 'الكل';

  @override
  String get settingsLogCategoryAll => 'كل الفئات';

  @override
  String get settingsCopyLogs => 'نسخ السجلات';

  @override
  String get settingsExportLogs => 'تصدير السجلات';

  @override
  String get settingsClearLogs => 'مسح السجلات';

  @override
  String get settingsLogsCopied => 'تم نسخ السجلات';

  @override
  String get settingsLogEntries => 'إدخالات السجل';

  @override
  String get settingsNoLogs => 'لا توجد سجلات بعد';

  @override
  String get settingsDeveloperOptions => 'خيارات المطور';

  @override
  String get settingsFeatureFlags => 'أعلام الميزات';

  @override
  String get settingsReadOnly => 'للقراءة فقط';

  @override
  String get settingsNoFeatureFlags => 'لا توجد أعلام ميزات';

  @override
  String get settingsNotifAttendance => 'إشعارات الحضور';

  @override
  String get settingsNotifTasks => 'إشعارات أوامر العمل';

  @override
  String get settingsNotifOvertime => 'إشعارات العمل الإضافي';

  @override
  String get settingsNotifSync => 'إشعارات المزامنة';

  @override
  String get settingsNotifUpdates => 'إشعارات التحديثات';

  @override
  String get settingsThemePreview => 'معاينة المظهر';

  @override
  String get settingsThemePreviewBody =>
      'للعرض فقط — بدّل بين الفاتح والداكن أدناه لمعاينة المكونات. هذا لا يغيّر مظهر التطبيق.';

  @override
  String get settingsAboutApp => 'حول التطبيق';

  @override
  String get settingsDeveloper => 'المطور';

  @override
  String settingsCopyright(String year, String company) {
    return 'حقوق النشر © $year $company. جميع الحقوق محفوظة.';
  }

  @override
  String get settingsOpenSourcePackages => 'حزم مفتوحة المصدر';

  @override
  String get settingsSectionPreferences => 'التفضيلات';

  @override
  String get settingsSectionSecurity => 'الأمان والخصوصية';

  @override
  String get settingsSectionSupport => 'المساعدة والدعم';

  @override
  String get settingsSectionDeveloper => 'المطور';

  @override
  String get settingsDiagDevice => 'الجهاز';

  @override
  String get settingsDiagNetwork => 'الشبكة';

  @override
  String get settingsDiagServer => 'الخادم';

  @override
  String get settingsDiagApi => 'واجهة البرمجة';

  @override
  String get settingsDiagDatabase => 'قاعدة البيانات';

  @override
  String get settingsDiagAuth => 'المصادقة';

  @override
  String get settingsDiagPerformance => 'الأداء';

  @override
  String get serverMgmtBadgeHttps => 'HTTPS آمن';

  @override
  String get serverMgmtBadgeLocal => 'محلي';

  @override
  String get serverMgmtBadgeDevelopment => 'تطوير';

  @override
  String get serverMgmtBadgeProduction => 'إنتاج';

  @override
  String get settingsLogLevelDebug => 'تصحيح';

  @override
  String get settingsLogLevelInfo => 'معلومة';

  @override
  String get settingsLogLevelWarning => 'تحذير';

  @override
  String get settingsLogLevelError => 'خطأ';

  @override
  String get settingsLogCategoryNetwork => 'الشبكة';

  @override
  String get settingsLogCategoryAuth => 'المصادقة';

  @override
  String get settingsLogCategorySync => 'المزامنة';

  @override
  String get permGroupDashboardDesc =>
      'الصلاحيات الخاصة بعرض إحصائيات النظام والمؤشرات الرئيسية.';

  @override
  String get permGroupUsersDesc => 'الصلاحيات الخاصة بإدارة حسابات المستخدمين.';

  @override
  String get permGroupRolesDesc =>
      'الصلاحيات الخاصة بإدارة الأدوار وتوزيع الصلاحيات.';

  @override
  String get permGroupAttendanceDesc =>
      'الصلاحيات الخاصة بإدارة ومراجعة سجلات حضور الموظفين.';

  @override
  String get permGroupOvertimeDesc =>
      'الصلاحيات الخاصة بإنشاء واعتماد وإدارة جلسات العمل الإضافي.';

  @override
  String get permGroupInventoryDesc =>
      'الصلاحيات الخاصة بإدارة الأصناف والكميات داخل المخزون.';

  @override
  String get permGroupAssetsDesc =>
      'الصلاحيات الخاصة بإدارة وتتبع أصول المؤسسة.';

  @override
  String get permGroupMaintenanceDesc =>
      'الصلاحيات الخاصة بخطط الصيانة والعمليات المرتبطة بها.';

  @override
  String get permGroupServiceReportsDesc =>
      'الصلاحيات الخاصة بعرض وإنشاء وتنزيل تقارير الخدمة.';

  @override
  String get permGroupWorkOrdersDesc =>
      'الصلاحيات الخاصة بإنشاء وإدارة وتنفيذ أوامر العمل.';

  @override
  String get permGroupSettingsDesc =>
      'الصلاحيات الخاصة بإعدادات النظام والمؤسسة.';

  @override
  String get permGroupProfileDesc =>
      'الصلاحيات الخاصة بإدارة الملف الشخصي للمستخدم.';

  @override
  String get permGroupNotificationsDesc =>
      'الصلاحيات الخاصة بالإشعارات وإرسالها واستقبالها.';

  @override
  String get permGroupOrganizationDesc =>
      'الصلاحيات الخاصة بإدارة هيكل المؤسسة والفروع والأقسام.';

  @override
  String get permGroupAuditDesc =>
      'الصلاحيات الخاصة بمراجعة سجل الأنشطة والتغييرات.';

  @override
  String get permGroupGeneralDesc =>
      'صلاحيات عامة في المنصة غير مرتبطة بوحدة محددة.';

  @override
  String get permOrganizationView => 'عرض المؤسسة';

  @override
  String get permOrganizationViewDesc =>
      'يسمح بالاطلاع على هيكل المؤسسة والفروع وشاشات الدليل.';

  @override
  String get permOrganizationManageBranches => 'إدارة الفروع';

  @override
  String get permOrganizationManageBranchesDesc =>
      'يسمح بإنشاء وتعديل فروع الشركة المستخدمة على مستوى المؤسسة.';

  @override
  String get permOrganizationManageRegions => 'إدارة المناطق';

  @override
  String get permOrganizationManageRegionsDesc =>
      'يسمح بإنشاء وتعديل المناطق الجغرافية المستخدمة في هيكل المؤسسة.';

  @override
  String get permOrganizationManageCities => 'إدارة المدن';

  @override
  String get permOrganizationManageCitiesDesc =>
      'يسمح بإنشاء وتعديل المدن المرتبطة بالفروع والعمليات الميدانية.';

  @override
  String get permOrganizationManageDepartments => 'إدارة الأقسام';

  @override
  String get permOrganizationManageDepartmentsDesc =>
      'يسمح بإنشاء وتعديل الأقسام التي تنظّم المستخدمين والفرق.';

  @override
  String get permOrganizationManageTeams => 'إدارة الفرق';

  @override
  String get permOrganizationManageTeamsDesc =>
      'يسمح بإنشاء وتعديل فرق العمل وأعضائها التشغيليين.';

  @override
  String get permOrganizationManageUsers => 'إدارة مستخدمي المؤسسة';

  @override
  String get permOrganizationManageUsersDesc =>
      'يسمح بتعيين المستخدمين ضمن الفروع والأقسام والفرق.';

  @override
  String get permSettingsView => 'عرض الإعدادات';

  @override
  String get permSettingsViewDesc =>
      'يسمح بفتح شاشات إعدادات النظام دون تعديل أي قيم.';

  @override
  String get permSettingsManage => 'إدارة إعدادات النظام';

  @override
  String get permSettingsManageDesc =>
      'يسمح بتعديل الإعدادات العامة التي تؤثر على جميع مستخدمي النظام.';

  @override
  String get permSettingsUpdate => 'تعديل إعدادات النظام';

  @override
  String get permSettingsUpdateDesc =>
      'يسمح بحفظ تعديلات قيم إعدادات النظام على مستوى المؤسسة.';

  @override
  String get permSettingsManageHolidays => 'إدارة العطل';

  @override
  String get permSettingsManageHolidaysDesc =>
      'يسمح بتعريف عطل الشركة التي تؤثر على الحضور والعمل الإضافي.';

  @override
  String get permAuditView => 'عرض سجل التدقيق';

  @override
  String get permAuditViewDesc =>
      'يسمح بمراجعة سجل الأنشطة والتغييرات الأمنية على مستوى المؤسسة.';

  @override
  String get permDashboardView => 'عرض لوحة التحكم';

  @override
  String get permDashboardViewDesc =>
      'يسمح بمشاهدة الإحصائيات والمؤشرات الرئيسية الخاصة بالنظام.';

  @override
  String get permRbacManageRoles => 'إدارة الأدوار والصلاحيات';

  @override
  String get permRbacManageRolesDesc =>
      'يسمح بالتحكم الكامل في الأدوار والصلاحيات المعينة لكل دور.';

  @override
  String get permRbacManagePermissions => 'إدارة الصلاحيات';

  @override
  String get permRbacManagePermissionsDesc =>
      'يسمح بالتحكم في كيفية تعيين الصلاحيات من كتالوج الوصول.';

  @override
  String get permRolesView => 'عرض الأدوار';

  @override
  String get permRolesViewDesc =>
      'يسمح بفتح قائمة الأدوار ومراجعة تعريفات الأدوار الحالية.';

  @override
  String get permRolesCreate => 'إضافة الأدوار';

  @override
  String get permRolesCreateDesc =>
      'يسمح بإنشاء أدوار جديدة وتحديد الصلاحيات الخاصة بها.';

  @override
  String get permRolesUpdate => 'تعديل الأدوار';

  @override
  String get permRolesUpdateDesc =>
      'يسمح بتعديل صلاحيات وأسماء الأدوار الموجودة.';

  @override
  String get permRolesDelete => 'حذف الأدوار';

  @override
  String get permRolesDeleteDesc =>
      'يسمح بحذف الأدوار التي لم يعد هناك حاجة إليها بشكل دائم.';

  @override
  String get permRolesManage => 'إدارة الأدوار والصلاحيات';

  @override
  String get permRolesManageDesc =>
      'يسمح بإنشاء وتعديل وتعيين الأدوار ومجموعات صلاحياتها.';

  @override
  String get permAttendanceViewOwn => 'عرض الحضور الخاص';

  @override
  String get permAttendanceViewOwnDesc =>
      'يسمح بمراجعة سجلات حضوره الشخصي فقط.';

  @override
  String get permAttendanceViewTeam => 'عرض حضور الفريق';

  @override
  String get permAttendanceViewTeamDesc =>
      'يسمح بالاطلاع على سجلات حضور أعضاء الفريق التابع له.';

  @override
  String get permAttendanceViewAll => 'عرض كل الحضور';

  @override
  String get permAttendanceViewAllDesc =>
      'يسمح بعرض جميع سجلات الحضور داخل المؤسسة.';

  @override
  String get permAttendanceManageOwn => 'إدارة الحضور الخاص';

  @override
  String get permAttendanceManageOwnDesc =>
      'يسمح بإنشاء وتعديل سجلات الحضور الشخصية للمستخدم فقط.';

  @override
  String get permAttendanceView => 'عرض الحضور';

  @override
  String get permAttendanceViewDesc =>
      'يسمح بفتح شاشات الحضور للسجلات ضمن نطاق صلاحية المستخدم.';

  @override
  String get permAttendanceUpdate => 'إدارة الحضور';

  @override
  String get permAttendanceUpdateDesc =>
      'يسمح بإنشاء وتعديل واعتماد وإدارة سجلات الحضور.';

  @override
  String get permAttendanceApprove => 'اعتماد الحضور';

  @override
  String get permAttendanceApproveDesc =>
      'يسمح باعتماد سجلات الحضور قبل تثبيتها بشكل نهائي.';

  @override
  String get permOvertimeViewOwn => 'عرض العمل الإضافي الخاص';

  @override
  String get permOvertimeViewOwnDesc =>
      'يسمح بمراجعة جلسات العمل الإضافي الخاصة بالمستخدم وحالتها فقط.';

  @override
  String get permOvertimeViewTeam => 'عرض العمل الإضافي للفريق';

  @override
  String get permOvertimeViewTeamDesc =>
      'يسمح بالاطلاع على جلسات العمل الإضافي الخاصة بأعضاء الفريق.';

  @override
  String get permOvertimeViewAll => 'عرض كل العمل الإضافي';

  @override
  String get permOvertimeViewAllDesc =>
      'يسمح بعرض جميع جلسات العمل الإضافي داخل المؤسسة.';

  @override
  String get permOvertimeCreate => 'إنشاء العمل الإضافي';

  @override
  String get permOvertimeCreateDesc =>
      'يسمح بإنشاء طلبات عمل إضافي جديدة للموظفين.';

  @override
  String get permOvertimeStart => 'بدء العمل الإضافي';

  @override
  String get permOvertimeStartDesc =>
      'يسمح ببدء جلسة عمل إضافي وتسجيل وقت وموقع البداية.';

  @override
  String get permOvertimeEnd => 'إنهاء العمل الإضافي';

  @override
  String get permOvertimeEndDesc =>
      'يسمح بإنهاء جلسة عمل إضافي نشطة وتسليم تفاصيل الإغلاق.';

  @override
  String get permOvertimeCancel => 'إلغاء العمل الإضافي';

  @override
  String get permOvertimeCancelDesc =>
      'يسمح بإلغاء جلسة عمل إضافي حتى لا تُحتسب ضمن وقت العمل.';

  @override
  String get permOvertimeApprove => 'اعتماد العمل الإضافي';

  @override
  String get permOvertimeApproveDesc =>
      'يسمح بالموافقة على طلبات العمل الإضافي قبل احتسابها.';

  @override
  String get permOvertimeReject => 'رفض العمل الإضافي';

  @override
  String get permOvertimeRejectDesc =>
      'يسمح برفض طلبات العمل الإضافي مع الاحتفاظ بسجل القرار.';

  @override
  String get permOvertimeArchive => 'أرشفة العمل الإضافي';

  @override
  String get permOvertimeArchiveDesc =>
      'يسمح بأرشفة سجلات العمل الإضافي المكتملة لإبقاء القوائم النشطة مرتبة.';

  @override
  String get permWorkOrdersViewOwn => 'عرض أوامر العمل الخاصة';

  @override
  String get permWorkOrdersViewOwnDesc =>
      'يسمح بعرض أوامر العمل المعينة للمستخدم فقط.';

  @override
  String get permWorkOrdersViewTeam => 'عرض أوامر عمل الفريق';

  @override
  String get permWorkOrdersViewTeamDesc =>
      'يسمح بالاطلاع على أوامر العمل الخاصة بالفريق التابع للمستخدم.';

  @override
  String get permWorkOrdersViewAll => 'عرض كل أوامر العمل';

  @override
  String get permWorkOrdersViewAllDesc =>
      'يسمح بعرض جميع أوامر العمل داخل المؤسسة.';

  @override
  String get permWorkOrdersCreate => 'إنشاء أوامر العمل';

  @override
  String get permWorkOrdersCreateDesc =>
      'يسمح بإنشاء أوامر عمل جديدة وتعيينها للموظفين.';

  @override
  String get permWorkOrdersUpdate => 'تعديل أوامر العمل';

  @override
  String get permWorkOrdersUpdateDesc =>
      'يسمح بتعديل تفاصيل أوامر العمل الحالية ضمن النطاق المسموح.';

  @override
  String get permWorkOrdersAssign => 'تعيين أوامر العمل';

  @override
  String get permWorkOrdersAssignDesc =>
      'يسمح بتعيين أو إعادة تعيين الفنيين من شاشات أوامر العمل.';

  @override
  String get permWorkOrdersComplete => 'إكمال أوامر العمل';

  @override
  String get permWorkOrdersCompleteDesc =>
      'يسمح بتغيير حالة أمر العمل إلى مكتمل بعد الانتهاء منه.';

  @override
  String get permWorkOrdersCancel => 'إلغاء أوامر العمل';

  @override
  String get permWorkOrdersCancelDesc =>
      'يسمح بإلغاء أوامر العمل حتى تتوقف عن الظهور كنشيطة للفريق الميداني.';

  @override
  String get permWorkOrdersDelete => 'حذف أوامر العمل';

  @override
  String get permWorkOrdersDeleteDesc =>
      'يسمح بحذف أوامر العمل نهائياً من سجلات المؤسسة.';

  @override
  String get permInventoryView => 'عرض المخزون';

  @override
  String get permInventoryViewDesc =>
      'يسمح بالاطلاع على أصناف المخزون والكميات المتوفرة.';

  @override
  String get permInventoryCreate => 'إضافة المخزون';

  @override
  String get permInventoryCreateDesc =>
      'يسمح بتسجيل أصناف مخزون جديدة في دليل المخزون.';

  @override
  String get permInventoryUpdate => 'تعديل المخزون';

  @override
  String get permInventoryUpdateDesc =>
      'يسمح بتعديل تفاصيل أصناف المخزون مثل الأسماء والخصائص.';

  @override
  String get permInventoryDelete => 'حذف المخزون';

  @override
  String get permInventoryDeleteDesc =>
      'يسمح بحذف أصناف المخزون من دليل المؤسسة.';

  @override
  String get permInventoryStockManage => 'إدارة المخزون والكميات';

  @override
  String get permInventoryStockManageDesc =>
      'يسمح بتحديث الكميات المتوفرة وحركة الأصناف داخل المخزون.';

  @override
  String get permAssetsView => 'عرض الأصول';

  @override
  String get permAssetsViewDesc =>
      'يسمح بالاطلاع على بيانات الأصول المسجلة في النظام.';

  @override
  String get permAssetsCreate => 'إضافة الأصول';

  @override
  String get permAssetsCreateDesc =>
      'يسمح بتسجيل أصول جديدة للشركة في سجل الأصول.';

  @override
  String get permAssetsUpdate => 'تعديل الأصول';

  @override
  String get permAssetsUpdateDesc =>
      'يسمح بتعديل بيانات الأصول مثل الحالة والموقع والخصائص.';

  @override
  String get permAssetsDelete => 'حذف الأصول';

  @override
  String get permAssetsDeleteDesc => 'يسمح بحذف الأصول نهائياً من سجل المؤسسة.';

  @override
  String get permAssetsAssign => 'تخصيص الأصول';

  @override
  String get permAssetsAssignDesc =>
      'يسمح بتخصيص الأصول للمستخدمين أو المواقع داخل المؤسسة.';

  @override
  String get permPmView => 'عرض الصيانة';

  @override
  String get permPmViewDesc => 'يسمح بفتح شاشات خطط وجداول الصيانة الوقائية.';

  @override
  String get permPmCreate => 'إنشاء خطط الصيانة';

  @override
  String get permPmCreateDesc =>
      'يسمح بإنشاء جداول وخطط الصيانة الدورية للأصول.';

  @override
  String get permPmUpdate => 'تعديل الصيانة';

  @override
  String get permPmUpdateDesc =>
      'يسمح بتعديل خطط الصيانة الحالية ومواعيدها وتفاصيلها.';

  @override
  String get permPmDelete => 'حذف الصيانة';

  @override
  String get permPmDeleteDesc =>
      'يسمح بحذف خطط الصيانة التي لم يعد هناك حاجة إليها.';

  @override
  String get permPmManage => 'إدارة الصيانة';

  @override
  String get permPmManageDesc =>
      'يسمح بالإدارة الكاملة لخطط وجداول الصيانة الوقائية.';

  @override
  String get permMaintenanceManage => 'إدارة عمليات الصيانة';

  @override
  String get permMaintenanceManageDesc =>
      'يسمح بإدارة عمليات الصيانة والجداول المرتبطة بها.';

  @override
  String get permReportsView => 'عرض تقارير الخدمة';

  @override
  String get permReportsViewDesc =>
      'يسمح بفتح وقراءة تقارير الخدمة المكتملة داخل النظام.';

  @override
  String get permReportsGenerate => 'إنشاء تقارير الخدمة';

  @override
  String get permReportsGenerateDesc =>
      'يسمح بإنشاء تقارير خدمة جديدة من الأعمال الميدانية المكتملة.';

  @override
  String get permReportsDownload => 'تنزيل تقارير الخدمة';

  @override
  String get permReportsDownloadDesc =>
      'يسمح بتنزيل تقارير الخدمة بصيغ قابلة للمشاركة أو الطباعة.';

  @override
  String get permUsersView => 'عرض المستخدمين';

  @override
  String get permUsersViewDesc =>
      'يسمح بفتح قائمة المستخدمين وعرض تفاصيل الحسابات على مستوى المؤسسة.';

  @override
  String get permUsersCreate => 'إضافة المستخدمين';

  @override
  String get permUsersCreateDesc =>
      'يسمح بإنشاء حسابات مستخدمين جديدة داخل المؤسسة.';

  @override
  String get permUsersUpdate => 'تعديل المستخدمين';

  @override
  String get permUsersUpdateDesc =>
      'يسمح بتعديل بيانات الملف الشخصي والاتصال وحساب المستخدم.';

  @override
  String get permUsersDelete => 'حذف المستخدمين';

  @override
  String get permUsersDeleteDesc =>
      'يسمح بحذف حسابات المستخدمين نهائياً من المؤسسة.';

  @override
  String get permUsersRead => 'عرض المستخدمين';

  @override
  String get permUsersReadDesc =>
      'يسمح بفتح قائمة المستخدمين وعرض تفاصيل الحسابات على مستوى المؤسسة.';

  @override
  String get permUsersResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get permUsersResetPasswordDesc =>
      'يسمح بإعادة تعيين كلمة مرور أي مستخدم دون معرفة كلمة المرور الحالية.';
}
