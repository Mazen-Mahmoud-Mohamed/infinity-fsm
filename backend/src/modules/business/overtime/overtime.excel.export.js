import ExcelJS from 'exceljs';
import { createRequire } from 'module';
import {
  resolveApprovedHours,
  workedHoursFromRecord,
} from './overtime.approved-hours.js';

const require = createRequire(import.meta.url);
const pkg = require('../../../../package.json');

const MAX_EXPORT_ROWS = 10000;
/** One detailed printable sheet per session; beyond this use overflow table. */
const MAX_SESSION_SHEETS = 100;
const THUMB_WIDTH = 140;
const THUMB_HEIGHT = 105;
const IMAGE_FETCH_CONCURRENCY = 6;
const IMAGE_FETCH_TIMEOUT_MS = 12000;

export const EXPORT_MODE = Object.freeze({
  SUMMARY: 'summary',
  DETAILED: 'detailed',
});

const COLORS = {
  navy: 'FF1E3A5F',
  navySoft: 'FFE8EEF7',
  surface: 'FFF8FAFC',
  border: 'FFCBD5E1',
  muted: 'FF64748B',
  white: 'FFFFFFFF',
  link: 'FF0563C1',
  start: 'FF16A34A',
  startBg: 'FFF0FDF4',
  arrived: 'FF2563EB',
  arrivedBg: 'FFEFF6FF',
  finished: 'FF7C3AED',
  finishedBg: 'FFF5F3FF',
  end: 'FFDC2626',
  endBg: 'FFFEF2F2',
  kpiBg: 'FFFFFFFF',
  altRow: 'FFF1F5F9',
};

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
  CANCELLED: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFF1F5F9' },
  },
};

const STAGE_META = [
  {
    key: 'startJourney',
    title: '🟢  START',
    voiceLabel: 'Start Voice',
    headerArgb: COLORS.start,
    bodyArgb: COLORS.startBg,
    legacyPhoto: 'startPhoto',
    legacyGps: 'startGps',
    legacyAt: 'startAt',
    legacyAddress: 'startAddress',
    legacyDevice: 'startDeviceId',
  },
  {
    key: 'arrivedAtWorkSite',
    title: '🔵  ARRIVED',
    voiceLabel: 'Arrived Voice',
    headerArgb: COLORS.arrived,
    bodyArgb: COLORS.arrivedBg,
  },
  {
    key: 'finishedWork',
    title: '🟣  FINISHED WORK',
    voiceLabel: 'Finished Voice',
    headerArgb: COLORS.finished,
    bodyArgb: COLORS.finishedBg,
  },
  {
    key: 'endJourney',
    title: '🔴  END',
    voiceLabel: 'End Voice',
    headerArgb: COLORS.end,
    bodyArgb: COLORS.endBg,
    legacyPhoto: 'endPhoto',
    legacyGps: 'endGps',
    legacyAt: 'endAt',
    legacyAddress: 'endAddress',
    legacyDevice: 'endDeviceId',
  },
];

function pad2(n) {
  return String(n).padStart(2, '0');
}

function formatDate(value) {
  if (!value) return '—';
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
}

function formatTime(value) {
  if (!value) return '—';
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return `${pad2(d.getUTCHours())}:${pad2(d.getUTCMinutes())}:${pad2(d.getUTCSeconds())}`;
}

