import { describe, it, expect } from '@jest/globals';
import workOrdersService, {
  normalizeCustomerPhoneNumbers,
  MAX_CUSTOMER_PHONE_NUMBERS,
} from '../modules/business/work-orders/work-orders.service.js';

describe('customerPhoneNumbers normalization', () => {
  it('returns undefined when field is omitted', () => {
    expect(normalizeCustomerPhoneNumbers(undefined)).toBeUndefined();
  });

  it('accepts empty array / empty string as []', () => {
    expect(normalizeCustomerPhoneNumbers([])).toEqual([]);
    expect(normalizeCustomerPhoneNumbers('')).toEqual([]);
    expect(normalizeCustomerPhoneNumbers('[]')).toEqual([]);
  });

  it('accepts one number', () => {
    expect(normalizeCustomerPhoneNumbers(['+201012345678'])).toEqual([
      '+201012345678',
    ]);
  });

  it('accepts multiple international-style numbers and trims', () => {
    expect(
      normalizeCustomerPhoneNumbers([
        ' +201012345678 ',
        '01098765432',
        '+966501234567',
      ])
    ).toEqual(['+201012345678', '01098765432', '+966501234567']);
  });

  it('dedupes by digit sequence without rewriting display form', () => {
    expect(
      normalizeCustomerPhoneNumbers(['+2010 1234 5678', '+201012345678'])
    ).toEqual(['+2010 1234 5678']);
  });

  it('skips blank entries', () => {
    expect(normalizeCustomerPhoneNumbers(['', '  ', '+201012345678'])).toEqual([
      '+201012345678',
    ]);
  });

  it('rejects numbers with too few digits', () => {
    expect(() => normalizeCustomerPhoneNumbers(['12345'])).toThrow(/7 and 15/);
  });

  it('rejects non-phone characters', () => {
    expect(() => normalizeCustomerPhoneNumbers(['call-me@home'])).toThrow(
      /punctuation|string/i
    );
  });

  it('enforces max count', () => {
    const many = Array.from(
      { length: MAX_CUSTOMER_PHONE_NUMBERS + 1 },
      (_, i) => `+2010${String(10000000 + i)}`
    );
    expect(() => normalizeCustomerPhoneNumbers(many)).toThrow(/at most/);
  });

  it('parses JSON string from multipart bodies', () => {
    expect(
      normalizeCustomerPhoneNumbers(JSON.stringify(['+201012345678', '01011112222']))
    ).toEqual(['+201012345678', '01011112222']);
  });
});

describe('WorkOrdersService mapping — customerPhoneNumbers', () => {
  function sampleDoc(overrides = {}) {
    return {
      _id: { toString: () => '64f000000000000000000001' },
      companyId: { toString: () => '64f0000000000000000000aa' },
      jobNumber: 'WO-0001',
      jobTitle: 'Install AC',
      customerName: 'Customer',
      customerPhoneNumbers: ['+201012345678', '+201098765432'],
      customerAddress: null,
      locationLabel: null,
      locationUrl: null,
      assignedTechnicianId: { toString: () => '64f0000000000000000000bb' },
      assignedTechnicianName: 'Tech One',
      assignedTechnicianIds: [{ toString: () => '64f0000000000000000000bb' }],
      assignedTechnicianNames: ['Tech One'],
      supervisorId: null,
      createdBy: { toString: () => '64f0000000000000000000dd' },
      organizationSnapshot: null,
      priority: 'MEDIUM',
      status: 'ASSIGNED',
      description: null,
      notes: null,
      voiceNote: undefined,
      scheduledAt: null,
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

  it('maps customerPhoneNumbers on detail', () => {
    const mapped = workOrdersService._map(sampleDoc());
    expect(mapped.customerPhoneNumbers).toEqual([
      '+201012345678',
      '+201098765432',
    ]);
  });

  it('maps missing customerPhoneNumbers as empty array', () => {
    const mapped = workOrdersService._map(
      sampleDoc({ customerPhoneNumbers: undefined })
    );
    expect(mapped.customerPhoneNumbers).toEqual([]);
  });

  it('keeps customer phones out of lightweight list projection', () => {
    const list = workOrdersService._mapList(sampleDoc());
    expect(list.customerPhoneNumbers).toBeUndefined();
    expect(list.attachments).toBeUndefined();
    expect(list.voiceNote).toBeUndefined();
  });
});
