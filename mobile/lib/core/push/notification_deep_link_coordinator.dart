import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/push/notification_idempotency_gate.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/push/pending_notification_store.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/window_focus_service.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_notification_policy.dart';

/// Shell-safe notification deep-link navigation for [StatefulShellRoute].
///
/// Uses [GoRouter.go] with full paths so go_router switches the correct
/// shell branch and mounts nested detail routes. Avoids root [GoRouter.push]
/// from outside the shell (blank IndexedStack body).
///
/// Cold start: [consumeColdStartRoute] lets Splash navigate directly to the
/// pending destination instead of `go(home)` then delayed `push(detail)`.
/// Warm/background: [open] waits for [notifyShellReady] when needed.
class NotificationDeepLinkCoordinator {
  NotificationDeepLinkCoordinator({
    required GoRouter router,
    required PendingNotificationStore pending,
    required WindowFocusService windowFocus,
    NotificationIdempotencyGate? idempotency,
  })  : _router = router,
        _pending = pending,
        _windowFocus = windowFocus,
        _idempotency = idempotency ?? NotificationIdempotencyGate();

  final GoRouter _router;
  final PendingNotificationStore _pending;
  final WindowFocusService _windowFocus;
  final NotificationIdempotencyGate _idempotency;

  bool _shellReady = false;
  bool _navigating = false;
  bool _bootstrapNavigationSettled = false;
  NotificationNavigationIntent? _queued;
  Completer<void>? _shellReadyWaiter;
  Completer<void>? _bootstrapWaiter;

  bool get isShellReady => _shellReady;

  /// Splash / login finished choosing the first authenticated location.
  ///
  /// [flushAfterAuthentication] waits for this so it cannot race Splash and
  /// overwrite a cold-start deep link with `go(home)`.
  void markBootstrapNavigationSettled() {
    _bootstrapNavigationSettled = true;
    final waiter = _bootstrapWaiter;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
    _bootstrapWaiter = null;
  }

  /// Called when [MainNavigationShell] is showing the real navigation shell
  /// (not the Technician Interface loading placeholder).
  void notifyShellReady() {
    final wasReady = _shellReady;
    _shellReady = true;
    final waiter = _shellReadyWaiter;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
    _shellReadyWaiter = null;
    if (!wasReady || _queued != null) {
      unawaited(flushQueued());
    }
  }

  /// Called when the shell is temporarily unavailable (TI loading spinner).
  void notifyShellNotReady() {
    _shellReady = false;
  }

  void clearSession() {
    _queued = null;
    _idempotency.clear();
    _shellReady = false;
    _bootstrapNavigationSettled = false;
    final shellWaiter = _shellReadyWaiter;
    if (shellWaiter != null && !shellWaiter.isCompleted) {
      shellWaiter.complete();
    }
    _shellReadyWaiter = null;
    final bootstrapWaiter = _bootstrapWaiter;
    if (bootstrapWaiter != null && !bootstrapWaiter.isCompleted) {
      bootstrapWaiter.complete();
    }
    _bootstrapWaiter = null;
  }

  /// Splash cold-start: take a pending deep link for [userId] if allowed.
  ///
  /// Returns the route to [GoRouter.go] immediately, or null to use home.
  Future<String?> consumeColdStartRoute({
    required String? userId,
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
  }) async {
    final intent = await _pending.takeForUser(userId);
    if (intent == null) return null;
    if (!_isNavigableDestination(intent.route)) return null;
    if (!_canNavigate(user: user, config: config, route: intent.route)) {
      return null;
    }
    // Record idempotency so a later flush does not re-navigate.
    _idempotency.shouldSkip(
      intent.idempotencyKey,
      userId: userId,
    );
    _queued = null;
    debugPrint('[DeepLink] cold-start → ${intent.route}');
    return intent.route;
  }

  /// Opens a notification destination when authenticated.
  ///
  /// If the shell is not ready yet, queues the intent and persists it until
  /// [notifyShellReady] (no arbitrary delay).
  Future<void> open({
    required NotificationNavigationIntent intent,
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
    required String source,
  }) async {
    if (!_isNavigableDestination(intent.route)) {
      debugPrint('[DeepLink] skip non-destination ($source) → ${intent.route}');
      return;
    }
    if (!_canNavigate(user: user, config: config, route: intent.route)) {
      debugPrint('[DeepLink] TI blocked ($source) → ${intent.route}');
      return;
    }

    final owned = intent.userId?.trim().isNotEmpty == true
        ? intent
        : intent.copyWith(userId: user?.id);

    if (!_shellReady) {
      _queued = owned;
      await _pending.persist(owned);
      debugPrint('[DeepLink] queued until shell ready ($source) → ${owned.route}');
      return;
    }

    await _navigate(owned, source: source);
  }

