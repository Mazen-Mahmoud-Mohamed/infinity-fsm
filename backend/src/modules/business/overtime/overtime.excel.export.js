import ExcelJS from 'exceljs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const pkg = require('../../../../package.json');

const MAX_EXPORT_ROWS = 10000;
/** Excel practical page size — split detailed data across sheets. */
const ROWS_PER_SHEET = 5000;

const HEADER_FILL = {
  type: 'pattern',
  pattern: 'solid',
  fgColor: { argb: 'FF1E3A5F' },
};
const HEADER_FONT = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
const ALT_ROW_FILL = {
  type: 'pattern',
  pattern: 'solid',
  fgColor: { argb: 'FFF3F6FA' },
};
const CARD_TITLE_FILL = {
  type: 'pattern',
  pattern: 'solid',
  fgColor: { argb: 'FFE8EEF7' },
};
const CARD_VALUE_FILL = {
  type: 'pattern',
  pattern: 'solid',
  fgColor: { argb: 'FFF8FAFC' },
};
const LINK_FONT = { color: { argb: 'FF0563C1' }, underline: true, size: 10 };

const STATUS_FILLS = {
  APPROVED: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDCFCE7' } },
  PENDING_REVIEW: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFFEF9C3' },
  },
  REJECTED: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFEE2E2' } },
  PENDING_SYNC: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFFFEDD5' },
  },
  RUNNING: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFE0F2FE' },
  },
};

const DETAILED_HEADERS = [
  'Session ID',
  'Employee Name',
  'Employee ID',
  'Department',
  'Overtime Type',
  'Status',
  'Created Date',
  'Approved Date',
  'Reviewer',
  'Review Notes',
  'Start Date',
  'Start Time',
  'Start Latitude',
  'Start Longitude',
  'Start Address',
  'Start GPS Accuracy (m)',
  'Start Google Maps',
  'Arrived Date',
  'Arrived Time',
  'Arrived Latitude',
  'Arrived Longitude',
  'Arrived Address',
  'Arrived GPS Accuracy (m)',
  'Arrived Google Maps',
  'Finished Work Date',
  'Finished Work Time',
  'Finished Work Latitude',
  'Finished Work Longitude',
  'Finished Work Address',
  'Finished Work GPS Accuracy (m)',
  'Finished Work Google Maps',
  'End Date',
  'End Time',
  'End Latitude',
  'End Longitude',
  'End Address',
  'End GPS Accuracy (m)',
  'End Google Maps',
  'Calculated Hours',
  'Working Hours',
  'Travel Hours',
  'Total Hours',
  'Approved Hours',
  'Voice Start',
  'Voice Arrived',
  'Voice Finished',
  'Voice End',
  'Photo Count',
  'Photo URLs',
  'Start Device ID',
  'Start Battery %',
  'Start Network',
  'End Device ID',
  'End Battery %',
  'End Network',
  'Platform',
  'Device Model',
  'App Version',
  'Branch ID',
];

export const EXPORT_MODE = Object.freeze({
  SUMMARY: 'summary',
  DETAILED: 'detailed',
});

function pad2(n) {
  return String(n).padStart(2, '0');
}

function formatDate(value) {
  if (!value) return '';
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
}

function formatTime(value) {
  if (!value) return '';
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${pad2(d.getUTCHours())}:${pad2(d.getUTCMinutes())}:${pad2(d.getUTCSeconds())}`;
}

function formatDateTimeStamp(value) {
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${formatDate(d)}_${pad2(d.getUTCHours())}-${pad2(d.getUTCMinutes())}`;
}

function minutesToHours(minutes) {
  if (minutes === null || minutes === undefined || minutes === '') return null;
  const n = Number(minutes);
  if (!Number.isFinite(n)) return null;
  return Math.round((n / 60) * 100) / 100;
}

function hoursOrBlank(minutes) {
  const h = minutesToHours(minutes);
  return h === null ? '' : h;
}

function formatVoiceDuration(seconds) {
  if (seconds === null || seconds === undefined || seconds === '') return null;
  const n = Number(seconds);
  if (!Number.isFinite(n) || n < 0) return null;
  const total = Math.round(n);
  return `${pad2(Math.floor(total / 60))}:${pad2(total % 60)}`;
}

