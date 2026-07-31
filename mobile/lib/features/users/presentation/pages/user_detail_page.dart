import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';
import 'package:mobile/features/users/presentation/widgets/user_status_badge.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late final UserDetailCubit _cubit;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UserDetailCubit>(param1: widget.userId)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final result = await _cubit.uploadAvatar(
      AvatarUploadBytes(bytes: bytes, fileName: file.name),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        _changed = true;
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  Future<void> _setStatus(ManagedUserStatus status) async {
    final l10n = AppLocalizations.of(context);
    final result = await _cubit.setStatus(status);
    if (!mounted) return;
    switch (result) {
      case Success():
        _changed = true;
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTimeSpaced(context);
    final canUpdate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canUpdateUsers() == true,
    );
    final canDelete = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canDeleteUsers() == true,
    );
    final canReset = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canResetUserPassword() == true,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.usersDetails),
            actions: [
              if (canUpdate)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final changed = await context.push<bool>(
                      RoutePaths.usersFormEdit(widget.userId),
                    );
                    if (changed == true && mounted) {
                      _changed = true;
                      await _cubit.load();
                    }
                  },
                ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.usersDelete),
                        content: Text(l10n.usersDeleteConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.usersCancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.usersDelete),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    final result = await _cubit.delete();
                    if (!context.mounted) return;
                    switch (result) {
                      case Success():
                        Navigator.of(context).pop(true);
                      case Failure(message: final message):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localizeAppMessage(l10n, message))),
                        );
                    }
                  },
                ),
            ],
          ),
          body: BlocBuilder<UserDetailCubit, UserDetailState>(
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.user != c.user ||
                p.message != c.message ||
                p.isRefreshing != c.isRefreshing,
            builder: (context, state) {
              if ((state.status == UserDetailStatus.loading ||
                      state.status == UserDetailStatus.initial) &&
                  state.user == null) {
                return AppLoader(message: l10n.usersLoading);
              }
              if ((state.status == UserDetailStatus.failure ||
                      state.user == null) &&
                  state.user == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message ?? l10n.usersLoadFailed),
                      FilledButton(
                        onPressed: _cubit.load,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              final user = state.user!;
              return Column(
                children: [
                  AppRefreshBar(visible: state.isRefreshing),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _cubit.load,
                child: ListView(
                  padding: AppScrollPadding.resolve(
                    context,
                    base: const EdgeInsets.all(AppSpacing.md),
                    chrome: AppBottomChrome.system,
                  ),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : '?',
                                    style:
                                        Theme.of(context).textTheme.headlineMedium,
                                  )
                                : null,
                          ),
                          if (canUpdate)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton.filledTonal(
                                onPressed: _pickAvatar,
                                icon: const Icon(Icons.camera_alt_outlined),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(child: UserStatusBadge(status: user.status)),
                    const SizedBox(height: AppSpacing.lg),
                    _row(l10n.usersUsername, user.username),
                    _row(l10n.usersEmail, user.email),
                    _row(l10n.usersPhone, user.phone),
                    _row(l10n.usersJobTitle, user.jobTitle),
                    _row(l10n.usersRole, user.primaryRole),
                    _row(l10n.usersDepartment, user.department?.name),
                    _row(l10n.usersBranch, user.branch?.name),
                    _row(
                      l10n.usersLastLogin,
                      user.lastLoginAt != null
                          ? dateFormat.format(user.lastLoginAt!.toLocal())
                          : null,
                    ),
                    _row(
                      l10n.usersLastActive,
                      user.lastActiveAt != null
                          ? dateFormat.format(user.lastActiveAt!.toLocal())
                          : null,
                    ),
                    _row(l10n.usersCreatedBy, user.createdBy?.name),
                    _row(l10n.usersUpdatedBy, user.updatedBy?.name),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (canUpdate &&
                            user.status != ManagedUserStatus.active)
                          FilledButton.tonal(
                            onPressed: () =>
                                _setStatus(ManagedUserStatus.active),
                            child: Text(l10n.usersEnable),
                          ),
                        if (canUpdate &&
                            user.status != ManagedUserStatus.disabled)
                          FilledButton.tonal(
                            onPressed: () =>
                                _setStatus(ManagedUserStatus.disabled),
                            child: Text(l10n.usersDisable),
                          ),
                        if (canUpdate &&
                            user.status != ManagedUserStatus.locked)
                          FilledButton.tonal(
                            onPressed: () =>
                                _setStatus(ManagedUserStatus.locked),
                            child: Text(l10n.usersLock),
                          ),
                        if (canReset)
                          FilledButton.icon(
                            onPressed: () => context.push(
                              RoutePaths.usersResetPassword(widget.userId),
                            ),
                            icon: const Icon(Icons.lock_reset),
                            label: Text(l10n.usersResetPassword),
                          ),
                      ],
                    ),
                    if (user.recentActivity.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.usersActivity,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...user.recentActivity.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.action),
                          subtitle: Text(item.summary ?? ''),
                          trailing: item.createdAt != null
                              ? Text(
                                  dateFormat.format(item.createdAt!.toLocal()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
