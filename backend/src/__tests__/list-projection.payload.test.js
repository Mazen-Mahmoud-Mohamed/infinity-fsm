import overtimeService from '../modules/business/overtime/overtime.service.js';
import workOrdersService from '../modules/business/work-orders/work-orders.service.js';

function utf8Bytes(value) {
  return Buffer.byteLength(JSON.stringify(value), 'utf8');
}

function sampleGps(seed = 0) {
  return {
    latitude: 24.7136 + seed * 0.001,
    longitude: 46.6753 + seed * 0.001,
    accuracy: 8,
    heading: 90,
    speed: 0,
    altitude: 620,
    provider: 'gps',
    recordedAt: new Date('2026-08-12T08:00:00.000Z'),
    fullAddress: 'King Fahd Road, Riyadh, Saudi Arabia',
    street: 'King Fahd Road',
    area: 'Olaya',
    city: 'Riyadh',
    country: 'SA',
    addressResolvedAt: new Date('2026-08-12T08:00:05.000Z'),
  };
}

function sampleCheckpoint(seed) {
  const hour = 8 + seed;
  return {
    at: new Date(`2026-08-12T${String(hour).padStart(2, '0')}:00:00.000Z`),
    gps: sampleGps(seed),
    photo: { url: `https://cdn.example.com/overtime/photo-${seed}.jpg` },
    voiceNote: {
      url: `https://cdn.example.com/overtime/voice-${seed}.m4a`,
      publicId: `voice-${seed}`,
      duration: 42.5,
      size: 128000,
      format: 'm4a',
      uploadedAt: new Date(
        `2026-08-12T${String(hour).padStart(2, '0')}:01:00.000Z`
      ),
    },
    address: 'King Fahd Road, Riyadh',
    deviceId: 'device-tech-001',
    clientRequestId: `ot-cp-${seed}`,
    batteryLevel: 78,
    networkStatus: 'wifi',
    notes: 'Stage note with enough text to resemble real technician input.',
  };
}

function sampleOvertimeDoc() {
  return {
    _id: { toString: () => '64f000000000000000000001' },
    companyId: { toString: () => '64f0000000000000000000aa' },
    userId: {
      _id: { toString: () => '64f0000000000000000000bb' },
      firstName: 'Ahmed',
      lastName: 'Technician',
      email: 'ahmed@example.com',
      roles: ['TECHNICIAN'],
    },
    branchId: { toString: () => '64f0000000000000000000cc' },
    departmentId: { toString: () => '64f0000000000000000000dd' },
    type: 'NORMAL',
    isOvernight: false,
    status: 'PENDING_REVIEW',
    workflowVersion: 'v2',
    checkpoints: {
      startJourney: sampleCheckpoint(0),
      arrivedAtWorkSite: sampleCheckpoint(1),
      finishedWork: sampleCheckpoint(2),
      endJourney: sampleCheckpoint(3),
    },
    requiresManualReview: false,
    reviewReason: null,
    reviewNotes: 'Internal admin notes that should not appear in list cards.',
    startAt: new Date('2026-08-12T08:00:00.000Z'),
    startGps: sampleGps(0),
    startPhoto: { url: 'https://cdn.example.com/overtime/start.jpg' },
    startAddress: 'King Fahd Road, Riyadh',
    startDeviceId: 'device-tech-001',
    endAt: new Date('2026-08-12T16:00:00.000Z'),
    endGps: sampleGps(3),
    endPhoto: { url: 'https://cdn.example.com/overtime/end.jpg' },
    endAddress: 'King Fahd Road, Riyadh',
    endDeviceId: 'device-tech-001',
    totalDurationMinutes: 480,
    workingDurationMinutes: 360,
    eligibleOvertimeMinutes: 120,
    approvedHours: null,
    calculationVersion: 2,
    calculatedAt: new Date('2026-08-12T16:00:01.000Z'),
    approvedBy: null,
    approvedAt: null,
    rejectedBy: null,
    rejectedAt: null,
    rejectionReason: null,
    createdAt: new Date('2026-08-12T08:00:00.000Z'),
    updatedAt: new Date('2026-08-12T16:00:01.000Z'),
  };
}