function formatDateTime(value) {
  if (!value) return '—';
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return `${formatDate(d)} ${formatTime(d)} UTC`;
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

function hoursLabel(minutes) {
  const h = minutesToHours(minutes);
  return h === null ? '—' : h;
}

function formatVoiceDuration(seconds) {
  if (seconds === null || seconds === undefined || seconds === '') return null;
  const n = Number(seconds);
  if (!Number.isFinite(n) || n < 0) return null;
  const total = Math.round(n);
  return `${pad2(Math.floor(total / 60))}:${pad2(total % 60)}`;
}

function userDisplayName(user) {
  if (!user) return '—';
  if (typeof user === 'string') return user;
  const full = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return full || user.email || user._id?.toString?.() || '—';
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

function travelMinutes(record) {
  const type = String(record.type || '').toUpperCase();
  if (type !== 'TRAVEL') return 0;
  const total = Number(record.totalDurationMinutes) || 0;
  const working = Number(record.workingDurationMinutes) || 0;
  return Math.max(0, total - working);
}

function voiceHttpUrl(voiceNote) {
  const url = voiceNote?.url;
  if (url && /^https?:\/\//i.test(String(url))) return String(url);
  return '';
}

function linkCell(text, url) {
  if (!url) return text || '—';
  return { text: text || url, hyperlink: url };
}

function applyWorksheetFooter(sheet, generatedAt) {
  const stamp = formatDateTime(generatedAt);
  sheet.headerFooter = {
    oddFooter: `&LInfinity FSM — Automatically Generated Report&C${stamp}&RPage &P of &N`,
    evenFooter: `&LInfinity FSM — Automatically Generated Report&C${stamp}&RPage &P of &N`,
  };
}

function applyPrintSetup(sheet) {
  sheet.pageSetup = {
    orientation: 'landscape',
    fitToPage: true,
    fitToWidth: 1,
    fitToHeight: 0,
    paperSize: 9,
    margins: {
      left: 0.5,
      right: 0.5,
      top: 0.6,
      bottom: 0.7,
      header: 0.3,
      footer: 0.3,
    },
  };
}

function solidFill(argb) {
  return { type: 'pattern', pattern: 'solid', fgColor: { argb } };
}

function thinBorder() {
  const edge = { style: 'thin', color: { argb: COLORS.border } };
  return { top: edge, left: edge, bottom: edge, right: edge };
}

function styleStatusBadge(cell, status) {
  const key = String(status || '').toUpperCase();
  const fill = STATUS_FILLS[key];
  if (fill) cell.fill = fill;
  cell.font = { bold: true, size: 11 };
  cell.alignment = { vertical: 'middle', horizontal: 'center' };
}

function buildFilterLines(filters) {
  return Object.entries(filters || {})
    .filter(
      ([k, v]) =>
        k !== 'mode' &&
        v !== undefined &&
        v !== null &&
        String(v).trim() !== '' &&
        String(v).toUpperCase() !== 'ALL'
    )
    .map(([k, v]) => `${k}: ${v}`)
    .join('  |  ');
}

function departmentName(record) {
  const tech = record.userId;
  const dept = tech?.departmentId;
  if (dept && typeof dept === 'object' && dept.name) return dept.name;
  return '—';
}

function branchName(record) {
  const fromRecord = record.branchId;
  if (fromRecord && typeof fromRecord === 'object' && fromRecord.name) {
    return fromRecord.name;
  }
  const fromUser = record.userId?.branchId;
  if (fromUser && typeof fromUser === 'object' && fromUser.name) {
    return fromUser.name;
  }
  return '—';
}

function jobTitle(record) {
  return record.userId?.jobTitle || '—';
}

function syncStatusLabel(record) {
  const st = String(record.status || '').toUpperCase();
  if (st === 'RUNNING') return 'Active Session';
  return 'Synced';
}

function stagePhotos(record, stageMeta) {
  const urls = [];
  const push = (url) => {
    if (url && String(url).trim() && /^https?:\/\//i.test(String(url))) {
      const u = String(url).trim();
      if (!urls.includes(u)) urls.push(u);
    }
  };
  const cp = record.checkpoints?.[stageMeta.key];
  push(cp?.photo?.url);
  if (stageMeta.legacyPhoto) {
    push(record[stageMeta.legacyPhoto]?.url);
  }
  return urls;
}

function resolveStage(record, stageMeta) {
  const cp = record.checkpoints?.[stageMeta.key] || null;
  const gps = cp?.gps || (stageMeta.legacyGps ? record[stageMeta.legacyGps] : null);
  const at = cp?.at || (stageMeta.legacyAt ? record[stageMeta.legacyAt] : null);
  const address =
    cp?.address ||
    (stageMeta.legacyAddress ? record[stageMeta.legacyAddress] : null) ||
    gps?.fullAddress ||
    '';
  return {
    at,
    gps,
    address: address || '—',
    battery: cp?.batteryLevel ?? null,
    network: cp?.networkStatus || '—',
    deviceId: cp?.deviceId || (stageMeta.legacyDevice ? record[stageMeta.legacyDevice] : '') || '—',
    notes: cp?.notes || '—',
    voiceNote: cp?.voiceNote || null,
    photos: stagePhotos(record, stageMeta),
  };
}

function toCloudinaryThumbUrl(url, width = THUMB_WIDTH, height = THUMB_HEIGHT) {
  if (!url || !url.includes('/upload/')) return url;
  // Avoid double-transforming.
  if (/\/upload\/[^/]*w_\d+/.test(url)) return url;
  return url.replace(
    '/upload/',
    `/upload/c_fill,w_${width},h_${height},q_auto:eco,f_jpg/`
  );
}

async function fetchImageBuffer(url, { width, height } = {}) {
  if (!url) return null;
  const target =
    width && height ? toCloudinaryThumbUrl(url, width, height) : url;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), IMAGE_FETCH_TIMEOUT_MS);
    const res = await fetch(target, {
      signal: controller.signal,
      headers: { Accept: 'image/*' },
    });
    clearTimeout(timer);
    if (!res.ok) return null;
    const buf = Buffer.from(await res.arrayBuffer());
    return buf.length > 0 ? buf : null;
  } catch {
    return null;
  }
}

