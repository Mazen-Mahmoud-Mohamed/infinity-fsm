/**
 * Generate duration-strategy probe workbooks and print OOXML + optional COM notes.
 */
import ExcelJS from 'exceljs';
import JSZip from 'jszip';
import fs from 'fs';

const text = '23 ساعة و 42 دقيقة';

async function build(name, { sheetRtl, cellAlign }) {
  const wb = new ExcelJS.Workbook();
  const ws = wb.addWorksheet('الملخص', {
    views: [{ rightToLeft: sheetRtl, activeCell: 'A1' }],
  });
  ws.getCell('A1').value = 'اسم الموظف';
  ws.getCell('B1').value = 'بريد الموظف';
  ws.getCell('C1').value = 'إجمالي الساعات المحسوبة / الفعلية';
  ws.getCell('F1').value = 'الجلسات العادية';
  ws.getCell('G1').value = 'جلسات السفر';
  ws.getCell('A2').value = 'Field Technician';
  ws.getCell('B2').value = 'test@gmail.com';
  ws.getCell('C2').value = text;
  if (cellAlign) ws.getCell('C2').alignment = cellAlign;
  ws.getCell('F2').value = 5;
  ws.getCell('G2').value = 1;

  const buf = Buffer.from(await wb.xlsx.writeBuffer());
  const file = `tmp-strategy-${name}.xlsx`;
  fs.writeFileSync(file, buf);

  const zip = await JSZip.loadAsync(buf);
  const styles = await zip.file('xl/styles.xml').async('string');
  const sheet = await zip.file('xl/worksheets/sheet1.xml').async('string');
  const aligns = [...styles.matchAll(/<alignment[^/]*\/>/g)].map((m) => m[0]);
  console.log(`\n=== ${name} ===`);
  console.log('file', file);
  console.log('sheetRtl xml', sheet.includes('rightToLeft="1"'));
  console.log('alignments', aligns);
  console.log('C2 style', sheet.match(/<c r="C2"[^>]*>/)?.[0]);
  return file;
}

await build('rtl-ro-ltr', {
  sheetRtl: true,
  cellAlign: { horizontal: 'left', wrapText: true, readingOrder: 'ltr' },
});
await build('rtl-no-ro', {
  sheetRtl: true,
  cellAlign: { horizontal: 'left', wrapText: true },
});
await build('rtl-ro-rtl', {
  sheetRtl: true,
  cellAlign: { horizontal: 'right', wrapText: true, readingOrder: 'rtl' },
});
await build('ltr-no-ro', {
  sheetRtl: false,
  cellAlign: { horizontal: 'left', wrapText: true },
});
await build('ltr-ro-ltr', {
  sheetRtl: false,
  cellAlign: { horizontal: 'left', wrapText: true, readingOrder: 'ltr' },
});

console.log('\nDone. Run excel-com-compare-strategies.ps1 next.');
