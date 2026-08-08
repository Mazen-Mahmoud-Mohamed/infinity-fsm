import {
  formatDurationProseFromHours,
  formatDurationProseFromMinutes,
  overnightLabel,
  buildOvertimeExcelWorkbook,
  computeEmployeeSummaries,
  getEmployeeSummaryColumnDefs,
  EXPORT_MODE,
  stripBidiMarks,
} from '../modules/business/overtime/overtime.excel.export.js';
import {
  excelStrings,
  statusLabel,
  typeLabel,
} from '../modules/business/overtime/overtime.excel.i18n.js';
import ExcelJS from 'exceljs';

const LRO = '\u202D';
const PDF = '\u202C';
const LRM = '\u200E';

function expectArabicDuration(actual, expectedLogical) {
  expect(stripBidiMarks(actual)).toBe(expectedLogical);
  expect(String(actual).startsWith(LRO)).toBe(true);
  expect(String(actual).endsWith(PDF)).toBe(true);
  // No per-digit LRM marks — they break Excel RTL rendering.
  expect(String(actual).includes(LRM)).toBe(false);
  // Hours digits must precede minutes digits in logical (storage) order.
  const hoursMatch = expectedLogical.match(/^(\d+)\s/);
  const minutesMatch = expectedLogical.match(/و\s+(\d+)\s/);
  if (hoursMatch && minutesMatch) {
    const stripped = stripBidiMarks(actual);
    expect(stripped.indexOf(hoursMatch[1])).toBeLessThan(
      stripped.indexOf(minutesMatch[1])
    );
  }
}

function makeRecord(overrides = {}) {
  return {
    _id: { toString: () => overrides.id || '507f1f77bcf86cd799439011' },
    type: 'TRAVEL',
    status: 'APPROVED',
    isOvernight: true,
    startAt: new Date('2026-03-01T08:00:00.000Z'),
    endAt: new Date('2026-03-01T22:57:00.000Z'),
    createdAt: new Date('2026-03-01T07:55:00.000Z'),
    eligibleOvertimeMinutes: 897,
    workingDurationMinutes: 480,
    totalDurationMinutes: 897,
    approvedHours: 10.33,
    reviewNotes: 'Partial approval',
    rejectionReason: null,
    userId: {
      _id: { toString: () => 'u-ada' },
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: 'ada@example.com',
      employeeId: 'E-100',
      jobTitle: 'Technician',
    },
    checkpoints: {},
    ...overrides,
  };
}

async function loadWorkbook({ mode = EXPORT_MODE.SUMMARY, language = 'en', records }) {
  const buffer = await buildOvertimeExcelWorkbook({
    records: records || [makeRecord()],
    generatedBy: 'Admin',
    generatedAt: new Date('2026-03-02T00:00:00.000Z'),
    companyName: 'Infinity',
    companyLogoUrl: '',
    appVersion: '1.0.0-test',
    mode,
    language,
    filters: {
      dateRange: 'All',
      status: 'ALL',
      type: 'ALL',
      mode,
      language,
    },
  });
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  return workbook;
}

function sheetText(sheet) {
  const text = [];
  sheet.eachRow((row) => {
    row.eachCell((cell) => {
      const v = cell.value;
      if (v == null) return;
      if (typeof v === 'object' && v.text) text.push(String(v.text));
      else text.push(String(v));
    });
  });
  return text.join(' | ');
}

function headerValues(sheet) {
  const row = sheet.getRow(1);
  const values = [];
  row.eachCell({ includeEmpty: false }, (cell) => {
    values.push(String(cell.value));
  });
  return values;
}

