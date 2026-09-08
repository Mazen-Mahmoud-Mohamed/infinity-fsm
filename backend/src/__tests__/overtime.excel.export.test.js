import {
  formatDurationProseFromHours,
  formatDurationProseFromMinutes,
  formatExcelDuration,
  overnightLabel,
  buildOvertimeExcelWorkbook,
  computeEmployeeSummaries,
  getEmployeeSummaryColumnDefs,
  employeeSummaryRowValues,
  excelSerialFromMinutes,
  countedVacationDayKeysForRecord,
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

function minutesFromExcelCell(cell) {
  const value = cell?.value;
  if (typeof value === 'number') {
    return Math.round(value * 24 * 60);
  }
  if (value instanceof Date) {
    return (
      value.getUTCHours() * 60 +
      value.getUTCMinutes() +
      Math.round(value.getUTCSeconds() / 60)
    );
  }
  if (value && typeof value === 'object' && typeof value.result === 'number') {
    return Math.round(value.result * 24 * 60);
  }
  return null;
}

function expectExcelDurationMinutes(cell, minutes) {
  expect(minutesFromExcelCell(cell)).toBe(minutes);
  expect(String(cell.numFmt || '')).toMatch(/\[h\]:mm/i);
}

function expectPhoneText(cell, expected) {
  expect(cell.value).toBe(expected);
  expect(typeof cell.value).toBe('string');
  expect(String(cell.numFmt || '')).toContain('@');
}

function makeUser(id, first, last, email, phone = null) {
  return {
    _id: { toString: () => id },
    firstName: first,
    lastName: last,
    email,
    employeeId: id,
    phone,
  };
}

/** Screenshot regression fixture: Field Technician + test2 test. */
function makeScreenshotRegressionRecords() {
  const u1 = makeUser('u1', 'Field', 'Technician', 'test@gmail.com', '01234567890');
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

function collectKpiPairs(sheet, kpiSectionTitle, employeeSectionTitle) {
  let start = 0;
  let end = Number.POSITIVE_INFINITY;
  sheet.eachRow((row, rowNumber) => {
    if (String(row.getCell(1).value) === kpiSectionTitle) start = rowNumber;
    if (String(row.getCell(1).value) === employeeSectionTitle) {
      end = rowNumber;
    }
  });
  const pairs = [];
  for (let r = start + 1; r < end; r += 3) {
    const labelRow = sheet.getRow(r);
    const valueRow = sheet.getRow(r + 1);
    const occupied = [];
    for (let c = 1; c <= 4; c += 1) {
      const label = labelRow.getCell(c).value;
      if (label == null || String(label).trim() === '') continue;
      occupied.push(c);
      pairs.push({
        label: String(label),
        cell: valueRow.getCell(c),
        col: c,
        labelRow: r,
      });
    }
    if (occupied.length > 0) {
      const last = occupied[occupied.length - 1];
      for (let c = 1; c <= last; c += 1) {
        expect(String(labelRow.getCell(c).value ?? '').trim()).not.toBe('');
        expect(valueRow.getCell(c).value).not.toBeNull();
        expect(valueRow.getCell(c).value).not.toBe('');
      }
    }
  }
  return pairs;
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
      phone: '01234567890',
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

function workbookVisibleText(workbook) {
  return workbook.worksheets
    .map((sheet) => `${sheet.name} | ${sheetText(sheet)}`)
    .join(' | ');
}

function flattenExcelI18nCatalog(lang) {
  const t = excelStrings(lang);
  const samples = [
    t.sheetSession(1),
    t.openSheet(t.sheetSession(1)),
    t.overflowNote(3, 12),
    t.sessionReportTitle(1),
    t.sessionIdLine('abc'),
    t.photosCount(2),
    t.photoN(1),
    t.openPhoto(1),
    t.minutes(5),
    t.hours(3),
    t.hoursAndMinutes(2, t.hours(2), 5, t.minutes(5)),
  ];
  return [
    ...Object.values(t)
      .filter((value) => typeof value !== 'function')
      .map(String),
    ...samples,
  ].join('\n');
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
          phone: '01234567890',
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
          phone: '01234567890',
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
    expect(ada.phone).toBe('01234567890');
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
    expect(ada.totalTravelApprovedMinutes).toBe(620);
    expect(ada.totalNormalApprovedMinutes).toBe(0);
    expect(formatDurationProseFromMinutes(ada.totalApprovedMinutes, 'en')).toBe(
      '10 hours 20 minutes'
    );
    expect(formatDurationProseFromMinutes(ada.totalWorkedMinutes, 'en')).toBe(
      '16 hours 57 minutes'
    );

    const bob = summaries.find((s) => s.email === 'bob@example.com');
    expect(bob.phone).toBe('—');
    expect(bob.totalSessions).toBe(1);
    expect(bob.overnightTrips).toBe(0);
    expect(bob.rejectedSessions).toBe(1);
    expect(bob.totalApprovedMinutes).toBe(0);
    expect(bob.totalTravelApprovedMinutes).toBe(0);
    expect(bob.totalNormalApprovedMinutes).toBe(0);
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
    expect(workbook.getWorksheet('Trips Index')).toBeUndefined();
    expect(workbook.getWorksheet('Trip 1')).toBeUndefined();
    const summary = workbook.getWorksheet('Summary');
    expect(summary).toBeTruthy();
    const joined = sheetText(summary);
    expect(joined).toMatch(/Overall Report KPIs/);
    expect(joined).toMatch(/Employee Summary/);
    expect(joined).toMatch(/Total Technicians/);
    expect(joined).not.toMatch(/Total Calculated \/ Worked Hours/);
    expect(joined).not.toMatch(/Total Approved Hours/);
    expect(joined).toMatch(/Total Overtime Work Hours/);
    expect(joined).toMatch(/Pending Review/);
    expect(joined).toMatch(/Rejected/);
    expect(joined).toMatch(/Overnight/);
    expect(joined).toMatch(/Ada Lovelace/);
    expect(joined).toMatch(/ada@example\.com/);
    expect(joined).toMatch(/01234567890/);
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
    expect(joined).not.toMatch(t.kpiTotalWorkedHours);
    expect(joined).not.toContain('إجمالي الساعات المحسوبة / الفعلية');
    expect(joined).not.toContain('إجمالي الساعات المعتمدة');
    expect(joined).toMatch(t.kpiTotalApprovedHours);
    expect(joined).toMatch(t.kpiPendingSessions);
    expect(joined).toMatch(t.kpiRejectedSessions);
    expect(joined).toMatch(/ada@example\.com/);
    expect(joined).not.toMatch(/Department/i);
    expect(joined).not.toMatch(/Branch/i);
  });

  test('detailed English index includes identity and duration columns without branch/department', async () => {
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.DETAILED, language: 'en' });
    const index = workbook.getWorksheet('Trips Index');
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
    expectExcelDurationMinutes(dataRow.getCell(14), 620);
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

  test('Arabic workbook duration cells use Excel [h]:mm numeric time', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    const summary = workbook.getWorksheet(t.sheetSummary);
    const found = [];
    summary.eachRow((row) => {
      row.eachCell((cell) => {
        if (String(cell.numFmt || '').includes('[h]:mm')) {
          found.push(cell);
        }
      });
    });
    expect(found.length).toBeGreaterThan(0);
    for (const cell of found) {
      const minutes = minutesFromExcelCell(cell);
      expect(minutes).not.toBeNull();
      expect(minutes).toBeGreaterThanOrEqual(0);
      expect(String(cell.value)).not.toMatch(/ساعة|دقيقة/);
      expect(String(cell.value)).not.toMatch(/[\u200E\u200F\u202A-\u202E\u2066-\u2069\u061C]/);
    }
  });

  test('employee summary canonical columns are A:N without worked-hours column', () => {
    const columns = getEmployeeSummaryColumnDefs('ar');
    expect(columns).toHaveLength(14);
    expect(columns.map((c) => c.key)).toEqual([
      'name',
      'email',
      'phone',
      'approvedHours',
      'totalSessions',
      'normalSessions',
      'travelSessions',
      'overnightSessions',
      'approvedSessions',
      'pendingSessions',
      'rejectedSessions',
      'travelApprovedHours',
      'normalApprovedHours',
      'countedVacationDays',
    ]);
    const t = excelStrings('ar');
    expect(columns.map((c) => c.header)).toEqual([
      'اسم الموظف',
      'بريد الموظف',
      'رقم الهاتف',
      'إجمالي ساعات عمل الإضافي',
      'إجمالي الرحلات',
      'الرحلات العادية',
      'السفر',
      'مبيت',
      'المعتمدة',
      'قيد المراجعة',
      'المرفوضة',
      'إجمالي ساعات السفر الإضافي',
      'إجمالي الساعات العادية',
      'عدد أيام الإجازات المحتسبة',
    ]);
    expect(columns.map((c) => c.header)).not.toContain(
      'إجمالي الساعات المحسوبة / الفعلية'
    );
    expect(t.empName).toBe(columns[0].header);
  });

  test('screenshot regression: employee A:N mapping and durations in generated XLSX', async () => {
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
    expect(Boolean(summary.views?.[0]?.rightToLeft)).toBe(false);

    const headerRowNumber = findEmployeeHeaderRow(summary, t.empName);
    expect(headerRowNumber).toBeGreaterThan(0);

    const headerRow = summary.getRow(headerRowNumber);
    const headers = columns.map((_, i) => String(headerRow.getCell(i + 1).value ?? ''));
    expect(headers).toEqual(columns.map((c) => c.header));
    expect(headers).not.toContain('إجمالي الساعات المحسوبة / الفعلية');
    expect(headers[5]).toBe('الرحلات العادية');
    expect(headers[6]).toBe('السفر');

    const row1 = summary.getRow(headerRowNumber + 1);
    const row2 = summary.getRow(headerRowNumber + 2);

    expect(row1.getCell(1).value).toBe('Field Technician');
    expect(row1.getCell(2).value).toBe('test@gmail.com');
    expectPhoneText(row1.getCell(3), '01234567890');
    expectExcelDurationMinutes(row1.getCell(4), 1124);
    expect(row1.getCell(5).value).toBe(6);
    expect(row1.getCell(6).value).toBe(5);
    expect(row1.getCell(7).value).toBe(1);
    expect(row1.getCell(8).value).toBe(1);
    expect(row1.getCell(9).value).toBe(3);
    expect(row1.getCell(10).value).toBe(3);
    expect(row1.getCell(11).value).toBe(0);
    expectExcelDurationMinutes(row1.getCell(12), 0);
    expectExcelDurationMinutes(row1.getCell(13), 1124);
    expect(row1.getCell(14).value).toBe(0);

    expect(row2.getCell(1).value).toBe('test2 test');
    expect(row2.getCell(2).value).toBe('test2@gmail.com');
    expectPhoneText(row2.getCell(3), '—');
    expectExcelDurationMinutes(row2.getCell(4), 858);
    expect(row2.getCell(5).value).toBe(4);
    expect(row2.getCell(6).value).toBe(0);
    expect(row2.getCell(7).value).toBe(4);
    expect(row2.getCell(8).value).toBe(1);
    expect(row2.getCell(9).value).toBe(1);
    expect(row2.getCell(10).value).toBe(3);
    expect(row2.getCell(11).value).toBe(0);
    expectExcelDurationMinutes(row2.getCell(12), 858);
    expectExcelDurationMinutes(row2.getCell(13), 0);
    expect(row2.getCell(14).value).toBe(0);

    const zip = await JSZip.loadAsync(buffer);
    const sheetXml = await zip.file('xl/worksheets/sheet1.xml').async('string');
    const stylesXml = await zip.file('xl/styles.xml').async('string');
    const sharedXml = await zip.file('xl/sharedStrings.xml').async('string');

    expect(sheetXml).not.toContain('rightToLeft="1"');
    expect(stylesXml).toMatch(/\[h\]:mm/);
    expect(stylesXml).toMatch(/numFmtId="49"|formatCode="@"/);
    expect(sharedXml).not.toContain(LRO);
    expect(sharedXml).not.toContain(PDF);
    expect(sharedXml).not.toContain('23 ساعة و 42 دقيقة');
    expect(sharedXml).toContain('Field Technician');
    expect(sharedXml).toContain('test2 test');
    expect(sharedXml).toContain('01234567890');

    const dataRowXml =
      sheetXml.match(
        new RegExp(`<row r="${headerRowNumber + 1}"[\\s\\S]*?</row>`)
      )?.[0] || '';
    expect(dataRowXml).toContain(`r="A${headerRowNumber + 1}"`);
    expect(dataRowXml).toContain(`r="B${headerRowNumber + 1}"`);
    expect(dataRowXml.indexOf(`r="A${headerRowNumber + 1}"`)).toBeLessThan(
      dataRowXml.indexOf(`r="B${headerRowNumber + 1}"`)
    );

    const summaries = computeEmployeeSummaries(records);
    const field = summaries.find((s) => s.email === 'test@gmail.com');
    const mapped = employeeSummaryRowValues(field, 'ar');
    expect(mapped.name).toBe('Field Technician');
    expect(mapped.phone).toBe('01234567890');
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
    expectPhoneText(dataRow.getCell(3), '01234567890');
    expectExcelDurationMinutes(dataRow.getCell(4), 620);
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
    const sheet = workbook.getWorksheet('Trip 1');
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
    expect(joined).not.toMatch(/Department/);
    expect(joined).not.toMatch(/\bBranch\b/);
    let foundApproved = false;
    sheet.eachRow((row) => {
      row.eachCell((cell) => {
        if (String(cell.numFmt || '').includes('[h]:mm') && minutesFromExcelCell(cell) === 620) {
          foundApproved = true;
        }
      });
    });
    expect(foundApproved).toBe(true);
  });

  test('KPI section matches employee-summary terminology and approved hours', async () => {
    const t = excelStrings('ar');
    const workbook = await loadWorkbook({
      mode: EXPORT_MODE.SUMMARY,
      language: 'ar',
    });
    const summary = workbook.getWorksheet(t.sheetSummary);
    const joined = sheetText(summary);

    expect(joined).not.toContain('إجمالي الساعات المحسوبة / الفعلية');
    expect(joined).not.toContain('إجمالي الساعات المعتمدة');
    expect(joined).not.toContain('جلسة');
    expect(joined).not.toContain('جلسات');
    expect(joined).not.toContain('جلسات السفر');
    expect(joined).not.toContain('جلسات المبيت');
    expect(joined).not.toContain('الجلسات المعتمدة');
    expect(joined).not.toContain('الجلسات قيد المراجعة');
    expect(joined).not.toContain('الجلسات المرفوضة');

    expect(t.kpiTotalApprovedHours).toBe(t.empApprovedHours);
    expect(t.kpiTravelTrips).toBe(t.empTravel);
    expect(t.kpiOvernightTrips).toBe(t.empOvernight);
    expect(t.kpiApprovedSessions).toBe(t.empApproved);
    expect(t.kpiPendingSessions).toBe(t.empPending);
    expect(t.kpiRejectedSessions).toBe(t.empRejected);
    expect(t.kpiNormalSessions).toBe(t.empNormal);

    const pairs = collectKpiPairs(
      summary,
      t.sectionKpis,
      t.sectionEmployeeBreakdown
    );
    const labels = pairs.map((p) => p.label);
    expect(labels).not.toContain(t.kpiTotalWorkedHours);
    expect(labels).toContain('إجمالي ساعات عمل الإضافي');
    expect(labels).toContain('السفر');
    expect(labels).toContain('مبيت');
    expect(labels).toContain('المعتمدة');
    expect(labels).toContain('قيد المراجعة');
    expect(labels).toContain('المرفوضة');
    expect(labels).toContain('الرحلات العادية');
    expect(labels).toContain('إجمالي الرحلات');
    expect(labels).toHaveLength(9);

    const hoursKpi = pairs.find((p) => p.label === t.kpiTotalApprovedHours);
    expect(hoursKpi).toBeTruthy();
    expectExcelDurationMinutes(hoursKpi.cell, 620);

    const travelKpi = pairs.find((p) => p.label === t.kpiTravelTrips);
    const overnightKpi = pairs.find((p) => p.label === t.kpiOvernightTrips);
    const approvedKpi = pairs.find((p) => p.label === t.kpiApprovedSessions);
    const pendingKpi = pairs.find((p) => p.label === t.kpiPendingSessions);
    const rejectedKpi = pairs.find((p) => p.label === t.kpiRejectedSessions);
    const normalKpi = pairs.find((p) => p.label === t.kpiNormalSessions);
    expect(travelKpi.cell.value).toBe(1);
    expect(overnightKpi.cell.value).toBe(1);
    expect(approvedKpi.cell.value).toBe(1);
    expect(pendingKpi.cell.value).toBe(0);
    expect(rejectedKpi.cell.value).toBe(0);
    expect(normalKpi.cell.value).toBe(0);

    const empHeader = findEmployeeHeaderRow(summary, t.empName);
    const empHeaders = getEmployeeSummaryColumnDefs('ar').map((_, i) =>
      String(summary.getRow(empHeader).getCell(i + 1).value ?? '')
    );
    expect(empHeaders).toEqual(
      getEmployeeSummaryColumnDefs('ar').map((c) => c.header)
    );
    expectExcelDurationMinutes(summary.getRow(empHeader + 1).getCell(4), 620);
  });

  test('Arabic Excel catalog and workbooks use رحلة/رحلات instead of جلسة/جلسات', async () => {
    const catalog = flattenExcelI18nCatalog('ar');
    expect(catalog).not.toContain('جلسة');
    expect(catalog).not.toContain('جلسات');
    expect(catalog).toContain('رحلة');
    expect(catalog).toContain('رحلات');

    const t = excelStrings('ar');
    expect(t.kpiTotalSessions).toBe('إجمالي الرحلات');
    expect(t.kpiNormalSessions).toBe('الرحلات العادية');
    expect(t.empSessions).toBe('إجمالي الرحلات');
    expect(t.empNormal).toBe('الرحلات العادية');
    expect(t.sheetSessionsIndex).toBe('فهرس الرحلات');
    expect(t.sheetAdditionalSessions).toBe('رحلات إضافية');
    expect(t.sheetSession(1)).toBe('رحلة 1');
    expect(t.sessionId).toBe('معرّف الرحلة');
    expect(t.sessionsInExport).toBe('الرحلات في التصدير');
    expect(t.syncActive).toBe('رحلة نشطة');

    const summary = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'ar' });
    const detailed = await loadWorkbook({
      mode: EXPORT_MODE.DETAILED,
      language: 'ar',
    });
    const emptyDetailed = await loadWorkbook({
      mode: EXPORT_MODE.DETAILED,
      language: 'ar',
      records: [],
    });
    for (const workbook of [summary, detailed, emptyDetailed]) {
      const text = workbookVisibleText(workbook);
      expect(text).not.toContain('جلسة');
      expect(text).not.toContain('جلسات');
      expect(text).toContain('رحلات');
    }

    const detailedText = workbookVisibleText(detailed);
    expect(detailedText).toContain('فهرس الرحلات');
    expect(detailedText).toContain('معرّف الرحلة');
    expect(detailedText).toContain(t.sessionReportTitle(1));
    expect(detailedText).toContain('رحلة 1');

    const emptyText = workbookVisibleText(emptyDetailed);
    expect(emptyText).toContain(t.noSessions);
    expect(emptyText).toContain('رحلات');

    const empHeaders = getEmployeeSummaryColumnDefs('ar')
      .map((c) => c.header)
      .join(' | ');
    expect(empHeaders).not.toContain('جلسة');
    expect(empHeaders).not.toContain('جلسات');
    expect(empHeaders).toContain('إجمالي الرحلات');
    expect(empHeaders).toContain('الرحلات العادية');

    const kpiLabels = collectKpiPairs(
      summary.getWorksheet(t.sheetSummary),
      t.sectionKpis,
      t.sectionEmployeeBreakdown
    ).map((p) => p.label);
    expect(kpiLabels.join(' ')).not.toContain('جلسة');
    expect(kpiLabels).toContain('إجمالي الرحلات');
    expect(kpiLabels).toContain('الرحلات العادية');
  });

  test('English Excel catalog and workbooks use Trip/Trips instead of Session/Sessions', async () => {
    const catalog = flattenExcelI18nCatalog('en');
    expect(catalog).not.toMatch(/\bSessions?\b/i);
    expect(catalog).toMatch(/\bTrips?\b/i);

    const t = excelStrings('en');
    expect(t.kpiTotalSessions).toBe('Total Trips');
    expect(t.kpiNormalSessions).toBe('Normal Trips');
    expect(t.empSessions).toBe('Total Trips');
    expect(t.empNormal).toBe('Normal Trips');
    expect(t.sheetSessionsIndex).toBe('Trips Index');
    expect(t.sheetAdditionalSessions).toBe('Additional Trips');
    expect(t.sheetSession(1)).toBe('Trip 1');
    expect(t.sessionId).toBe('Trip ID');
    expect(t.sessionsInExport).toBe('Trips in Export');
    expect(t.syncActive).toBe('Active Trip');
    expect(t.sessionReportTitle(1)).toBe('Overtime Trip Report — 1');
    expect(t.sessionIdLine('abc')).toBe('Trip ID: abc');

    const summary = await loadWorkbook({ mode: EXPORT_MODE.SUMMARY, language: 'en' });
    const detailed = await loadWorkbook({
      mode: EXPORT_MODE.DETAILED,
      language: 'en',
    });
    const emptyDetailed = await loadWorkbook({
      mode: EXPORT_MODE.DETAILED,
      language: 'en',
      records: [],
    });
    for (const workbook of [summary, detailed, emptyDetailed]) {
      const text = workbookVisibleText(workbook);
      expect(text).not.toMatch(/\bSessions?\b/i);
      expect(text).toMatch(/\bTrips?\b/i);
    }

    const detailedText = workbookVisibleText(detailed);
    expect(detailedText).toContain('Trips Index');
    expect(detailedText).toContain('Trip 1');
    expect(detailedText).toContain('Trip ID');
    expect(detailedText).toContain('Overtime Trip Report');
    expect(workbookVisibleText(emptyDetailed)).toContain(t.noSessions);
  });
});

