import JSZip from 'jszip';
import fs from 'fs';

const z = await JSZip.loadAsync(fs.readFileSync('tmp-inspect.xlsx'));
const styles = await z.file('xl/styles.xml').async('string');
const sheet = await z.file('xl/worksheets/sheet1.xml').async('string');
const block = styles.match(/<cellXfs[^>]*count="(\d+)"[^>]*>([\s\S]*?)<\/cellXfs>/);
console.log('count attr', block?.[1]);
const body = block?.[2] || '';
const xfs = [...body.matchAll(/<xf[\s\S]*?(?:\/>|<\/xf>)/g)].map((m) => m[0]);
console.log('xf len', xfs.length);
xfs.forEach((x, i) => console.log(i, x.replace(/\s+/g, ' ').slice(0, 240)));
console.log('C24', sheet.match(/<c r="C24"[^>]*>/)?.[0]);
console.log('D24', sheet.match(/<c r="D24"[^>]*>/)?.[0]);
console.log('A24', sheet.match(/<c r="A24"[^>]*>/)?.[0]);
