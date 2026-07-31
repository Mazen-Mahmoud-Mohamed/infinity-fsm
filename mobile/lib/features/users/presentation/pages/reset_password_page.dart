import 'package:flutter/material.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.userId});

  final String userId;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await getIt<ResetManagedUserPasswordUseCase>()(
      widget.userId,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.usersPasswordResetSuccess)),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersResetPassword)),
      body: Form(
        key: _formKey,
        child: AppBottomSafeListView(
          basePadding: const EdgeInsets.all(AppSpacing.md),
          chrome: AppBottomChrome.system,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.usersNewPassword),
              validator: (v) {
                if (v == null || v.length < 8) return l10n.usersPasswordMin;
                return null;
              },
              enabled: !_saving,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: l10n.usersConfirmPassword),
              validator: (v) {
                if (v != _passwordController.text) {
                  return l10n.usersPasswordMismatch;
                }
                return null;
              },
              enabled: !_saving,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.usersResetPassword),
            ),
          ],
        ),
      ),
    );
  }
}
