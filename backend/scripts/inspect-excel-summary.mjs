import fs from 'fs';
import path from 'path';
import JSZip from 'jszip';
import ExcelJS from 'exceljs';
import {
  buildOvertimeExcelWorkbook,
  EXPORT_MODE,
  getEmployeeSummaryColumnDefs,
  stripBidiMarks,
} from '../src/modules/business/overtime/overtime.excel.export.js';
import { excelStrings } from '../src/modules/business/overtime/overtime.excel.i18n.js';

function makeUser(id, first, last, email) {
  return {
    _id: { toString: () => id },
    firstName: first,
    lastName: last,
    email,
    employeeId: id,
  };
}

function makeRecord(o) {
  return {
    _id: { toString: () => o.id },
    type: o.type || 'NORMAL',
    status: o.status || 'APPROVED',
    isOvernight: !!o.isOvernight,
    startAt: new Date('2026-03-01T08:00:00.000Z'),
    endAt: new Date('2026-03-01T22:00:00.000Z'),
    createdAt: new Date('2026-03-01T07:55:00.000Z'),
    eligibleOvertimeMinutes: o.eligible ?? 60,
    workingDurationMinutes: o.working ?? 60,
    totalDurationMinutes: o.total ?? 60,
    approvedHours: o.approvedHours ?? null,
    userId: o.user,
  };
}

const u1 = makeUser('u1', 'Field', 'Technician', 'test@gmail.com');
const u2 = makeUser('u2', 'test2', 'test', 'test2@gmail.com');
const records = [];

// Field Technician: 6 sessions, worked 1422m (23h42), approved 1124m (18h44)
// 5 normal + 1 travel overnight; 3 approved + 3 pending
const fieldEligible = [250, 250, 250, 250, 250, 172];
for (let i = 0; i < 6; i += 1) {
  records.push(
    makeRecord({
      id: `f${i}`,
      user: u1,
      type: i === 5 ? 'TRAVEL' : 'NORMAL',
      isOvernight: i === 5,
      status: i < 3 ? 'APPROVED' : 'PENDING_REVIEW',
      eligible: fieldEligible[i],
      approvedHours: i < 3 ? null : null,
    })
  );
}
records[0].approvedHours = 6;
records[1].approvedHours = 6;
records[2].approvedHours = (1124 - 720) / 60;

// test2: 4 travel, 1 overnight, 1 approved, 3 pending; worked 1188 (19h48), approved 858 (14h18)
records.push(
  makeRecord({
    id: 't0',
    user: u2,
    type: 'TRAVEL',
    isOvernight: true,
    status: 'APPROVED',
    eligible: 300,
    approvedHours: 14.3,
  })
);
records.push(
  makeRecord({
    id: 't1',
    user: u2,
    type: 'TRAVEL',
    status: 'PENDING_REVIEW',
    eligible: 300,
  })
);
records.push(
  makeRecord({
    id: 't2',
    user: u2,
    type: 'TRAVEL',
    status: 'PENDING_REVIEW',
    eligible: 300,
  })
);
records.push(
  makeRecord({
    id: 't3',
    user: u2,
    type: 'TRAVEL',
    status: 'PENDING_REVIEW',
    eligible: 288,
  })
);

const buf = await buildOvertimeExcelWorkbook({
  records,
  language: 'ar',
  mode: EXPORT_MODE.SUMMARY,
  generatedBy: 'tester',
  companyName: 'Infinity',
  filters: { dateRange: 'ALL' },
});

const out = path.resolve('tmp-inspect.xlsx');
fs.writeFileSync(out, buf);

const wb = new ExcelJS.Workbook();
await wb.xlsx.load(buf);
const t = excelStrings('ar');
const ws = wb.getWorksheet(t.sheetSummary);
let headerRow = 0;
ws.eachRow((row, n) => {
  if (String(row.getCell(1).value) === t.empName) headerRow = n;
});

const cols = getEmployeeSummaryColumnDefs('ar');
console.log('headerRow', headerRow);
console.log('sheetRightToLeft', Boolean(ws.views?.[0]?.rightToLeft));
console.log(
  'COL ORDER',
  cols.map((c) => `${c.key}:${c.header}`).join(' | ')
);
console.log(
  'widths',
  cols.map((c) => `${c.key}:${c.width}`).join(' | ')
);

for (let r = headerRow; r <= headerRow + 2; r += 1) {
  const line = [];
  for (let c = 1; c <= 11; c += 1) {
    const cell = ws.getRow(r).getCell(c);
    const v = cell.value;
    line.push(
      `${cell.address}=${JSON.stringify(
        typeof v === 'string' ? stripBidiMarks(v) : v
      )}(ro=${cell.alignment?.readingOrder ?? '-'})`
    );
  }
  console.log(`ROW ${r}:`, line.join(' | '));
}

const zip = await JSZip.loadAsync(buf);
const sheetXml = await zip.file('xl/worksheets/sheet1.xml').async('string');
const stylesXml = await zip.file('xl/styles.xml').async('string');
const sharedXml = await zip.file('xl/sharedStrings.xml').async('string');

console.log('rightToLeft=1 in sheet?', sheetXml.includes('rightToLeft="1"'));
console.log('readingOrder=1 in styles?', stylesXml.includes('readingOrder="1"'));
console.log(
  'shared has LRO?',
  sharedXml.includes('\u202D') || sharedXml.includes('&#x202D;')
);
console.log(
  'shared has LRM?',
  sharedXml.includes('\u200E') || sharedXml.includes('&#x200E;')
);
console.log(
  'shared plain 23h42?',
  sharedXml.includes('23 ساعة و 42 دقيقة')
);
console.log(
  'F/G headers normal then travel?',
  cols[5]?.key === 'normalSessions' && cols[6]?.key === 'travelSessions'
);
console.log(
  'F24/G24 values',
  ws.getRow(headerRow + 1).getCell(6).value,
  ws.getRow(headerRow + 1).getCell(7).value
);

const rowRe = new RegExp(`<row r="${headerRow + 1}"[\\s\\S]*?</row>`);
const rowXml = sheetXml.match(rowRe)?.[0] || '';
console.log('first data row xml:', rowXml.slice(0, 1200));

const aCell = rowXml.match(/<c r="A\d+"[^>]*>[\s\S]*?<\/c>/)?.[0];
const bCell = rowXml.match(/<c r="B\d+"[^>]*>[\s\S]*?<\/c>/)?.[0];
console.log('A cell:', aCell);
console.log('B cell:', bCell);
console.log('Wrote', out);
