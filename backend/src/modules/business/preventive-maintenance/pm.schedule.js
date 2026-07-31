import {
  PM_FREQUENCIES,
} from './models/maintenancePlan.model.js';

export function addFrequency(date, frequency) {
  const next = new Date(date);
  switch (frequency) {
    case 'DAILY':
      next.setDate(next.getDate() + 1);
      break;
    case 'WEEKLY':
      next.setDate(next.getDate() + 7);
      break;
    case 'MONTHLY':
      next.setMonth(next.getMonth() + 1);
      break;
    case 'QUARTERLY':
      next.setMonth(next.getMonth() + 3);
      break;
    case 'SEMI_ANNUAL':
      next.setMonth(next.getMonth() + 6);
      break;
    case 'ANNUAL':
      next.setFullYear(next.getFullYear() + 1);
      break;
    default:
      next.setMonth(next.getMonth() + 1);
  }
  return next;
}

export function generateScheduleDates({
  startDate,
  frequency,
  count = 6,
}) {
  if (!startDate || !PM_FREQUENCIES.includes(frequency)) {
    return [];
  }

  const dates = [];
  let cursor = new Date(startDate);
  for (let i = 0; i < count; i += 1) {
    dates.push(new Date(cursor));
    cursor = addFrequency(cursor, frequency);
  }
  return dates;
}

export function startOfDay(date = new Date()) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}