describe('overtime excel export helpers', () => {
  test('formats decimal hours as hours and minutes prose (English)', () => {
    expect(formatDurationProseFromHours(14.95, 'en')).toBe('14 hours 57 minutes');
    expect(formatDurationProseFromHours(10.33, 'en')).toBe('10 hours 20 minutes');
    expect(formatDurationProseFromMinutes(620, 'en')).toBe('10 hours 20 minutes');
    expect(formatDurationProseFromHours(0, 'en')).toBe('0 minutes');
    expect(formatDurationProseFromHours(null, 'en')).toBe('—');
  });

  test('English durations are not wrapped with bidi marks', () => {
    const value = formatDurationProseFromMinutes(897, 'en');
    expect(value).toBe('14 hours 57 minutes');
    expect(value.includes(LRO)).toBe(false);
    expect(value.includes(PDF)).toBe(false);
  });

  test('Arabic durations use full-string LRO and keep hours-before-minutes order', () => {
    expectArabicDuration(formatDurationProseFromMinutes(0, 'ar'), '0 دقيقة');
    expectArabicDuration(formatDurationProseFromMinutes(1, 'ar'), '1 دقيقة');
    expectArabicDuration(formatDurationProseFromMinutes(120, 'ar'), '2 ساعة');
    expectArabicDuration(
      formatDurationProseFromMinutes(2 * 60 + 33, 'ar'),
      '2 ساعة و 33 دقيقة'
    );
    expectArabicDuration(
      formatDurationProseFromMinutes(14 * 60 + 57, 'ar'),
      '14 ساعة و 57 دقيقة'
    );
    expectArabicDuration(
      formatDurationProseFromMinutes(44 * 60 + 18, 'ar'),
      '44 ساعة و 18 دقيقة'
    );
    expectArabicDuration(
      formatDurationProseFromMinutes(18 * 60 + 44, 'ar'),
      '18 ساعة و 44 دقيقة'
    );
    expectArabicDuration(
      formatDurationProseFromMinutes(23 * 60 + 42, 'ar'),
      '23 ساعة و 42 دقيقة'
    );
    expectArabicDuration(
      formatDurationProseFromMinutes(43 * 60 + 30, 'ar'),
      '43 ساعة و 30 دقيقة'
    );
    expectArabicDuration(formatDurationProseFromMinutes(60, 'ar'), 'ساعة واحدة');
    expectArabicDuration(formatDurationProseFromMinutes(40, 'ar'), '40 دقيقة');
    expectArabicDuration(
      formatDurationProseFromHours(14.95, 'ar'),
      '14 ساعة و 57 دقيقة'
    );
  });

  test('overnight label is travel-only and localized', () => {
    expect(overnightLabel({ type: 'NORMAL', isOvernight: true }, 'en')).toBe('—');
    expect(overnightLabel({ type: 'TRAVEL', isOvernight: true }, 'en')).toBe('Yes');
    expect(overnightLabel({ type: 'TRAVEL', isOvernight: false }, 'en')).toBe('No');
    expect(overnightLabel({ type: 'TRAVEL', isOvernight: true }, 'ar')).toBe('نعم');
    expect(overnightLabel({ type: 'TRAVEL', isOvernight: false }, 'ar')).toBe('لا');
  });

  test('status and type labels localize', () => {
    expect(statusLabel('APPROVED', 'en')).toBe('Approved');
    expect(statusLabel('APPROVED', 'ar')).toBe('معتمد');
    expect(typeLabel('TRAVEL', 'ar')).toBe('سفر');
  });
});

describe('employee summary aggregation', () => {
  test('aggregates hours from minutes and counts overnight only for travel', () => {
    const records = [
      makeRecord({
        id: '1',
        type: 'TRAVEL',
        status: 'APPROVED',
        isOvernight: true,
        eligibleOvertimeMinutes: 897,
        approvedHours: 10.33,
        userId: {
          _id: { toString: () => 'u-ada' },
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@example.com',
        },
      }),
      makeRecord({
        id: '2',
        type: 'NORMAL',
        status: 'PENDING_REVIEW',
        isOvernight: true,
        eligibleOvertimeMinutes: 120,
        approvedHours: null,
        userId: {
          _id: { toString: () => 'u-ada' },
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@example.com',
        },
      }),
      makeRecord({
        id: '3',
        type: 'TRAVEL',
        status: 'REJECTED',
        isOvernight: false,
        eligibleOvertimeMinutes: 60,
        approvedHours: null,
        userId: {
          _id: { toString: () => 'u-bob' },
          firstName: 'Bob',
          lastName: 'Builder',
          email: 'bob@example.com',
        },
      }),
    ];

    const summaries = computeEmployeeSummaries(records);
    expect(summaries).toHaveLength(2);

    const ada = summaries.find((s) => s.email === 'ada@example.com');
    expect(ada.totalSessions).toBe(2);
    expect(ada.normalSessions).toBe(1);
    expect(ada.travelSessions).toBe(1);
    expect(ada.overnightTrips).toBe(1);
    expect(ada.approvedSessions).toBe(1);
    expect(ada.pendingReviewSessions).toBe(1);
    expect(ada.rejectedSessions).toBe(0);
    expect(ada.totalWorkedMinutes).toBe(897 + 120);
    // 10.33 hours → round(10.33 * 60) = 620 minutes via resolveApprovedMinutes
    expect(ada.totalApprovedMinutes).toBe(620);
    expect(formatDurationProseFromMinutes(ada.totalApprovedMinutes, 'en')).toBe(
      '10 hours 20 minutes'
    );
    expect(formatDurationProseFromMinutes(ada.totalWorkedMinutes, 'en')).toBe(
      '16 hours 57 minutes'
    );

    const bob = summaries.find((s) => s.email === 'bob@example.com');
    expect(bob.totalSessions).toBe(1);
    expect(bob.overnightTrips).toBe(0);
    expect(bob.rejectedSessions).toBe(1);
    expect(bob.totalApprovedMinutes).toBe(0);
  });

  test('does not double-count sessions across technicians', () => {
    const records = [
      makeRecord({ id: 'a', userId: { _id: { toString: () => '1' }, firstName: 'A', email: 'a@x.com' } }),
      makeRecord({ id: 'b', userId: { _id: { toString: () => '1' }, firstName: 'A', email: 'a@x.com' } }),
      makeRecord({ id: 'c', userId: { _id: { toString: () => '2' }, firstName: 'B', email: 'b@x.com' } }),
    ];
    const summaries = computeEmployeeSummaries(records);
    expect(summaries.reduce((sum, s) => sum + s.totalSessions, 0)).toBe(3);
    expect(summaries).toHaveLength(2);
  });
});

