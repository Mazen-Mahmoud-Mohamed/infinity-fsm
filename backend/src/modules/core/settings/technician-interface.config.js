export const TECHNICIAN_INTERFACE_KEY = 'technician_interface';

export const TECHNICIAN_INTERFACE_DEFAULTS = Object.freeze({
  overtime: true,
  workOrders: true,
  profile: true,
});

/**
 * Normalizes stored technician interface flags.
 * Unknown keys are ignored; missing keys fall back to defaults (all enabled).
 */
export function normalizeTechnicianInterface(value) {
  const source =
    value && typeof value === 'object' && !Array.isArray(value) ? value : {};

  return {
    overtime:
      typeof source.overtime === 'boolean'
        ? source.overtime
        : TECHNICIAN_INTERFACE_DEFAULTS.overtime,
    workOrders:
      typeof source.workOrders === 'boolean'
        ? source.workOrders
        : TECHNICIAN_INTERFACE_DEFAULTS.workOrders,
    profile:
      typeof source.profile === 'boolean'
        ? source.profile
        : TECHNICIAN_INTERFACE_DEFAULTS.profile,
  };
}

export function hasAnyTechnicianSectionEnabled(config) {
  return config.overtime || config.workOrders || config.profile;
}
