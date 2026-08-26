const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const s = fs.readFileSync(
  path.join(root, 'lib', 'core', 'push', 'firebase_options.dart'),
  'utf8'
);
const m = s.match(
  /static const FirebaseOptions android = FirebaseOptions\(([\s\S]*?)\);/
);
const block = m ? m[1] : '';
console.log('android_has_replace=' + block.includes('REPLACE_WITH'));
console.log(
  'ios_still_placeholder=' + s.includes("apiKey: 'REPLACE_WITH_IOS")
);
console.log(
  'configured_getter=' +
    /!android\.apiKey\.startsWith\('REPLACE_WITH'\)/.test(s)
);
console.log(
  'android_ready=' +
    (Boolean(block) &&
      !block.includes('REPLACE_WITH') &&
      /apiKey: '/.test(block))
);