  /// After authentication, flush any pending deep link once the shell is ready.
  ///
  /// Waits for Splash/login bootstrap navigation to settle, then for
  /// [notifyShellReady] (event-driven). Does not use a fixed delay.
  Future<void> flushAfterAuthentication({
    required String? userId,
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
  }) async {
    await _waitForBootstrapNavigationSettled();
    await _waitForShellReady();
    if (!_shellReady) return;

    final queued = _queued;
    _queued = null;
    if (queued != null) {
      await open(
        intent: queued,
        user: user,
        config: config,
        source: 'auth_queued',
      );
      return;
    }

    final pending = await _pending.takeForUser(userId);
    if (pending == null) return;
    await open(
      intent: pending,
      user: user,
      config: config,
      source: 'auth_pending',
    );
  }

  Future<void> flushQueued() async {
    final queued = _queued;
    if (queued == null || !_shellReady || _navigating) return;
    _queued = null;
    await _navigate(queued, source: 'shell_ready');
  }

  /// Shell branch index for a resolved notification route (for tests/docs).
  static int? shellBranchForRoute(String route) {
    if (route.startsWith(RoutePaths.workOrders) ||
        route.startsWith('/work-orders')) {
      return TechnicianInterfaceNavigation.branchWorkOrders;
    }
    if (route.startsWith(RoutePaths.overtime) ||
        route.startsWith('/overtime')) {
      return TechnicianInterfaceNavigation.branchOvertime;
    }
    if (route.startsWith(RoutePaths.settings) ||
        route.startsWith('/settings')) {
      return TechnicianInterfaceNavigation.branchSettings;
    }
    if (route.startsWith(RoutePaths.dashboard) ||
        route.startsWith('/dashboard')) {
      return TechnicianInterfaceNavigation.branchDashboard;
    }
    if (route.startsWith(RoutePaths.profile) ||
        route.startsWith('/profile')) {
      return TechnicianInterfaceNavigation.branchProfile;
    }
    return null;
  }

  Future<void> _waitForBootstrapNavigationSettled() async {
    if (_bootstrapNavigationSettled) return;
    final existing = _bootstrapWaiter;
    if (existing != null) {
      await existing.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {},
      );
      return;
    }
    final completer = Completer<void>();
    _bootstrapWaiter = completer;
    await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        debugPrint('[DeepLink] bootstrap navigation wait timed out');
        _bootstrapNavigationSettled = true;
      },
    );
  }

  Future<void> _waitForShellReady() async {
    if (_shellReady) return;
    final existing = _shellReadyWaiter;
    if (existing != null) {
      await existing.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {},
      );
      return;
    }
    final completer = Completer<void>();
    _shellReadyWaiter = completer;
    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('[DeepLink] shell ready wait timed out');
      },
    );
  }

  Future<void> _navigate(
    NotificationNavigationIntent intent, {
    required String source,
  }) async {
    if (_navigating) return;

    final userId = intent.userId;
    final key = intent.idempotencyKey;
    if (_idempotency.shouldSkip(key, userId: userId)) {
      await _pending.clear();
      debugPrint('[DeepLink] idempotent skip ($source) → ${intent.route}');
      return;
    }

    if (_isAlreadyAt(intent.route)) {
      await _pending.clear();
      debugPrint('[DeepLink] already at ($source) → ${intent.route}');
      return;
    }

    _navigating = true;
    try {
      await _pending.clear();
      await _windowFocus.focusApp();

      final branch = shellBranchForRoute(intent.route);
      debugPrint(
        '[DeepLink] go ($source) → ${intent.route}'
        '${branch != null ? ' (branch=$branch)' : ''}',
      );

      // Full-path go() is the StatefulShellRoute-safe deep-link API: go_router
      // selects the matching branch and mounts the nested detail route.
      _router.go(intent.route);
    } on Object catch (error) {
      debugPrint('[DeepLink] navigate failed: $error');
      _idempotency.forgetLastKey();
    } finally {
      _navigating = false;
    }
  }

  bool _isAlreadyAt(String route) {
    final current = _router.routerDelegate.currentConfiguration.uri.path;
    return _normalizePath(current) == _normalizePath(route);
  }

  static String _normalizePath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  static bool _isNavigableDestination(String route) {
    if (route.isEmpty) return false;
    // Missing entity IDs resolve to the inbox — not a deep-link destination.
    if (route == RoutePaths.notifications) return false;
    return true;
  }

  static bool _canNavigate({
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
    required String route,
  }) {
    return TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
      user: user,
      config: config,
      route: route,
    );
  }
}
