import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/domain/services/overtime_cellular_upload_prompt_service.dart';

Future<CellularUploadChoice> showCellularUploadPrompt(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<CellularUploadChoice>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.overtimeCellularUploadTitle),
        content: Text(l10n.overtimeCellularUploadMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, CellularUploadChoice.wifiOnly),
            child: Text(l10n.overtimeCellularUploadWifiOnly),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, CellularUploadChoice.mobileData),
            child: Text(l10n.overtimeCellularUploadMobileData),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, CellularUploadChoice.later),
            child: Text(l10n.overtimeCellularUploadLater),
          ),
        ],
      );
    },
  );
  return result ?? CellularUploadChoice.later;
}
