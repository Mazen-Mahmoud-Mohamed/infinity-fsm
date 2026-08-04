import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const arPath = path.join(__dirname, '../lib/core/localization/l10n/app_ar.arb');
const enPath = path.join(__dirname, '../lib/core/localization/l10n/app_en.arb');

let ar = fs.readFileSync(arPath, 'utf8');
let en = fs.readFileSync(enPath, 'utf8');

ar = ar.replaceAll('الوقت الإضافي', 'العمل الإضافي');
ar = ar.replaceAll('وقت إضافي', 'عمل إضافي');

const arReplacements = [
  ['"navDashboard": "الرئيسية"', '"navDashboard": "لوحة التحكم"'],
  ['"navAttendance": "الوقت"', '"navAttendance": "الحضور"'],
  ['"navWorkOrders": "المهام"', '"navWorkOrders": "أوامر العمل"'],
  ['"navOvertime": "إضافي"', '"navOvertime": "العمل الإضافي"'],
  ['"orgTitle": "الهيكل التنظيمي"', '"orgTitle": "المؤسسة"'],
  ['"workOrderJobTitle": "عنوان المهمة"', '"workOrderJobTitle": "عنوان أمر العمل"'],
  ['"dashboardKpiCompletedJobs": "المهام المكتملة"', '"dashboardKpiCompletedJobs": "أوامر العمل المكتملة"'],
  ['"settingsNotifTasks": "إشعارات المهام"', '"settingsNotifTasks": "إشعارات أوامر العمل"'],
  ['"approve": "موافقة"', '"approve": "اعتماد"'],
];

for (const [from, to] of arReplacements) {
  if (!ar.includes(from)) console.log('AR missing:', from);
  else ar = ar.replace(from, to);
}

const enReplacements = [
  ['"navDashboard": "Home"', '"navDashboard": "Dashboard"'],
  ['"navAttendance": "Time"', '"navAttendance": "Attendance"'],
  ['"navWorkOrders": "Tasks"', '"navWorkOrders": "Work Orders"'],
  ['"navOvertime": "OT"', '"navOvertime": "Overtime"'],
  ['"workOrderJobTitle": "Job title"', '"workOrderJobTitle": "Work order title"'],
  ['"dashboardKpiCompletedJobs": "Completed jobs"', '"dashboardKpiCompletedJobs": "Completed work orders"'],
  ['"settingsNotifTasks": "Task notifications"', '"settingsNotifTasks": "Work order notifications"'],
];

for (const [from, to] of enReplacements) {
  if (!en.includes(from)) console.log('EN missing:', from);
  else en = en.replace(from, to);
}

function ensureKey(text, key, value) {
  if (text.includes(`"${key}":`)) return text;
  return text.replace(`"retry":`, `"${key}": ${JSON.stringify(value)},\n  "retry":`);
}

for (const [key, enVal, arVal] of [
  ['cancel', 'Cancel', 'إلغاء'],
  ['save', 'Save', 'حفظ'],
  ['delete', 'Delete', 'حذف'],
  ['create', 'Create', 'إنشاء'],
  ['add', 'Add', 'إضافة'],
  ['back', 'Back', 'رجوع'],
  ['update', 'Update', 'تحديث'],
  ['reject', 'Reject', 'رفض'],
]) {
  en = ensureKey(en, key, enVal);
  ar = ensureKey(ar, key, arVal);
}

if (!en.includes('"dashboardLoadFailed"')) {
  en = en.replace(
    '"dashboardLoading":',
    '"dashboardLoadFailed": "Unable to load the dashboard.",\n  "dashboardLoading":',
  );
  ar = ar.replace(
    '"dashboardLoading":',
    '"dashboardLoadFailed": "تعذر تحميل لوحة التحكم.",\n  "dashboardLoading":',
  );
}

fs.writeFileSync(arPath, ar);
fs.writeFileSync(enPath, en);
console.log('ARB terminology + global actions updated');
