import { jest } from '@jest/globals';
import { getPermissionsForRoles } from '../shared/constants/permissions.constants.js';
import { ROLES } from '../shared/constants/roles.constants.js';
import { ForbiddenError, ValidationError } from '../shared/errors/AppError.js';

const mockFind = jest.fn();
const mockCreate = jest.fn();
const mockDeleteMany = jest.fn();
const mockFindOneAndDelete = jest.fn();
const mockInsertMany = jest.fn();

jest.unstable_mockModule(
  '../modules/core/settings/models/holiday.model.js',
  () => ({
    default: {
      find: mockFind,
      create: mockCreate,
      deleteMany: mockDeleteMany,
      findOneAndDelete: mockFindOneAndDelete,
      insertMany: mockInsertMany,
    },
  })
);

const { default: holidayService } = await import(
  '../modules/core/settings/holiday.service.js'
);

function leanList(docs) {
  return {
    sort: () => ({
      lean: async () => docs,
      select: () => ({
        sort: () => ({
          lean: async () => docs,
        }),
      }),
    }),
    select: () => ({
      sort: () => ({
        lean: async () => docs,
      }),
    }),
  };
}

describe('HolidayService authorization and isolation', () => {
  const companyA = 'aaaaaaaaaaaaaaaaaaaaaaaa';
  const companyB = 'bbbbbbbbbbbbbbbbbbbbbbbb';
  const adminAuth = {
    permissions: getPermissionsForRoles([ROLES.ADMIN]),
    roles: [ROLES.ADMIN],
  };
  const technicianAuth = {
    permissions: getPermissionsForRoles([ROLES.TECHNICIAN]),
    roles: [ROLES.TECHNICIAN],
  };
  const supervisorAuth = {
    permissions: getPermissionsForRoles([ROLES.SUPERVISOR]),
    roles: [ROLES.SUPERVISOR],
  };
  const adminUser = { _id: 'admin-1', companyId: companyA };
  const techUser = { _id: 'tech-1', companyId: companyA };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('allows technician to list holidays for their company', async () => {
    mockFind.mockReturnValue(
      leanList([{ _id: 'h1', date: '2026-01-01', name: null }])
    );

    const result = await holidayService.listHolidays(techUser, technicianAuth, {
      from: '2026-01-01',
      to: '2026-01-31',
    });

    expect(mockFind).toHaveBeenCalledWith({
      companyId: companyA,
      date: { $gte: '2026-01-01', $lte: '2026-01-31' },
    });
    expect(result.dates).toEqual(['2026-01-01']);
  });

  it('rejects technician create', async () => {
    await expect(
      holidayService.createHoliday(techUser, technicianAuth, {
        date: '2026-08-05',
      })
    ).rejects.toBeInstanceOf(ForbiddenError);
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it('rejects supervisor without manage_holidays on replace', async () => {
    await expect(
      holidayService.replaceHolidaysInRange(adminUser, supervisorAuth, {
        from: '2026-01-01',
        to: '2026-12-31',
        dates: ['2026-08-05'],
      })
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('rejects invalid dates on create', async () => {
    await expect(
      holidayService.createHoliday(adminUser, adminAuth, {
        date: '2026-02-30',
      })
    ).rejects.toBeInstanceOf(ValidationError);
  });

  it('rejects duplicate create via unique index', async () => {
    mockCreate.mockRejectedValue({ code: 11000 });
    await expect(
      holidayService.createHoliday(adminUser, adminAuth, {
        date: '2026-08-05',
      })
    ).rejects.toBeInstanceOf(ValidationError);
  });

  it('scopes getDateKeysForCompany to companyId', async () => {
    mockFind.mockReturnValue(
      leanList([{ date: '2026-08-05' }, { date: '2026-08-07' }])
    );
    const keys = await holidayService.getDateKeysForCompany(
      companyB,
      '2026-08-01',
      '2026-08-31'
    );
    expect(mockFind).toHaveBeenCalledWith({
      companyId: companyB,
      date: { $gte: '2026-08-01', $lte: '2026-08-31' },
    });
    expect(keys).toEqual(['2026-08-05', '2026-08-07']);
  });

  it('admin replace deletes then inserts within range', async () => {
    mockDeleteMany.mockResolvedValue({ deletedCount: 1 });
    mockInsertMany.mockResolvedValue([]);
    mockFind.mockReturnValue(
      leanList([{ _id: 'h2', date: '2026-08-05', name: null }])
    );

    const result = await holidayService.replaceHolidaysInRange(
      adminUser,
      adminAuth,
      {
        from: '2026-08-01',
        to: '2026-08-31',
        dates: ['2026-08-05', '2026-08-05'],
      }
    );

    expect(mockDeleteMany).toHaveBeenCalledWith({
      companyId: companyA,
      date: { $gte: '2026-08-01', $lte: '2026-08-31' },
    });
    expect(mockInsertMany).toHaveBeenCalled();
    const inserted = mockInsertMany.mock.calls[0][0];
    expect(inserted).toHaveLength(1);
    expect(inserted[0].date).toBe('2026-08-05');
    expect(inserted[0].companyId).toBe(companyA);
    expect(result.dates).toEqual(['2026-08-05']);
  });
});
