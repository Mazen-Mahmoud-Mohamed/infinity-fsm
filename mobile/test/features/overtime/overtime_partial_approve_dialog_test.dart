import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/utils/approved_hours_hhmm.dart';

GpsSnapshot _gps(DateTime at) => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: at,
      provider: 'gps',
    );

OvertimeSession _pendingSession({int eligibleMinutes = 1188}) {
  final start = DateTime.utc(2026, 8, 8, 10);
  return OvertimeSession(
    id: 'ot-1',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.travel,
    isOvernight: true,
    status: OvertimeStatus.pendingReview,
    startAt: start,
    startGps: _gps(start),
    startDeviceId: 'd1',
    createdAt: start,
    eligibleOvertimeMinutes: eligibleMinutes,
    workflowVersion: OvertimeWorkflowVersion.v2,
  );
}

OvertimeSession _approved(double hours) {
  final base = _pendingSession();
  return OvertimeSession(
    id: base.id,
    companyId: base.companyId,
    userId: base.userId,
    type: base.type,
    isOvernight: base.isOvernight,
    status: OvertimeStatus.approved,
    startAt: base.startAt,
    startGps: base.startGps,
    startDeviceId: base.startDeviceId,
    createdAt: base.createdAt,
    eligibleOvertimeMinutes: base.eligibleOvertimeMinutes,
    approvedHours: hours,
    workflowVersion: base.workflowVersion,
  );
}

class _NoopRepo extends Fake implements OvertimeRepository {}

class _FakeGetById extends GetOvertimeByIdUseCase {
  _FakeGetById(this.session) : super(_NoopRepo());
  OvertimeSession session;

  @override
  Future<Result<OvertimeSession>> call(String id) async => Success(session);
}

class _FakeApprove extends ApproveOvertimeUseCase {
  _FakeApprove() : super(_NoopRepo());

  final calls = <double?>[];
  Completer<Result<OvertimeSession>>? gate;

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) async {
    calls.add(approvedHours);
    if (gate != null) return gate!.future;
    return Success(_approved(approvedHours ?? 0));
  }
}

class _FakeReject extends RejectOvertimeUseCase {
  _FakeReject() : super(_NoopRepo());
}

/// Mirrors production `_PartialApproveDialog`: await approve, then pop.
class _TestPartialDialog extends StatefulWidget {
  const _TestPartialDialog({required this.cubit});
  final OvertimeDetailCubit cubit;

  @override
  State<_TestPartialDialog> createState() => _TestPartialDialogState();
}

class _TestPartialDialogState extends State<_TestPartialDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    final minutes = widget.cubit.state.session?.eligibleOvertimeMinutes ?? 0;
    _controller = TextEditingController(
      text: ApprovedHoursHhMm.formatFromMinutes(minutes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;
    final worked = widget.cubit.state.session?.eligibleOvertimeMinutes ?? 0;
    final parsed = ApprovedHoursHhMm.parseAndValidateAgainstWorked(
      raw: _controller.text,
      workedMinutes: worked,
    );
    final hours = parsed.apiHours;
    if (hours == null) return;

    setState(() => _submitting = true);
    await widget.cubit.approvePartial(approvedHours: hours);
    if (!mounted) return;
    if (widget.cubit.state.isError) {
      setState(() => _submitting = false);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final worked = widget.cubit.state.session?.eligibleOvertimeMinutes ?? 0;
    return AlertDialog(
      title: Text(l10n.overtimeApprovePartialTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          enabled: !_submitting,
          decoration: InputDecoration(
            labelText: l10n.overtimeApprovedHours,
            hintText: l10n.overtimeApprovedHoursHint,
          ),
          validator: (value) {
            final parsed = ApprovedHoursHhMm.parseAndValidateAgainstWorked(
              raw: value,
              workedMinutes: worked,
            );
            return parsed.isValid ? null : l10n.overtimeApprovedHoursInvalid;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _confirm,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.approve),
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApprovedHoursHhMm exact failure cases', () {
    test('10:20 → 620 minutes (not 10.20 decimal hours)', () {
      final parsed = ApprovedHoursHhMm.parse('10:20');
      expect(parsed.totalMinutes, 620);
      expect(parsed.apiHours, 10.33);
      expect(parsed.apiHours, isNot(10.20));
      // Decimal 10.20h would be 612 minutes — must never happen.
      expect((parsed.apiHours! * 60).round(), 620);
    });

    test('19:48 → 1188 minutes', () {
      final parsed = ApprovedHoursHhMm.parse('19:48');
      expect(parsed.totalMinutes, 1188);
      expect(parsed.apiHours, 19.8);
    });

    test('14:30 / 10:00 / 0:30', () {
      expect(ApprovedHoursHhMm.parse('14:30').totalMinutes, 870);
      expect(ApprovedHoursHhMm.parse('10:00').totalMinutes, 600);
      expect(ApprovedHoursHhMm.parse('0:30').totalMinutes, 30);
    });

    test('rejects 10:60, 14:75, abc, empty', () {
      expect(ApprovedHoursHhMm.parse('10:60').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse('14:75').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse('abc').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse('').isValid, isFalse);
    });
  });

  group('Partial Approve dialog lifecycle', () {
    late OvertimeDetailCubit cubit;
    late _FakeApprove approve;

    setUp(() async {
      approve = _FakeApprove();
      cubit = OvertimeDetailCubit(
        getById: _FakeGetById(_pendingSession()),
        approve: approve,
        reject: _FakeReject(),
        sessionId: 'ot-1',
      );
      await cubit.load();
    });

    tearDown(() async {
      await cubit.close();
    });

    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => _TestPartialDialog(cubit: cubit),
                      );
                    },
                    child: const Text('open-partial'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open-partial'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Partial Approve 10:20 succeeds and closes without dependents crash',
      (tester) async {
        await openDialog(tester);
        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), '10:20');
        await tester.pump();

        approve.gate = Completer<Result<OvertimeSession>>();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
        await tester.pump();

        expect(cubit.state.isApprovingPartial, isTrue);
        expect(cubit.state.isApproving, isFalse);
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        approve.gate!.complete(Success(_approved(10.33)));
        await tester.pumpAndSettle();

        expect(approve.calls, hasLength(1));
        expect(approve.calls.single, 10.33);
        expect(find.byType(AlertDialog), findsNothing);
        expect(cubit.state.isBusy, isFalse);
        expect(cubit.state.session?.status, OvertimeStatus.approved);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Partial Approve failure keeps dialog open and clears loading',
      (tester) async {
        await openDialog(tester);
        await tester.enterText(find.byType(TextFormField), '10:20');

        approve.gate = Completer<Result<OvertimeSession>>();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
        await tester.pump();

        approve.gate!.complete(const Failure('network'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(cubit.state.isBusy, isFalse);
        expect(cubit.state.isError, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
