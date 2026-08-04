import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const files = [
  'features/dashboard/presentation/pages/dashboard_page.dart',
  'features/inventory/presentation/pages/inventory_dashboard_page.dart',
  'features/work_orders/presentation/pages/work_orders_page.dart',
  'features/assets/presentation/pages/assets_page.dart',
  'features/pm/presentation/pages/pm_dashboard_page.dart',
  'features/service_reports/presentation/pages/service_reports_dashboard_page.dart',
  'features/overtime/presentation/pages/overtime_page.dart',
];

const root = path.join(__dirname, '../lib');
const importLine =
  "import 'package:mobile/core/localization/localize_app_message.dart';";

for (const rel of files) {
  const file = path.join(root, rel);
  let text = fs.readFileSync(file, 'utf8');
  const before = text;

  // Pattern: state.message ?? l10n.xxx  (not already wrapped)
  text = text.replace(
    /(?<!localizeAppMessage\(l10n, )state\.message \?\? (l10n\.\w+)/g,
    (match, fallback) =>
      `state.message != null\n                          ? localizeAppMessage(l10n, state.message)\n                          : ${fallback}`,
  );

  // overtime special: state.message ?? 'overtimeLoadFailed'
  text = text.replace(
    /state\.message \?\? 'overtimeLoadFailed'/g,
    `state.message != null\n                ? localizeAppMessage(l10n, state.message)\n                : l10n.overtimeLoadFailed`,
  );

  if (text === before) {
    console.log('no change', rel);
    continue;
  }

  if (!text.includes('localize_app_message.dart')) {
    if (text.includes("import 'package:mobile/core/localization/l10n/app_localizations.dart';")) {
      text = text.replace(
        "import 'package:mobile/core/localization/l10n/app_localizations.dart';",
        `import 'package:mobile/core/localization/l10n/app_localizations.dart';\n${importLine}`,
      );
    } else {
      text = `${importLine}\n${text}`;
    }
  }

  fs.writeFileSync(file, text);
  console.log('patched', rel);
}
