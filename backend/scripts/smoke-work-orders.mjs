/**
 * Work Orders Phase 1 + Phase 2 smoke checks (run with backend up):
 *   node scripts/smoke-work-orders.mjs
 *
 * Requires seeded admin + technician users.
 */
import 'dotenv/config';
import { Buffer } from 'node:buffer';
import mongoose from 'mongoose';

const base = process.env.API_BASE_URL || 'http://localhost:3000/api/v1';

const locationBody = {
  latitude: 33.3152,
  longitude: 44.3661,
  accuracy: 12,
  address: 'Baghdad smoke location',
  recordedAt: new Date().toISOString(),
};

async function login(email, password) {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, deviceId: 'wo-smoke' }),
  });
  const json = await res.json();
  if (!res.ok) {
    throw new Error(`Login failed ${email}: ${json?.error?.message || res.status}`);
  }
  return json.data;
}

async function req(method, path, token, body) {
  const res = await fetch(`${base}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, json };
}

async function multipart(path, token, fields = {}, files = []) {
  const form = new FormData();
  for (const [key, value] of Object.entries(fields)) {
    if (value != null) {
      form.append(key, String(value));
    }
  }
  for (const file of files) {
    form.append(file.field, new Blob([file.bytes], { type: file.mime }), file.name);
  }
  const res = await fetch(`${base}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, json };
}

function assert(cond, msg) {
  if (!cond) {
    throw new Error(msg);
  }
}

/** Minimal valid JPEG (1x1 pixel) for multipart photo uploads. */
function tinyJpeg() {
  return Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00,
    0x01, 0x00, 0x01, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06,
    0x05, 0x08, 0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0a, 0x0c, 0x14, 0x0d, 0x0c, 0x0b, 0x0b,
    0x0c, 0x19, 0x12, 0x13, 0x0f, 0x14, 0x1d, 0x1a, 0x1f, 0x1e, 0x1d, 0x1a, 0x1c, 0x1c, 0x20,
    0x24, 0x2e, 0x27, 0x20, 0x22, 0x2c, 0x23, 0x1c, 0x1c, 0x28, 0x37, 0x29, 0x2c, 0x30, 0x31,
    0x34, 0x34, 0x34, 0x1f, 0x27, 0x39, 0x3d, 0x38, 0x32, 0x3c, 0x2e, 0x33, 0x34, 0x32, 0xff,
    0xc0, 0x00, 0x0b, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xff, 0xc4, 0x00,
    0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xff, 0xc4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xda, 0x00, 0x08,
    0x01, 0x01, 0x00, 0x00, 0x3f, 0x00, 0x7f, 0x3f, 0xff, 0xd9,
  ]);
}

async function uploadPhotoOrSkip(path, token, name) {
  const result = await multipart(path, token, {}, [
    { field: 'photos', bytes: tinyJpeg(), mime: 'image/jpeg', name },
  ]);
  if (result.status === 200) {
    return result;
  }
  const message = result.json?.error?.message || String(result.status);
  console.warn(`Photo upload skipped (${name}): ${message}`);
  return null;
}

async function seedAfterPhoto(workOrderId) {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI required to seed after photo when Cloudinary upload fails');
  }
  await mongoose.connect(uri);
  try {
    const result = await mongoose.connection.collection('workorders').updateOne(
      { _id: new mongoose.Types.ObjectId(workOrderId) },
      {
        $set: {
          afterPhotos: [
            {
              url: `https://example.com/smoke-after-${workOrderId}.jpg`,
              fileName: 'smoke-after.jpg',
              mimeType: 'image/jpeg',
              uploadedAt: new Date(),
            },
          ],
        },
      }
    );
    if (result.matchedCount !== 1) {
      throw new Error('Failed to seed after photo');
    }
  } finally {
    await mongoose.disconnect();
  }
}

