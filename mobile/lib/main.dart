import 'package:flutter/material.dart';
import 'package:mobile/core/app/app.dart';
import 'package:mobile/core/app/bootstrap.dart';
import 'package:mobile/core/theme/app_system_ui.dart';

Future<void> main() async {
  await bootstrap(() async {
    // Avoid a white Android nav bar flash before the first frame paints.
    AppSystemUi.applyBootstrap();
    runApp(const InfinityApp());
  });
}