async function mapPool(items, concurrency, mapper) {
  const results = new Array(items.length);
  let next = 0;
  async function worker() {
    while (next < items.length) {
      const i = next;
      next += 1;
      results[i] = await mapper(items[i], i);
    }
  }
  const workers = Array.from(
    { length: Math.min(concurrency, Math.max(1, items.length)) },
    () => worker()
  );
  await Promise.all(workers);
  return results;
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
    }
    if (st === 'APPROVED') {
      const approved = resolveApprovedHours(record);
      if (approved !== null && Number.isFinite(approved)) {
        totalApprovedEligible += approved * 60;
      }
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
    return { year: m[1], month: months[idx] || m[2], monthNum: m[2] };
  })();

  if (safeEmployee && monthLabel) {
    return `Overtime_Employee_${safeEmployee}_${monthLabel.year}-${monthLabel.monthNum}.xlsx`;
  }
  if (String(mode).toLowerCase() === EXPORT_MODE.SUMMARY) {
    return `Overtime_Summary_${stamp}.xlsx`;
  }
  if (status === 'APPROVED' && monthLabel) {
    return `Overtime_Approved_${monthLabel.month}_${monthLabel.year}.xlsx`;
  }
  return `Overtime_Report_${stamp}.xlsx`;
}

function sessionSheetName(index) {
  // Excel sheet name max 31 chars; keep stable & linkable.
  return `Session ${index}`;
}

