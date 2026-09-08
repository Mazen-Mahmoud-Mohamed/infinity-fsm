import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockFindOne = jest.fn();
const mockAuditLog = jest.fn();

jest.unstable_mockModule(
  '../modules/business/work-orders/models/workOrder.model.js',
  () => ({
    default: {
      findOne: (...args) => mockFindOne(...args),
    },
    WORK_ORDER_STATUSES: Object.freeze([
      'PENDING',
      'ASSIGNED',
      'ACCEPTED',
      'REJECTED',
      'IN_PROGRESS',
      'COMPLETED',
      'CANCELLED',
    ]),
    WORK_ORDER_PRIORITIES: Object.freeze([
      'LOW',
      'MEDIUM',
      'HIGH',
      'CRITICAL',
    ]),
  })
);

jest.unstable_mockModule('../modules/core/audit/audit.service.js', () => ({
  default: {
    log: (...args) => mockAuditLog(...args),
  },
}));

const { default: workOrdersService } = await import(
  '../modules/business/work-orders/work-orders.service.js'
);
const { default: PERMISSIONS } = await import(
  '../shared/constants/permissions.constants.js'
);

const COMPANY_A = '64f0000000000000000000aa';
const COMPANY_B = '64f0000000000000000000bb';
const WO_ID = '64f000000000000000000101';
const TECH_ID = '64f0000000000000000000cc';
const OTHER_TECH_ID = '64f0000000000000000000dd';

function oid(value) {
  return { toString: () => value };
}

function samplePhoto(seed) {
  return {
    url: `https://cdn.example.com/wo/photo-${seed}.jpg`,
    publicId: `photo-${seed}`,
    fileName: `photo-${seed}.jpg`,
    mimeType: 'image/jpeg',
    uploadedAt: new Date('2026-08-12T10:00:00.000Z'),
    uploadedBy: oid(TECH_ID),
  };
}

function samplePlainDoc(overrides = {}) {
  return {
    _id: oid(WO_ID),
    companyId: oid(COMPANY_A),
    jobNumber: 'WO-20260812-0001',
    jobTitle: 'HVAC repair at customer site',
    customerId: oid('64f0000000000000000000ee'),
    customerName: 'Acme Corp',
    customerPhoneNumbers: ['+966500000001'],
    customerAddress: {
      street: 'Olaya St',
      city: 'Riyadh',
      governorate: 'Riyadh',
      lat: 24.71,
      lng: 46.67,
    },
    locationLabel: 'Building A - Floor 3',
    locationUrl: 'https://maps.example.com/?q=24.71,46.67',
    assignedTechnicianId: oid(TECH_ID),
    assignedTechnicianName: 'Ahmed Technician',
    assignedTechnicianIds: [oid(TECH_ID)],
    assignedTechnicianNames: ['Ahmed Technician'],
    supervisorId: oid('64f0000000000000000000ff'),
    createdBy: oid('64f0000000000000000000ff'),
    organizationSnapshot: {
      companyId: oid(COMPANY_A),
      branchId: oid('64f000000000000000000011'),
      regionId: null,
      cityId: null,
      departmentId: oid('64f000000000000000000022'),
      teamId: null,
    },
    priority: 'HIGH',
    status: 'IN_PROGRESS',
    description: 'Investigate AC failure.',
    notes: 'Customer prefers afternoon visit.',
    voiceNote: {
      url: 'https://cdn.example.com/wo/voice.m4a',
      publicId: 'voice-1',
      duration: 12,
      size: 1024,
      format: 'm4a',
      uploadedAt: new Date('2026-08-12T10:00:00.000Z'),
    },
    scheduledAt: new Date('2026-08-12T11:00:00.000Z'),
    attachments: [
      {
        url: 'https://cdn.example.com/wo/att-0.pdf',
        publicId: 'att-0',
        fileName: 'doc-0.pdf',
        mimeType: 'application/pdf',
        uploadedAt: new Date('2026-08-12T09:00:00.000Z'),
      },
    ],
    beforePhotos: [samplePhoto(1), samplePhoto(2)],
    afterPhotos: [samplePhoto(10)],
    progressPhotos: [samplePhoto(20), samplePhoto(21), samplePhoto(22)],
    beforeNotes: 'Unit was offline on arrival.',
    progressNotes: [
      {
        _id: oid('note-1'),
        text: 'Replaced filter',
        createdAt: new Date('2026-08-12T12:00:00.000Z'),
        createdBy: oid(TECH_ID),
        createdByName: 'Ahmed Technician',
      },
    ],
    completionNotes: null,
    startedLocation: {
      latitude: 24.71,
      longitude: 46.67,
      accuracy: 10,
      recordedAt: new Date('2026-08-12T11:05:00.000Z'),
    },
    completedLocation: null,
    timeline: [
      {
        type: 'CREATED',
        at: new Date('2026-08-12T09:00:00.000Z'),
        userId: oid('64f0000000000000000000ff'),
        userName: 'Admin',
        note: null,
      },
      {
        type: 'STARTED',
        at: new Date('2026-08-12T11:05:00.000Z'),
        userId: oid(TECH_ID),
        userName: 'Ahmed Technician',
        note: null,
      },
    ],
    estimatedDurationMinutes: 180,
    actualDurationMinutes: null,
    startedAt: new Date('2026-08-12T11:05:00.000Z'),
    completedAt: null,
    cancelledAt: null,
    cancelledBy: null,
    cancellationReason: null,
    rejectedAt: null,
    rejectionReason: null,
    acceptedAt: new Date('2026-08-12T10:30:00.000Z'),
    createdAt: new Date('2026-08-12T09:00:00.000Z'),
    updatedAt: new Date('2026-08-12T11:05:00.000Z'),
    deletedAt: null,
    ...overrides,
  };
}

