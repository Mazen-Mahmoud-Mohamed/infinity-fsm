import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/login_state.dart';
import 'package:mobile/features/auth/presentation/widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(
        loginUseCase: getIt<LoginUseCase>(),
        localDataSource: getIt<AuthLocalDataSource>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) =>
          current is LoginSuccess || current is LoginFailure,
      listener: (context, state) {
        if (state is LoginSuccess) {
          context.read<AuthCubit>().setAuthenticated(state.user);
          context.go(RoutePaths.dashboard);
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(localizeAppMessage(l10n, state.message)),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: GestureDetector(
            onTap: _dismissKeyboard,
            behavior: HitTestBehavior.opaque,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final isWide = constraints.maxWidth >= 900;
                final minContentHeight =
                    (constraints.maxHeight - viewInsets.bottom)
                        .clamp(0.0, double.infinity);

                return AnimatedPadding(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (minContentHeight - AppSpacing.lg * 2)
                            .clamp(0.0, double.infinity),
                        maxWidth: 1100,
                      ),
                      child: Center(
                        child: isWide
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(child: _BrandingPanel()),
                                    const SizedBox(width: AppSpacing.xl),
                                    Expanded(child: _FormColumn(l10n: l10n)),
                                  ],
                                ),
                              )
                            : _FormColumn(l10n: l10n),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: const Center(
        child: InfinityBrandHeader(
          image: InfinityBrandImage.logo,
          imageHeight: 140,
        ),
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showMobileBrand = MediaQuery.sizeOf(context).width < 900;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMobileBrand) ...[
              const InfinityBrandHeader(
                image: InfinityBrandImage.logo,
                imageHeight: 72,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text(
              l10n.loginTitle,
              style: showMobileBrand
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.loginSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const LoginForm(),
          ],
        ),
      ),
    );
  }
}
