import ExcelJS from 'exceljs';
import { createRequire } from 'module';
import {
  resolveApprovedHours,
  resolveApprovedMinutes,
  workedHoursFromRecord,
} from './overtime.approved-hours.js';
import {
  EXPORT_LANG,
  normalizeExportLanguage,
  excelStrings,
  formatDurationProseFromMinutes,
  formatDurationProseFromHours,
  statusLabel,
  typeLabel,
  overnightLabel,
  stageMetaForLang,
  excelSafeDurationText,
  stripBidiMarks,
} from './overtime.excel.i18n.js';

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

function hoursLabel(minutes, lang = EXPORT_LANG.EN) {
  return formatDurationProseFromMinutes(minutes, lang);
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
    .replace(/[^\w-]+/g, '_')
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

function applyWorksheetFooter(sheet, generatedAt, lang = EXPORT_LANG.EN) {
  const t = excelStrings(lang);
  const stamp = formatDateTime(generatedAt);
  sheet.headerFooter = {
    oddFooter: `&L${t.footerLeft}&C${stamp}&R${t.footerPage}`,
    evenFooter: `&L${t.footerLeft}&C${stamp}&R${t.footerPage}`,
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

function buildFilterLines(filters, lang = EXPORT_LANG.EN) {
  const t = excelStrings(lang);
  const labels = {
    status: t.status,
    type: t.type,
    dateRange: t.dateRange,
    startDate: t.startDate,
    endDate: t.endDate,
    employeeId: t.employeeId,
    userId: t.employeeName,
    employeeName: t.employeeName,
  };
  return Object.entries(filters || {})
    .filter(
      ([k, v]) =>
        k !== 'mode' &&
        k !== 'language' &&
        v !== undefined &&
        v !== null &&
        String(v).trim() !== '' &&
        String(v).toUpperCase() !== 'ALL'
    )
    .map(([k, v]) => {
      let value = v;
      if (String(v).toUpperCase() === 'ALL') value = t.all;
      else if (k === 'status') value = statusLabel(v, lang);
      else if (k === 'type') value = typeLabel(v, lang);
      return `${labels[k] || k}: ${value}`;
    })
    .join('  |  ');
}

function userEmail(record) {
  const user = record?.userId;
  if (!user || typeof user === 'string') return '—';
  return user.email || '—';
}

function jobTitle(record) {
  return record.userId?.jobTitle || '—';
}

function syncStatusLabel(record, lang = EXPORT_LANG.EN) {
  const t = excelStrings(lang);
  const st = String(record.status || '').toUpperCase();
  if (st === 'RUNNING') return t.syncActive;
  return t.syncSynced;
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
    const controller = new globalThis.AbortController();
    const timer = setTimeout(() => controller.abort(), IMAGE_FETCH_TIMEOUT_MS);
    const res = await globalThis.fetch(target, {
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
  let overnightTravelCount = 0;
  let totalEligible = 0;
  let totalWorking = 0;
  let totalTravel = 0;
  let totalApprovedMinutes = 0;
  const eligibleSamples = [];

  for (const record of records) {
    const st = String(record.status || '').toUpperCase();
    if (statusCounts[st] !== undefined) statusCounts[st] += 1;
    const type = String(record.type || '').toUpperCase();
    if (type === 'TRAVEL') {
      travelCount += 1;
      if (record.isOvernight) overnightTravelCount += 1;
    } else if (type === 'NORMAL') {
      normalCount += 1;
    }

    const eligible = Number(record.eligibleOvertimeMinutes);
    if (Number.isFinite(eligible)) {
      totalEligible += eligible;
      eligibleSamples.push(eligible);
    }
    if (st === 'APPROVED') {
      totalApprovedMinutes += resolveApprovedMinutes(record);
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
    overnightTravelCount,
    averageMinutes: avg,
    maximumMinutes: max,
    minimumMinutes: min,
    totalApprovedMinutes,
    totalWorkingMinutes: totalWorking,
    totalTravelMinutes: totalTravel,
    totalEligibleMinutes: totalEligible,
  };
}

/**
 * Aggregate each overtime record exactly once into its technician summary.
 */
export function computeEmployeeSummaries(records = []) {
  const employees = new Map();

  for (const record of records || []) {
    const user = record?.userId;
    const name = userDisplayName(user);
    const email = userEmail(record);
    const identity =
      (typeof user === 'object' && user?._id?.toString?.()) ||
      (email !== '—' ? email.toLowerCase() : '') ||
      name;
    const key = String(identity || '—');
    let summary = employees.get(key);
    if (!summary) {
      summary = {
        technicianName: name,
        email,
        totalApprovedMinutes: 0,
        totalWorkedMinutes: 0,
        totalSessions: 0,
        normalSessions: 0,
        travelSessions: 0,
        overnightTrips: 0,
        approvedSessions: 0,
        pendingReviewSessions: 0,
        rejectedSessions: 0,
      };
      employees.set(key, summary);
    }

    const status = String(record?.status || '').toUpperCase();
    const type = String(record?.type || '').toUpperCase();
    const eligibleMinutes = Number(record?.eligibleOvertimeMinutes);
    summary.totalSessions += 1;
    if (Number.isFinite(eligibleMinutes)) {
      summary.totalWorkedMinutes += eligibleMinutes;
    }
    if (type === 'TRAVEL') {
      summary.travelSessions += 1;
      if (record?.isOvernight) summary.overnightTrips += 1;
    } else if (type === 'NORMAL') {
      summary.normalSessions += 1;
    }
    if (status === 'APPROVED') {
      summary.approvedSessions += 1;
      summary.totalApprovedMinutes += resolveApprovedMinutes(record);
    } else if (status === 'PENDING_REVIEW') {
      summary.pendingReviewSessions += 1;
    } else if (status === 'REJECTED') {
      summary.rejectedSessions += 1;
    }
  }

  return [...employees.values()].sort((a, b) =>
    a.technicianName.localeCompare(b.technicianName, undefined, {
      sensitivity: 'base',
    })
  );
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

function sessionSheetName(index, lang = EXPORT_LANG.EN) {
  // Excel sheet name max 31 chars; keep stable & linkable.
  return excelStrings(lang).sheetSession(index);
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

function writeEmployeeSummaryTable(sheet, startRow, summaries, lang) {
  const t = excelStrings(lang);
  const headers = [
    t.empName,
    t.empEmail,
    t.empApprovedHours,
    t.empWorkedHours,
    t.empSessions,
    t.empNormal,
    t.empTravel,
    t.empOvernight,
    t.empApproved,
    t.empPending,
    t.empRejected,
  ];
  const headerRow = sheet.getRow(startRow);
  headers.forEach((header, index) => {
    const cell = headerRow.getCell(index + 1);
    cell.value = header;
    cell.font = { bold: true, color: { argb: COLORS.white } };
    cell.fill = solidFill(COLORS.navy);
    cell.border = thinBorder();
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
  });
  headerRow.height = 34;

  summaries.forEach((employee, index) => {
    const row = sheet.getRow(startRow + index + 1);
    row.values = [
      null,
      employee.technicianName,
      employee.email,
      formatDurationProseFromMinutes(employee.totalApprovedMinutes, lang),
      formatDurationProseFromMinutes(employee.totalWorkedMinutes, lang),
      employee.totalSessions,
      employee.normalSessions,
      employee.travelSessions,
      employee.overnightTrips,
      employee.approvedSessions,
      employee.pendingReviewSessions,
      employee.rejectedSessions,
    ];
    row.eachCell((cell) => {
      cell.border = thinBorder();
      cell.alignment = { vertical: 'middle', wrapText: true };
      if (index % 2 === 1) cell.fill = solidFill(COLORS.altRow);
    });
  });
  return startRow + summaries.length + 1;
}

async function addEmbeddedImage(workbook, sheet, buffer, {
  col,
  row,
  width = THUMB_WIDTH,
  height = THUMB_HEIGHT,
  hyperlink,
  tooltip,
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
      tooltip,
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
  language = EXPORT_LANG.EN,
} = {}) {
  const lang = normalizeExportLanguage(language);
  const t = excelStrings(lang);
  const stageMeta = stageMetaForLang(lang);
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Infinity FSM';
  workbook.company = companyName || 'Infinity FSM';
  workbook.created = generatedAt;
  workbook.modified = generatedAt;

  const limited = records.slice(0, MAX_EXPORT_ROWS);
  const stats = computeStats(limited);
  const employeeSummaries = computeEmployeeSummaries(limited);
  const filterLines = buildFilterLines(filters, lang);
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
      for (const stage of stageMeta) {
        photoUrls.push(...stagePhotos(record, stage));
      }
    }
    imageCache = await buildImageCache(photoUrls);
  }

  // ——— Summary ———
  const summary = workbook.addWorksheet(t.sheetSummary, {
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
    { width: 18 },
    { width: 18 },
    { width: 18 },
    { width: 18 },
    { width: 18 },
  ];
  applyPrintSetup(summary);
  applyWorksheetFooter(summary, generatedAt, lang);

  if (logoBuffer) {
    await addEmbeddedImage(workbook, summary, logoBuffer, {
      col: 1,
      row: 1,
      width: 160,
      height: 58,
      hyperlink: companyLogoUrl || undefined,
      tooltip: t.openOriginalImage,
    });
    summary.getRow(1).height = 62;
  }

  summary.mergeCells(2, 1, 2, 4);
  const titleCell = summary.getRow(2).getCell(1);
  titleCell.value = t.reportTitle;
  titleCell.font = { bold: true, size: 18, color: { argb: COLORS.navy } };
  summary.getRow(2).height = 28;

  summary.mergeCells(3, 1, 3, 4);
  summary.getRow(3).getCell(1).value =
    companyName || t.companyFallback;
  summary.getRow(3).getCell(1).font = {
    size: 12,
    color: { argb: COLORS.muted },
  };

  let cursor = 5;
  cursor = writeSectionHeader(summary, cursor, t.sectionReportMetadata, COLORS.navy);
  cursor = writeKvRow(
    summary,
    cursor,
    t.companyName,
    companyName || '—',
    t.generatedBy,
    generatedBy || '—'
  );
  cursor = writeKvRow(
    summary,
    cursor,
    t.generatedAt,
    formatDateTime(generatedAt),
    t.applicationVersion,
    appVersion || '—'
  );
  cursor = writeKvRow(
    summary,
    cursor,
    t.exportType,
    exportMode === EXPORT_MODE.SUMMARY ? t.exportModeSummary : t.exportModeDetailed,
    t.dateRange,
    String(filters.dateRange || '').toUpperCase() === 'ALL'
      ? t.all
      : filters.dateRange || t.all
  );
  cursor = writeKvRow(
    summary,
    cursor,
    t.appliedFilters,
    filterLines || t.none,
    t.sessionsInExport,
    limited.length
  );
  cursor = writeKvRow(
    summary,
    cursor,
    t.reportLanguage,
    lang === EXPORT_LANG.AR ? t.languageArabic : t.languageEnglish
  );
  cursor += 1;

  cursor = writeSectionHeader(
    summary,
    cursor,
    t.sectionKpis,
    COLORS.navy
  );
  cursor = writeSummaryKpiGrid(summary, cursor, [
    { label: t.kpiTotalTechnicians, value: employeeSummaries.length },
    {
      label: t.kpiTotalOvertimeHours,
      value: formatDurationProseFromMinutes(stats.totalEligibleMinutes, lang),
    },
    { label: t.kpiTotalSessions, value: limited.length },
    { label: t.kpiTravelTrips, value: stats.travelCount },
    { label: t.kpiNormalSessions, value: stats.normalCount },
    { label: t.kpiOvernightTrips, value: stats.overnightTravelCount },
    { label: t.kpiApprovedSessions, value: stats.statusCounts.APPROVED },
  ]);

  cursor = writeSectionHeader(
    summary,
    cursor,
    t.sectionEmployeeBreakdown,
    COLORS.navy
  );
  writeEmployeeSummaryTable(summary, cursor, employeeSummaries, lang);

  if (exportMode === EXPORT_MODE.SUMMARY) {
    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  // ——— Sessions Index ———
  const indexSheet = workbook.addWorksheet(t.sheetSessionsIndex, {
    views: [{ state: 'frozen', ySplit: 1 }],
  });
  applyPrintSetup(indexSheet);
  applyWorksheetFooter(indexSheet, generatedAt, lang);
  indexSheet.columns = [
    { width: 26 },
    { width: 22 },
    { width: 28 },
    { width: 14 },
    { width: 12 },
    { width: 20 },
    { width: 20 },
    { width: 20 },
    { width: 14 },
    { width: 12 },
    { width: 12 },
    { width: 18 },
    { width: 18 },
    { width: 18 },
    { width: 18 },
  ];

  const indexHeaders = [
    t.sessionId,
    t.employeeName,
    t.email,
    t.employeeId,
    t.date,
    t.startTime,
    t.endTime,
    t.createdAt,
    t.status,
    t.type,
    t.overnight,
    t.workedHours,
    t.calculatedHours,
    t.approvedHours,
    t.worksheet,
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

  const indexColCount = indexHeaders.length;
  const indexRows = [];
  limited.forEach((record, i) => {
    const seq = i + 1;
    const hasSheet = i < MAX_SESSION_SHEETS;
    const sheetName = hasSheet ? sessionSheetName(seq, lang) : t.sheetAdditionalSessions;
    const approvedHours =
      String(record.status).toUpperCase() === 'APPROVED'
        ? formatDurationProseFromHours(resolveApprovedHours(record), lang)
        : t.dash;
    const rowValues = [
      record._id?.toString?.() || '',
      userDisplayName(record.userId),
      userEmail(record),
      record.userId?.employeeId || t.dash,
      formatDate(record.startAt || record.createdAt),
      formatDateTime(record.startAt),
      formatDateTime(record.endAt),
      formatDateTime(record.createdAt),
      statusLabel(record.status, lang),
      typeLabel(record.type, lang),
      overnightLabel(record, lang),
      formatDurationProseFromHours(workedHoursFromRecord(record), lang),
      hoursLabel(record.eligibleOvertimeMinutes, lang),
      approvedHours,
      hasSheet
        ? linkCell(t.openSheet(sheetName), sessionHyperlink(sheetName))
        : linkCell(t.seeAdditional, sessionHyperlink(t.sheetAdditionalSessions)),
    ];
    indexRows.push(rowValues);
  });

  if (indexRows.length === 0) {
    indexHeaders.forEach((h, i) => {
      const cell = headerRow.getCell(i + 1);
      cell.value = h;
    });
    indexSheet.getRow(2).getCell(1).value = t.noSessions;
    indexSheet.mergeCells(2, 1, 2, indexColCount);
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
      styleStatusBadge(excelRow.getCell(9), limited[i]?.status);
      excelRow.alignment = { vertical: 'middle', wrapText: true };
    }
  }

  if (overflow.length > 0) {
    const noteRow = indexSheet.getRow(indexRows.length + 3);
    noteRow.getCell(1).value = t.overflowNote(overflow.length, MAX_SESSION_SHEETS);
    indexSheet.mergeCells(noteRow.number, 1, noteRow.number, indexColCount);
    noteRow.getCell(1).font = { italic: true, color: { argb: COLORS.muted } };
  }

  // ——— Per-session sheets ———
  for (let i = 0; i < sheetable.length; i += 1) {
    const record = sheetable[i];
    const seq = i + 1;
    const sheet = workbook.addWorksheet(sessionSheetName(seq, lang), {
      views: [{ state: 'frozen', ySplit: 2 }],
    });
    applyPrintSetup(sheet);
    applyWorksheetFooter(sheet, generatedAt, lang);
    sheet.columns = [
      { width: 24 },
      { width: 36 },
      { width: 24 },
      { width: 28 },
      { width: 18 },
      { width: 18 },
    ];

    sheet.mergeCells(1, 1, 1, 6);
    sheet.getRow(1).getCell(1).value = t.sessionReportTitle(seq);
    sheet.getRow(1).getCell(1).font = {
      bold: true,
      size: 16,
      color: { argb: COLORS.navy },
    };
    sheet.getRow(1).height = 28;

    sheet.mergeCells(2, 1, 2, 6);
    sheet.getRow(2).getCell(1).value = t.sessionIdLine(
      record._id?.toString?.() || t.dash
    );
    sheet.getRow(2).getCell(1).font = { size: 10, color: { argb: COLORS.muted } };

    let r = 4;
    r = writeSectionHeader(sheet, r, t.sectionEmployeeInfo, COLORS.navy);
    r = writeKvRow(
      sheet,
      r,
      t.employeeName,
      userDisplayName(record.userId),
      t.employeeId,
      record.userId?.employeeId || t.dash
    );
    r = writeKvRow(
      sheet,
      r,
      t.email,
      userEmail(record),
      t.jobTitle,
      jobTitle(record)
    );
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
        ? formatDurationProseFromHours(resolveApprovedHours(record), lang)
        : t.dash;
    const workedHours = formatDurationProseFromHours(
      workedHoursFromRecord(record),
      lang
    );

    r = writeSectionHeader(sheet, r, t.sectionOvertimeInfo, COLORS.navy);
    const statusRow = r;
    r = writeKvRow(
      sheet,
      r,
      t.status,
      statusLabel(record.status, lang),
      t.type,
      typeLabel(record.type, lang)
    );
    styleStatusBadge(sheet.getRow(statusRow).getCell(2), record.status);

    r = writeKvRow(
      sheet,
      r,
      t.overnight,
      overnightLabel(record, lang),
      t.syncStatus,
      syncStatusLabel(record, lang)
    );
    r = writeKvRow(
      sheet,
      r,
      t.startTime,
      formatDateTime(record.startAt),
      t.endTime,
      formatDateTime(record.endAt)
    );
    r = writeKvRow(
      sheet,
      r,
      t.createdAt,
      formatDateTime(record.createdAt),
      t.approvedReviewedBy,
      reviewer
    );
    r = writeKvRow(
      sheet,
      r,
      t.approvedReviewedAt,
      formatDateTime(reviewedAt),
      '',
      ''
    );
    r = writeKvRow(
      sheet,
      r,
      t.workedHours,
      workedHours,
      t.approvedHours,
      approvedHours
    );
    r = writeKvRow(
      sheet,
      r,
      t.calculatedHours,
      hoursLabel(record.eligibleOvertimeMinutes, lang),
      t.workingHours,
      hoursLabel(record.workingDurationMinutes, lang)
    );
    r = writeKvRow(
      sheet,
      r,
      t.totalDuration,
      hoursLabel(record.totalDurationMinutes, lang),
      t.travelHours,
      hoursLabel(travelMinutes(record), lang)
    );
    r = writeKvRow(
      sheet,
      r,
      t.reviewNotes,
      record.reviewNotes || t.dash,
      t.rejectionReason,
      record.rejectionReason || t.dash
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

    r = writeSectionHeader(sheet, r, t.sectionJourneyTimeline, COLORS.navy);

    for (const stage of stageMeta) {
      const stageData = resolveStage(record, stage);
      r = writeSectionHeader(sheet, r, stage.title, stage.headerArgb);

      const map = mapsUrl(stageData.gps?.latitude, stageData.gps?.longitude);
      const voiceUrl = voiceHttpUrl(stageData.voiceNote);
      const voiceDur = formatVoiceDuration(stageData.voiceNote?.duration);
      const voiceDisplay = voiceUrl
        ? linkCell(
            `🎤 ${stage.voiceLabel}${voiceDur ? ` (${voiceDur})` : ''}`,
            voiceUrl
          )
        : t.dash;

      r = writeKvRow(
        sheet,
        r,
        t.timestamp,
        formatDateTime(stageData.at),
        t.gpsAccuracy,
        stageData.gps?.accuracy ?? t.dash
      );
      // Full address — never truncate; wrap + tall row.
      const addrRow = r;
      r = writeKvRow(sheet, r, t.fullAddress, stageData.address, '', '');
      sheet.mergeCells(addrRow, 2, addrRow, 4);
      sheet.getRow(addrRow).getCell(2).alignment = {
        wrapText: true,
        vertical: 'top',
      };
      sheet.getRow(addrRow).height = Math.max(
        36,
        estimateWrapHeight(stageData.address, 55)
      );

      r = writeKvRow(
        sheet,
        r,
        t.latitude,
        stageData.gps?.latitude ?? t.dash,
        t.longitude,
        stageData.gps?.longitude ?? t.dash
      );
      const mapsRow = r;
      r = writeKvRow(
        sheet,
        r,
        t.googleMaps,
        map ? linkCell(t.openMaps, map) : t.dash,
        t.batteryLevel,
        stageData.battery === null || stageData.battery === undefined
          ? t.dash
          : `${stageData.battery}%`
      );
      const mapsCell = sheet.getRow(mapsRow).getCell(2);
      if (map) {
        mapsCell.value = { text: t.openMaps, hyperlink: map };
        mapsCell.font = {
          color: { argb: COLORS.link },
          underline: true,
          bold: true,
        };
      }

      r = writeKvRow(
        sheet,
        r,
        t.networkType,
        stageData.network,
        t.deviceId,
        stageData.deviceId
      );
      r = writeKvRow(
        sheet,
        r,
        t.devicePlatform,
        t.dash,
        t.deviceModel,
        t.dash
      );
      r = writeKvRow(
        sheet,
        r,
        t.appVersion,
        appVersion || '—',
        t.stageNotes,
        stageData.notes
      );

      const voiceRow = r;
      r = writeKvRow(
        sheet,
        r,
        t.voiceRecording,
        voiceDisplay,
        t.photoCount,
        stageData.photos.length
      );
      const voiceCell = sheet.getRow(voiceRow).getCell(2);
      if (voiceUrl) {
        voiceCell.value = {
          text: `🎤 ${stage.voiceLabel}${voiceDur ? ` (${voiceDur})` : ''}`,
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
        stageData.photos.length > 0
          ? t.photosCount(stageData.photos.length)
          : t.photos;
      sheet.getRow(r).getCell(1).font = { bold: true };
      sheet.getRow(r).getCell(1).fill = solidFill(stage.bodyArgb);
      for (let c = 1; c <= 6; c += 1) {
        sheet.getRow(r).getCell(c).fill = solidFill(stage.bodyArgb);
        sheet.getRow(r).getCell(c).border = thinBorder();
      }
      r += 1;

      if (stageData.photos.length === 0) {
        sheet.getRow(r).getCell(1).value = t.dash;
        r += 1;
      } else {
        const perRow = 4;
        for (let p = 0; p < stageData.photos.length; p += perRow) {
          const batch = stageData.photos.slice(p, p + perRow);
          const labelRowNum = r;
          const imageRowNum = r + 1;
          batch.forEach((url, idx) => {
            const col = idx + 1;
            const labelCell = sheet.getRow(labelRowNum).getCell(col);
            labelCell.value = {
              text: t.photoN(p + idx + 1),
              hyperlink: url,
            };
            labelCell.font = {
              color: { argb: COLORS.link },
              underline: true,
              size: 9,
              bold: true,
            };
            labelCell.alignment = { horizontal: 'center' };
            labelCell.fill = solidFill(stage.bodyArgb);
            labelCell.border = thinBorder();

            const buf = imageCache.get(url);
            if (buf) {
              // Fire-and-forget sync add (buffer already loaded).
              // exceljs addImage is sync once buffer exists.
            }
            sheet.getRow(imageRowNum).getCell(col).fill = solidFill(
              stage.bodyArgb
            );
            sheet.getRow(imageRowNum).getCell(col).border = thinBorder();
          });
          sheet.getRow(labelRowNum).height = 18;
          sheet.getRow(imageRowNum).height = THUMB_HEIGHT + 12;

          batch.forEach((url, idx) => {
            const buf = imageCache.get(url);
            if (!buf) {
              sheet.getRow(imageRowNum).getCell(idx + 1).value = {
                text: t.openImage,
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
                tooltip: t.openPhoto(p + idx + 1),
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
      text: t.backToIndex,
      hyperlink: sessionHyperlink(t.sheetSessionsIndex),
    };
    sheet.getRow(r).getCell(1).font = {
      color: { argb: COLORS.link },
      underline: true,
      bold: true,
    };
  }

  // ——— Overflow bulk sheet (when > MAX_SESSION_SHEETS) ———
  if (overflow.length > 0) {
    const bulk = workbook.addWorksheet(t.sheetAdditionalSessions, {
      views: [{ state: 'frozen', ySplit: 1 }],
    });
    applyPrintSetup(bulk);
    applyWorksheetFooter(bulk, generatedAt, lang);
    const bulkHeaders = [
      t.sessionId,
      t.employeeName,
      t.email,
      t.employeeId,
      t.date,
      t.startTime,
      t.endTime,
      t.createdAt,
      t.status,
      t.type,
      t.overnight,
      t.workedHours,
      t.calculatedHours,
      t.approvedHours,
      t.workingHours,
      t.travelHours,
      t.reviewNotes,
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
        userEmail(record),
        record.userId?.employeeId || t.dash,
        formatDate(record.startAt || record.createdAt),
        formatDateTime(record.startAt),
        formatDateTime(record.endAt),
        formatDateTime(record.createdAt),
        statusLabel(record.status, lang),
        typeLabel(record.type, lang),
        overnightLabel(record, lang),
        formatDurationProseFromHours(workedHoursFromRecord(record), lang),
        hoursLabel(record.eligibleOvertimeMinutes, lang),
        String(record.status).toUpperCase() === 'APPROVED'
          ? formatDurationProseFromHours(resolveApprovedHours(record), lang)
          : t.dash,
        hoursLabel(record.workingDurationMinutes, lang),
        hoursLabel(travelMinutes(record), lang),
        record.reviewNotes || t.dash,
      ];
      styleStatusBadge(row.getCell(9), record.status);
      row.alignment = { vertical: 'middle', wrapText: true };
    });
  }

  const buffer = await workbook.xlsx.writeBuffer();
  return Buffer.from(buffer);
}

export {
  MAX_EXPORT_ROWS,
  MAX_SESSION_SHEETS,
  formatDurationProseFromMinutes,
  formatDurationProseFromHours,
  overnightLabel,
  excelSafeDurationText,
  stripBidiMarks,
};
