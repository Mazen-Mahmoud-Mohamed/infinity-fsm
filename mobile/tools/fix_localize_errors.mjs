import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '../lib');

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (entry.name.endsWith('.dart')) out.push(full);
  }
  return out;
}

const importLine =
  "import 'package:mobile/core/localization/localize_app_message.dart';";

const pattern =
  /Text\(\s*state\.message\s*\?\?\s*(l10n\.\w+)\s*\)/g;

let filesChanged = 0;
let replacements = 0;

for (const file of walk(root)) {
  let text = fs.readFileSync(file, 'utf8');
  if (!pattern.test(text)) continue;
  pattern.lastIndex = 0;

  const next = text.replace(pattern, (_, fallback) => {
    replacements += 1;
    return `Text(\n                          state.message != null\n                              ? localizeAppMessage(l10n, state.message)\n                              : ${fallback},\n                        )`;
  });

  if (next === text) continue;

  if (!next.includes(importLine) && next.includes('AppLocalizations')) {
    // Insert import after app_localizations import when present.
    if (next.includes("import 'package:mobile/core/localization/l10n/app_localizations.dart';")) {
      text = next.replace(
        "import 'package:mobile/core/localization/l10n/app_localizations.dart';",
        `import 'package:mobile/core/localization/l10n/app_localizations.dart';\n${importLine}`,
      );
    } else {
      text = `${importLine}\n${next}`;
    }
  } else {
    text = next;
  }

  fs.writeFileSync(file, text);
  filesChanged += 1;
  console.log('patched', path.relative(root, file));
}

console.log(`Done. files=${filesChanged} replacements=${replacements}`);
