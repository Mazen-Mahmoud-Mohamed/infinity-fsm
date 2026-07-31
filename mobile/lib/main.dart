import 'package:flutter/material.dart';
import 'package:mobile/core/app/app.dart';
import 'package:mobile/core/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() async {
    runApp(const InfinityApp());
  });
}