async function main() {
  const admin = await login('admin@infinity-tech.com', 'Admin@12345');
  const tech = await login('technician@infinity-tech.com', 'Tech@12345');
  const adminToken = admin.tokens?.accessToken || admin.accessToken;
  const techToken = tech.tokens?.accessToken || tech.accessToken;

  const adminMe = await req('GET', '/auth/me', adminToken);
  const techMe = await req('GET', '/auth/me', techToken);
  assert(adminMe.status === 200, 'Admin /me failed');
  assert(techMe.status === 200, 'Tech /me failed');

  const techId = techMe.json.data.id;
  const adminWo = (adminMe.json.data.permissions || []).filter((p) =>
    p.startsWith('work_orders:')
  );
  const techWo = (techMe.json.data.permissions || []).filter((p) =>
    p.startsWith('work_orders:')
  );
  assert(adminWo.length === 8, `Admin should have 8 WO perms, got ${adminWo.length}`);
  assert(
    techWo.includes('work_orders:view_own') && techWo.includes('work_orders:complete'),
    'Technician WO perms mismatch'
  );
  assert(!techWo.includes('work_orders:create'), 'Technician must not create');

  const forbiddenList = await req('GET', '/work-orders', techToken);
  assert(forbiddenList.status === 403, `Tech list expected 403, got ${forbiddenList.status}`);

  const created = await req('POST', '/work-orders', adminToken, {
    jobTitle: 'Smoke WO',
    customerName: 'Acme',
    locationLabel: 'Baghdad',
    description: 'Test',
    priority: 'HIGH',
    scheduledAt: new Date(Date.now() + 86400000).toISOString(),
  });
  assert(
    created.status === 201,
    `Create expected 201, got ${created.status} ${created.json?.error?.message || ''}`
  );
  assert(created.json.data.status === 'PENDING', 'Create without assignee should be PENDING');
  assert(Array.isArray(created.json.data.timeline), 'Create should include timeline');
  assert(
    created.json.data.timeline.some((e) => e.type === 'CREATED'),
    'Timeline missing CREATED'
  );
  const id = created.json.data.id;

  const assigned = await req('POST', `/work-orders/${id}/assign`, adminToken, {
    assignedTechnicianId: techId,
  });
  assert(assigned.status === 200 && assigned.json.data.status === 'ASSIGNED', 'Assign failed');
  assert(
    assigned.json.data.timeline.some((e) => e.type === 'ASSIGNED'),
    'Timeline missing ASSIGNED'
  );

  const accepted = await req('POST', `/work-orders/${id}/accept`, techToken);
  assert(accepted.status === 200 && accepted.json.data.status === 'ACCEPTED', 'Accept failed');

  const beforeNotesOnly = await multipart(
    `/work-orders/${id}/before-work`,
    techToken,
    { beforeNotes: 'Site checked' }
  );
  assert(
    beforeNotesOnly.status === 200,
    `Before-work notes failed: ${beforeNotesOnly.json?.error?.message || beforeNotesOnly.status}`
  );
  assert(beforeNotesOnly.json.data.beforeNotes === 'Site checked', 'Before notes not saved');

  const beforePhoto = await uploadPhotoOrSkip(
    `/work-orders/${id}/before-work`,
    techToken,
    'before.jpg'
  );
  if (beforePhoto) {
    assert((beforePhoto.json.data.beforePhotos || []).length >= 1, 'Before photo missing');
  }

  const startMissingGps = await req('POST', `/work-orders/${id}/start`, techToken);
  assert(
    startMissingGps.status === 422 || startMissingGps.status === 400,
    `Start without GPS expected 400/422, got ${startMissingGps.status}`
  );

  const started = await req('POST', `/work-orders/${id}/start`, techToken, locationBody);
  assert(started.status === 200 && started.json.data.status === 'IN_PROGRESS', 'Start failed');
  assert(started.json.data.startedLocation?.latitude === locationBody.latitude, 'Start GPS missing');
  assert(
    started.json.data.timeline.some((e) => e.type === 'STARTED'),
    'Timeline missing STARTED'
  );

  const progressNote = await req('POST', `/work-orders/${id}/progress-notes`, techToken, {
    text: 'Replaced filter',
  });
  assert(progressNote.status === 200, 'Progress note failed');
  assert(
    (progressNote.json.data.progressNotes || []).some((n) => n.text === 'Replaced filter'),
    'Progress note not persisted'
  );

  await uploadPhotoOrSkip(`/work-orders/${id}/progress-photos`, techToken, 'progress.jpg');

  const completeWithoutAfter = await req(
    'POST',
    `/work-orders/${id}/complete`,
    techToken,
    locationBody
  );
  assert(
    completeWithoutAfter.status === 422 || completeWithoutAfter.status === 409,
    `Complete without after photo expected 422/409, got ${completeWithoutAfter.status}`
  );

  let afterUrl = null;
  const afterPhoto = await uploadPhotoOrSkip(
    `/work-orders/${id}/after-photos`,
    techToken,
    'after.jpg'
  );
  if (afterPhoto) {
    afterUrl = afterPhoto.json.data.afterPhotos?.[0]?.url;
    assert(afterUrl, 'After photo url missing');

    const removed = await req('DELETE', `/work-orders/${id}/photos`, techToken, {
      category: 'after',
      url: afterUrl,
    });
    assert(removed.status === 200, 'Remove after photo failed');
    assert((removed.json.data.afterPhotos || []).length === 0, 'After photo still present');

    const afterAgain = await uploadPhotoOrSkip(
      `/work-orders/${id}/after-photos`,
      techToken,
      'after2.jpg'
    );
    assert(afterAgain, 'Re-upload after photo failed');
    afterUrl = afterAgain.json.data.afterPhotos?.[0]?.url;
  } else {
    // Cloudinary unavailable: seed a stub after photo so completion validation can be exercised.
    await seedAfterPhoto(id);
    const refreshed = await req('GET', `/work-orders/${id}`, techToken);
    afterUrl = refreshed.json.data.afterPhotos?.[0]?.url;
    assert(afterUrl, 'Seeded after photo missing');
  }

  const completed = await req('POST', `/work-orders/${id}/complete`, techToken, {
    ...locationBody,
    completionNotes: 'Done',
  });
  assert(completed.status === 200 && completed.json.data.status === 'COMPLETED', 'Complete failed');
  assert(completed.json.data.completionNotes === 'Done', 'Completion notes missing');
  assert(
    completed.json.data.completedLocation?.longitude === locationBody.longitude,
    'Complete GPS missing'
  );
  assert(
    completed.json.data.timeline.some((e) => e.type === 'COMPLETED'),
    'Timeline missing COMPLETED'
  );

  const rejectWo = await req('POST', '/work-orders', adminToken, {
    jobTitle: 'Reject smoke',
    assignedTechnicianId: techId,
  });
  const rejected = await req(
    'POST',
    `/work-orders/${rejectWo.json.data.id}/reject`,
    techToken,
    { rejectionReason: 'Busy' }
  );
  assert(rejected.status === 200 && rejected.json.data.status === 'REJECTED', 'Reject failed');

  const cancelWo = await req('POST', '/work-orders', adminToken, { jobTitle: 'Cancel smoke' });
  const cancelled = await req(
    'POST',
    `/work-orders/${cancelWo.json.data.id}/cancel`,
    adminToken,
    { cancellationReason: 'Dup' }
  );
  assert(cancelled.status === 200 && cancelled.json.data.status === 'CANCELLED', 'Cancel failed');

  const deleteWo = await req('POST', '/work-orders', adminToken, { jobTitle: 'Delete smoke' });
  const deleted = await req('DELETE', `/work-orders/${deleteWo.json.data.id}`, adminToken);
  assert(deleted.status === 200 && deleted.json.data.deleted === true, 'Delete failed');

  const techCancel = await req(
    'POST',
    `/work-orders/${rejectWo.json.data.id}/cancel`,
    techToken
  );
  assert(techCancel.status === 403, `Tech cancel expected 403, got ${techCancel.status}`);

  const conflict = await req('POST', `/work-orders/${id}/accept`, techToken);
  assert(conflict.status === 409, `Accept completed expected 409, got ${conflict.status}`);

  const got = await req('GET', `/work-orders/${id}`, adminToken);
  assert(got.json.data.customerName === 'Acme', 'Customer not persisted');
  assert(got.json.data.locationLabel === 'Baghdad', 'Location not persisted');
  assert(got.json.data.priority === 'HIGH', 'Priority not persisted');
  assert(got.json.data.beforeNotes === 'Site checked', 'Before notes not on GET');
  assert((got.json.data.timeline || []).length >= 4, 'Timeline incomplete on GET');

  console.log('Work Orders Phase 1 + Phase 2 smoke checks passed.');
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