function sessionHyperlink(sheetName) {
  const escaped = String(sheetName).replace(/'/g, "''");
  return `#'${escaped}'!A1`;
}

async function buildImageCache(urls) {
  const unique = [...new Set(urls.filter(Boolean))];
  const cache = new Map();
  await mapPool(unique, IMAGE_FETCH_CONCURRENCY, async (url) => {
    const buf = await fetchImageBuffer(url, {
      width: THUMB_WIDTH,
      height: THUMB_HEIGHT,
    });
    if (buf) cache.set(url, buf);
  });
  return cache;
}

function writeKvRow(sheet, row, label1, value1, label2, value2) {
  const r = sheet.getRow(row);
  r.getCell(1).value = label1;
  r.getCell(1).font = { bold: true, color: { argb: COLORS.muted } };
  r.getCell(2).value = value1 ?? '—';
  r.getCell(2).alignment = { vertical: 'middle', wrapText: true };
  if (label2 !== undefined) {
    r.getCell(3).value = label2;
    r.getCell(3).font = { bold: true, color: { argb: COLORS.muted } };
    r.getCell(4).value = value2 ?? '—';
    r.getCell(4).alignment = { vertical: 'middle', wrapText: true };
  }
  for (let c = 1; c <= 4; c += 1) {
    r.getCell(c).border = thinBorder();
    r.getCell(c).fill = solidFill(COLORS.surface);
  }
  r.height = Math.max(22, estimateWrapHeight(String(value1 ?? ''), 40));
  return row + 1;
}

function estimateWrapHeight(text, charsPerLine) {
  const lines = Math.max(1, Math.ceil(String(text || '').length / charsPerLine));
  return Math.min(90, 18 + (lines - 1) * 14);
}

function writeSectionHeader(sheet, row, title, fillArgb = COLORS.navy) {
  sheet.mergeCells(row, 1, row, 6);
  const cell = sheet.getRow(row).getCell(1);
  cell.value = title;
  cell.font = { bold: true, color: { argb: COLORS.white }, size: 12 };
  cell.fill = solidFill(fillArgb);
  cell.alignment = { vertical: 'middle', horizontal: 'left', indent: 1 };
  sheet.getRow(row).height = 26;
  for (let c = 1; c <= 6; c += 1) {
    sheet.getRow(row).getCell(c).fill = solidFill(fillArgb);
    sheet.getRow(row).getCell(c).border = thinBorder();
  }
  return row + 1;
}

function writeSummaryKpiGrid(sheet, startRow, kpis) {
  let row = startRow;
  const cols = 4;
  for (let i = 0; i < kpis.length; i += cols) {
    const slice = kpis.slice(i, i + cols);
    const labelRow = sheet.getRow(row);
    const valueRow = sheet.getRow(row + 1);
    slice.forEach((kpi, idx) => {
      const col = idx + 1;
      labelRow.getCell(col).value = kpi.label;
      labelRow.getCell(col).font = {
        bold: true,
        size: 9,
        color: { argb: COLORS.muted },
      };
      labelRow.getCell(col).fill = solidFill(COLORS.navySoft);
      labelRow.getCell(col).alignment = {
        horizontal: 'center',
        vertical: 'middle',
      };
      labelRow.getCell(col).border = thinBorder();

      valueRow.getCell(col).value = kpi.value;
      valueRow.getCell(col).font = {
        bold: true,
        size: 16,
        color: { argb: COLORS.navy },
      };
      valueRow.getCell(col).fill = solidFill(COLORS.kpiBg);
      valueRow.getCell(col).alignment = {
        horizontal: 'center',
        vertical: 'middle',
      };
      valueRow.getCell(col).border = thinBorder();
    });
    labelRow.height = 20;
    valueRow.height = 32;
    row += 3;
  }
  return row;
}

async function addEmbeddedImage(workbook, sheet, buffer, {
  col,
  row,
  width = THUMB_WIDTH,
  height = THUMB_HEIGHT,
  hyperlink,
}) {
  if (!buffer) return;
  const imageId = workbook.addImage({
    buffer,
    extension: 'jpeg',
  });
  const opts = {
    tl: { col: col - 0.1, row: row - 1 + 0.15 },
    ext: { width, height },
    editAs: 'oneCell',
  };
  if (hyperlink) {
    opts.hyperlinks = {
      hyperlink,
      tooltip: 'Open original image',
    };
  }
  sheet.addImage(imageId, opts);
}

/**
 * Builds a polished enterprise overtime workbook.
 * Summary mode → Summary sheet only.
 * Detailed mode → Summary + Sessions Index + one sheet per session.
 */
export async function buildOvertimeExcelWorkbook({
  records,
  generatedBy,
  generatedAt = new Date(),
  filters = {},
  companyName = '',
  companyLogoUrl = '',
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

  // Pre-fetch thumbnails only for detailed session sheets (capped).
  const sheetable = limited.slice(0, MAX_SESSION_SHEETS);
  const overflow = limited.slice(MAX_SESSION_SHEETS);
  let imageCache = new Map();
  let logoBuffer = null;

  if (companyLogoUrl) {
    logoBuffer = await fetchImageBuffer(companyLogoUrl, {
      width: 220,
      height: 80,
    });
  }

  if (exportMode === EXPORT_MODE.DETAILED && sheetable.length > 0) {
    const photoUrls = [];
    for (const record of sheetable) {
      for (const stage of STAGE_META) {
        photoUrls.push(...stagePhotos(record, stage));
      }
    }
    imageCache = await buildImageCache(photoUrls);
  }

  // ——— Summary ———
  const summary = workbook.addWorksheet('Summary', {
    views: [{ state: 'frozen', ySplit: 3 }],
    properties: { defaultRowHeight: 18 },
  });
  summary.columns = [
    { width: 28 },
    { width: 28 },
    { width: 28 },
    { width: 28 },
    { width: 18 },
    { width: 18 },
  ];
  applyPrintSetup(summary);
  applyWorksheetFooter(summary, generatedAt);

  if (logoBuffer) {
    await addEmbeddedImage(workbook, summary, logoBuffer, {
      col: 1,
      row: 1,
      width: 160,
      height: 58,
      hyperlink: companyLogoUrl || undefined,
    });
    summary.getRow(1).height = 62;
  }

  summary.mergeCells(2, 1, 2, 4);
  const titleCell = summary.getRow(2).getCell(1);
  titleCell.value = 'Infinity FSM — Overtime Executive Report';
  titleCell.font = { bold: true, size: 18, color: { argb: COLORS.navy } };
  summary.getRow(2).height = 28;

  summary.mergeCells(3, 1, 3, 4);
  summary.getRow(3).getCell(1).value =
    companyName || 'Enterprise Field Service Management';
  summary.getRow(3).getCell(1).font = {
    size: 12,
    color: { argb: COLORS.muted },
  };

  let cursor = 5;
  cursor = writeSectionHeader(summary, cursor, 'Report Metadata', COLORS.navy);
  cursor = writeKvRow(
    summary,
    cursor,
    'Company Name',
    companyName || '—',
    'Generated By',
    generatedBy || '—'
  );
  cursor = writeKvRow(
    summary,
    cursor,
    'Generated At',
    formatDateTime(generatedAt),
    'Application Version',
    appVersion || '—'
  );
  cursor = writeKvRow(
    summary,
    cursor,
    'Export Type',
    exportMode === EXPORT_MODE.SUMMARY ? 'Summary' : 'Detailed Report',
    'Date Range',
    filters.dateRange || 'All'
  );
  cursor = writeKvRow(
    summary,
    cursor,
    'Applied Filters',
    filterLines || 'None',
    'Sessions in Export',
    limited.length
  );
  cursor += 1;

  cursor = writeSectionHeader(
    summary,
    cursor,
    'Key Performance Indicators',
    COLORS.navy
  );
  cursor = writeSummaryKpiGrid(summary, cursor, [
    { label: 'Total Sessions', value: limited.length },
    { label: 'Approved', value: stats.statusCounts.APPROVED },
    { label: 'Pending', value: stats.statusCounts.PENDING_REVIEW },
    { label: 'Rejected', value: stats.statusCounts.REJECTED },
    { label: 'Travel Overtime', value: stats.travelCount },
    { label: 'Normal Overtime', value: stats.normalCount },
    { label: 'Average Hours', value: stats.averageHours },
    { label: 'Maximum Hours', value: stats.maximumHours },
    { label: 'Minimum Hours', value: stats.minimumHours },
    { label: 'Total Approved Hours', value: stats.totalApprovedHours },
    { label: 'Total Working Hours', value: stats.totalWorkingHours },
    { label: 'Total Travel Hours', value: stats.totalTravelHours },
    { label: 'Total Calculated Hours', value: stats.totalEligibleHours },
  ]);

  if (exportMode === EXPORT_MODE.SUMMARY) {
    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  // ——— Sessions Index ———
  const indexSheet = workbook.addWorksheet('Sessions Index', {
    views: [{ state: 'frozen', ySplit: 1 }],
  });
  applyPrintSetup(indexSheet);
  applyWorksheetFooter(indexSheet, generatedAt);
  indexSheet.columns = [
    { width: 26 },
    { width: 22 },
    { width: 14 },
    { width: 18 },
    { width: 16 },
    { width: 12 },
    { width: 16 },
    { width: 12 },
    { width: 14 },
    { width: 18 },
  ];

  const indexHeaders = [
    'Session ID',
    'Employee Name',
    'Employee ID',
    'Department',
    'Branch',
    'Date',
    'Status',
    'Type',
    'Approved Hours',
    'Worksheet',
  ];
  const headerRow = indexSheet.getRow(1);
  indexHeaders.forEach((h, i) => {
    const cell = headerRow.getCell(i + 1);
    cell.value = h;
    cell.font = { bold: true, color: { argb: COLORS.white } };
    cell.fill = solidFill(COLORS.navy);
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
    cell.border = thinBorder();
  });
  headerRow.height = 28;

  const indexRows = [];
  limited.forEach((record, i) => {
    const seq = i + 1;
    const hasSheet = i < MAX_SESSION_SHEETS;
    const sheetName = hasSheet ? sessionSheetName(seq) : 'Additional Sessions';
    const approvedHours =
      String(record.status).toUpperCase() === 'APPROVED'
        ? (resolveApprovedHours(record) ?? '—')
        : '—';
    const rowValues = [
      record._id?.toString?.() || '',
      userDisplayName(record.userId),
      record.userId?.employeeId || '—',
      departmentName(record),
      branchName(record),
      formatDate(record.startAt || record.createdAt),
      record.status || '—',
      record.type || '—',
      approvedHours,
      hasSheet
        ? linkCell(`Open ${sheetName}`, sessionHyperlink(sheetName))
        : linkCell('See Additional Sessions', "#'Additional Sessions'!A1"),
    ];
    indexRows.push(rowValues);
  });

  if (indexRows.length === 0) {
    indexHeaders.forEach((h, i) => {
      const cell = headerRow.getCell(i + 1);
      cell.value = h;
    });
    indexSheet.getRow(2).getCell(1).value = 'No overtime sessions matched the selected filters.';
    indexSheet.mergeCells(2, 1, 2, 10);
  } else {
    indexSheet.addTable({
      name: 'SessionsIndexTable',
      ref: 'A1',
      headerRow: true,
      style: { theme: 'TableStyleMedium2', showRowStripes: true },
      columns: indexHeaders.map((name) => ({ name, filterButton: true })),
      rows: indexRows.map((row) =>
        row.map((cell) =>
          cell && typeof cell === 'object' && cell.hyperlink ? cell.text : cell
        )
      ),
    });

    for (let i = 0; i < indexRows.length; i += 1) {
      const excelRow = indexSheet.getRow(i + 2);
      const source = indexRows[i];
      source.forEach((value, colIdx) => {
        const cell = excelRow.getCell(colIdx + 1);
        if (value && typeof value === 'object' && value.hyperlink) {
          cell.value = { text: value.text, hyperlink: value.hyperlink };
          cell.font = {
            color: { argb: COLORS.link },
            underline: true,
            size: 10,
          };
        }
      });
      styleStatusBadge(excelRow.getCell(7), limited[i]?.status);
      excelRow.alignment = { vertical: 'middle', wrapText: true };
    }
  }

  if (overflow.length > 0) {
    const noteRow = indexSheet.getRow(indexRows.length + 3);
    noteRow.getCell(1).value = `Note: ${overflow.length} additional session(s) appear in “Additional Sessions” (export exceeded ${MAX_SESSION_SHEETS} detailed sheets for performance).`;
    indexSheet.mergeCells(noteRow.number, 1, noteRow.number, 10);
    noteRow.getCell(1).font = { italic: true, color: { argb: COLORS.muted } };
  }

  // ——— Per-session sheets ———
  for (let i = 0; i < sheetable.length; i += 1) {
    const record = sheetable[i];
    const seq = i + 1;
    const sheet = workbook.addWorksheet(sessionSheetName(seq), {
      views: [{ state: 'frozen', ySplit: 2 }],
    });
    applyPrintSetup(sheet);
    applyWorksheetFooter(sheet, generatedAt);
    sheet.columns = [
      { width: 24 },
      { width: 36 },
      { width: 24 },
      { width: 28 },
      { width: 18 },
      { width: 18 },
    ];

    sheet.mergeCells(1, 1, 1, 6);
    sheet.getRow(1).getCell(1).value = `Overtime Session Report — ${seq}`;
    sheet.getRow(1).getCell(1).font = {
      bold: true,
      size: 16,
      color: { argb: COLORS.navy },
    };
    sheet.getRow(1).height = 28;

    sheet.mergeCells(2, 1, 2, 6);
    sheet.getRow(2).getCell(1).value = `Session ID: ${record._id?.toString?.() || '—'}`;
    sheet.getRow(2).getCell(1).font = { size: 10, color: { argb: COLORS.muted } };

    let r = 4;
    r = writeSectionHeader(sheet, r, 'Employee Information', COLORS.navy);
    r = writeKvRow(
      sheet,
      r,
      'Employee Name',
      userDisplayName(record.userId),
      'Employee ID',
      record.userId?.employeeId || '—'
    );
    r = writeKvRow(
      sheet,
      r,
      'Department',
      departmentName(record),
      'Branch',
      branchName(record)
    );
    r = writeKvRow(sheet, r, 'Job Title', jobTitle(record), '', '');
    r += 1;

    const reviewer =
      String(record.status).toUpperCase() === 'REJECTED'
        ? userDisplayName(record.rejectedBy)
        : userDisplayName(record.approvedBy);
    const reviewedAt =
      String(record.status).toUpperCase() === 'REJECTED'
        ? record.rejectedAt
        : record.approvedAt;
    const approvedHours =
      String(record.status).toUpperCase() === 'APPROVED'
        ? (resolveApprovedHours(record) ?? '—')
        : '—';
    const workedHours = workedHoursFromRecord(record) ?? '—';

    r = writeSectionHeader(sheet, r, 'Overtime Information', COLORS.navy);
    const statusRow = r;
    r = writeKvRow(
      sheet,
      r,
      'Status',
      record.status || '—',
      'Type',
      record.type || '—'
    );
    styleStatusBadge(sheet.getRow(statusRow).getCell(2), record.status);

    r = writeKvRow(
      sheet,
      r,
      'Created At',
      formatDateTime(record.createdAt),
      'Approved / Reviewed By',
      reviewer
    );
    r = writeKvRow(
      sheet,
      r,
      'Approved / Reviewed At',
      formatDateTime(reviewedAt),
      'Sync Status',
      syncStatusLabel(record)
    );
    r = writeKvRow(
      sheet,
      r,
      'Worked Hours',
      workedHours,
      'Approved Hours',
      approvedHours
    );
    r = writeKvRow(
      sheet,
      r,
      'Calculated Hours',
      hoursLabel(record.eligibleOvertimeMinutes),
      '',
      ''
    );
    r = writeKvRow(
      sheet,
      r,
      'Working Hours',
      hoursLabel(record.workingDurationMinutes),
      'Travel Hours',
      hoursLabel(travelMinutes(record))
    );
    r = writeKvRow(
      sheet,
      r,
      'Review Notes',
      record.reviewNotes || '—',
      'Rejection Reason',
      record.rejectionReason || '—'
    );
    // Expand review notes row for long text.
    sheet.getRow(r - 1).height = Math.max(
      28,
      estimateWrapHeight(
        `${record.reviewNotes || ''} ${record.rejectionReason || ''}`,
        50
      )
    );
    r += 1;

    r = writeSectionHeader(sheet, r, 'Journey Timeline', COLORS.navy);

    for (const stageMeta of STAGE_META) {
      const stage = resolveStage(record, stageMeta);
      r = writeSectionHeader(sheet, r, stageMeta.title, stageMeta.headerArgb);

      const map = mapsUrl(stage.gps?.latitude, stage.gps?.longitude);
      const voiceUrl = voiceHttpUrl(stage.voiceNote);
      const voiceDur = formatVoiceDuration(stage.voiceNote?.duration);
      const voiceDisplay = voiceUrl
        ? linkCell(
            `🎤 ${stageMeta.voiceLabel}${voiceDur ? ` (${voiceDur})` : ''}`,
            voiceUrl
          )
        : '—';

      r = writeKvRow(
        sheet,
        r,
        'Timestamp',
        formatDateTime(stage.at),
        'GPS Accuracy (m)',
        stage.gps?.accuracy ?? '—'
      );
      // Full address — never truncate; wrap + tall row.
      const addrRow = r;
      r = writeKvRow(sheet, r, 'Full Address', stage.address, '', '');
      sheet.mergeCells(addrRow, 2, addrRow, 4);
      sheet.getRow(addrRow).getCell(2).alignment = {
        wrapText: true,
        vertical: 'top',
      };
      sheet.getRow(addrRow).height = Math.max(
        36,
        estimateWrapHeight(stage.address, 55)
      );

      r = writeKvRow(
        sheet,
        r,
        'Latitude',
        stage.gps?.latitude ?? '—',
        'Longitude',
        stage.gps?.longitude ?? '—'
      );
      const mapsRow = r;
      r = writeKvRow(
        sheet,
        r,
        'Google Maps',
        map ? linkCell('📍 Open in Google Maps', map) : '—',
        'Battery Level',
        stage.battery === null || stage.battery === undefined
          ? '—'
          : `${stage.battery}%`
      );
      const mapsCell = sheet.getRow(mapsRow).getCell(2);
      if (map) {
        mapsCell.value = { text: '📍 Open in Google Maps', hyperlink: map };
        mapsCell.font = {
          color: { argb: COLORS.link },
          underline: true,
          bold: true,
        };
      }

      r = writeKvRow(
        sheet,
        r,
        'Network Type',
        stage.network,
        'Device ID',
        stage.deviceId
      );
      r = writeKvRow(
        sheet,
        r,
        'Device Platform',
        '—',
        'Device Model',
        '—'
      );
      r = writeKvRow(
        sheet,
        r,
        'App Version',
        appVersion || '—',
        'Stage Notes',
        stage.notes
      );

      const voiceRow = r;
      r = writeKvRow(sheet, r, 'Voice Recording', voiceDisplay, 'Photo Count', stage.photos.length);
      const voiceCell = sheet.getRow(voiceRow).getCell(2);
      if (voiceUrl) {
        voiceCell.value = {
          text: `🎤 ${stageMeta.voiceLabel}${voiceDur ? ` (${voiceDur})` : ''}`,
          hyperlink: voiceUrl,
        };
        voiceCell.font = {
          color: { argb: COLORS.link },
          underline: true,
          bold: true,
        };
      }

      // Photos section — embed ALL stage thumbnails.
      sheet.mergeCells(r, 1, r, 6);
      sheet.getRow(r).getCell(1).value =
        stage.photos.length > 0
          ? `Photos (${stage.photos.length})`
          : 'Photos';
      sheet.getRow(r).getCell(1).font = { bold: true };
      sheet.getRow(r).getCell(1).fill = solidFill(stageMeta.bodyArgb);
      for (let c = 1; c <= 6; c += 1) {
        sheet.getRow(r).getCell(c).fill = solidFill(stageMeta.bodyArgb);
        sheet.getRow(r).getCell(c).border = thinBorder();
      }
      r += 1;

      if (stage.photos.length === 0) {
        sheet.getRow(r).getCell(1).value = '—';
        r += 1;
      } else {
        const perRow = 4;
        for (let p = 0; p < stage.photos.length; p += perRow) {
          const batch = stage.photos.slice(p, p + perRow);
          const labelRowNum = r;
          const imageRowNum = r + 1;
          batch.forEach((url, idx) => {
            const col = idx + 1;
            const labelCell = sheet.getRow(labelRowNum).getCell(col);
            labelCell.value = {
              text: `Photo ${p + idx + 1}`,
              hyperlink: url,
            };
            labelCell.font = {
              color: { argb: COLORS.link },
              underline: true,
              size: 9,
              bold: true,
            };
            labelCell.alignment = { horizontal: 'center' };
            labelCell.fill = solidFill(stageMeta.bodyArgb);
            labelCell.border = thinBorder();

            const buf = imageCache.get(url);
            if (buf) {
              // Fire-and-forget sync add (buffer already loaded).
              // exceljs addImage is sync once buffer exists.
            }
            sheet.getRow(imageRowNum).getCell(col).fill = solidFill(
              stageMeta.bodyArgb
            );
            sheet.getRow(imageRowNum).getCell(col).border = thinBorder();
          });
          sheet.getRow(labelRowNum).height = 18;
          sheet.getRow(imageRowNum).height = THUMB_HEIGHT + 12;

          batch.forEach((url, idx) => {
            const buf = imageCache.get(url);
            if (!buf) {
              sheet.getRow(imageRowNum).getCell(idx + 1).value = {
                text: 'Open image',
                hyperlink: url,
              };
              sheet.getRow(imageRowNum).getCell(idx + 1).font = {
                color: { argb: COLORS.link },
                underline: true,
              };
              return;
            }
            // Synchronous image add with preloaded buffer.
            const imageId = workbook.addImage({
              buffer: buf,
              extension: 'jpeg',
            });
            sheet.addImage(imageId, {
              tl: { col: idx + 0.05, row: imageRowNum - 1 + 0.1 },
              ext: { width: THUMB_WIDTH, height: THUMB_HEIGHT },
              editAs: 'oneCell',
              hyperlinks: {
                hyperlink: url,
                tooltip: `Open Photo ${p + idx + 1}`,
              },
            });
          });

          r += 2;
        }
      }
      r += 1;
    }

    // Back to index link
    sheet.getRow(r).getCell(1).value = {
      text: '← Back to Sessions Index',
      hyperlink: "#'Sessions Index'!A1",
    };
    sheet.getRow(r).getCell(1).font = {
      color: { argb: COLORS.link },
      underline: true,
      bold: true,
    };
  }

  // ——— Overflow bulk sheet (when > MAX_SESSION_SHEETS) ———
  if (overflow.length > 0) {
    const bulk = workbook.addWorksheet('Additional Sessions', {
      views: [{ state: 'frozen', ySplit: 1 }],
    });
    applyPrintSetup(bulk);
    applyWorksheetFooter(bulk, generatedAt);
    const bulkHeaders = [
      'Session ID',
      'Employee Name',
      'Employee ID',
      'Department',
      'Branch',
      'Date',
      'Status',
      'Type',
      'Calculated Hours',
      'Approved Hours',
      'Working Hours',
      'Travel Hours',
    ];
    bulk.columns = bulkHeaders.map(() => ({ width: 16 }));
    bulk.getRow(1).values = bulkHeaders;
    bulk.getRow(1).eachCell((cell) => {
      cell.font = { bold: true, color: { argb: COLORS.white } };
      cell.fill = solidFill(COLORS.navy);
      cell.border = thinBorder();
    });
    overflow.forEach((record, idx) => {
      const row = bulk.getRow(idx + 2);
      row.values = [
        null,
        record._id?.toString?.() || '',
        userDisplayName(record.userId),
        record.userId?.employeeId || '—',
        departmentName(record),
        branchName(record),
        formatDate(record.startAt || record.createdAt),
        record.status || '—',
        record.type || '—',
        hoursLabel(record.eligibleOvertimeMinutes),
        String(record.status).toUpperCase() === 'APPROVED'
          ? (resolveApprovedHours(record) ?? '—')
          : '—',
        hoursLabel(record.workingDurationMinutes),
        hoursLabel(travelMinutes(record)),
      ];
      styleStatusBadge(row.getCell(7), record.status);
      row.alignment = { vertical: 'middle', wrapText: true };
    });
  }

  const buffer = await workbook.xlsx.writeBuffer();
  return Buffer.from(buffer);
}

export { MAX_EXPORT_ROWS, MAX_SESSION_SHEETS };
