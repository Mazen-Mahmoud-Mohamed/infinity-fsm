import 'package:flutter/material.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/presentation/widgets/report_status_badge.dart';

class ServiceReportPreviewCard extends StatelessWidget {
  const ServiceReportPreviewCard({super.key, required this.report});

  final ServiceReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTimeSpaced(context);
    final theme = Theme.of(context);
    final logoUrl = report.company.logoUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: AppCachedNetworkImage(
                  imageUrl: logoUrl,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              )
            else
              Text(
                report.company.name ?? l10n.reportsTitle,
                style: theme.textTheme.titleLarge,
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.reportNumber,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ReportStatusBadge(status: report.status),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _section(context, l10n.reportsWorkOrderInfo, [
              _line(l10n.reportsJobNumber, report.workOrder.jobNumber),
              _line(l10n.reportsJobTitle, report.workOrder.jobTitle),
              _line(l10n.reportsCustomerName, report.workOrder.customerName),
              _line(l10n.reportsCustomerAddress, report.workOrder.customerAddress),
            ]),
            _section(context, l10n.reportsAssetInfo, [
              _line(l10n.reportsAssetNumber, report.asset.assetNumber),
              _line(l10n.reportsAssetName, report.asset.name),
              _line(l10n.reportsSerialNumber, report.asset.serialNumber),
            ]),
            _section(context, l10n.reportsTechnician, [
              _line(l10n.reportsTechnicianName, report.technician.name),
              _line(
                l10n.reportsStartTime,
                report.startTime != null
                    ? dateFormat.format(report.startTime!.toLocal())
                    : null,
              ),
              _line(
                l10n.reportsEndTime,
                report.endTime != null
                    ? dateFormat.format(report.endTime!.toLocal())
                    : null,
              ),
              _line(
                l10n.reportsTotalDuration,
                report.totalDurationMinutes != null
                    ? DurationFormatter.fromMinutes(
                        report.totalDurationMinutes,
                        l10n,
                      )
                    : null,
              ),
            ]),
            if (report.technicianNotes != null &&
                report.technicianNotes!.isNotEmpty)
              _section(context, l10n.reportsTechnicianNotes, [
                Text(report.technicianNotes!),
              ]),
            if (report.customerNotes != null &&
                report.customerNotes!.isNotEmpty)
              _section(context, l10n.reportsCustomerNotes, [
                Text(report.customerNotes!),
              ]),
            _photoSection(context, l10n.reportsBeforePhotos, report.beforePhotos),
            _photoSection(
              context,
              l10n.reportsProgressPhotos,
              report.progressPhotos,
            ),
            _photoSection(context, l10n.reportsAfterPhotos, report.afterPhotos),
            _section(context, l10n.reportsCustomerSignature, [
              _line(
                l10n.reportsCustomerName,
                report.customerSignature.customerName,
              ),
              _line(
                l10n.reportsCustomerPosition,
                report.customerSignature.customerPosition,
              ),
              if (report.customerSignature.signatureImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: AppCachedNetworkImage(
                    imageUrl: report.customerSignature.signatureImageUrl!,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
            ]),
            _section(context, l10n.reportsQrCode, [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  report.reportQrCode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    );
  }

  Widget _line(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }

  Widget _photoSection(
    BuildContext context,
    String title,
    List<ReportPhotoRef> photos,
  ) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return _section(context, title, [
      SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppCachedNetworkImage(
                imageUrl: photos[index].url,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    ]);
  }
}