function samplePhoto(i) {
  return {
    url: `https://cdn.example.com/wo/photo-${i}.jpg`,
    publicId: `wo-photo-${i}`,
    fileName: `photo-${i}.jpg`,
    mimeType: 'image/jpeg',
    uploadedAt: new Date('2026-08-12T10:00:00.000Z'),
    uploadedBy: { toString: () => '64f0000000000000000000bb' },
  };
}

function sampleWorkOrderDoc() {
  return {
    _id: { toString: () => '64f000000000000000000101' },
    companyId: { toString: () => '64f0000000000000000000aa' },
    jobNumber: 'WO-20260812-0001',
    jobTitle: 'HVAC repair at customer site',
    customerId: { toString: () => '64f0000000000000000000ee' },
    customerName: 'Acme Corp',
    customerAddress: {
      street: 'Olaya St',
      city: 'Riyadh',
      governorate: 'Riyadh',
      lat: 24.71,
      lng: 46.67,
    },
    locationLabel: 'Building A - Floor 3',
    assignedTechnicianId: { toString: () => '64f0000000000000000000bb' },
    assignedTechnicianName: 'Ahmed Technician',
    supervisorId: { toString: () => '64f0000000000000000000ff' },
    createdBy: { toString: () => '64f0000000000000000000ff' },
    organizationSnapshot: {
      companyId: { toString: () => '64f0000000000000000000aa' },
      branchId: { toString: () => '64f0000000000000000000cc' },
      regionId: null,
      cityId: null,
      departmentId: { toString: () => '64f0000000000000000000dd' },
      teamId: null,
    },
    priority: 'HIGH',
    status: 'IN_PROGRESS',
    description: 'Investigate AC failure and replace filter if needed.',
    notes: 'Customer prefers afternoon visit.',
    scheduledAt: new Date('2026-08-12T11:00:00.000Z'),
    attachments: Array.from({ length: 3 }, (_, i) => ({
      url: `https://cdn.example.com/wo/att-${i}.pdf`,
      publicId: `att-${i}`,
      fileName: `doc-${i}.pdf`,
      mimeType: 'application/pdf',
      uploadedAt: new Date('2026-08-12T09:00:00.000Z'),
    })),
    beforePhotos: Array.from({ length: 4 }, (_, i) => samplePhoto(i)),
    afterPhotos: Array.from({ length: 4 }, (_, i) => samplePhoto(i + 10)),
    progressPhotos: Array.from({ length: 6 }, (_, i) => samplePhoto(i + 20)),
    beforeNotes: 'Unit was offline on arrival.',
    progressNotes: Array.from({ length: 5 }, (_, i) => ({
      _id: { toString: () => `note-${i}` },
      text: `Progress update ${i}: replaced component and tested airflow.`,
      createdAt: new Date('2026-08-12T12:00:00.000Z'),
      createdBy: { toString: () => '64f0000000000000000000bb' },
      createdByName: 'Ahmed Technician',
    })),
    completionNotes: 'Work completed and verified with customer.',
    startedLocation: {
      latitude: 24.71,
      longitude: 46.67,
      accuracy: 10,
      recordedAt: new Date('2026-08-12T11:05:00.000Z'),
    },
    completedLocation: {
      latitude: 24.71,
      longitude: 46.67,
      accuracy: 9,
      recordedAt: new Date('2026-08-12T14:00:00.000Z'),
    },
    timeline: Array.from({ length: 12 }, (_, i) => ({
      type: 'STATUS_CHANGE',
      at: new Date('2026-08-12T11:00:00.000Z'),
      userId: { toString: () => '64f0000000000000000000bb' },
      userName: 'Ahmed Technician',
      note: `Timeline event ${i}`,
    })),
    estimatedDurationMinutes: 180,
    actualDurationMinutes: 175,
    startedAt: new Date('2026-08-12T11:05:00.000Z'),
    completedAt: null,
    cancelledAt: null,
    cancelledBy: null,
    cancellationReason: null,
    rejectedAt: null,
    rejectionReason: null,
    acceptedAt: new Date('2026-08-12T10:30:00.000Z'),
    createdAt: new Date('2026-08-12T09:00:00.000Z'),
    updatedAt: new Date('2026-08-12T14:00:00.000Z'),
  };
}

