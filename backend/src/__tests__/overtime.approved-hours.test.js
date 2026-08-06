import {
  minutesToHours,
  normalizeApprovedHoursInput,
  resolveApprovedHours,
  resolveApprovedMinutes,
  workedHoursFromRecord,
} from '../modules/business/overtime/overtime.approved-hours.js';

describe('overtime approvedHours helpers', () => {
  it('converts minutes to hours with 2 decimals', () => {
    expect(minutesToHours(90)).toBe(1.5);
    expect(minutesToHours(1140)).toBe(19);
    expect(minutesToHours(null)).toBeNull();
  });

  it('falls back approvedHours to worked hours when null', () => {
    const record = { eligibleOvertimeMinutes: 600, approvedHours: null };
    expect(workedHoursFromRecord(record)).toBe(10);
    expect(resolveApprovedHours(record)).toBe(10);
    expect(resolveApprovedMinutes(record)).toBe(600);
  });

  it('uses stored approvedHours when present', () => {
    const record = { eligibleOvertimeMinutes: 1140, approvedHours: 10 };
    expect(workedHoursFromRecord(record)).toBe(19);
    expect(resolveApprovedHours(record)).toBe(10);
    expect(resolveApprovedMinutes(record)).toBe(600);
  });

  it('normalizes full approval when approvedHours omitted', () => {
    expect(normalizeApprovedHoursInput(undefined, 19)).toEqual({
      ok: true,
      value: 19,
    });
  });

  it('rejects approvedHours above worked hours', () => {
    const result = normalizeApprovedHoursInput(20, 19);
    expect(result.ok).toBe(false);
  });

  it('accepts partial approvedHours within range', () => {
    expect(normalizeApprovedHoursInput(10, 19)).toEqual({
      ok: true,
      value: 10,
    });
    expect(normalizeApprovedHoursInput(0, 19)).toEqual({
      ok: true,
      value: 0,
    });
  });
});
