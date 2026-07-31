import { Router } from 'express';
import mongoose from 'mongoose';
import authRoutes from '../../modules/core/auth/auth.routes.js';
import organizationRoutes from '../../modules/core/organization/organization.routes.js';
import attendanceRoutes from '../../modules/business/attendance/attendance.routes.js';
import overtimeRoutes from '../../modules/business/overtime/overtime.routes.js';
import workOrderRoutes from '../../modules/business/work-orders/work-orders.routes.js';
import inventoryRoutes from '../../modules/business/inventory/inventory.routes.js';
import assetsRoutes from '../../modules/business/assets/assets.routes.js';
import pmRoutes from '../../modules/business/preventive-maintenance/pm.routes.js';
import reportsRoutes from '../../modules/business/service-reports/reports.routes.js';
import usersRoutes from '../../modules/core/user-management/users.routes.js';
import rolesRoutes from '../../modules/core/rbac/rbac.routes.js';
import settingsRoutes from '../../modules/core/settings/settings.routes.js';
import timeRoutes from '../../modules/core/time/time.routes.js';
import securityRoutes from '../../modules/core/security/security.routes.js';
import dashboardRoutes from '../../modules/core/dashboard/dashboard.routes.js';

const router = Router();

router.get('/health', (_req, res) => {
  const now = new Date();
  res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      uptime: process.uptime(),
      timestamp: now.toISOString(),
      utcNow: now.toISOString(),
      unixMs: now.getTime(),
    },
  });
});

router.get('/health/ready', (_req, res) => {
  const dbState = mongoose.connection.readyState;
  const isDbReady = dbState === 1;

  if (!isDbReady) {
    return res.status(503).json({
      success: false,
      error: {
        code: 'SERVICE_UNAVAILABLE',
        message: 'Database is not ready',
      },
      data: {
        mongodb: 'disconnected',
      },
    });
  }

  return res.status(200).json({
    success: true,
    data: {
      status: 'ready',
      mongodb: 'connected',
      timestamp: new Date().toISOString(),
    },
  });
});

router.use('/auth', authRoutes);
router.use('/organization', organizationRoutes);
router.use('/attendance', attendanceRoutes);
router.use('/overtime', overtimeRoutes);
router.use('/work-orders', workOrderRoutes);
router.use('/inventory', inventoryRoutes);
router.use('/assets', assetsRoutes);
router.use('/pm', pmRoutes);
router.use('/reports', reportsRoutes);
router.use('/users', usersRoutes);
router.use('/roles', rolesRoutes);
router.use('/settings', settingsRoutes);
router.use('/time', timeRoutes);
router.use('/security', securityRoutes);
router.use('/dashboard', dashboardRoutes);

export default router;
