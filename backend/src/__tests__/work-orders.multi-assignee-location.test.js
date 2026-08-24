import {
  describe,
  it,
  expect,
  beforeEach,
  jest,
} from '@jest/globals';

/**
 * Focused unit tests for Work Order multi-assignee + locationUrl mapping helpers.
 * These import the service module and exercise _map / assignee resolution via
 * documented public mapping behavior on sample documents.
 */

import workOrdersService from '../modules/business/work-orders/work-orders.service.js';

function sampleDoc(overrides = {}) {
  return {
    _id: { toString: () => '64f000000000000000000001' },
    companyId: { toString: () => '64f0000000000000000000aa' },
    jobNumber: 'WO-0001',
    jobTitle: 'Install AC',
    customerName: 'Customer',
    customerAddress: null,
    locationLabel: 'https://maps.google.com/?q=24.7,46.6',
    locationUrl: 'https://maps.google.com/?q=24.7,46.6',
    assignedTechnicianId: { toString: () => '64f0000000000000000000bb' },
    assignedTechnicianName: 'Tech One',
    assignedTechnicianIds: [
      { toString: () => '64f0000000000000000000bb' },
      { toString: () => '64f0000000000000000000cc' },
    ],
    assignedTechnicianNames: ['Tech One', 'Tech Two'],
    supervisorId: null,
    createdBy: { toString: () => '64f0000000000000000000dd' },
    organizationSnapshot: null,
    priority: 'CRITICAL',
    status: 'ASSIGNED',
    description: 'Legacy description',
    notes: 'Admin notes',
    voiceNote: {
      url: 'https://cdn.example.com/voice.m4a',
      publicId: 'voice-1',
      duration: 12,
      size: 1024,
      format: 'm4a',
      uploadedAt: new Date('2026-08-24T10:00:00.000Z'),
    },
    scheduledAt: new Date('2026-08-24T10:30:00.000Z'),
    attachments: [],
    beforePhotos: [],
    afterPhotos: [],
    progressPhotos: [],
    beforeNotes: null,
    progressNotes: [],
    completionNotes: null,
    startedLocation: null,
    completedLocation: null,
    timeline: [],
    estimatedDurationMinutes: null,
    actualDurationMinutes: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
    cancelledBy: null,
    cancellationReason: null,
    rejectedAt: null,
    rejectionReason: null,
    acceptedAt: null,
    createdAt: new Date('2026-08-24T08:00:00.000Z'),
    updatedAt: new Date('2026-08-24T08:00:00.000Z'),
    ...overrides,
  };
}

describe('WorkOrdersService mapping — locationUrl + multi-assignee', () => {
  it('maps locationUrl and multi-technician fields', () => {
    const mapped = workOrdersService._map(sampleDoc());
    expect(mapped.locationUrl).toBe('https://maps.google.com/?q=24.7,46.6');
    expect(mapped.assignedTechnicianIds).toEqual([
      '64f0000000000000000000bb',
      '64f0000000000000000000cc',
    ]);
    expect(mapped.assignedTechnicianNames).toEqual(['Tech One', 'Tech Two']);
    expect(mapped.assignedTechnicianId).toBe('64f0000000000000000000bb');
    expect(mapped.voiceNote?.url).toBe('https://cdn.example.com/voice.m4a');
    expect(mapped.scheduledAt).toBe('2026-08-24T10:30:00.000Z');
    expect(mapped.description).toBe('Legacy description');
  });

  it('falls back to single assignee when assignedTechnicianIds is empty', () => {
    const mapped = workOrdersService._map(
      sampleDoc({
        assignedTechnicianIds: [],
        assignedTechnicianNames: [],
      })
    );
    expect(mapped.assignedTechnicianIds).toEqual(['64f0000000000000000000bb']);
    expect(mapped.assignedTechnicianNames).toEqual(['Tech One']);
  });

  it('list projection includes multi-assignee fields without heavy payloads', () => {
    const mapped = workOrdersService._mapList(sampleDoc());
    expect(mapped.assignedTechnicianIds).toHaveLength(2);
    expect(mapped.attachments).toBeUndefined();
    expect(mapped.voiceNote).toBeUndefined();
    expect(mapped.locationUrl).toBeUndefined();
  });
});