describe('overtime excel workbook columns', () => {
  test('English summary has KPIs, employee table, no department/branch, no session sheets', async () => {
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'en' });
    expect(workbook.getWorksheet('Sessions Index')).toBeUndefined();
    expect(workbook.getWorksheet('Session 1')).toBeUndefined();
    const summary = workbook.getWorksheet('Summary');
    expect(summary).toBeTruthy();
    const joined = sheetText(summary);
    expect(joined).toMatch(/Overall Report KPIs/);
    expect(joined).toMatch(/Employee Summary/);
    expect(joined).toMatch(/Total Technicians/);
    expect(joined).toMatch(/Total Calculated \/ Worked Hours/);
    expect(joined).toMatch(/Total Approved Hours/);
    expect(joined).toMatch(/Pending \/ Review Sessions/);
    expect(joined).toMatch(/Rejected Sessions/);
    expect(joined).toMatch(/Overnight Sessions/);
    expect(joined).toMatch(/Ada Lovelace/);
    expect(joined).toMatch(/ada@example\.com/);
    expect(joined).toMatch(/10 hours 20 minutes/);
    expect(joined).toMatch(/14 hours 57 minutes/);
    expect(joined).not.toMatch(/Department/i);
    expect(joined).not.toMatch(/Branch/i);
  });

  test('Arabic summary localizes sheet name and labels', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    expect(workbook.getWorksheet('Summary')).toBeUndefined();
    const summary = workbook.getWorksheet(t.sheetSummary);
    expect(summary).toBeTruthy();
    const joined = sheetText(summary);
    expect(joined).toMatch(t.sectionKpis);
    expect(joined).toMatch(t.sectionEmployeeBreakdown);
    expect(joined).toMatch(t.kpiTotalTechnicians);
    expect(joined).toMatch(t.kpiTotalWorkedHours);
    expect(joined).toMatch(t.kpiTotalApprovedHours);
    expect(joined).toMatch(t.kpiPendingSessions);
    expect(joined).toMatch(t.kpiRejectedSessions);
    expect(stripBidiMarks(joined)).toMatch(/14 ساعة و 57 دقيقة/);
    expect(stripBidiMarks(joined)).toMatch(/10 ساعة و 20 دقيقة/);
    expect(joined).toMatch(/ada@example\.com/);
    expect(joined).not.toMatch(/Department/i);
    expect(joined).not.toMatch(/Branch/i);
  });

  test('detailed English index includes identity and duration columns without branch/department', async () => {
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.DETAILED, language: 'en' });
    const index = workbook.getWorksheet('Sessions Index');
    const headers = headerValues(index);
    expect(headers).toEqual(
      expect.arrayContaining([
        'Employee Name',
        'Email',
        'Start Time',
        'End Time',
        'Created At',
        'Overnight',
        'Worked Hours',
        'Calculated Hours',
        'Approved Hours',
      ])
    );
    expect(headers).not.toContain('Department');
    expect(headers).not.toContain('Branch');

    const dataRow = index.getRow(2);
    expect(dataRow.getCell(2).value).toBe('Ada Lovelace');
    expect(dataRow.getCell(3).value).toBe('ada@example.com');
    expect(dataRow.getCell(11).value).toBe('Yes');
    expect(String(dataRow.getCell(14).value)).toBe('10 hours 20 minutes');
  });

  test('detailed Arabic uses localized sheet and overnight labels', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.DETAILED, language: 'ar' });
    const index = workbook.getWorksheet(t.sheetSessionsIndex);
    expect(index).toBeTruthy();
    expect(workbook.getWorksheet(t.sheetSession(1))).toBeTruthy();
    const dataRow = index.getRow(2);
    expect(dataRow.getCell(11).value).toBe('نعم');
    expect(String(dataRow.getCell(10).value)).toBe('سفر');
    expect(String(dataRow.getCell(9).value)).toBe('معتمد');
  });

  test('Arabic workbook duration cells keep protected hours-before-minutes order', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    const summary = workbook.getWorksheet(t.sheetSummary);
    const found = [];
    summary.eachRow((row) => {
      row.eachCell((cell) => {
        const raw = cell.value == null ? '' : String(cell.value);
        if (raw.includes('ساعة') || raw.includes('دقيقة')) {
          found.push(raw);
        }
      });
    });
    expect(found.length).toBeGreaterThan(0);
    for (const value of found) {
      expect(value.startsWith(LRO)).toBe(true);
      expect(value.endsWith(PDF)).toBe(true);
      expect(value.includes(LRM)).toBe(false);
      const logical = stripBidiMarks(value);
      const hoursMatch = logical.match(/^(\d+)\s+ساعة/);
      const minutesMatch = logical.match(/و\s+(\d+)\s+دقيقة/);
      if (hoursMatch && minutesMatch) {
        expect(logical.indexOf(hoursMatch[1])).toBeLessThan(
          logical.indexOf(minutesMatch[1])
        );
      }
    }
  });

  test('employee summary headers and row values stay column-aligned', async () => {
    const columns = getEmployeeSummaryColumnDefs('ar');
    expect(columns).toHaveLength(11);
    expect(columns.map((c) => c.key)).toEqual([
      'name',
      'email',
      'workedHours',
      'approvedHours',
      'sessions',
      'travel',
      'normal',
      'overnight',
      'approved',
      'pending',
      'rejected',
    ]);

    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    const summary = workbook.getWorksheet(t.sheetSummary);
    expect(summary).toBeTruthy();

    // Locate the employee header row by the canonical first header.
    let headerRowNumber = 0;
    summary.eachRow((row, rowNumber) => {
      if (String(row.getCell(1).value) === t.empName) {
        headerRowNumber = rowNumber;
      }
    });
    expect(headerRowNumber).toBeGreaterThan(0);

    const headerRow = summary.getRow(headerRowNumber);
    const headers = columns.map((_, i) => String(headerRow.getCell(i + 1).value ?? ''));
    expect(headers).toEqual(columns.map((c) => c.header));
    expect(headers).toHaveLength(columns.length);

    const dataRow = summary.getRow(headerRowNumber + 1);
    const values = columns.map((_, i) => dataRow.getCell(i + 1).value);
    expect(values).toHaveLength(headers.length);
    expect(values[0]).toBe('Ada Lovelace');
    expect(values[1]).toBe('ada@example.com');
    expect(stripBidiMarks(String(values[2]))).toMatch(/ساعة|دقيقة/);
    expect(stripBidiMarks(String(values[3]))).toMatch(/ساعة|دقيقة/);

    // Ensure no off-by-one empty name column.
    expect(values[0]).not.toBeNull();
    expect(values[0]).not.toBe('');
    expect(String(values[0])).not.toMatch(/@/);

    const joined = sheetText(summary);
    expect(joined).not.toMatch(/Department/i);
    expect(joined).not.toMatch(/Branch/i);
    expect(joined).not.toMatch(/قسم|فرع/);
  });

  test('sessions index headers align with row values and exclude branch/department', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.DETAILED, language: 'ar' });
    const index = workbook.getWorksheet(t.sheetSessionsIndex);
    const headers = headerValues(index);
    expect(headers[0]).toBe(t.sessionId);
    expect(headers[1]).toBe(t.employeeName);
    expect(headers[2]).toBe(t.email);
    expect(headers).toHaveLength(15);
    expect(headers).not.toContain('Department');
    expect(headers).not.toContain('Branch');
    expect(headers.join(' ')).not.toMatch(/قسم|فرع/);

    const dataRow = index.getRow(2);
    expect(dataRow.getCell(1).value).toBeTruthy();
    expect(dataRow.getCell(2).value).toBe('Ada Lovelace');
    expect(dataRow.getCell(3).value).toBe('ada@example.com');
    expect(String(dataRow.getCell(9).value)).toBe(t.statusApproved);
    expect(String(dataRow.getCell(10).value)).toBe(t.typeTravel);
    expect(String(dataRow.getCell(11).value)).toBe(t.yes);
  });

  test('detailed session sheet includes email, overnight, times, and no department/branch', async () => {
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.DETAILED, language: 'en' });
    const sheet = workbook.getWorksheet('Session 1');
    expect(sheet).toBeTruthy();
    const joined = sheetText(sheet);
    expect(joined).toMatch(/Email/);
    expect(joined).toMatch(/ada@example\.com/);
    expect(joined).toMatch(/Overnight/);
    expect(joined).toMatch(/\bYes\b/);
    expect(joined).toMatch(/Start Time/);
    expect(joined).toMatch(/End Time/);
    expect(joined).toMatch(/Review Notes/);
    expect(joined).toMatch(/Partial approval/);
    expect(joined).toMatch(/10 hours 20 minutes/);
    expect(joined).not.toMatch(/Department/);
    expect(joined).not.toMatch(/\bBranch\b/);
  });
});