function userDisplayName(user) {
  if (!user) return '';
  if (typeof user === 'string') return user;
  const full = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return full || user.email || user._id?.toString?.() || '';
}

function safeFileToken(value) {
  return String(value || '')
    .trim()
    .replace(/[^\w\-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .slice(0, 48);
}

function mapsUrl(lat, lng) {
  if (lat === null || lat === undefined || lng === null || lng === undefined) {
    return '';
  }
  const a = Number(lat);
  const b = Number(lng);
  if (!Number.isFinite(a) || !Number.isFinite(b)) return '';
  return `https://maps.google.com/?q=${a},${b}`;
}

function stageFromRecord(record, key) {
  return record?.checkpoints?.[key] || null;
}

function stageGps(stage, legacyGps) {
  return stage?.gps || legacyGps || null;
}

function stageAt(stage, legacyAt) {
  return stage?.at || legacyAt || null;
}

function collectPhotoUrls(record) {
  const urls = [];
  const push = (url) => {
    if (url && String(url).trim()) urls.push(String(url).trim());
  };
  push(record.startPhoto?.url);
  push(record.endPhoto?.url);
  const cp = record.checkpoints || {};
  push(cp.startJourney?.photo?.url);
  push(cp.arrivedAtWorkSite?.photo?.url);
  push(cp.finishedWork?.photo?.url);
  push(cp.endJourney?.photo?.url);
  return [...new Set(urls)];
}

function travelMinutes(record) {
  const type = String(record.type || '').toUpperCase();
  if (type !== 'TRAVEL') return 0;
  const total = Number(record.totalDurationMinutes) || 0;
  const working = Number(record.workingDurationMinutes) || 0;
  return Math.max(0, total - working);
}

function voiceHttpUrl(voiceNote) {
  const url = voiceNote?.url;
  if (url && (String(url).startsWith('http://') || String(url).startsWith('https://'))) {
    return String(url);
  }
  return '';
}

function voiceDisplay(voiceNote) {
  const url = voiceHttpUrl(voiceNote);
  const duration = formatVoiceDuration(voiceNote?.duration);
  if (!url && !duration) return { text: '—', hyperlink: null };
  const text = duration || 'Available';
  return { text, hyperlink: url || null };
}

function linkCell(text, url) {
  if (!url) return text || '';
  return { text: text || url, hyperlink: url };
}

function applyWorksheetFooter(sheet, generatedAt) {
  const stamp = `${formatDate(generatedAt)} ${formatTime(generatedAt)} UTC`;
  sheet.headerFooter = {
    oddFooter: `&LInfinity FSM — Generated automatically&C${stamp}&RPage &P of &N`,
    evenFooter: `&LInfinity FSM — Generated automatically&C${stamp}&RPage &P of &N`,
  };
}

function applyHeaderStyle(row) {
  row.eachCell((cell) => {
    cell.fill = HEADER_FILL;
    cell.font = HEADER_FONT;
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
    cell.border = {
      bottom: { style: 'thin', color: { argb: 'FFCBD5E1' } },
    };
  });
  row.height = 30;
}

function autoWidth(sheet, headers, sampleRows = []) {
  headers.forEach((header, index) => {
    let maxLen = String(header).length;
    for (const row of sampleRows.slice(0, 40)) {
      const raw = row[index];
      const text =
        raw && typeof raw === 'object' && raw.text != null
          ? String(raw.text)
          : String(raw ?? '');
      maxLen = Math.max(maxLen, Math.min(48, text.length));
    }
    sheet.getColumn(index + 1).width = Math.min(44, Math.max(12, maxLen + 2));
  });
}

function computeStats(records) {
  const statusCounts = {
    APPROVED: 0,
    REJECTED: 0,
    PENDING_REVIEW: 0,
    RUNNING: 0,
    CANCELLED: 0,
  };
  let normalCount = 0;
  let travelCount = 0;
  let totalEligible = 0;
  let totalWorking = 0;
  let totalTravel = 0;
  let totalApprovedEligible = 0;
  const eligibleSamples = [];

  for (const record of records) {
    const st = String(record.status || '').toUpperCase();
    if (statusCounts[st] !== undefined) statusCounts[st] += 1;

    const type = String(record.type || '').toUpperCase();
    if (type === 'TRAVEL') travelCount += 1;
    else normalCount += 1;

    const eligible = Number(record.eligibleOvertimeMinutes);
    if (Number.isFinite(eligible)) {
      totalEligible += eligible;
      eligibleSamples.push(eligible);
      if (st === 'APPROVED') totalApprovedEligible += eligible;
    }
    const working = Number(record.workingDurationMinutes);
    if (Number.isFinite(working)) totalWorking += working;
    totalTravel += travelMinutes(record);
  }

  const avg =
    eligibleSamples.length > 0
      ? eligibleSamples.reduce((a, b) => a + b, 0) / eligibleSamples.length
      : 0;
  const max = eligibleSamples.length ? Math.max(...eligibleSamples) : 0;
  const min = eligibleSamples.length ? Math.min(...eligibleSamples) : 0;

  return {
    statusCounts,
    normalCount,
    travelCount,
    averageHours: Math.round((avg / 60) * 100) / 100,
    maximumHours: Math.round((max / 60) * 100) / 100,
    minimumHours: Math.round((min / 60) * 100) / 100,
    totalApprovedHours: Math.round((totalApprovedEligible / 60) * 100) / 100,
    totalWorkingHours: Math.round((totalWorking / 60) * 100) / 100,
    totalTravelHours: Math.round((totalTravel / 60) * 100) / 100,
    totalEligibleHours: Math.round((totalEligible / 60) * 100) / 100,
  };
}

function buildDetailedRow(record, departmentNameById, appVersion) {
  const tech = record.userId;
  const startCp = stageFromRecord(record, 'startJourney');
  const arrivedCp = stageFromRecord(record, 'arrivedAtWorkSite');
  const finishedCp = stageFromRecord(record, 'finishedWork');
  const endCp = stageFromRecord(record, 'endJourney');

  const startGps = stageGps(startCp, record.startGps);
  const arrivedGps = stageGps(arrivedCp, null);
  const finishedGps = stageGps(finishedCp, null);
  const endGps = stageGps(endCp, record.endGps);

  const startAt = stageAt(startCp, record.startAt);
  const arrivedAt = stageAt(arrivedCp, null);
  const finishedAt = stageAt(finishedCp, null);
  const endAt = stageAt(endCp, record.endAt);

  const photoUrls = collectPhotoUrls(record);
  const deptId =
    tech?.departmentId?._id?.toString?.() ||
    tech?.departmentId?.toString?.() ||
    tech?.departmentId ||
    '';
  const departmentName =
    (typeof tech?.departmentId === 'object' && tech.departmentId?.name) ||
    departmentNameById.get(String(deptId)) ||
    '';

  const reviewer =
    record.status === 'REJECTED'
      ? userDisplayName(record.rejectedBy)
      : userDisplayName(record.approvedBy);
  const approvedDate =
    record.status === 'REJECTED' ? record.rejectedAt : record.approvedAt;

  const startMap = mapsUrl(startGps?.latitude, startGps?.longitude);
  const arrivedMap = mapsUrl(arrivedGps?.latitude, arrivedGps?.longitude);
  const finishedMap = mapsUrl(finishedGps?.latitude, finishedGps?.longitude);
  const endMap = mapsUrl(endGps?.latitude, endGps?.longitude);

  const vStart = voiceDisplay(startCp?.voiceNote);
  const vArrived = voiceDisplay(arrivedCp?.voiceNote);
  const vFinished = voiceDisplay(finishedCp?.voiceNote);
  const vEnd = voiceDisplay(endCp?.voiceNote);

  const firstPhoto = photoUrls[0] || '';

  return [
    record._id?.toString?.() || '',
    userDisplayName(tech),
    tech?.employeeId || '',
    departmentName,
    record.type || '',
    record.status || '',
    formatDate(record.createdAt),
    formatDate(approvedDate),
    reviewer,
    record.reviewNotes || record.rejectionReason || '',
    formatDate(startAt),
    formatTime(startAt),
    startGps?.latitude ?? '',
    startGps?.longitude ?? '',
    startCp?.address || record.startAddress || startGps?.fullAddress || '',
    startGps?.accuracy ?? '',
    linkCell(startMap ? 'Open Map' : '', startMap),
    formatDate(arrivedAt),
    formatTime(arrivedAt),
    arrivedGps?.latitude ?? '',
    arrivedGps?.longitude ?? '',
    arrivedCp?.address || arrivedGps?.fullAddress || '',
    arrivedGps?.accuracy ?? '',
    linkCell(arrivedMap ? 'Open Map' : '', arrivedMap),
    formatDate(finishedAt),
    formatTime(finishedAt),
    finishedGps?.latitude ?? '',
    finishedGps?.longitude ?? '',
    finishedCp?.address || finishedGps?.fullAddress || '',
    finishedGps?.accuracy ?? '',
    linkCell(finishedMap ? 'Open Map' : '', finishedMap),
    formatDate(endAt),
    formatTime(endAt),
    endGps?.latitude ?? '',
    endGps?.longitude ?? '',
    endCp?.address || record.endAddress || endGps?.fullAddress || '',
    endGps?.accuracy ?? '',
    linkCell(endMap ? 'Open Map' : '', endMap),
    hoursOrBlank(record.eligibleOvertimeMinutes),
    hoursOrBlank(record.workingDurationMinutes),
    hoursOrBlank(travelMinutes(record)),
    hoursOrBlank(record.totalDurationMinutes),
    String(record.status).toUpperCase() === 'APPROVED'
      ? hoursOrBlank(record.eligibleOvertimeMinutes)
      : '',
    linkCell(vStart.text, vStart.hyperlink),
    linkCell(vArrived.text, vArrived.hyperlink),
    linkCell(vFinished.text, vFinished.hyperlink),
    linkCell(vEnd.text, vEnd.hyperlink),
    photoUrls.length,
    firstPhoto
      ? linkCell(
          photoUrls.length <= 1
            ? firstPhoto
            : `${firstPhoto}\n(+${photoUrls.length - 1} more)`,
          firstPhoto
        )
      : '—',
    startCp?.deviceId || record.startDeviceId || '',
    startCp?.batteryLevel ?? endCp?.batteryLevel ?? '',
    startCp?.networkStatus || endCp?.networkStatus || '',
    endCp?.deviceId || record.endDeviceId || '',
    endCp?.batteryLevel ?? '',
    endCp?.networkStatus || '',
    '', // Platform — not stored on overtime documents yet
    '', // Device Model — not stored on overtime documents yet
    appVersion || '',
    record.branchId?.toString?.() || record.branchId || '',
  ];
}

function styleDataRow(row, status) {
  row.alignment = { vertical: 'middle', wrapText: true };
  row.eachCell((cell) => {
    if (cell.value && typeof cell.value === 'object' && cell.value.hyperlink) {
      cell.font = LINK_FONT;
    }
  });
  const statusCell = row.getCell(6);
  const fill = STATUS_FILLS[String(status || '').toUpperCase()];
  if (fill) {
    statusCell.fill = fill;
    statusCell.font = { bold: true };
  }
}

function addSummarySection(sheet, title, rows, startRow) {
  let r = startRow;
  const titleRow = sheet.getRow(r);
  titleRow.getCell(1).value = title;
  titleRow.getCell(1).font = { bold: true, size: 12, color: { argb: 'FF1E3A5F' } };
  titleRow.getCell(1).fill = CARD_TITLE_FILL;
  titleRow.getCell(2).fill = CARD_TITLE_FILL;
  sheet.mergeCells(r, 1, r, 2);
  r += 1;
  for (const [label, value] of rows) {
    const row = sheet.getRow(r);
    row.getCell(1).value = label;
    row.getCell(1).font = { bold: true };
    row.getCell(1).fill = CARD_VALUE_FILL;
    row.getCell(2).value = value;
    row.getCell(2).fill = CARD_VALUE_FILL;
    row.getCell(1).border = {
      top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
    };
    row.getCell(2).border = {
      top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      right: { style: 'thin', color: { argb: 'FFE2E8F0' } },
    };
    r += 1;
  }
  return r + 1;
}

function buildFilterLines(filters) {
  return Object.entries(filters || {})
    .filter(([, v]) => v !== undefined && v !== null && String(v).trim() !== '')
    .map(([k, v]) => `${k}: ${v}`)
    .join('; ');
}

/**
 * Smart enterprise filename for overtime exports.
 */
export function buildOvertimeExportFileName({
  mode = EXPORT_MODE.DETAILED,
  filters = {},
  generatedAt = new Date(),
  employeeName,
} = {}) {
  const stamp = formatDateTimeStamp(generatedAt);
  const status = String(filters.status || '').toUpperCase();
  const safeEmployee = safeFileToken(employeeName);
  const start = filters.startDate || '';
  const monthLabel = (() => {
    const source = start || formatDate(generatedAt);
    const m = /^(\d{4})-(\d{2})/.exec(String(source));
    if (!m) return null;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const idx = Number(m[2]) - 1;
    return { year: m[1], month: months[idx] || m[2] };
  })();

  if (safeEmployee && monthLabel) {
    return `Overtime_Employee_${safeEmployee}_${monthLabel.year}-${pad2(
      Number(
        String(filters.startDate || formatDate(generatedAt)).slice(5, 7)
      ) || 1
    )}.xlsx`;
  }
  if (String(mode).toLowerCase() === EXPORT_MODE.SUMMARY) {
    return `Overtime_Summary_${stamp}.xlsx`;
  }
  if (status === 'APPROVED' && monthLabel) {
    return `Overtime_Approved_${monthLabel.month}_${monthLabel.year}.xlsx`;
  }
  return `Overtime_Report_${stamp}.xlsx`;
}

/**
 * Builds a polished enterprise overtime workbook.
 * @returns {Promise<Buffer>}
 */
export async function buildOvertimeExcelWorkbook({
  records,
  generatedBy,
  generatedAt = new Date(),
  filters = {},
  companyName = '',
  appVersion = pkg.version || '1.0.0',
  mode = EXPORT_MODE.DETAILED,
} = {}) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Infinity FSM';
  workbook.company = companyName || 'Infinity FSM';
  workbook.created = generatedAt;
  workbook.modified = generatedAt;

  const limited = records.slice(0, MAX_EXPORT_ROWS);
  const stats = computeStats(limited);
  const filterLines = buildFilterLines(filters);
  const exportMode =
    String(mode || '').toLowerCase() === EXPORT_MODE.SUMMARY
      ? EXPORT_MODE.SUMMARY
      : EXPORT_MODE.DETAILED;

  const departmentNameById = new Map();
  for (const record of limited) {
    const tech = record.userId;
    const dept = tech?.departmentId;
    if (dept && typeof dept === 'object' && dept.name) {
      departmentNameById.set(
        dept._id?.toString?.() || String(dept._id),
        dept.name
      );
    }
  }

  // ——— Summary sheet ———
  const summary = workbook.addWorksheet('Summary', {
    views: [{ state: 'frozen', ySplit: 1 }],
    properties: { defaultRowHeight: 18 },
  });
  summary.columns = [
    { width: 32 },
    { width: 56 },
  ];
  summary.getRow(1).values = ['Infinity FSM — Overtime Report', ''];
  summary.mergeCells(1, 1, 1, 2);
  summary.getRow(1).font = { bold: true, size: 16, color: { argb: 'FF1E3A5F' } };
  summary.getRow(1).height = 28;

  let cursor = 3;
  cursor = addSummarySection(
    summary,
    'Report Metadata',
    [
      ['Company Name', companyName || '—'],
      ['Generated By', generatedBy || '—'],
      [
        'Generated At',
        `${formatDate(generatedAt)} ${formatTime(generatedAt)} UTC`,
      ],
      ['Application Version', appVersion || '—'],
      ['Export Type', exportMode === EXPORT_MODE.SUMMARY ? 'Summary' : 'Detailed'],
      ['Date Range', filters.dateRange || 'All'],
      ['Applied Filters', filterLines || 'None'],
    ],
    cursor
  );

  cursor = addSummarySection(
    summary,
    'Session Statistics',
    [
      ['Total Sessions', limited.length],
      ['Approved', stats.statusCounts.APPROVED],
      ['Rejected', stats.statusCounts.REJECTED],
      ['Pending', stats.statusCounts.PENDING_REVIEW],
      ['Travel Overtime', stats.travelCount],
      ['Normal Overtime', stats.normalCount],
    ],
    cursor
  );

  cursor = addSummarySection(
    summary,
    'Hours Overview',
    [
      ['Average Hours', stats.averageHours],
      ['Maximum Hours', stats.maximumHours],
      ['Minimum Hours', stats.minimumHours],
      ['Total Approved Hours', stats.totalApprovedHours],
      ['Total Working Hours', stats.totalWorkingHours],
      ['Total Travel Hours', stats.totalTravelHours],
      ['Total Calculated Hours', stats.totalEligibleHours],
    ],
    cursor
  );

  applyWorksheetFooter(summary, generatedAt);

  if (exportMode === EXPORT_MODE.SUMMARY) {
    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  // ——— Detailed data sheets (split when large) ———
  const dataRows = limited.map((record) =>
    buildDetailedRow(record, departmentNameById, appVersion)
  );
  const chunks = [];
  for (let i = 0; i < dataRows.length; i += ROWS_PER_SHEET) {
    chunks.push({
      rows: dataRows.slice(i, i + ROWS_PER_SHEET),
      records: limited.slice(i, i + ROWS_PER_SHEET),
      index: Math.floor(i / ROWS_PER_SHEET) + 1,
    });
  }
  if (chunks.length === 0) {
    chunks.push({ rows: [], records: [], index: 1 });
  }

  for (const chunk of chunks) {
    const sheetName =
      chunks.length === 1 ? 'Overtime' : `Overtime (${chunk.index})`;
    const sheet = workbook.addWorksheet(sheetName, {
      views: [{ state: 'frozen', ySplit: 1 }],
      properties: { defaultRowHeight: 18 },
    });

    if (chunk.rows.length === 0) {
      sheet.addRow(DETAILED_HEADERS);
      applyHeaderStyle(sheet.getRow(1));
      autoWidth(sheet, DETAILED_HEADERS, []);
      applyWorksheetFooter(sheet, generatedAt);
      continue;
    }

    const tableRows = chunk.rows.map((row) =>
      row.map((cell) => {
        if (cell && typeof cell === 'object' && cell.hyperlink) {
          return cell.text;
        }
        return cell;
      })
    );

    // Prefer Excel Table for professional filtering/sorting.
    sheet.addTable({
      name: `OvertimeTable${chunk.index}`,
      ref: 'A1',
      headerRow: true,
      totalsRow: false,
      style: {
        theme: 'TableStyleMedium2',
        showRowStripes: true,
      },
      columns: DETAILED_HEADERS.map((name) => ({
        name,
        filterButton: true,
      })),
      rows: tableRows,
    });

    // Re-apply hyperlinks & status colors on the real cells.
    for (let i = 0; i < chunk.rows.length; i += 1) {
      const excelRow = sheet.getRow(i + 2);
      const source = chunk.rows[i];
      source.forEach((value, colIdx) => {
        const cell = excelRow.getCell(colIdx + 1);
        if (value && typeof value === 'object' && value.hyperlink) {
          cell.value = { text: value.text, hyperlink: value.hyperlink };
          cell.font = LINK_FONT;
        }
      });
      styleDataRow(excelRow, chunk.records[i]?.status);
    }

    applyHeaderStyle(sheet.getRow(1));
    autoWidth(sheet, DETAILED_HEADERS, chunk.rows);
    applyWorksheetFooter(sheet, generatedAt);
  }

  const buffer = await workbook.xlsx.writeBuffer();
  return Buffer.from(buffer);
}

export { MAX_EXPORT_ROWS, ROWS_PER_SHEET };
