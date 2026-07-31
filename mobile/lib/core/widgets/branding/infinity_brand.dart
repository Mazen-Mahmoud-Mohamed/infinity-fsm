import 'package:flutter/material.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_assets.dart';
import 'package:mobile/core/constants/app_spacing.dart';

enum InfinityBrandImage { icon, logo }

/// Official Infinity mark using [BoxFit.contain] (never stretched).
class InfinityBrandImageView extends StatelessWidget {
  const InfinityBrandImageView({
    super.key,
    required this.image,
    this.height = 72,
    this.width,
  });

  const InfinityBrandImageView.icon({
    super.key,
    this.height = 56,
    this.width,
  }) : image = InfinityBrandImage.icon;

  const InfinityBrandImageView.logo({
    super.key,
    this.height = 120,
    this.width,
  }) : image = InfinityBrandImage.logo;

  final InfinityBrandImage image;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? height,
      child: Image.asset(
        image == InfinityBrandImage.logo
            ? AppAssets.infinityLogo
            : AppAssets.infinityIcon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// Centered brand hierarchy: INFINITY + Total-Com Solutions.
class InfinityBrandHeader extends StatelessWidget {
  const InfinityBrandHeader({
    super.key,
    this.image = InfinityBrandImage.logo,
    this.imageHeight = 120,
    this.compact = false,
  });

  final InfinityBrandImage image;
  final double imageHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = compact
        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfinityBrandImageView(
          image: image,
          height: imageHeight,
          width: image == InfinityBrandImage.logo ? imageHeight * 1.6 : imageHeight,
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        Text(
          AppConfig.appName,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppConfig.companyName,
          textAlign: TextAlign.center,
          style: subtitleStyle,
        ),
      ],
    );
  }
}

/// Small brand chip for empty states and secondary surfaces.
class InfinityEmptyBrandMark extends StatelessWidget {
  const InfinityEmptyBrandMark({
    super.key,
    this.size = 64,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: InfinityBrandImageView.icon(height: size),
    );
  }
}
