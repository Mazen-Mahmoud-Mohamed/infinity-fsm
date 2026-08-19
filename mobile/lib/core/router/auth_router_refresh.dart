import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';

class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh({
    required AuthCubit authCubit,
    TechnicianInterfaceCubit? technicianInterfaceCubit,
  }) {
    _subscriptions.add(authCubit.stream.listen((_) => notifyListeners()));
    if (technicianInterfaceCubit != null) {
      _subscriptions.add(
        technicianInterfaceCubit.stream.listen((_) => notifyListeners()),
      );
    }
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
