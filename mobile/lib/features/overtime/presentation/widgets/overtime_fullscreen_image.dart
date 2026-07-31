import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';

class OvertimeFullscreenImagePage extends StatelessWidget {
  const OvertimeFullscreenImagePage({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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

void openOvertimeFullscreenImage(
  BuildContext context, {
  required String imageUrl,
  required String title,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OvertimeFullscreenImagePage(
        imageUrl: imageUrl,
        title: title,
      ),
    ),
  );
}
