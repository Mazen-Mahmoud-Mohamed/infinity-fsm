import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';

class WorkOrderFullscreenImagePage extends StatelessWidget {
  const WorkOrderFullscreenImagePage({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.heroTag,
  });

  final String imageUrl;
  final String title;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: AppCachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              errorIcon: Icons.broken_image_outlined,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openWorkOrderFullscreenImage(
  BuildContext context, {
  required String imageUrl,
  required String title,
  required Object heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: WorkOrderFullscreenImagePage(
            imageUrl: imageUrl,
            title: title,
            heroTag: heroTag,
          ),
        );
      },
    ),
  );
}

class WorkOrderPhotoGallery extends StatelessWidget {
  const WorkOrderPhotoGallery({
    super.key,
    required this.photos,
    required this.title,
    this.heroPrefix = 'wo-photo',
    this.canRemove = false,
    this.onRemove,
    this.onAdd,
    this.isBusy = false,
  });

  final List<WorkOrderAttachment> photos;
  final String title;
  final String heroPrefix;
  final bool canRemove;
  final ValueChanged<WorkOrderAttachment>? onRemove;
  final VoidCallback? onAdd;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 5
        : width >= 600
            ? 4
            : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${photos.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton.filledTonal(
                tooltip: l10n.workOrderAddPhoto,
                onPressed: isBusy ? null : onAdd,
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.workOrderNoPhotosYet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final heroTag = '$heroPrefix-${photo.url}';
              return _PhotoTile(
                photo: photo,
                heroTag: heroTag,
                canRemove: canRemove && onRemove != null,
                onOpen: () => openWorkOrderFullscreenImage(
                  context,
                  imageUrl: photo.url,
                  title: photo.fileName ?? title,
                  heroTag: heroTag,
                ),
                onRemove: isBusy ? null : () => onRemove?.call(photo),
              );
            },
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.heroTag,
    required this.canRemove,
    required this.onOpen,
    this.onRemove,
  });

  final WorkOrderAttachment photo;
  final Object heroTag;
  final bool canRemove;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: 0.5,
      shadowColor: scheme.shadow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: onOpen,
            child: Hero(
              tag: heroTag,
              child: AppCachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.cover,
                memCacheWidth: 400,
              ),
            ),
          ),
          if (canRemove)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: scheme.surface.withValues(alpha: 0.92),
                elevation: 1,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: scheme.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