describe('employee summary A/B/C export fixtures', () => {
  const friday = {
    start: new Date('2026-03-06T08:00:00.000Z'),
    end: new Date('2026-03-06T14:00:00.000Z'),
  };
  const friday2 = {
    start: new Date('2026-03-13T08:00:00.000Z'),
    end: new Date('2026-03-13T14:00:00.000Z'),
  };
  const sunday = {
    start: new Date('2026-03-01T08:00:00.000Z'),
    end: new Date('2026-03-01T14:00:00.000Z'),
  };

  function makeAbcRecords() {
    const a = makeUser('u-a', 'Employee', 'A', 'a@example.com', '01234567890');
    const b = makeUser('u-b', 'Employee', 'B', 'b@example.com', '0555555555');
    const c = makeUser('u-c', 'Employee', 'C', 'c@example.com', '01000000000');
    return [
      makeRecord({
        id: 'a-n-ok',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 2,
        eligibleOvertimeMinutes: 120,
        startAt: friday.start,
        endAt: friday.end,
        userId: a,
      }),
      makeRecord({
        id: 'a-t-ok',
        type: 'TRAVEL',
        status: 'APPROVED',
        isOvernight: true,
        approvedHours: 1,
        eligibleOvertimeMinutes: 60,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: a,
      }),
      makeRecord({
        id: 'a-n-pending',
        type: 'NORMAL',
        status: 'PENDING_REVIEW',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 45,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: a,
      }),
      makeRecord({
        id: 'a-t-rej',
        type: 'TRAVEL',
        status: 'REJECTED',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 30,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: a,
      }),
      makeRecord({
        id: 'b-n-ok',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 3,
        eligibleOvertimeMinutes: 180,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: b,
      }),
      makeRecord({
        id: 'c-t1',
        type: 'TRAVEL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 1.5,
        eligibleOvertimeMinutes: 90,
        startAt: friday.start,
        endAt: friday.end,
        userId: c,
      }),
      makeRecord({
        id: 'c-t2',
        type: 'TRAVEL',
        status: 'APPROVED',
        isOvernight: true,
        approvedHours: 2.25,
        eligibleOvertimeMinutes: 135,
        startAt: friday2.start,
        endAt: friday2.end,
        userId: c,
      }),
    ];
  }

  test('vacation-day helper counts official non-working days that contributed eligible OT', () => {
    const keys = countedVacationDayKeysForRecord({
      startAt: friday.start,
      endAt: friday.end,
    });
    expect(keys).toEqual(['2026-03-06']);
    const sundayKeys = countedVacationDayKeysForRecord({
      startAt: sunday.start,
      endAt: sunday.end,
    });
    expect(sundayKeys).toEqual([]);
  });

  test('counted vacation days include only APPROVED official non-working days', () => {
    const user = makeUser('u-vac', 'Vac', 'Tech', 'vac@example.com');

    const fridayApproved = computeEmployeeSummaries([
      makeRecord({
        id: 'v-fri-ok',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 2,
        eligibleOvertimeMinutes: 120,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
    ]);
    expect(fridayApproved[0].countedVacationDays).toBe(1);

    const fridayPending = computeEmployeeSummaries([
      makeRecord({
        id: 'v-fri-pending',
        type: 'NORMAL',
        status: 'PENDING_REVIEW',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 120,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
    ]);
    expect(fridayPending[0].countedVacationDays).toBe(0);

    const fridayRejected = computeEmployeeSummaries([
      makeRecord({
        id: 'v-fri-rej',
        type: 'TRAVEL',
        status: 'REJECTED',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 120,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
    ]);
    expect(fridayRejected[0].countedVacationDays).toBe(0);

    const twoSameFriday = computeEmployeeSummaries([
      makeRecord({
        id: 'v-fri-a',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 1,
        eligibleOvertimeMinutes: 60,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
      makeRecord({
        id: 'v-fri-b',
        type: 'TRAVEL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 1,
        eligibleOvertimeMinutes: 60,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
    ]);
    expect(twoSameFriday[0].countedVacationDays).toBe(1);

    const fridayPlusWeekday = computeEmployeeSummaries([
      makeRecord({
        id: 'v-fri-plus',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 2,
        eligibleOvertimeMinutes: 120,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
      makeRecord({
        id: 'v-sun-ok',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 3,
        eligibleOvertimeMinutes: 180,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: user,
      }),
    ]);
    expect(fridayPlusWeekday[0].countedVacationDays).toBe(1);
  });

  test('approved travel and normal hours exclude pending and rejected sessions', () => {
    const user = makeUser('u-hrs', 'Hours', 'Tech', 'hours@example.com');
    const summaries = computeEmployeeSummaries([
      makeRecord({
        id: 'h-t-ok',
        type: 'TRAVEL',
        status: 'APPROVED',
        isOvernight: true,
        approvedHours: 1.5,
        eligibleOvertimeMinutes: 90,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
      makeRecord({
        id: 'h-t-pending',
        type: 'TRAVEL',
        status: 'PENDING_REVIEW',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 200,
        startAt: friday.start,
        endAt: friday.end,
        userId: user,
      }),
      makeRecord({
        id: 'h-t-rej',
        type: 'TRAVEL',
        status: 'REJECTED',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 80,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: user,
      }),
      makeRecord({
        id: 'h-n-ok',
        type: 'NORMAL',
        status: 'APPROVED',
        isOvernight: false,
        approvedHours: 2,
        eligibleOvertimeMinutes: 120,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: user,
      }),
      makeRecord({
        id: 'h-n-pending',
        type: 'NORMAL',
        status: 'PENDING_REVIEW',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 45,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: user,
      }),
      makeRecord({
        id: 'h-n-rej',
        type: 'NORMAL',
        status: 'REJECTED',
        isOvernight: false,
        approvedHours: null,
        eligibleOvertimeMinutes: 30,
        startAt: sunday.start,
        endAt: sunday.end,
        userId: user,
      }),
    ]);
    const row = summaries[0];
    expect(row.totalTravelApprovedMinutes).toBe(Math.round(1.5 * 60));
    expect(row.totalNormalApprovedMinutes).toBe(120);
    expect(row.totalApprovedMinutes).toBe(Math.round(1.5 * 60) + 120);
    expect(row.travelSessions).toBe(3);
    expect(row.normalSessions).toBe(3);
    expect(row.approvedSessions).toBe(2);
    expect(row.pendingReviewSessions).toBe(2);
    expect(row.rejectedSessions).toBe(2);
  });

  test('excel serial durations cover hours+minutes, hours-only, and minutes-only', () => {
    expect(excelSerialFromMinutes(14 * 60 + 57) * 24 * 60).toBe(14 * 60 + 57);
    expect(excelSerialFromMinutes(120) * 24 * 60).toBe(120);
    expect(excelSerialFromMinutes(40) * 24 * 60).toBe(40);
    expect(excelSerialFromMinutes(0) * 24 * 60).toBe(0);
  });

  test('Employee A/B/C summary columns, phones, hours, and vacation days', async () => {
    const records = makeAbcRecords();
    const summaries = computeEmployeeSummaries(records);
    const empA = summaries.find((s) => s.email === 'a@example.com');
    const empB = summaries.find((s) => s.email === 'b@example.com');
    const empC = summaries.find((s) => s.email === 'c@example.com');

    expect(empA.totalSessions).toBe(4);
    expect(empA.normalSessions).toBe(2);
    expect(empA.travelSessions).toBe(2);
    expect(empA.overnightTrips).toBe(1);
    expect(empA.approvedSessions).toBe(2);
    expect(empA.pendingReviewSessions).toBe(1);
    expect(empA.rejectedSessions).toBe(1);
    expect(empA.totalApprovedMinutes).toBe(180);
    expect(empA.totalTravelApprovedMinutes).toBe(60);
    expect(empA.totalNormalApprovedMinutes).toBe(120);
    expect(empA.countedVacationDays).toBe(1);
    expect(empA.phone).toBe('01234567890');

    expect(empB.travelSessions).toBe(0);
    expect(empB.totalTravelApprovedMinutes).toBe(0);
    expect(empB.totalNormalApprovedMinutes).toBe(180);
    expect(empB.totalApprovedMinutes).toBe(180);
    expect(empB.countedVacationDays).toBe(0);

    expect(empC.travelSessions).toBe(2);
    expect(empC.normalSessions).toBe(0);
    expect(empC.totalTravelApprovedMinutes).toBe(
      Math.round(1.5 * 60) + Math.round(2.25 * 60)
    );
    expect(empC.totalNormalApprovedMinutes).toBe(0);
    expect(empC.countedVacationDays).toBe(2);

    const t = excelStrings('ar');
    const workbook = await loadWorkbook({
      mode: EXPORT_MODE.SUMMARY,
      language: 'ar',
      records,
    });
    const summary = workbook.getWorksheet(t.sheetSummary);
    const headerRowNumber = findEmployeeHeaderRow(summary, t.empName);
    const headerDefs = getEmployeeSummaryColumnDefs('ar');
    const headers = headerDefs.map((_, i) =>
      String(summary.getRow(headerRowNumber).getCell(i + 1).value ?? '')
    );
    expect(headers).toEqual(headerDefs.map((c) => c.header));
    expect(headers).not.toContain('إجمالي الساعات المحسوبة / الفعلية');

    const rows = {};
    for (let offset = 1; offset <= 3; offset += 1) {
      const row = summary.getRow(headerRowNumber + offset);
      rows[String(row.getCell(2).value)] = row;
    }
    const rowA = rows['a@example.com'];
    expectPhoneText(rowA.getCell(3), '01234567890');
    expectExcelDurationMinutes(rowA.getCell(4), 180);
    expect(rowA.getCell(7).value).toBe(2);
    expect(rowA.getCell(8).value).toBe(1);
    expect(rowA.getCell(9).value).toBe(2);
    expect(rowA.getCell(10).value).toBe(1);
    expect(rowA.getCell(11).value).toBe(1);
    expectExcelDurationMinutes(rowA.getCell(12), 60);
    expectExcelDurationMinutes(rowA.getCell(13), 120);
    expect(rowA.getCell(14).value).toBe(1);

    const rowB = rows['b@example.com'];
    expect(rowB.getCell(7).value).toBe(0);
    expectExcelDurationMinutes(rowB.getCell(12), 0);
    expectExcelDurationMinutes(rowB.getCell(13), 180);

    const rowC = rows['c@example.com'];
    expect(rowC.getCell(7).value).toBe(2);
    expectExcelDurationMinutes(
      rowC.getCell(12),
      Math.round(1.5 * 60) + Math.round(2.25 * 60)
    );
    expectExcelDurationMinutes(rowC.getCell(13), 0);
    expect(rowC.getCell(14).value).toBe(2);
  });
});
