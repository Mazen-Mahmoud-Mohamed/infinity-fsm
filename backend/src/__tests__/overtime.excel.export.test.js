import {
  formatDurationProseFromHours,
  formatDurationProseFromMinutes,
  formatExcelDuration,
  overnightLabel,
  buildOvertimeExcelWorkbook,
  computeEmployeeSummaries,
  getEmployeeSummaryColumnDefs,
  employeeSummaryRowValues,
  EXPORT_MODE,
  stripBidiMarks,
} from '../modules/business/overtime/overtime.excel.export.js';
import {
  excelStrings,
  statusLabel,
  typeLabel,
} from '../modules/business/overtime/overtime.excel.i18n.js';
import ExcelJS from 'exceljs';
import JSZip from 'jszip';

const LRO = '\u202D';
const PDF = '\u202C';
const LRM = '\u200E';
const RLM = '\u200F';

function expectPlainArabicDuration(actual, expectedLogical) {
  const value = String(actual);
  expect(value).toBe(expectedLogical);
  expect(value).not.toMatch(/[\u200E\u200F\u202A-\u202E\u2066-\u2069\u061C]/);
  const hoursMatch = expectedLogical.match(/^(\d+)\s+ساعة/);
  const minutesMatch = expectedLogical.match(/و\s+(\d+)\s+دقيقة/);
  if (hoursMatch && minutesMatch) {
    expect(value.indexOf(hoursMatch[1])).toBeLessThan(
      value.indexOf(minutesMatch[1])
    );
    expect(value.indexOf('ساعة')).toBeLessThan(value.indexOf('دقيقة'));
  }
}

function makeUser(id, first, last, email) {
  return {
    _id: { toString: () => id },
    firstName: first,
    lastName: last,
    email,
    employeeId: id,
  };
}

/** Screenshot regression fixture: Field Technician + test2 test. */
function makeScreenshotRegressionRecords() {
  const u1 = makeUser('u1', 'Field', 'Technician', 'test@gmail.com');
  const u2 = makeUser('u2', 'test2', 'test', 'test2@gmail.com');
  const records = [];
  const fieldEligible = [250, 250, 250, 250, 250, 172];
  for (let i = 0; i < 6; i += 1) {
    records.push({
      _id: { toString: () => `f${i}` },
      type: i === 5 ? 'TRAVEL' : 'NORMAL',
      status: i < 3 ? 'APPROVED' : 'PENDING_REVIEW',
      isOvernight: i === 5,
      startAt: new Date('2026-03-01T08:00:00.000Z'),
      endAt: new Date('2026-03-01T22:00:00.000Z'),
      createdAt: new Date('2026-03-01T07:55:00.000Z'),
      eligibleOvertimeMinutes: fieldEligible[i],
      workingDurationMinutes: fieldEligible[i],
      totalDurationMinutes: fieldEligible[i],
      approvedHours: null,
      userId: u1,
    });
  }
  records[0].approvedHours = 6;
  records[1].approvedHours = 6;
  records[2].approvedHours = (1124 - 720) / 60;

  const test2 = [
    { id: 't0', eligible: 300, status: 'APPROVED', overnight: true, approvedHours: 14.3 },
    { id: 't1', eligible: 300, status: 'PENDING_REVIEW', overnight: false },
    { id: 't2', eligible: 300, status: 'PENDING_REVIEW', overnight: false },
    { id: 't3', eligible: 288, status: 'PENDING_REVIEW', overnight: false },
  ];
  for (const row of test2) {
    records.push({
      _id: { toString: () => row.id },
      type: 'TRAVEL',
      status: row.status,
      isOvernight: !!row.overnight,
      startAt: new Date('2026-03-01T08:00:00.000Z'),
      endAt: new Date('2026-03-01T22:00:00.000Z'),
      createdAt: new Date('2026-03-01T07:55:00.000Z'),
      eligibleOvertimeMinutes: row.eligible,
      workingDurationMinutes: row.eligible,
      totalDurationMinutes: row.eligible,
      approvedHours: row.approvedHours ?? null,
      userId: u2,
    });
  }
  return records;
}