function adminAuth() {
  return {
    companyId: COMPANY_A,
    permissions: [
      PERMISSIONS.WORK_ORDERS_VIEW_ALL,
      PERMISSIONS.WORK_ORDERS_UPDATE,
    ],
  };
}

function techAuth(userId = TECH_ID) {
  return {
    user: { _id: userId, roles: ['TECHNICIAN'] },
    auth: {
      companyId: COMPANY_A,
      permissions: [PERMISSIONS.WORK_ORDERS_VIEW_OWN],
    },
  };
}

describe('WorkOrdersService getById lean read path', () => {
  let lastQuery;
  let store;

  beforeEach(() => {
    mockFindOne.mockReset();
    mockAuditLog.mockReset();
    mockAuditLog.mockResolvedValue(undefined);
    lastQuery = null;
    const plain = samplePlainDoc();
    const save = jest.fn(async function persist() {
      this._savedDeletedAt = this.deletedAt;
      return this;
    });
    const hydrated = {
      ...plain,
      save,
      $isNew: false,
      constructor: { modelName: 'WorkOrder' },
    };
    store = { match: true, plain, hydrated, save };

    mockFindOne.mockImplementation((filter) => {
      const match =
        store.match &&
        String(filter._id) === WO_ID &&
        String(filter.companyId) === COMPANY_A &&
        filter.deletedAt === null;
      const query = {
        lean: jest.fn(async () => (match ? store.plain : null)),
        then(resolve, reject) {
          return Promise.resolve(match ? store.hydrated : null).then(
            resolve,
            reject
          );
        },
      };
      lastQuery = { filter, query };
      return query;
    });
  });

  it('getById maps a lean document to the same JSON as _map', async () => {
    const user = { _id: 'admin-1', roles: ['ADMIN'] };
    const mapped = await workOrdersService.getById(user, adminAuth(), WO_ID);

    expect(lastQuery.filter).toEqual({
      _id: WO_ID,
      companyId: COMPANY_A,
      deletedAt: null,
    });
    expect(lastQuery.query.lean).toHaveBeenCalledTimes(1);
    expect(store.save).not.toHaveBeenCalled();
    expect(mapped).toEqual(workOrdersService._map(store.plain));
    expect(mapped.beforePhotos).toHaveLength(2);
    expect(mapped.progressPhotos).toHaveLength(3);
    expect(mapped.afterPhotos).toHaveLength(1);
    expect(mapped.attachments).toHaveLength(1);
    expect(mapped.timeline).toHaveLength(2);
    expect(mapped.progressNotes).toHaveLength(1);
    expect(mapped.voiceNote.url).toContain('voice.m4a');
    expect(mapped.startedLocation.latitude).toBe(24.71);
  });

  it('keeps media and timeline keys required by Flutter detail', async () => {
    const mapped = await workOrdersService.getById(
      { _id: 'admin-1' },
      adminAuth(),
      WO_ID
    );
    for (const key of [
      'beforePhotos',
      'progressPhotos',
      'afterPhotos',
      'attachments',
      'timeline',
      'progressNotes',
      'voiceNote',
      'startedLocation',
      'notes',
      'createdAt',
      'updatedAt',
    ]) {
      expect(mapped).toHaveProperty(key);
    }
  });

  it('isolates by companyId (other company is not found)', async () => {
    await expect(
      workOrdersService.getById(
        { _id: 'admin-1' },
        { ...adminAuth(), companyId: COMPANY_B },
        WO_ID
      )
    ).rejects.toMatchObject({
      code: 'WORK_ORDER_NOT_FOUND',
      statusCode: 404,
    });
    expect(lastQuery.filter.companyId).toBe(COMPANY_B);
  });

  it('does not return soft-deleted work orders', async () => {
    store.match = false;
    await expect(
      workOrdersService.getById({ _id: 'admin-1' }, adminAuth(), WO_ID)
    ).rejects.toMatchObject({
      code: 'WORK_ORDER_NOT_FOUND',
      statusCode: 404,
    });
  });

  it('allows VIEW_ALL and VIEW_TEAM without being the assignee', async () => {
    const teamAuth = {
      companyId: COMPANY_A,
      permissions: [PERMISSIONS.WORK_ORDERS_VIEW_TEAM],
    };
    const mapped = await workOrdersService.getById(
      { _id: OTHER_TECH_ID },
      teamAuth,
      WO_ID
    );
    expect(mapped.id).toBe(WO_ID);
  });

  it('allows VIEW_OWN only for the assigned technician', async () => {
    const { user, auth } = techAuth(TECH_ID);
    const mapped = await workOrdersService.getById(user, auth, WO_ID);
    expect(mapped.id).toBe(WO_ID);

    const outsider = techAuth(OTHER_TECH_ID);
    await expect(
      workOrdersService.getById(outsider.user, outsider.auth, WO_ID)
    ).rejects.toMatchObject({
      statusCode: 403,
    });
  });

  it('_findActive still returns a hydrated document with save()', async () => {
    const record = await workOrdersService._findActive(WO_ID, COMPANY_A);
    expect(lastQuery.query.lean).not.toHaveBeenCalled();
    expect(record.constructor.modelName).toBe('WorkOrder');
    expect(typeof record.save).toBe('function');
    expect(record).toBe(store.hydrated);

    await record.save();
    expect(store.save).toHaveBeenCalledTimes(1);
  });

  it('mutation path still persists via hydrated .save()', async () => {
    const result = await workOrdersService.softDelete(
      { _id: 'admin-1', roles: ['ADMIN'] },
      adminAuth(),
      WO_ID
    );
    expect(result).toEqual({ id: WO_ID, deleted: true });
    expect(store.hydrated.deletedAt).toBeInstanceOf(Date);
    expect(store.save).toHaveBeenCalledTimes(1);
    expect(lastQuery.query.lean).not.toHaveBeenCalled();
    expect(mockAuditLog).toHaveBeenCalled();
  });

  it('keeps _findActive source free of lean() and getById on the read helper', () => {
    expect(workOrdersService._findActive.toString()).not.toMatch(/\.lean\s*\(/);
    expect(workOrdersService.getById.toString()).toMatch(/_findActiveRead/);
    expect(workOrdersService._findActiveRead.toString()).toMatch(/\.lean\s*\(/);
  });
});
