import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';
import 'package:mobile/features/users/presentation/utils/user_labels.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key, this.userId});

  final String? userId;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  late final UserFormCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();

  String _role = 'TECHNICIAN';
  ManagedUserStatus _status = ManagedUserStatus.active;
  String? _branchId;
  String? _departmentId;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UserFormCubit>(param1: widget.userId ?? '')..load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _seed(ManagedUser user) {
    if (_seeded) return;
    _seeded = true;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _usernameController.text = user.username ?? '';
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
    _jobTitleController.text = user.jobTitle ?? '';
    _employeeIdController.text = user.employeeId ?? '';
    _role = user.primaryRole ??
        (user.roles.isNotEmpty ? user.roles.first : 'TECHNICIAN');
    _status = user.status;
    _branchId = user.branchId;
    _departmentId = user.departmentId;
    setState(() {});
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    Department? department;
    for (final d in _cubit.state.departments) {
      if (d.id == _departmentId) {
        department = d;
        break;
      }
    }
    if (department == null ||
        department.regionId == null ||
        department.cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usersOrgRefsRequired)),
      );
      return;
    }

    final isEditing = widget.userId != null && widget.userId!.isNotEmpty;
    final input = ManagedUserUpsertInput(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: isEditing ? null : _passwordController.text,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      jobTitle: _jobTitleController.text.trim().isEmpty
          ? null
          : _jobTitleController.text.trim(),
      employeeId: _employeeIdController.text.trim().isEmpty
          ? _usernameController.text.trim()
          : _employeeIdController.text.trim(),
      roles: [_role],
      branchId: department.branchId,
      regionId: department.regionId!,
      cityId: department.cityId!,
      departmentId: department.id,
      status: _status,
    );

    final result = await _cubit.save(input);
    if (!mounted) return;
    switch (result) {
      case Success():
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
    final isEditing = widget.userId != null && widget.userId!.isNotEmpty;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? l10n.usersEdit : l10n.usersCreate),
        ),
        body: BlocConsumer<UserFormCubit, UserFormState>(
          listener: (context, state) {
            if (state.user != null) _seed(state.user!);
          },
          builder: (context, state) {
            if (state.status == UserFormStatus.loading ||
                state.status == UserFormStatus.initial) {
              return AppLoader(message: l10n.usersLoading);
            }

            final saving = state.status == UserFormStatus.saving;
            final departments = state.departments
                .where((d) => _branchId == null || d.branchId == _branchId)
                .toList();

            return Form(
              key: _formKey,
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.md),
                chrome: AppBottomChrome.system,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration:
                        InputDecoration(labelText: l10n.usersFirstName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.usersRequired : null,
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(labelText: l10n.usersLastName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.usersRequired : null,
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: l10n.usersUsername),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.usersRequired : null,
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: l10n.usersEmail),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.usersRequired : null,
                    enabled: !saving,
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      decoration:
                          InputDecoration(labelText: l10n.usersPassword),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return l10n.usersPasswordMin;
                        }
                        return null;
                      },
                      enabled: !saving,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: l10n.usersPhone),
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: InputDecoration(labelText: l10n.usersJobTitle),
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _employeeIdController,
                    decoration:
                        InputDecoration(labelText: l10n.usersEmployeeId),
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: InputDecoration(labelText: l10n.usersRole),
                    items: [
                      DropdownMenuItem(
                        value: 'ADMIN',
                        child: Text(userRoleLabel(l10n, 'ADMIN')),
                      ),
                      DropdownMenuItem(
                        value: 'SUPERVISOR',
                        child: Text(userRoleLabel(l10n, 'SUPERVISOR')),
                      ),
                      DropdownMenuItem(
                        value: 'TECHNICIAN',
                        child: Text(userRoleLabel(l10n, 'TECHNICIAN')),
                      ),
                      DropdownMenuItem(
                        value: 'HR',
                        child: Text(userRoleLabel(l10n, 'HR')),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _role = v);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<ManagedUserStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(labelText: l10n.usersStatus),
                    items: [
                      DropdownMenuItem(
                        value: ManagedUserStatus.active,
                        child: Text(l10n.usersStatusActive),
                      ),
                      DropdownMenuItem(
                        value: ManagedUserStatus.disabled,
                        child: Text(l10n.usersStatusDisabled),
                      ),
                      DropdownMenuItem(
                        value: ManagedUserStatus.locked,
                        child: Text(l10n.usersStatusLocked),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _status = v);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _branchId,
                    decoration: InputDecoration(labelText: l10n.usersBranch),
                    items: state.branches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() {
                              _branchId = v;
                              _departmentId = null;
                            }),
                    validator: (v) =>
                        v == null || v.isEmpty ? l10n.usersRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _departmentId,
                    decoration:
                        InputDecoration(labelText: l10n.usersDepartment),
                    items: departments
                        .map(
                          (Department d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() => _departmentId = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? l10n.usersRequired : null,
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
