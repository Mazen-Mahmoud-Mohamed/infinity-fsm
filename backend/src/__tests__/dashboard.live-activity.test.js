import {
  mapLiveActivityRow,
} from '../modules/core/dashboard/dashboard.service.js';
import dashboardService from '../modules/core/dashboard/dashboard.service.js';
import AuditLog from '../modules/core/audit/models/auditLog.model.js';

describe('dashboard liveActivity mapping', () => {
  it('maps populated actor using firstName/lastName when fullName missing', () => {
    const mapped = mapLiveActivityRow({
      _id: { toString: () => 'abc123' },
      action: 'auth.login',
      module: 'auth',
      actorId: { firstName: 'Mazen', lastName: 'Mahmoud' },
      createdAt: new Date('2026-08-24T07:32:37.818Z'),
    });

    expect(mapped).toEqual({
      id: 'abc123',
      action: 'auth.login',
      module: 'auth',
      actorName: 'Mazen Mahmoud',
      createdAt: '2026-08-24T07:32:37.818Z',
    });
  });

  it('prefers fullName when present (legacy populate shape)', () => {
    const mapped = mapLiveActivityRow({
      _id: 'id1',
      action: 'overtime.ended',
      module: 'overtime',
      actorId: {
        fullName: 'Display Name',
        firstName: 'A',
        lastName: 'B',
      },
      createdAt: new Date('2026-08-23T03:50:22.109Z'),
    });

    expect(mapped.actorName).toBe('Display Name');
  });

  it('returns null actorName when actor is missing', () => {
    const mapped = mapLiveActivityRow({
      _id: 'id2',
      action: 'system.event',
      module: 'system',
      actorId: null,
      createdAt: new Date('2026-08-23T00:00:00.000Z'),
    });

    expect(mapped.actorName).toBeNull();
  });

  it('returns null createdAt when missing', () => {
    const mapped = mapLiveActivityRow({
      _id: 'id3',
      action: 'x',
      module: 'y',
      actorId: null,
      createdAt: null,
    });

    expect(mapped.createdAt).toBeNull();
  });
});

describe('dashboard liveActivity $lookup parity vs find+populate', () => {
  const runLive = process.env.DASHBOARD_PARITY === '1';

  (runLive ? it : it.skip)(
    'matches legacy find+populate output for admin company scope',
    async () => {
      await import('dotenv/config');
      const mongoose = (await import('mongoose')).default;
      const User = (
        await import('../modules/core/organization/models/user.model.js')
      ).default;
      const { ROLES } = await import(
        '../shared/constants/roles.constants.js'
      );

      await mongoose.connect(process.env.MONGODB_URI, {
        serverSelectionTimeoutMS: 20000,
      });

      try {
        const admin = await User.findOne({ roles: ROLES.ADMIN });
        const companyId = admin.companyId;

        const legacyRows = await AuditLog.find({ companyId })
          .sort({ createdAt: -1 })
          .limit(10)
          .populate('actorId', 'firstName lastName fullName')
          .lean();
        const legacy = legacyRows.map((row) => mapLiveActivityRow(row));

        const optimized = await dashboardService._liveActivity(companyId, null);

        expect(optimized).toEqual(legacy);
        expect(optimized).toHaveLength(Math.min(10, legacy.length));
        for (const item of optimized) {
          expect(Object.keys(item).sort()).toEqual([
            'action',
            'actorName',
            'createdAt',
            'id',
            'module',
          ]);
        }
      } finally {
        await mongoose.disconnect();
      }
    },
    60000
  );

  (runLive ? it : it.skip)(
    'matches legacy find+populate when scoped to actor ids',
    async () => {
      await import('dotenv/config');
      const mongoose = (await import('mongoose')).default;
      const User = (
        await import('../modules/core/organization/models/user.model.js')
      ).default;
      const { ROLES } = await import(
        '../shared/constants/roles.constants.js'
      );

      await mongoose.connect(process.env.MONGODB_URI, {
        serverSelectionTimeoutMS: 20000,
      });

      try {
        const tech = await User.findOne({ roles: ROLES.TECHNICIAN });
        const companyId = tech.companyId;
        const ids = [tech._id];

        const legacyRows = await AuditLog.find({
          companyId,
          actorId: { $in: ids },
        })
          .sort({ createdAt: -1 })
          .limit(10)
          .populate('actorId', 'firstName lastName fullName')
          .lean();
        const legacy = legacyRows.map((row) => mapLiveActivityRow(row));
        const optimized = await dashboardService._liveActivity(companyId, ids);

        expect(optimized).toEqual(legacy);
      } finally {
        await mongoose.disconnect();
      }
    },
    60000
  );
});
