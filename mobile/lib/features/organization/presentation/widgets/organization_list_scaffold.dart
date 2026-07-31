import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/features/organization/presentation/widgets/offline_banner.dart';

class OrganizationListScaffold extends StatelessWidget {
  const OrganizationListScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.isOffline,
    required this.hasError,
    required this.isEmpty,
    required this.errorMessage,
    required this.onRefresh,
    required this.onSearch,
    required this.itemCount,
    required this.itemBuilder,
    this.isRefreshing = false,
    this.searchHint,
    this.emptyMessage,
  });

  final String title;
  final bool isLoading;
  final bool isRefreshing;
  final bool isOffline;
  final bool hasError;
  final bool isEmpty;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearch;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final String? searchHint;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolvedSearchHint = searchHint ?? l10n.orgSearch;
    final resolvedEmptyMessage = emptyMessage ?? l10n.orgEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          AppRefreshBar(visible: isRefreshing),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: resolvedSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: _buildBody(context, l10n, resolvedEmptyMessage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    String resolvedEmptyMessage,
  ) {
    if (isLoading && itemCount == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120),
          AppLoader(message: l10n.loadingGeneric),
        ],
      );
    }

    final showHardError = hasError &&
        itemCount == 0 &&
        !isOffline &&
        !isUserFacingNetworkNoise(errorMessage);

    if (showHardError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppScrollPadding.resolve(
          context,
          base: const EdgeInsets.all(AppSpacing.lg),
          chrome: AppBottomChrome.system,
        ),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            localizeAppMessage(l10n, errorMessage),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }

    if (isEmpty || (hasError && itemCount == 0)) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppScrollPadding.resolve(
          context,
          base: const EdgeInsets.all(AppSpacing.lg),
          chrome: AppBottomChrome.system,
        ),
        children: [
          const SizedBox(height: 80),
          const InfinityEmptyBrandMark(size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOffline ? l10n.orgNoCachedData : resolvedEmptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        chrome: AppBottomChrome.system,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
