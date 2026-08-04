import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/media_url.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';

/// Opens gallery/file picker, previews a square crop, uploads own avatar only.
///
/// Reuses [UploadUserAvatarUseCase] + refreshes [AuthCubit] so every
/// `AppNetworkAvatar` listening to the current user updates immediately.
///
/// Returns `true` when the avatar was uploaded and the session user refreshed.
Future<bool> changeOwnProfilePhoto(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final auth = context.read<AuthCubit>();
  final user = auth.state.user;
  if (user == null) return false;

  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 2048,
    imageQuality: 92,
  );
  if (file == null || !context.mounted) return false;

  final name = file.name.toLowerCase();
  final allowed = name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.webp') ||
      name.isEmpty; // some platforms omit extension
  if (!allowed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsPhotoUnsupportedFormat)),
    );
    return false;
  }

  final rawBytes = await file.readAsBytes();
  final cropped = await compute(_cropAvatarIsolate, rawBytes);
  if (!context.mounted) return false;
  if (cropped == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsPhotoDecodeFailed)),
    );
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ProfilePhotoPreviewDialog(
      bytes: cropped,
      title: l10n.settingsPhotoPreview,
      cancelLabel: l10n.cancel,
      saveLabel: l10n.inventorySave,
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  final oldUrl = user.profilePhotoUrl;
  final userId = user.id;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  final upload = getIt<UploadUserAvatarUseCase>();
  final fileName = _normalizeFileName(file.name);
  final result = await upload(
    userId,
    AvatarUploadBytes(bytes: cropped, fileName: fileName),
  );

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  switch (result) {
    case Success():
      await auth.refreshCurrentUser();
      await evictAvatarCache(oldUrl);
      await evictAvatarCache(auth.state.user?.profilePhotoUrl);
      if (!context.mounted) return true;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsPhotoUpdated)),
      );
      return true;
    case Failure(message: final message):
      if (!context.mounted) return false;
      messenger.showSnackBar(
        SnackBar(
          content: Text(localizeAppMessage(l10n, message)),
        ),
      );
      return false;
  }
}

Future<void> evictAvatarCache(String? rawUrl) async {
  final resolved = resolveMediaUrl(rawUrl);
  if (resolved == null) return;
  try {
    await CachedNetworkImage.evictFromCache(resolved);
  } catch (_) {}
  PaintingBinding.instance.imageCache.evict(NetworkImage(resolved));
}

String _normalizeFileName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'avatar.jpg';
  final lower = trimmed.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp')) {
    return trimmed;
  }
  return '$trimmed.jpg';
}

/// Isolate entry: center-crop to square JPEG for upload.
Uint8List? _cropAvatarIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final size = math.min(decoded.width, decoded.height);
  if (size <= 0) return null;
  final x = (decoded.width - size) ~/ 2;
  final y = (decoded.height - size) ~/ 2;
  final cropped = img.copyCrop(
    decoded,
    x: x,
    y: y,
    width: size,
    height: size,
  );
  final target = size > 512 ? 512 : size;
  final resized = img.copyResize(
    cropped,
    width: target,
    height: target,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
}

class _ProfilePhotoPreviewDialog extends StatelessWidget {
  const _ProfilePhotoPreviewDialog({
    required this.bytes,
    required this.title,
    required this.cancelLabel,
    required this.saveLabel,
  });

  final Uint8List bytes;
  final String title;
  final String cancelLabel;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: isDesktop ? 360 : 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).settingsPhotoPreviewHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CircleAvatar(
              radius: isDesktop ? 96 : 80,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: MemoryImage(bytes),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(saveLabel),
        ),
      ],
    );
  }
}
