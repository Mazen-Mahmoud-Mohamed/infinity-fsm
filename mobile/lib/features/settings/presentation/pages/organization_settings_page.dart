import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';

class OrganizationSettingsPage extends StatefulWidget {
  const OrganizationSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<OrganizationSettingsPage> createState() =>
      _OrganizationSettingsPageState();
}

class _OrganizationSettingsPageState extends State<OrganizationSettingsPage> {
  late final OrganizationSettingsCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _timezone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _governorate = TextEditingController();
  final _country = TextEditingController();
  final _postal = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<OrganizationSettingsCubit>()..load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _timezone,
      _line1,
      _line2,
      _city,
      _governorate,
      _country,
      _postal,
      _start,
      _end,
    ]) {
      c.dispose();
    }
    _cubit.close();
    super.dispose();
  }

  void _hydrate(OrganizationSettings settings) {
    if (_hydrated) return;
    _name.text = settings.name;
    _email.text = settings.contactEmail ?? '';
    _phone.text = settings.contactPhone ?? '';
    _timezone.text = settings.timezone ?? settings.workingHours.timezone;
    _line1.text = settings.address.line1 ?? '';
    _line2.text = settings.address.line2 ?? '';
    _city.text = settings.address.city ?? '';
    _governorate.text = settings.address.governorate ?? '';
    _country.text = settings.address.country ?? '';
    _postal.text = settings.address.postalCode ?? '';
    _start.text = settings.workingHours.start;
    _end.text = settings.workingHours.end;
    _hydrated = true;
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final result = await _cubit.save(
      OrganizationSettingsUpsert(
        name: _name.text.trim(),
        contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        timezone: _timezone.text.trim(),
        address: CompanyAddressSettings(
          line1: _line1.text.trim().isEmpty ? null : _line1.text.trim(),
          line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          governorate:
              _governorate.text.trim().isEmpty ? null : _governorate.text.trim(),
          country: _country.text.trim().isEmpty ? null : _country.text.trim(),
          postalCode: _postal.text.trim().isEmpty ? null : _postal.text.trim(),
        ),
        workingHoursStart: _start.text.trim(),
        workingHoursEnd: _end.text.trim(),
        workingHoursTimezone: _timezone.text.trim(),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsSaved)),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  Future<void> _pickLogo(AppLocalizations l10n) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final result = await _cubit.uploadLogo(
      bytes: bytes,
      fileName: file.name,
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLogoUpdated)),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canManageSettings() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: widget.embedded
          ? _buildBody(l10n, canManage)
          : Scaffold(
              appBar: AppBar(title: Text(l10n.settingsCompanyInformation)),
              body: _buildBody(l10n, canManage),
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool canManage) {
    return BlocConsumer<OrganizationSettingsCubit, OrganizationSettingsState>(
      listener: (context, state) {
        if (state.settings != null) {
          _hydrate(state.settings!);
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == OrganizationSettingsStatus.loading &&
            state.settings == null) {
          return AppLoader(message: l10n.settingsLoading);
        }
        if (state.status == OrganizationSettingsStatus.failure &&
            state.settings == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.settingsLoadFailed,
                        ),
                FilledButton(
                  onPressed: _cubit.load,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }

        final saving = state.status == OrganizationSettingsStatus.saving;
        final logoUrl = state.settings?.logoUrl;

        return Column(
          children: [
            AppRefreshBar(visible: state.isRefreshing),
            if (saving) const LinearProgressIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: AppBottomSafeListView(
                  basePadding: const EdgeInsets.all(AppSpacing.md),
                  chrome: AppBottomChrome.system,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            child: logoUrl != null
                                ? ClipOval(
                                    child: AppCachedNetworkImage(
                                      imageUrl: logoUrl,
                                      width: 80,
                                      height: 80,
                                      memCacheWidth: 160,
                                      memCacheHeight: 160,
                                      errorIcon: Icons.business,
                                    ),
                                  )
                                : const Icon(Icons.business, size: 36),
                          ),
                          if (canManage)
                            TextButton.icon(
                              onPressed: saving ? null : () => _pickLogo(l10n),
                              icon: const Icon(Icons.upload),
                              label: Text(l10n.settingsCompanyLogo),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _name,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsCompanyName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.usersRequired
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _email,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsContactEmail,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phone,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsContactPhone,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.settingsAddress,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _line1,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsAddressLine1,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _line2,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsAddressLine2,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _city,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsCity,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _governorate,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsGovernorate,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _country,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsCountry,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _postal,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsPostalCode,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.settingsWorkingHours,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _start,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsWorkingHoursStart,
                        border: const OutlineInputBorder(),
                        hintText: '09:00',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _end,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsWorkingHoursEnd,
                        border: const OutlineInputBorder(),
                        hintText: '17:00',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _timezone,
                      enabled: canManage && !saving,
                      decoration: InputDecoration(
                        labelText: l10n.settingsTimezone,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: saving ? null : () => _save(l10n),
                        child: Text(l10n.settingsSave),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
