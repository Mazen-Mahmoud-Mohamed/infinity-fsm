import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/presentation/widgets/roles_desktop_table.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/widgets/users_desktop_table.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpInDesktopBox(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: child,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Users desktop table expands vertically after skeleton era', (
    tester,
  ) async {
    await pumpInDesktopBox(
      tester,
      UsersDesktopTable(
        users: const [
          ManagedUser(
            id: 'u1',
            companyId: 'c1',
            email: 'a@example.com',
            firstName: 'Ada',
            lastName: 'Lovelace',
            fullName: 'Ada Lovelace',
            status: ManagedUserStatus.active,
            roles: const ['ADMIN'],
          ),
        ],
        scrollController: ScrollController(),
      ),
    );

    final table = tester.widget<AppDesktopDataTable>(
      find.byType(AppDesktopDataTable),
    );
    expect(table.expandVertically, isTrue);

    final tableBox = tester.getTopLeft(find.byType(AppDesktopDataTable));
    // Table should sit near the top of the 800px body, not vertically centered.
    expect(tableBox.dy, lessThan(120));
  });

  testWidgets('Roles desktop table expands vertically after skeleton era', (
    tester,
  ) async {
    await pumpInDesktopBox(
      tester,
      RolesDesktopTable(
        roles: const [
          RoleEntity(
            id: 'r1',
            companyId: 'c1',
            name: 'Technician',
            slug: 'technician',
            isSystem: true,
            isActive: true,
            assignedUsersCount: 3,
            permissions: const [],
          ),
        ],
        scrollController: ScrollController(),
      ),
    );

    final table = tester.widget<AppDesktopDataTable>(
      find.byType(AppDesktopDataTable),
    );
    expect(table.expandVertically, isTrue);

    final tableBox = tester.getTopLeft(find.byType(AppDesktopDataTable));
    expect(tableBox.dy, lessThan(120));
  });
}
