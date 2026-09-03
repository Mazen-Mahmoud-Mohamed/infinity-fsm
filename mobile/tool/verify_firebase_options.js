const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const requireConfigured = process.argv.includes('--require-configured');
const s = fs.readFileSync(
  path.join(root, 'lib', 'core', 'push', 'firebase_options.dart'),
  'utf8'
);
const m = s.match(
  /static const FirebaseOptions android = FirebaseOptions\(([\s\S]*?)\);/
);
const block = m ? m[1] : '';
const androidHasReplace = block.includes('REPLACE_WITH');
const androidReady =
  Boolean(block) && !androidHasReplace && /apiKey: '/.test(block);

console.log('android_has_replace=' + androidHasReplace);
console.log(
  'ios_still_placeholder=' + s.includes("apiKey: 'REPLACE_WITH_IOS")
);
console.log(
  'configured_getter=' +
    /!android\.apiKey\.startsWith\('REPLACE_WITH'\)/.test(s)
);
console.log('android_ready=' + androidReady);

if (requireConfigured && !androidReady) {
  console.error('FIREBASE_OPTIONS_NOT_CONFIGURED');
  process.exit(1);
}
