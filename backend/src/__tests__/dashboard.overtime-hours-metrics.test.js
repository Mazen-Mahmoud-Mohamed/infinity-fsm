import {
  overtimeRecordApprovedKpiMinutes,
  overtimeRecordTrendMinutes,
} from '../modules/core/dashboard/dashboard.service.js';

describe('dashboard overtime KPI: approved vs total', () => {
  it('approved KPI minutes include only APPROVED sessions', () => {
    const approved = {
      status: 'APPROVED',
      approvedHours: 2,
      eligibleOvertimeMinutes: 9999,
    };

    const pending = {
      status: 'PENDING_REVIEW',
      approvedHours: null,
      eligibleOvertimeMinutes: 12 * 60 + 30,
    };

    const rejected = {
      status: 'REJECTED',
      approvedHours: null,
      eligibleOvertimeMinutes: 3 * 60,
    };

    const records = [approved, pending, rejected];

    const totalMinutes = records.reduce(
      (sum, r) => sum + overtimeRecordTrendMinutes(r),
      0
    );
    const approvedMinutes = records.reduce(
      (sum, r) => sum + overtimeRecordApprovedKpiMinutes(r),
      0
    );

    // Total includes all statuses.
    expect(totalMinutes).toBe(
      overtimeRecordTrendMinutes(approved) +
        overtimeRecordTrendMinutes(pending) +
        overtimeRecordTrendMinutes(rejected)
    );

    // Approved KPI excludes pending and rejected.
    expect(approvedMinutes).toBe(overtimeRecordTrendMinutes(approved));
    expect(approvedMinutes).not.toBe(totalMinutes);
  });

  it('approved KPI uses approvedHours fallback semantics for APPROVED records', () => {
    const approvedLegacy = {
      status: 'APPROVED',
      approvedHours: null, // legacy / full-approval equivalent
      eligibleOvertimeMinutes: 7 * 60 + 15,
    };

    expect(overtimeRecordApprovedKpiMinutes(approvedLegacy)).toBe(
      overtimeRecordTrendMinutes(approvedLegacy)
    );
  });

  it('pending/rejected are excluded even if approvedHours is present', () => {
    const pendingWithApprovedHours = {
      status: 'PENDING_REVIEW',
      approvedHours: 10,
      eligibleOvertimeMinutes: 1,
    };

    expect(overtimeRecordTrendMinutes(pendingWithApprovedHours)).toBe(
      Math.floor(10 * 60)
    );
    expect(overtimeRecordApprovedKpiMinutes(pendingWithApprovedHours)).toBe(0);
  });
});

