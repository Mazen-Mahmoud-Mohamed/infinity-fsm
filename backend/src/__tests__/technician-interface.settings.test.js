import { jest } from '@jest/globals';
import {
  TECHNICIAN_INTERFACE_DEFAULTS,
  normalizeTechnicianInterface,
  hasAnyTechnicianSectionEnabled,
} from '../modules/core/settings/technician-interface.config.js';
import { getPermissionsForRoles } from '../shared/constants/permissions.constants.js';
import { ROLES } from '../shared/constants/roles.constants.js';
import { ForbiddenError } from '../shared/errors/AppError.js';

describe('technician-interface.config', () => {
  it('defaults all sections to enabled when value is missing', () => {
    expect(normalizeTechnicianInterface(null)).toEqual(
      TECHNICIAN_INTERFACE_DEFAULTS
    );
    expect(normalizeTechnicianInterface(undefined)).toEqual(
      TECHNICIAN_INTERFACE_DEFAULTS
    );
  });

  it('preserves explicit boolean flags and fills missing keys from defaults', () => {
    expect(
      normalizeTechnicianInterface({
        overtime: false,
        workOrders: true,
      })
    ).toEqual({
      overtime: false,
      workOrders: true,
      attendance: true,
      profile: true,
    });
  });

  it('detects when no sections are enabled', () => {
    const config = normalizeTechnicianInterface({
      overtime: false,
      workOrders: false,
      attendance: false,
      profile: false,
    });
    expect(hasAnyTechnicianSectionEnabled(config)).toBe(false);
  });
});

describe('SettingsService technician interface authorization', () => {
  let settingsService;

  beforeAll(async () => {
    ({ default: settingsService } = await import(
      '../modules/core/settings/settings.service.js'
    ));
  });

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

  const user = { _id: 'user-1', companyId: 'company-1' };

  it('allows admin to read technician interface settings', async () => {
    const resolveSpy = jest
      .spyOn(settingsService, 'resolveTechnicianInterface')
      .mockResolvedValue(TECHNICIAN_INTERFACE_DEFAULTS);

    const result = await settingsService.getTechnicianInterfaceSettings(
      user,
      adminAuth
    );

    expect(result).toEqual(TECHNICIAN_INTERFACE_DEFAULTS);
    expect(resolveSpy).toHaveBeenCalledWith('company-1');
    resolveSpy.mockRestore();
  });

  it('blocks technician from reading admin technician interface settings', async () => {
    await expect(
      settingsService.getTechnicianInterfaceSettings(user, technicianAuth)
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('blocks supervisor from reading admin technician interface settings', async () => {
    await expect(
      settingsService.getTechnicianInterfaceSettings(user, supervisorAuth)
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('blocks technician from updating technician interface settings', async () => {
    await expect(
      settingsService.updateTechnicianInterfaceSettings(
        user,
        technicianAuth,
        { overtime: false }
      )
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('persists all four flags via admin update', async () => {
    const upsertSpy = jest
      .spyOn(settingsService, '_upsertSetting')
      .mockResolvedValue({});
    const logSpy = jest
      .spyOn(settingsService, '_logOvertimeAuditChange')
      .mockResolvedValue(undefined);
    jest.spyOn(settingsService, 'resolveTechnicianInterface').mockResolvedValue({
      overtime: true,
      workOrders: true,
      attendance: true,
      profile: true,
    });

    const payload = {
      overtime: false,
      workOrders: true,
      attendance: false,
      profile: true,
    };

    const result = await settingsService.updateTechnicianInterfaceSettings(
      user,
      adminAuth,
      payload
    );

    expect(result).toEqual(payload);
    expect(upsertSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        companyId: 'company-1',
        value: payload,
        group: 'technician_interface',
        dataType: 'object',
      })
    );

    upsertSpy.mockRestore();
    logSpy.mockRestore();
    settingsService.resolveTechnicianInterface.mockRestore();
  });

  it('allows any authenticated user to read effective technician config', async () => {
    const resolveSpy = jest
      .spyOn(settingsService, 'resolveTechnicianInterface')
      .mockResolvedValue({
        overtime: false,
        workOrders: true,
        attendance: false,
        profile: false,
      });

    const result = await settingsService.getTechnicianInterfaceConfig(user);

    expect(result).toEqual({
      overtime: false,
      workOrders: true,
      attendance: false,
      profile: false,
    });
    expect(resolveSpy).toHaveBeenCalledWith('company-1');
    resolveSpy.mockRestore();
  });
});
