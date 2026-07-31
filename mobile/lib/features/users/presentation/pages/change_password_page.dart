import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late final ChangePasswordCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ChangePasswordCubit>();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final result = await _cubit.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.usersPasswordChanged)),
        );
        Navigator.of(context).pop(true);
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.usersChangePassword)),
        body: BlocBuilder<ChangePasswordCubit, ChangePasswordState>(
          builder: (context, state) {
            final saving = state.status == ChangePasswordStatus.saving;
            return Form(
              key: _formKey,
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.md),
                chrome: AppBottomChrome.system,
                children: [
                  TextFormField(
                    controller: _currentController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.usersCurrentPassword,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? l10n.usersRequired : null,
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _newController,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: l10n.usersNewPassword),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return l10n.usersPasswordMin;
                      }
                      return null;
                    },
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.usersConfirmPassword,
                    ),
                    validator: (v) {
                      if (v != _newController.text) {
                        return l10n.usersPasswordMismatch;
                      }
                      return null;
                    },
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.usersSave),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
