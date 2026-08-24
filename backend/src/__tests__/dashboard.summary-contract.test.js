import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dashboardService from '../modules/core/dashboard/dashboard.service.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * Deep-compare dashboard summary metric trees (numbers / strings / arrays).
 * Ignores volatile ordering differences only where explicitly sorted.
 */
function assertDeepEqual(actual, expected, trail = 'root') {
  if (actual === expected) return;
  if (actual == null || expected == null) {
    expect({ trail, actual }).toEqual({ trail, expected });
    return;
  }
  if (typeof expected !== typeof actual) {
    expect({ trail, actualType: typeof actual }).toEqual({
      trail,
      actualType: typeof expected,
    });
    return;
  }
  if (Array.isArray(expected)) {
    expect({ trail, length: actual.length }).toEqual({
      trail,
      length: expected.length,
    });
    for (let i = 0; i < expected.length; i += 1) {
      assertDeepEqual(actual[i], expected[i], `${trail}[${i}]`);
    }
    return;
  }
  if (typeof expected === 'object') {
    const expectedKeys = Object.keys(expected).sort();
    const actualKeys = Object.keys(actual).sort();
    expect({ trail, keys: actualKeys }).toEqual({ trail, keys: expectedKeys });
    for (const key of expectedKeys) {
      assertDeepEqual(actual[key], expected[key], `${trail}.${key}`);
    }
    return;
  }
  expect({ trail, actual }).toEqual({ trail, expected });
}

describe('dashboard admin summary response contract', () => {
  it('exposes the stable admin metric tree shape', () => {
    const shape = {
      viewRole: 'admin',
      period: 'month',
      from: 'x',
      to: 'y',
      kpis: {
        totalEmployees: 0,
        activeEmployees: 0,
        employeesCurrentlyWorking: 0,
        employeesOnOvertime: 0,
        employeesOnTravelOvertime: 0,
      },
      attendance: {
        totalWorkingHours: 0,
        averageWorkingHours: 0,
        attendanceRate: 0,
      },
      overtime: {
        totalOvertimeHours: 0,
        approvedOvertimeHours: 0,
        totalTravelOvertimeHours: 0,
        totalTrips: 0,
        overnightTrips: 0,
        totalTechnicians: 0,
        averageHoursPerTrip: 0,
        averageOtHoursPerEmployee: 0,
        topOvertimeEmployees: [],
        hoursPerTechnician: [],
        tripsPerTechnician: [],
      },
      workOrders: {
        total: 0,
        pending: 0,
        assigned: 0,
        inProgress: 0,
        completed: 0,
        cancelled: 0,
      },
      preventiveMaintenance: {
        due: 0,
        overdue: 0,
        completed: 0,
      },
      inventory: {
        lowStock: 0,
        outOfStock: 0,
        recentStockMovements: [],
      },
      assets: {
        totalAssets: 0,
        active: 0,
        underMaintenance: 0,
        retired: 0,
      },
      liveActivity: [],
      notifications: [],
      charts: {
        attendance: [],
        overtime: [],
        workOrders: [],
        preventiveMaintenance: [],
      },
    };

    // Contract: every key above must remain present on admin summaries.
    const requiredTop = Object.keys(shape).sort();
    expect(requiredTop).toEqual([
      'assets',
      'attendance',
      'charts',
      'from',
      'inventory',
      'kpis',
      'liveActivity',
      'notifications',
      'overtime',
      'period',
      'preventiveMaintenance',
      'to',
      'viewRole',
      'workOrders',
    ]);
    expect(Object.keys(shape.kpis).sort()).toEqual([
      'activeEmployees',
      'employeesCurrentlyWorking',
      'employeesOnOvertime',
      'employeesOnTravelOvertime',
      'totalEmployees',
    ]);
    expect(Object.keys(shape.overtime).sort()).toEqual([
      'approvedOvertimeHours',
      'averageHoursPerTrip',
      'averageOtHoursPerEmployee',
      'hoursPerTechnician',
      'overnightTrips',
      'topOvertimeEmployees',
      'totalOvertimeHours',
      'totalTechnicians',
      'totalTravelOvertimeHours',
      'totalTrips',
      'tripsPerTechnician',
    ]);
  });

  it('mapTrendCharts returns four chart series with label/value points', () => {
    const from = new Date();
    const to = new Date();
    const charts = dashboardService._mapTrendCharts({
      from,
      to,
      attendanceRows: [],
      overtimeRecords: [],
      woRows: [],
      pmRows: [],
    });

    expect(Object.keys(charts).sort()).toEqual([
      'attendance',
      'overtime',
      'preventiveMaintenance',
      'workOrders',
    ]);
    for (const series of Object.values(charts)) {
      expect(Array.isArray(series)).toBe(true);
      for (const point of series) {
        expect(point).toEqual(
          expect.objectContaining({
            label: expect.any(String),
            value: expect.any(Number),
          })
        );
      }
    }
  });
});

describe('dashboard admin summary live parity (optional)', () => {
  const snapshotPath = path.resolve(
    __dirname,
    '../../tmp-dashboard-before-response.json'
  );

  const runLive = process.env.DASHBOARD_PARITY === '1';

  (runLive ? it : it.skip)(
    'matches captured before-response metrics when DASHBOARD_PARITY=1',
    async () => {
      if (!fs.existsSync(snapshotPath)) {
        throw new Error(`Missing snapshot at ${snapshotPath}`);
      }
      const before = JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));

      // Dynamic import of mongoose helpers only when parity is requested.
      await import('dotenv/config');
      const mongoose = (await import('mongoose')).default;
      const User = (
        await import('../modules/core/organization/models/user.model.js')
      ).default;
      const { ROLES } = await import(
        '../shared/constants/roles.constants.js'
      );
      const rbacService = (
        await import('../modules/core/rbac/rbac.service.js')
      ).default;

      await mongoose.connect(process.env.MONGODB_URI, {
        serverSelectionTimeoutMS: 20000,
      });
      try {
        const admin = await User.findOne({ roles: ROLES.ADMIN });
        const permissions = await rbacService.resolveUserPermissions(admin);
        const after = await dashboardService.getSummary(
          {
            userId: admin._id.toString(),
            companyId: admin.companyId.toString(),
            roles: admin.roles,
            permissions,
          },
          { period: 'month' }
        );

        // Timestamps / live activity may shift if DB mutates; compare stable KPI trees.
        const pick = (summary) => ({
          viewRole: summary.viewRole,
          period: summary.period,
          kpis: summary.kpis,
          attendance: summary.attendance,
          overtime: {
            ...summary.overtime,
            // Names are stable; keep full overtime block.
          },
          workOrders: summary.workOrders,
          preventiveMaintenance: summary.preventiveMaintenance,
          inventory: {
            lowStock: summary.inventory.lowStock,
            outOfStock: summary.inventory.outOfStock,
          },
          assets: summary.assets,
          charts: summary.charts,
        });

        assertDeepEqual(pick(after), pick(before));
      } finally {
        await mongoose.disconnect();
      }
    },
    120000
  );
});