function findEmployeeHeaderRow(summary, empName) {
  let headerRowNumber = 0;
  summary.eachRow((row, rowNumber) => {
    if (String(row.getCell(1).value) === empName) {
      headerRowNumber = rowNumber;
    }
  });
  return headerRowNumber;
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

  test('formatExcelDuration always uses hours → ساعة → و → minutes → دقيقة', () => {
    expect(formatExcelDuration(2, 33)).toBe('2 ساعة و 33 دقيقة');
    expect(formatExcelDuration(23, 42)).toBe('23 ساعة و 42 دقيقة');
    expect(formatExcelDuration(18, 44)).toBe('18 ساعة و 44 دقيقة');
    expect(formatExcelDuration(19, 48)).toBe('19 ساعة و 48 دقيقة');
    expect(formatExcelDuration(14, 18)).toBe('14 ساعة و 18 دقيقة');
    expect(formatExcelDuration(0, 40)).toBe('40 دقيقة');
    expect(formatExcelDuration(2, 0)).toBe('2 ساعة');
  });

  test('Arabic durations are plain logical strings without bidi marks', () => {
    expectPlainArabicDuration(formatDurationProseFromMinutes(0, 'ar'), '0 دقيقة');
    expectPlainArabicDuration(formatDurationProseFromMinutes(1, 'ar'), '1 دقيقة');
    expectPlainArabicDuration(formatDurationProseFromMinutes(120, 'ar'), '2 ساعة');
    expectPlainArabicDuration(
      formatDurationProseFromMinutes(2 * 60 + 33, 'ar'),
      '2 ساعة و 33 دقيقة'
    );
    expectPlainArabicDuration(
      formatDurationProseFromMinutes(14 * 60 + 57, 'ar'),
      '14 ساعة و 57 دقيقة'
    );
    expectPlainArabicDuration(
      formatDurationProseFromMinutes(18 * 60 + 44, 'ar'),
      '18 ساعة و 44 دقيقة'
    );
    expectPlainArabicDuration(
      formatDurationProseFromMinutes(23 * 60 + 42, 'ar'),
      '23 ساعة و 42 دقيقة'
    );
    expectPlainArabicDuration(
      formatDurationProseFromMinutes(19 * 60 + 48, 'ar'),
      '19 ساعة و 48 دقيقة'
    );
    expectPlainArabicDuration(
      formatDurationProseFromMinutes(14 * 60 + 18, 'ar'),
      '14 ساعة و 18 دقيقة'
    );
    expectPlainArabicDuration(formatDurationProseFromMinutes(60, 'ar'), '1 ساعة');
    expectPlainArabicDuration(formatDurationProseFromMinutes(40, 'ar'), '40 دقيقة');
    expectPlainArabicDuration(
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

  test('Arabic workbook duration cells are plain text with LTR readingOrder', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    const summary = workbook.getWorksheet(t.sheetSummary);
    const found = [];
    summary.eachRow((row) => {
      row.eachCell((cell) => {
        const raw = cell.value == null ? '' : String(cell.value);
        if (raw.includes('ساعة') || raw.includes('دقيقة')) {
          found.push(cell);
        }
      });
    });
    expect(found.length).toBeGreaterThan(0);
    for (const cell of found) {
      const value = String(cell.value);
      expect(value).not.toMatch(/[\u200E\u200F\u202A-\u202E\u2066-\u2069\u061C]/);
      expect(cell.alignment?.readingOrder).toBe('ltr');
      const hoursMatch = value.match(/^(\d+)\s+ساعة/);
      const minutesMatch = value.match(/و\s+(\d+)\s+دقيقة/);
      if (hoursMatch && minutesMatch) {
        expect(value.indexOf(hoursMatch[1])).toBeLessThan(
          value.indexOf(minutesMatch[1])
        );
      }
    }
  });

  test('employee summary canonical columns are A:K with normal before travel', () => {
    const columns = getEmployeeSummaryColumnDefs('ar');
    expect(columns).toHaveLength(11);
    expect(columns.map((c) => c.key)).toEqual([
      'name',
      'email',
      'workedHours',
      'approvedHours',
      'totalSessions',
      'normalSessions',
      'travelSessions',
      'overnightSessions',
      'approvedSessions',
      'pendingSessions',
      'rejectedSessions',
    ]);
    const t = excelStrings('ar');
    expect(columns.map((c) => c.header)).toEqual([
      'اسم الموظف',
      'بريد الموظف',
      'إجمالي الساعات المحسوبة / الفعلية',
      'إجمالي الساعات المعتمدة',
      'إجمالي الجلسات',
      'الجلسات العادية',
      'جلسات السفر',
      'جلسات المبيت',
      'الجلسات المعتمدة',
      'الجلسات قيد المراجعة',
      'الجلسات المرفوضة',
    ]);
    expect(t.empName).toBe(columns[0].header);
  });

  test('screenshot regression: employee A:K mapping and durations in generated XLSX', async () => {
    const t = excelStrings('ar');
    const columns = getEmployeeSummaryColumnDefs('ar');
    const records = makeScreenshotRegressionRecords();
    const buffer = await buildOvertimeExcelWorkbook({
      records,
      generatedBy: 'Admin',
      generatedAt: new Date('2026-03-02T00:00:00.000Z'),
      companyName: 'Infinity',
      companyLogoUrl: '',
      appVersion: '1.0.0-test',
      mode: EXPORT_MODE.SUMMARY,
      language: 'ar',
      filters: { dateRange: 'All', status: 'ALL', type: 'ALL' },
    });

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer);
    const summary = workbook.getWorksheet(t.sheetSummary);
    expect(summary).toBeTruthy();
    // Column-LTR sheet so A is visually on the left (matches A:K semantic order).
    expect(Boolean(summary.views?.[0]?.rightToLeft)).toBe(false);

    const headerRowNumber = findEmployeeHeaderRow(summary, t.empName);
    expect(headerRowNumber).toBeGreaterThan(0);

    const headerRow = summary.getRow(headerRowNumber);
    const headers = columns.map((_, i) => String(headerRow.getCell(i + 1).value ?? ''));
    expect(headers).toEqual(columns.map((c) => c.header));
    expect(headers[5]).toBe('الجلسات العادية');
    expect(headers[6]).toBe('جلسات السفر');

    const row1 = summary.getRow(headerRowNumber + 1);
    const row2 = summary.getRow(headerRowNumber + 2);

    // First employee starts at A, not B — no leading empty cell.
    expect(row1.getCell(1).value).toBe('Field Technician');
    expect(row1.getCell(2).value).toBe('test@gmail.com');
    expect(row1.getCell(1).value).not.toBe('');
    expect(row1.getCell(1).value).not.toBeNull();
    const sparse = row1.values;
    if (Array.isArray(sparse) && sparse.length > 1) {
      expect(sparse[1]).toBe('Field Technician');
    }

    expectPlainArabicDuration(row1.getCell(3).value, '23 ساعة و 42 دقيقة');
    expectPlainArabicDuration(row1.getCell(4).value, '18 ساعة و 44 دقيقة');
    expect(row1.getCell(5).value).toBe(6);
    expect(row1.getCell(6).value).toBe(5); // F = normal
    expect(row1.getCell(7).value).toBe(1); // G = travel
    expect(row1.getCell(8).value).toBe(1);
    expect(row1.getCell(9).value).toBe(3);
    expect(row1.getCell(10).value).toBe(3);
    expect(row1.getCell(11).value).toBe(0);

    expect(row2.getCell(1).value).toBe('test2 test');
    expect(row2.getCell(2).value).toBe('test2@gmail.com');
    expectPlainArabicDuration(row2.getCell(3).value, '19 ساعة و 48 دقيقة');
    expectPlainArabicDuration(row2.getCell(4).value, '14 ساعة و 18 دقيقة');
    expect(row2.getCell(5).value).toBe(4);
    expect(row2.getCell(6).value).toBe(0);
    expect(row2.getCell(7).value).toBe(4);
    expect(row2.getCell(8).value).toBe(1);
    expect(row2.getCell(9).value).toBe(1);
    expect(row2.getCell(10).value).toBe(3);
    expect(row2.getCell(11).value).toBe(0);

    expect(row1.getCell(3).alignment?.readingOrder).toBe('ltr');
    expect(row1.getCell(4).alignment?.readingOrder).toBe('ltr');
    expect(row2.getCell(3).alignment?.readingOrder).toBe('ltr');
    expect(row2.getCell(4).alignment?.readingOrder).toBe('ltr');

    // OOXML: column-LTR sheet, duration readingOrder=1, plain strings, A before B.
    const zip = await JSZip.loadAsync(buffer);
    const sheetXml = await zip.file('xl/worksheets/sheet1.xml').async('string');
    const stylesXml = await zip.file('xl/styles.xml').async('string');
    const sharedXml = await zip.file('xl/sharedStrings.xml').async('string');

    expect(sheetXml).not.toContain('rightToLeft="1"');
    expect(stylesXml).toContain('readingOrder="1"');
    expect(sharedXml).not.toContain(LRO);
    expect(sharedXml).not.toContain(PDF);
    expect(sharedXml).not.toContain(LRM);
    expect(sharedXml).not.toContain(RLM);
    expect(sharedXml).toContain('23 ساعة و 42 دقيقة');
    expect(sharedXml).toContain('Field Technician');
    expect(sharedXml).toContain('test2 test');
    // Hours digit must appear before minutes digit in stored text.
    const durationIdx = sharedXml.indexOf('23 ساعة و 42 دقيقة');
    expect(durationIdx).toBeGreaterThan(-1);
    expect(sharedXml.indexOf('42', durationIdx)).toBeGreaterThan(
      sharedXml.indexOf('23', durationIdx)
    );

    const dataRowXml =
      sheetXml.match(
        new RegExp(`<row r="${headerRowNumber + 1}"[\\s\\S]*?</row>`)
      )?.[0] || '';
    expect(dataRowXml).toContain(`r="A${headerRowNumber + 1}"`);
    expect(dataRowXml).toContain(`r="B${headerRowNumber + 1}"`);
    expect(dataRowXml.indexOf(`r="A${headerRowNumber + 1}"`)).toBeLessThan(
      dataRowXml.indexOf(`r="B${headerRowNumber + 1}"`)
    );
    // Duration cells must use a style that includes readingOrder (s index with ltr).
    expect(dataRowXml).toMatch(
      new RegExp(`<c r="C${headerRowNumber + 1}" s="\\d+"`)
    );

    const summaries = computeEmployeeSummaries(records);
    const field = summaries.find((s) => s.email === 'test@gmail.com');
    const mapped = employeeSummaryRowValues(field, 'ar');
    expect(mapped.name).toBe('Field Technician');
    expect(mapped.normalSessions).toBe(5);
    expect(mapped.travelSessions).toBe(1);
    expect(Object.keys(mapped)).toEqual(columns.map((c) => c.key));
  });

  test('employee summary headers and row values stay column-aligned', async () => {
    const columns = getEmployeeSummaryColumnDefs('ar');
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    const summary = workbook.getWorksheet(t.sheetSummary);
    expect(summary).toBeTruthy();

    const headerRowNumber = findEmployeeHeaderRow(summary, t.empName);
    expect(headerRowNumber).toBeGreaterThan(0);

    const headerRow = summary.getRow(headerRowNumber);
    const headers = columns.map((_, i) => String(headerRow.getCell(i + 1).value ?? ''));
    expect(headers).toEqual(columns.map((c) => c.header));

    const dataRow = summary.getRow(headerRowNumber + 1);
    const values = columns.map((_, i) => dataRow.getCell(i + 1).value);
    expect(values[0]).toBe('Ada Lovelace');
    expect(values[1]).toBe('ada@example.com');
    expect(String(values[2])).toMatch(/ساعة|دقيقة/);
    expect(String(values[3])).toMatch(/ساعة|دقيقة/);
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
