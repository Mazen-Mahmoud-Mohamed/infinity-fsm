import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/login_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final initial = context.read<LoginCubit>().state;
    final email = initial is LoginInitial ? initial.email : '';
    _emailController = TextEditingController(text: email);
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emailFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final formState = state is LoginInitial
            ? state
            : state is LoginFailure
                ? const LoginInitial()
                : const LoginInitial();
        final isLoading = state is LoginLoading;

        return Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  autofocus: true,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: localizeFieldError(l10n, formState.emailError),
                  ),
                  onChanged: context.read<LoginCubit>().emailChanged,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !isLoading,
                  obscureText: formState.obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: localizeFieldError(l10n, formState.passwordError),
                    suffixIcon: IconButton(
                      tooltip: formState.obscurePassword
                          ? l10n.showPassword
                          : l10n.hidePassword,
                      onPressed: isLoading
                          ? null
                          : context.read<LoginCubit>().togglePasswordVisibility,
                      icon: Icon(
                        formState.obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onChanged: context.read<LoginCubit>().passwordChanged,
                  onFieldSubmitted: (_) => _submit(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  value: formState.rememberMe,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          context
                              .read<LoginCubit>()
                              .rememberMeChanged(value ?? false);
                        },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.rememberMe),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(context),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.signingIn),
                          ],
                        )
                      : Text(l10n.signIn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit();
  }
}