describe('list projection payload sizes', () => {
  it('overtime list projection is much smaller than full detail map', () => {
    const doc = sampleOvertimeDoc();
    const full = overtimeService._map(doc);
    const list = overtimeService._mapList(doc);

    const fullBytes = utf8Bytes(full);
    const listBytes = utf8Bytes(list);
    const pageFull = utf8Bytes({ items: Array.from({ length: 20 }, () => full) });
    const pageList = utf8Bytes({ items: Array.from({ length: 20 }, () => list) });

    // eslint-disable-next-line no-console
    console.log(
      JSON.stringify({
        overtime: {
          fullItemBytes: fullBytes,
          listItemBytes: listBytes,
          reductionPct: Number(
            (((fullBytes - listBytes) / fullBytes) * 100).toFixed(1)
          ),
          page20FullBytes: pageFull,
          page20ListBytes: pageList,
          page20ReductionPct: Number(
            (((pageFull - pageList) / pageFull) * 100).toFixed(1)
          ),
        },
      })
    );

    expect(list.checkpoints).toBeUndefined();
    expect(list.startGps).toBeUndefined();
    expect(list.startPhotoUrl).toBeUndefined();
    expect(full.checkpoints).toBeTruthy();
    expect(full.startGps).toBeTruthy();
    expect(listBytes).toBeLessThan(fullBytes * 0.25);
    expect(list.status).toBe('PENDING_REVIEW');
    expect(list.eligibleOvertimeMinutes).toBe(120);
    expect(list.technician.email).toBe('ahmed@example.com');
  });

  it('work order list projection is much smaller than full detail map', () => {
    const doc = sampleWorkOrderDoc();
    const full = workOrdersService._map(doc);
    const list = workOrdersService._mapList(doc);

    const fullBytes = utf8Bytes(full);
    const listBytes = utf8Bytes(list);
    const pageFull = utf8Bytes({ items: Array.from({ length: 20 }, () => full) });
    const pageList = utf8Bytes({ items: Array.from({ length: 20 }, () => list) });

    // eslint-disable-next-line no-console
    console.log(
      JSON.stringify({
        workOrders: {
          fullItemBytes: fullBytes,
          listItemBytes: listBytes,
          reductionPct: Number(
            (((fullBytes - listBytes) / fullBytes) * 100).toFixed(1)
          ),
          page20FullBytes: pageFull,
          page20ListBytes: pageList,
          page20ReductionPct: Number(
            (((pageFull - pageList) / pageFull) * 100).toFixed(1)
          ),
        },
      })
    );

    expect(list.beforePhotos).toBeUndefined();
    expect(list.timeline).toBeUndefined();
    expect(list.attachments).toBeUndefined();
    expect(full.beforePhotos.length).toBeGreaterThan(0);
    expect(full.timeline.length).toBeGreaterThan(0);
    expect(listBytes).toBeLessThan(fullBytes * 0.15);
    expect(list.jobNumber).toBe('WO-20260812-0001');
    expect(list.assignedTechnicianName).toBe('Ahmed Technician');
  });

  it('detail map retains heavy fields needed by detail pages', () => {
    const ot = overtimeService._map(sampleOvertimeDoc());
    expect(ot.checkpoints.startJourney.photoUrl).toContain('photo-0');
    expect(ot.checkpoints.startJourney.voiceNote.url).toContain('voice-0');
    expect(ot.startGps.latitude).toBeCloseTo(24.7136);

    const wo = workOrdersService._map(sampleWorkOrderDoc());
    expect(wo.progressPhotos.length).toBe(6);
    expect(wo.timeline.length).toBe(12);
    expect(wo.startedLocation.latitude).toBe(24.71);
  });
});
