/**
 * Checklist is owned by a Maintenance Plan.
 * This model documents the checklist item shape and supports
 * checklist-centric queries / future reusable templates.
 */
export {
  checklistItemSchema,
} from './maintenancePlan.model.js';

export const CHECKLIST_RESULT_VALUES = Object.freeze(['PASS', 'FAIL', 'NA']);
