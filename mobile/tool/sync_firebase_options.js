const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const jsonPath = path.join(root, 'android', 'app', 'google-services.json');
const outPath = path.join(root, 'lib', 'core', 'push', 'firebase_options.dart');

const j = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const client = (j.client || []).find(
  (c) =>
    c?.client_info?.android_client_info?.package_name === 'com.example.mobile'
);

if (!client) {
  console.error('NO_MATCHING_CLIENT');
  process.exit(1);
}

const apiKey = client.api_key?.[0]?.current_key;
const appId = client.client_info?.mobilesdk_app_id;
const projectId = j.project_info?.project_id;
const messagingSenderId = String(j.project_info?.project_number || '');
const storageBucket = j.project_info?.storage_bucket || '';

if (!apiKey || !appId || !projectId || !messagingSenderId) {
  console.error('MISSING_FIELDS');
  process.exit(1);
}

function q(value) {
  return String(value).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

const dart = `/// Firebase options for Infinity FSM.
///
/// Android values are generated from mobile/android/app/google-services.json.
/// Server FCM credentials must stay on the backend only
/// (FIREBASE_SERVICE_ACCOUNT_JSON / FIREBASE_SERVICE_ACCOUNT_PATH).
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options are not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        // Windows uses Socket.IO + local toasts; Firebase init is optional.
        return android;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${q(apiKey)}',
    appId: '${q(appId)}',
    messagingSenderId: '${q(messagingSenderId)}',
    projectId: '${q(projectId)}',
    storageBucket: '${q(storageBucket)}',
  );

  /// iOS placeholder (Android-focused). Keep projectId/sender aligned.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '${q(messagingSenderId)}',
    projectId: '${q(projectId)}',
    storageBucket: '${q(storageBucket)}',
    iosBundleId: 'com.example.mobile',
  );

  static bool get isConfigured =>
      !android.apiKey.startsWith('REPLACE_WITH');
}
`;

fs.writeFileSync(outPath, dart, 'utf8');
console.log('UPDATED_FIREBASE_OPTIONS');
console.log('package_ok=true');
console.log('isConfigured_will_be_true=true');
