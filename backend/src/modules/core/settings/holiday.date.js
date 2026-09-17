/**
 * Gregorian YYYY-MM-DD helpers for holiday calendar keys (Africa/Cairo days).
 * No time component — validate calendar existence via UTC date parts.
 */

const YMD_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

/**
 * @param {unknown} value
 * @returns {boolean}
 */
export function isValidYmdDate(value) {
  if (typeof value !== 'string') return false;
  const trimmed = value.trim();
  const match = YMD_RE.exec(trimmed);
  if (!match) return false;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;
  const dt = new Date(Date.UTC(year, month - 1, day));
  return (
    dt.getUTCFullYear() === year &&
    dt.getUTCMonth() === month - 1 &&
    dt.getUTCDate() === day
  );
}

/**
 * @param {unknown} value
 * @returns {string|null} normalized YYYY-MM-DD or null
 */
export function normalizeYmdDate(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!isValidYmdDate(trimmed)) return null;
  return trimmed;
}

/**
 * @param {unknown[]} values
 * @returns {{ dates: string[], invalid: string[] }}
 */
export function normalizeYmdDateList(values) {
  const dates = [];
  const invalid = [];
  const seen = new Set();
  for (const raw of values || []) {
    const normalized = normalizeYmdDate(raw);
    if (!normalized) {
      invalid.push(String(raw ?? ''));
      continue;
    }
    if (seen.has(normalized)) continue;
    seen.add(normalized);
    dates.push(normalized);
  }
  dates.sort();
  return { dates, invalid };
}

/**
 * @param {string} a
 * @param {string} b
 * @returns {number}
 */
export function compareYmdStrings(a, b) {
  return String(a).localeCompare(String(b));
}
