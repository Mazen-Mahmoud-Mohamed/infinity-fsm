import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:mobile/features/work_orders/domain/usecases/create_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/update_work_order_usecase.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_form_cubit.dart';

UserSummary _tech(String id, String name) {
  return UserSummary(
    id: id,
    code: id,
    name: name,
    status: 'ACTIVE',
    companyId: 'c1',
    email: '$id@example.com',
    firstName: name,
    lastName: 'Tech',
    fullName: name,
    roles: const ['TECHNICIAN'],
    branchId: 'b1',
    departmentId: 'd1',
  );
}

class _FakeOrgRepo implements OrganizationRepository {
  @override
  Future<Result<List<UserSummary>>> getUsers({
    String? search,
    bool forceRefresh = false,
  }) async {
    return Success([_tech('t1', 'Tech One'), _tech('t2', 'Tech Two')]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkOrderRepo implements WorkOrderRepository {
  WorkOrderUpsertInput? lastCreateInput;
  WorkOrderUpsertInput? lastUpdateInput;

  @override
  Future<Result<WorkOrder>> create(WorkOrderUpsertInput input) async {
    lastCreateInput = input;
    return Success(
      WorkOrder(
        id: 'new',
        companyId: 'c',
        jobNumber: 'WO-1',
        jobTitle: input.jobTitle,
        priority: input.priority,
        status: WorkOrderStatus.assigned,
        locationUrl: input.locationUrl,
        notes: input.notes,
        scheduledAt: input.scheduledAt,
        customerPhoneNumbers: input.customerPhoneNumbers,
        assignedTechnicianIds: input.assignedTechnicianIds,
        assignedTechnicianId: input.assignedTechnicianIds.isEmpty
            ? null
            : input.assignedTechnicianIds.first,
      ),
    );
  }

  @override
  Future<Result<WorkOrder>> update(String id, WorkOrderUpsertInput input) async {
    lastUpdateInput = input;
    return Success(
      WorkOrder(
        id: id,
        companyId: 'c',
        jobNumber: 'WO-1',
        jobTitle: input.jobTitle,
        priority: input.priority,
        status: WorkOrderStatus.assigned,
        locationUrl: input.locationUrl,
        notes: input.notes,
        scheduledAt: input.scheduledAt,
        customerPhoneNumbers: input.customerPhoneNumbers,
        assignedTechnicianIds: input.assignedTechnicianIds,
        assignedTechnicianId: input.assignedTechnicianIds.isEmpty
            ? null
            : input.assignedTechnicianIds.first,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('form cubit sends multiple technician ids and location URL', () async {
    final repo = _FakeWorkOrderRepo();
    final cubit = WorkOrderFormCubit(
      create: CreateWorkOrderUseCase(repo),
      update: UpdateWorkOrderUseCase(repo),
      getById: GetWorkOrderByIdUseCase(repo),
      organizationRepository: _FakeOrgRepo(),
    );

    await cubit.load();
    cubit.updateField(
      jobTitle: 'AC Install',
      locationUrl: 'https://maps.google.com/?q=24,46',
      notes: 'Bring ladder',
      scheduledAt: DateTime(2026, 8, 24, 10, 30),
    );
    cubit.toggleTechnician('t1');
    cubit.toggleTechnician('t2');
    cubit.addAttachment(
      const WorkOrderAttachmentInput(
        bytes: [1, 2, 3],
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
      ),
    );
    cubit.addAttachment(
      const WorkOrderAttachmentInput(
        bytes: [4, 5, 6],
        fileName: 'b.jpg',
        mimeType: 'image/jpeg',
      ),
    );
    cubit.setVoiceDraft(
      const OvertimeVoiceDraft(
        filePath: '/tmp/note.m4a',
        bytes: [9, 9],
        durationSeconds: 3,
      ),
    );

    await cubit.submit();

    expect(repo.lastCreateInput, isNotNull);
    expect(repo.lastCreateInput!.assignedTechnicianIds, ['t1', 't2']);
    expect(
      repo.lastCreateInput!.locationUrl,
      'https://maps.google.com/?q=24,46',
    );
    expect(repo.lastCreateInput!.description, isNull);
    expect(repo.lastCreateInput!.attachments.length, 2);
    expect(repo.lastCreateInput!.voiceNoteBytes, isNotNull);
    expect(repo.lastCreateInput!.scheduledAt!.hour, 10);
    expect(repo.lastCreateInput!.scheduledAt!.minute, 30);
    expect(repo.lastCreateInput!.customerPhoneNumbers, isEmpty);
    expect(cubit.state.status, WorkOrderFormStatus.success);
  });

  test('form cubit submits zero, one, and multiple phones; skips empties', () async {
    Future<WorkOrderFormCubit> freshCubit(_FakeWorkOrderRepo repo) async {
      final cubit = WorkOrderFormCubit(
        create: CreateWorkOrderUseCase(repo),
        update: UpdateWorkOrderUseCase(repo),
        getById: GetWorkOrderByIdUseCase(repo),
        organizationRepository: _FakeOrgRepo(),
      );
      await cubit.load();
      return cubit;
    }

    final repo = _FakeWorkOrderRepo();
    var cubit = await freshCubit(repo);
    cubit.updateField(jobTitle: 'Phones optional');
    await cubit.submit();
    expect(repo.lastCreateInput!.customerPhoneNumbers, isEmpty);

    cubit = await freshCubit(repo);
    cubit.updateField(jobTitle: 'One phone');
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(0, '+201012345678');
    await cubit.submit();
    expect(repo.lastCreateInput!.customerPhoneNumbers, ['+201012345678']);

    cubit = await freshCubit(repo);
    cubit.updateField(jobTitle: 'Multi phones');
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(0, '+201012345678');
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(1, ' ');
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(2, '+966501234567');
    await cubit.submit();
    expect(repo.lastCreateInput!.customerPhoneNumbers, [
      '+201012345678',
      '+966501234567',
    ]);
  });

  test('form cubit can remove an individual phone row', () async {
    final repo = _FakeWorkOrderRepo();
    final cubit = WorkOrderFormCubit(
      create: CreateWorkOrderUseCase(repo),
      update: UpdateWorkOrderUseCase(repo),
      getById: GetWorkOrderByIdUseCase(repo),
      organizationRepository: _FakeOrgRepo(),
    );
    await cubit.load();
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(0, '+201011111111');
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(1, '+201022222222');
    cubit.removePhoneNumberAt(0);
    expect(cubit.state.customerPhoneNumbers, ['+201022222222']);
  });

  test('form cubit rejects invalid phone', () async {
    final repo = _FakeWorkOrderRepo();
    final cubit = WorkOrderFormCubit(
      create: CreateWorkOrderUseCase(repo),
      update: UpdateWorkOrderUseCase(repo),
      getById: GetWorkOrderByIdUseCase(repo),
      organizationRepository: _FakeOrgRepo(),
    );
    await cubit.load();
    cubit.updateField(jobTitle: 'Bad phone');
    cubit.addPhoneNumberRow();
    cubit.updatePhoneNumberAt(0, '12');
    await cubit.submit();
    expect(repo.lastCreateInput, isNull);
    expect(cubit.state.message, 'workOrderCustomerPhoneInvalid');
  });

  test('form cubit rejects invalid location URL', () async {
    final repo = _FakeWorkOrderRepo();
    final cubit = WorkOrderFormCubit(
      create: CreateWorkOrderUseCase(repo),
      update: UpdateWorkOrderUseCase(repo),
      getById: GetWorkOrderByIdUseCase(repo),
      organizationRepository: _FakeOrgRepo(),
    );

    await cubit.load();
    cubit.updateField(jobTitle: 'Job', locationUrl: 'not-a-url');
    await cubit.submit();

    expect(repo.lastCreateInput, isNull);
    expect(cubit.state.message, 'workOrderLocationUrlInvalid');
    expect(cubit.state.isError, isTrue);
  });

  test('removing a pending attachment keeps others', () async {
    final repo = _FakeWorkOrderRepo();
    final cubit = WorkOrderFormCubit(
      create: CreateWorkOrderUseCase(repo),
      update: UpdateWorkOrderUseCase(repo),
      getById: GetWorkOrderByIdUseCase(repo),
      organizationRepository: _FakeOrgRepo(),
    );
    await cubit.load();
    cubit.addAttachment(
      const WorkOrderAttachmentInput(
        bytes: [1],
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
      ),
    );
    cubit.addAttachment(
      const WorkOrderAttachmentInput(
        bytes: [2],
        fileName: 'b.jpg',
        mimeType: 'image/jpeg',
      ),
    );
    cubit.removePendingAttachment(0);
    expect(cubit.state.pendingAttachments.length, 1);
    expect(cubit.state.pendingAttachments.first.fileName, 'b.jpg');
  });
}
