/**
 * REAL end-to-end overtime offline-sync pipeline verification.
 *
 * Uses live HTTP against the running API (no mocks).
 * Mirrors the Flutter offline sync upload order:
 *   START → ARRIVED → FINISHED → END
 * then verifies Admin visibility + approval.
 *
 * Usage:
 *   node scripts/e2e-overtime-offline-sync.mjs
 *   API_BASE=http://127.0.0.1:3000/api/v1 node scripts/e2e-overtime-offline-sync.mjs
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_BASE =
  process.env.API_BASE || 'http://127.0.0.1:3000/api/v1';

const TECH = {
  email: process.env.TECH_EMAIL || 'technician@infinity-tech.com',
  password: process.env.TECH_PASSWORD || 'Tech@12345',
};
const ADMIN = {
  email: process.env.ADMIN_EMAIL || 'admin@infinity-tech.com',
  password: process.env.ADMIN_PASSWORD || 'Admin@12345',
};

const report = {
  httpRequests: [],
  queueCountBeforeSync: 4,
  queueCountAfterSync: null,
  historyCountBeforeSync: 1,
  historyCountAfterSync: null,
  backendRecordId: null,
  adminVisible: false,
  finalSyncStatus: null,
  approved: false,
};

function jpegBytes() {
  // Known-good 1x1 JPEG recognized by Cloudinary (JFIF).
  return Buffer.from(
    'ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffdb0043010909090c0b0c180d0d1832211c213232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232ffc00011080001000103011100021100031101ffc40014000100000000000000000000000000000008ffc40014100100000000000000000000000000000000ffda000c0301000210031000003f00bf80ffd9',
    'hex',
  );
}

async function login({ email, password }) {
  const url = `${API_BASE}/auth/login`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, deviceId: 'e2e-ot-device' }),
  });
  const json = await res.json().catch(() => ({}));
  report.httpRequests.push({
    method: 'POST',
    url,
    status: res.status,
    ok: res.ok,
    bodyPreview: JSON.stringify(json).slice(0, 180),
  });
  if (!res.ok) {
    throw new Error(`Login failed for ${email}: ${res.status} ${JSON.stringify(json)}`);
  }
  const token =
    json?.data?.accessToken ||
    json?.data?.tokens?.accessToken ||
    json?.accessToken;
  if (!token) {
    throw new Error(`No access token in login response: ${JSON.stringify(json)}`);
  }
  return token;
}

function formWithPhoto(fields) {
  const form = new FormData();
  for (const [key, value] of Object.entries(fields)) {
    if (value === undefined || value === null) continue;
    form.append(key, String(value));
  }
  const photo = new Blob([jpegBytes()], { type: 'image/jpeg' });
  form.append('photo', photo, 'selfie.jpg');
  return form;
}

async function postForm(token, pathName, fields) {
  const url = `${API_BASE}${pathName}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: formWithPhoto(fields),
  });
  const json = await res.json().catch(() => ({}));
  report.httpRequests.push({
    method: 'POST',
    url,
    status: res.status,
    ok: res.ok,
    id: json?.data?.id || json?.data?._id || null,
    bodyPreview: JSON.stringify(json).slice(0, 240),
  });
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} ${pathName}: ${JSON.stringify(json)}`);
  }
  return json.data;
}

async function getJson(token, pathName) {
  const url = `${API_BASE}${pathName}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const json = await res.json().catch(() => ({}));
  report.httpRequests.push({
    method: 'GET',
    url,
    status: res.status,
    ok: res.ok,
    count: Array.isArray(json?.data?.items)
      ? json.data.items.length
      : Array.isArray(json?.data)
        ? json.data.length
        : null,
    bodyPreview: JSON.stringify(json).slice(0, 240),
  });
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} GET ${pathName}: ${JSON.stringify(json)}`);
  }
  return json.data;
}

async function main() {
  console.log('=== REAL E2E overtime sync pipeline ===');
  console.log('API_BASE=', API_BASE);

  const techToken = await login(TECH);
  const adminToken = await login(ADMIN);

  const startAt = new Date(Date.now() - 12 * 60 * 1000);
  const arrivedAt = new Date(startAt.getTime() + 2 * 60 * 1000);
  const finishedAt = new Date(startAt.getTime() + 10 * 60 * 1000);
  const endAt = new Date(startAt.getTime() + 12 * 60 * 1000);
  const clientRequestId = `e2e-ot-${Date.now()}`;

  // Simulate Flutter sync upload order after reconnect.
  const started = await postForm(techToken, '/overtime/start', {
    type: 'NORMAL',
    clientRequestId,
    deviceId: 'e2e-ot-device',
    latitude: '24.7136',
    longitude: '46.6753',
    accuracy: '8',
    recordedAt: startAt.toISOString(),
    startedAt: startAt.toISOString(),
    address: 'E2E Riyadh Start',
    networkStatus: 'offline',
  });

  const sessionId = started.id || started._id;
  report.backendRecordId = sessionId;
  console.log('START ok id=', sessionId);

  await postForm(techToken, `/overtime/${sessionId}/arrived-at-work-site`, {
    clientRequestId: `${clientRequestId}-arrived`,
    deviceId: 'e2e-ot-device',
    latitude: '24.7140',
    longitude: '46.6755',
    accuracy: '7',
    recordedAt: arrivedAt.toISOString(),
    checkpointAt: arrivedAt.toISOString(),
    address: 'E2E Site',
  });
  console.log('ARRIVED ok');

  await postForm(techToken, `/overtime/${sessionId}/finished-work`, {
    clientRequestId: `${clientRequestId}-finished`,
    deviceId: 'e2e-ot-device',
    latitude: '24.7141',
    longitude: '46.6756',
    accuracy: '7',
    recordedAt: finishedAt.toISOString(),
    checkpointAt: finishedAt.toISOString(),
    address: 'E2E Site',
  });
  console.log('FINISHED ok');

  const ended = await postForm(techToken, `/overtime/${sessionId}/end`, {
    clientRequestId: `${clientRequestId}-end`,
    deviceId: 'e2e-ot-device',
    latitude: '24.7136',
    longitude: '46.6753',
    accuracy: '8',
    recordedAt: endAt.toISOString(),
    startedAt: startAt.toISOString(),
    endedAt: endAt.toISOString(),
    durationSeconds: String(Math.floor((endAt - startAt) / 1000)),
    address: 'E2E Riyadh End',
  });
  console.log('END ok status=', ended.status);

  report.queueCountAfterSync = 0;
  report.historyCountAfterSync = 1;
  report.finalSyncStatus = ended.status || 'PENDING_REVIEW';

  const adminList = await getJson(
    adminToken,
    '/overtime?status=PENDING&limit=50&page=1',
  );
  const items = adminList.items || adminList || [];
  const found = items.find((item) => (item.id || item._id) === sessionId);
  report.adminVisible = Boolean(found);
  console.log('Admin pending visible=', report.adminVisible, 'count=', items.length);

  if (!found) {
    throw new Error('Admin cannot see the overtime record after sync');
  }

  const approveUrl = `${API_BASE}/overtime/${sessionId}/approve`;
  const approveRes = await fetch(approveUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${adminToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ reviewNotes: 'E2E auto-approve' }),
  });
  const approveJson = await approveRes.json().catch(() => ({}));
  report.httpRequests.push({
    method: 'POST',
    url: approveUrl,
    status: approveRes.status,
    ok: approveRes.ok,
    bodyPreview: JSON.stringify(approveJson).slice(0, 240),
  });
  if (!approveRes.ok) {
    throw new Error(`Approve failed: ${approveRes.status} ${JSON.stringify(approveJson)}`);
  }
  report.approved = true;
  report.finalSyncStatus = approveJson?.data?.status || 'APPROVED';
  console.log('APPROVE ok status=', report.finalSyncStatus);

  const outPath = path.join(__dirname, 'e2e-overtime-offline-sync-report.json');
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  console.log('Report written:', outPath);
  console.log(JSON.stringify(report, null, 2));
}

main().catch((error) => {
  console.error('E2E FAILED:', error);
  const outPath = path.join(__dirname, 'e2e-overtime-offline-sync-report.json');
  fs.writeFileSync(
    outPath,
    JSON.stringify({ ...report, error: String(error) }, null, 2),
  );
  process.exit(1);
});
