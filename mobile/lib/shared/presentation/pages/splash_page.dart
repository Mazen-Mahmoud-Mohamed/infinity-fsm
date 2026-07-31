import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  Future<void> _start() async {
    final appCubit = context.read<AppCubit>();
    final authCubit = context.read<AuthCubit>();

    await appCubit.initialize();

    if (!mounted) {
      return;
    }

    if (appCubit.state.startupStatus == AppStartupStatus.failure) {
      return;
    }

    await authCubit.checkSession();

    if (!mounted) {
      return;
    }

    final authStatus = authCubit.state.status;
    if (authStatus == AuthStatus.authenticated) {
      context.go(RoutePaths.dashboard);
    } else {
      context.go(RoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            if (state.startupStatus == AppStartupStatus.failure) {
              return _StartupFailureView(
                message: state.message ?? l10n.errorGeneric,
                onRetry: _start,
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const InfinityBrandHeader(
                      image: InfinityBrandImage.logo,
                      imageHeight: 230,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppLoader(message: l10n.splashLoading),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StartupFailureView extends StatelessWidget {
  const _StartupFailureView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const InfinityBrandImageView.icon(height: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
