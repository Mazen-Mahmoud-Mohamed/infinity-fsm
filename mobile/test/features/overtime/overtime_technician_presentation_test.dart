import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/l10n/app_localizations_ar.dart';
import 'package:mobile/core/localization/l10n/app_localizations_en.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_technician_presentation.dart';

void main() {
  late AppLocalizations ar;
  late AppLocalizations en;

  setUp(() {
    ar = AppLocalizationsAr();
    en = AppLocalizationsEn();
  });

  group('technician overtime Arabic presentation', () {
    test('technician keys omit الإضافي while shared admin keys keep it', () {
      expect(ar.overtimeTechnicianTitle, 'العمل');
      expect(ar.overtimeTechnicianNav, 'العمل');
      expect(ar.overtimeTechnicianStart, 'بدء العمل');
      expect(ar.overtimeTechnicianStartTitle, 'بدء رحلة العمل');
      expect(ar.overtimeTechnicianMyHistory, 'وقتي');
      expect(ar.overtimeTechnicianMyTooltip, 'وقتي');
      expect(ar.overtimeTechnicianLoading, 'جاري تحميل العمل...');
      expect(ar.overtimeTechnicianLoadFailed, 'تعذر تحميل العمل.');
      expect(ar.overtimeTechnicianHistoryEmpty, 'لا يوجد سجل عمل بعد.');
      expect(ar.overtimeTechnicianHistoryLoadFailed, 'تعذر تحميل سجل العمل.');
      expect(ar.overtimeTechnicianTypeNormal, 'عمل عادي');
      expect(ar.overtimeTechnicianTypeTravel, 'عمل للسفر');
      expect(ar.overtimeTechnicianContinueExistingSession,
          'لديك بالفعل جلسة عمل قيد التشغيل.');
      expect(ar.overtimeTechnicianEnded,
          'انتهى العمل. تم احتساب العمل المؤهل تلقائياً.');
      expect(ar.overtimeTechnicianNormalStarted, 'بدأ العمل العادي.');
      expect(ar.overtimeTechnicianTravelStarted, 'بدأ العمل للسفر.');
      expect(ar.overtimeTechnicianActiveSessionReminder,
          'جلسة العمل ما زالت قيد التشغيل. لا تنسَ إنهاءها عند الانتهاء.');
      expect(ar.overtimeTechnicianErrorNotFound, 'جلسة العمل غير موجودة.');
      expect(
        ar.overtimeTechnicianNoRunningSession,
        'لا توجد جلسة عمل قيد التشغيل لإنهائها.',
      );

      for (final value in [
        ar.overtimeTechnicianTitle,
        ar.overtimeTechnicianNav,
        ar.overtimeTechnicianStart,
        ar.overtimeTechnicianStartTitle,
        ar.overtimeTechnicianMyHistory,
        ar.overtimeTechnicianMyTooltip,
        ar.overtimeTechnicianLoading,
        ar.overtimeTechnicianLoadFailed,
        ar.overtimeTechnicianHistoryEmpty,
        ar.overtimeTechnicianHistoryLoadFailed,
        ar.overtimeTechnicianTypeNormal,
        ar.overtimeTechnicianTypeTravel,
        ar.overtimeTechnicianContinueExistingSession,
        ar.overtimeTechnicianEnded,
        ar.overtimeTechnicianNormalStarted,
        ar.overtimeTechnicianTravelStarted,
        ar.overtimeTechnicianActiveSessionReminder,
        ar.overtimeTechnicianErrorNotFound,
        ar.overtimeTechnicianNoRunningSession,
      ]) {
        expect(value.contains('الإضافي'), isFalse, reason: value);
        expect(value.contains('إضافي'), isFalse, reason: value);
      }

      // Shared admin / supervisor wording stays unchanged.
      expect(ar.overtime, 'العمل الإضافي');
      expect(ar.navOvertime, 'العمل الإضافي');
      expect(ar.overtimeManagement, 'إدارة العمل الإضافي');
      expect(ar.overtimeDetails, 'تفاصيل العمل الإضافي');
      expect(ar.overtimeStart, 'بدء العمل الإضافي');
      expect(ar.overtimeStartTitle, 'بدء رحلة العمل الإضافي');
      expect(ar.overtimeMyHistory, 'وقتي الإضافي');
      expect(ar.overtimeTypeNormal, 'عمل إضافي عادي');
      expect(ar.overtimeTypeTravel, 'عمل إضافي للسفر');
      expect(ar.overtimeEligible, 'ساعات الإضافي');
    });

    test('technician type labels and message mapping use presentation keys',
        () {
      expect(
        overtimeTechnicianTypeLabel(ar, OvertimeType.normal),
        ar.overtimeTechnicianTypeNormal,
      );
      expect(
        overtimeTechnicianTypeLabel(ar, OvertimeType.travel),
        ar.overtimeTechnicianTypeTravel,
      );
      // Admin helper remains on shared keys.
      expect(overtimeTypeLabel(ar, OvertimeType.normal), ar.overtimeTypeNormal);

      expect(
        localizeTechnicianOvertimeMessage(ar, 'overtimeEnded'),
        ar.overtimeTechnicianEnded,
      );
      expect(
        localizeTechnicianOvertimeMessage(ar, 'normalOvertimeStarted'),
        ar.overtimeTechnicianNormalStarted,
      );
      expect(
        localizeTechnicianOvertimeMessage(ar, 'travelOvertimeStarted'),
        ar.overtimeTechnicianTravelStarted,
      );
      expect(
        localizeTechnicianOvertimeMessage(
          ar,
          'overtimeContinueExistingSession',
        ),
        ar.overtimeTechnicianContinueExistingSession,
      );
      expect(
        localizeTechnicianOvertimeMessage(ar, 'overtimeActiveSessionReminder'),
        ar.overtimeTechnicianActiveSessionReminder,
      );
      expect(
        localizeTechnicianOvertimeMessage(ar, 'OVERTIME_NOT_FOUND'),
        ar.overtimeTechnicianErrorNotFound,
      );
      expect(
        localizeTechnicianOvertimeMessage(ar, 'overtimeNoRunningSession'),
        ar.overtimeTechnicianNoRunningSession,
      );
    });

    test('English technician presentation mirrors existing English wording',
        () {
      expect(en.overtimeTechnicianTitle, en.overtime);
      expect(en.overtimeTechnicianNav, en.navOvertime);
      expect(en.overtimeTechnicianStart, en.overtimeStart);
      expect(en.overtimeTechnicianStartTitle, en.overtimeStartTitle);
      expect(en.overtimeTechnicianMyHistory, en.overtimeMyHistory);
      expect(en.overtimeTechnicianTypeNormal, en.overtimeTypeNormal);
      expect(en.overtimeTechnicianTypeTravel, en.overtimeTypeTravel);
    });
  });
}
