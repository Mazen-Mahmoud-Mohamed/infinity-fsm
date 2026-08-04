/**
 * Additive: insert August overtime records so the current-month dashboard
 * has meaningful KPIs. Uses ONLY current MONGODB_URI / infinity_fsm.
 * Does NOT delete or modify other databases.
 */
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import config from '../src/config/index.js';
import Company from '../src/modules/core/organization/models/company.model.js';
import Branch from '../src/modules/core/organization/models/branch.model.js';
import Department from '../src/modules/core/organization/models/department.model.js';
import User from '../src/modules/core/organization/models/user.model.js';
import OvertimeRecord from '../src/modules/business/overtime/models/overtimeRecord.model.js';
import {
  calculateOvertimeDurations,
  zonedLocalToUtc,
} from '../src/modules/business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../src/modules/business/overtime/working-hours.policy.js';
import { ROLES } from '../src/shared/constants/roles.constants.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const REQUIRED_DB_NAME = 'infinity_fsm';
const TZ = OFFICIAL_WORKING_HOURS.timeZone;

const LOCATIONS = [
  { name: 'New Cairo', address: '90th Street, New Cairo, Cairo', lat: 30.0074, lng: 31.4913 },
  { name: 'Nasr City', address: 'Abbas El-Akkad, Nasr City, Cairo', lat: 30.05, lng: 31.34 },
  { name: 'Heliopolis', address: 'Korba, Heliopolis, Cairo', lat: 30.091, lng: 31.324 },
  { name: 'Maadi', address: 'Road 9, Maadi, Cairo', lat: 29.9602, lng: 31.2569 },
  { name: 'Downtown', address: 'Tahrir Square Area, Downtown Cairo', lat: 30.0444, lng: 31.2357 },
  { name: 'Rehab', address: 'First Settlement, El Rehab City', lat: 30.062, lng: 31.492 },
];

function maskUri(uri) {
  return String(uri || '').replace(/(mongodb(\+srv)?:\/\/[^:]+:)[^@]+@/, '$1***@');
}

function cairo(year, month, day, hour, minute, second = 0) {
  return zonedLocalToUtc(TZ, year, month, day, hour, minute, second);
}

function addMinutes(date, minutes) {
  return new Date(date.getTime() + minutes * 60_000);
}

function photoRef(seed) {
  return {
    url: `https://picsum.photos/seed/${encodeURIComponent(seed)}/480/480.jpg`,
    publicId: `seed/overtime/${seed}`,
  };
}

function gpsAt(location, at, accuracy = 8) {
  const jitterLat = ((at.getTime() % 17) - 8) * 0.00001;
  const jitterLng = ((at.getTime() % 13) - 6) * 0.00001;
  return {
    latitude: Number((location.lat + jitterLat).toFixed(6)),
    longitude: Number((location.lng + jitterLng).toFixed(6)),
    accuracy,
    heading: null,
    speed: null,
    altitude: null,
    provider: 'gps',
    recordedAt: at,
    fullAddress: location.address,
    street: location.address.split(',')[0],
    area: location.name,
    city: 'Cairo',
    country: 'Egypt',
    addressResolvedAt: at,
  };
}

function checkpoint({ at, location, deviceId, clientRequestId, seed, notes = null }) {
  return {
    at,
    gps: gpsAt(location, at),
    photo: photoRef(seed),
    address: location.address,
    deviceId,
    clientRequestId,
    batteryLevel: 60 + (seed.length % 30),
    networkStatus: 'wifi',
    notes,
  };
}

function assertTarget() {
  const uri = process.env.MONGODB_URI || config.mongodb.uri;
  if (!uri) throw new Error('MONGODB_URI missing');
  if (/localhost|127\.0\.0\.1/i.test(uri)) {
    throw new Error('Refusing localhost MongoDB');
  }
  console.log('URI', maskUri(uri));
  return uri;
}

async function main() {
  const uri = assertTarget();
  await mongoose.connect(uri);
  if (mongoose.connection.name !== REQUIRED_DB_NAME) {
    throw new Error(`Wrong DB: ${mongoose.connection.name}`);
  }

  const company = await Company.findOne();
  const branch = await Branch.findOne();
  const department = await Department.findOne();
  const admin = await User.findOne({ email: 'mazen@gmail.com' });
  const technician = await User.findOne({
    email: 'test@gmail.com',
    roles: ROLES.TECHNICIAN,
  });

  if (!company || !branch || !department || !admin || !technician) {
    throw new Error('Required system entities missing — run init-new-database.mjs first');
  }

  const existingAug = await OvertimeRecord.countDocuments({
    startAt: {
      $gte: cairo(2026, 8, 1, 0, 0),
      $lt: cairo(2026, 9, 1, 0, 0),
    },
  });
  if (existingAug >= 8) {
    console.log(`August records already present (${existingAug}). Skipping.`);
    await mongoose.disconnect();
    return;
  }

  const scenarios = [
    { type: 'NORMAL', start: cairo(2026, 8, 1, 5, 30), end: cairo(2026, 8, 1, 8, 30), status: 'APPROVED' },
    { type: 'NORMAL', start: cairo(2026, 8, 1, 18, 0), end: cairo(2026, 8, 1, 22, 0), status: 'PENDING_REVIEW' },
    { type: 'TRAVEL', start: cairo(2026, 8, 2, 7, 0), end: cairo(2026, 8, 2, 12, 0), status: 'APPROVED', route: true },
    { type: 'TRAVEL', start: cairo(2026, 8, 2, 17, 0), end: cairo(2026, 8, 2, 21, 30), status: 'PENDING_REVIEW', route: true },
    { type: 'NORMAL', start: cairo(2026, 8, 3, 22, 0), end: cairo(2026, 8, 4, 2, 30), status: 'APPROVED' },
    {
      type: 'NORMAL',
      start: cairo(2026, 8, 3, 18, 30),
      end: cairo(2026, 8, 3, 23, 0),
      status: 'REJECTED',
      rejectionReason: 'Overlapping with another approved overtime window.',
    },
    { type: 'TRAVEL', start: cairo(2026, 8, 3, 6, 45), end: cairo(2026, 8, 3, 11, 15), status: 'APPROVED', route: true },
    { type: 'TRAVEL', start: cairo(2026, 8, 4, 7, 15), end: cairo(2026, 8, 4, 10, 45), status: 'PENDING_REVIEW', route: true },
    // Friday Aug 1? Aug 1 2026 is Saturday. Friday Aug 7 is future. Use Friday Jul 31 already exists.
    // Saturday full day stretch for current week visibility:
    { type: 'NORMAL', start: cairo(2026, 8, 2, 9, 0), end: cairo(2026, 8, 2, 14, 0), status: 'APPROVED' },
    { type: 'TRAVEL', start: cairo(2026, 8, 4, 17, 0), end: cairo(2026, 8, 4, 20, 30), status: 'APPROVED', route: true },
  ];

  const deviceId = 'android-tech-seed-aug';
  const docs = [];

  for (let i = 0; i < scenarios.length; i += 1) {
    const s = scenarios[i];
    const startLoc = LOCATIONS[i % LOCATIONS.length];
    const siteLoc = LOCATIONS[(i + 2) % LOCATIONS.length];
    const endLoc = s.route ? LOCATIONS[(i + 1) % LOCATIONS.length] : startLoc;
    const startAt = s.start;
    const endAt = s.end;
    const spanMs = endAt.getTime() - startAt.getTime();
    const arrivedAt = new Date(startAt.getTime() + Math.floor(spanMs * 0.22));
    const finishedAt = new Date(startAt.getTime() + Math.floor(spanMs * 0.78));
    const calculated = calculateOvertimeDurations(startAt, endAt);
    const clientRequestId = `seed-ot-aug-${String(i + 1).padStart(3, '0')}`;

    const startCp = checkpoint({
      at: startAt,
      location: startLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-start`,
      seed: `aug-${i}-start`,
      notes: s.type === 'TRAVEL' ? 'Start journey' : 'Start overtime',
    });
    const arrivedCp = checkpoint({
      at: arrivedAt,
      location: siteLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-arrived`,
      seed: `aug-${i}-arrived`,
      notes: 'Arrived at work site',
    });
    const finishedCp = checkpoint({
      at: finishedAt,
      location: siteLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-finished`,
      seed: `aug-${i}-finished`,
      notes: 'Finished on-site work',
    });
    const endCp = checkpoint({
      at: endAt,
      location: endLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-end`,
      seed: `aug-${i}-end`,
      notes: s.type === 'TRAVEL' ? 'End journey' : 'End overtime',
    });

    const doc = {
      companyId: company._id,
      userId: technician._id,
      branchId: branch._id,
      departmentId: department._id,
      type: s.type,
      status: s.status,
      workflowVersion: 'v2',
      checkpoints: {
        startJourney: startCp,
        arrivedAtWorkSite: arrivedCp,
        finishedWork: finishedCp,
        endJourney: endCp,
      },
      startAt,
      startGps: startCp.gps,
      startPhoto: startCp.photo,
      startAddress: startCp.address,
      startDeviceId: deviceId,
      endAt,
      endGps: endCp.gps,
      endPhoto: endCp.photo,
      endAddress: endCp.address,
      endDeviceId: deviceId,
      totalDurationMinutes: calculated.totalDurationMinutes,
      workingDurationMinutes: calculated.workingDurationMinutes,
      eligibleOvertimeMinutes: calculated.eligibleOvertimeMinutes,
      calculationVersion: calculated.calculationVersion,
      calculatedAt: calculated.calculatedAt,
      clientRequestId,
      requiresManualReview: false,
      reviewReason: null,
      rejectionReason: s.rejectionReason || null,
      reviewNotes:
        s.status === 'APPROVED'
          ? 'Approved — August dashboard seed.'
          : s.status === 'REJECTED'
            ? s.rejectionReason
            : null,
    };

    if (s.status === 'APPROVED') {
      doc.approvedBy = admin._id;
      doc.approvedAt = addMinutes(endAt, 90);
    }
    if (s.status === 'REJECTED') {
      doc.rejectedBy = admin._id;
      doc.rejectedAt = addMinutes(endAt, 120);
    }

    docs.push(doc);
  }

  await OvertimeRecord.insertMany(docs);

  const monthFrom = cairo(2026, 8, 1, 0, 0);
  const monthTo = new Date();
  const augustCount = await OvertimeRecord.countDocuments({
    startAt: { $gte: monthFrom, $lte: monthTo },
  });
  const total = await OvertimeRecord.countDocuments();
  console.log(
    JSON.stringify(
      {
        inserted: docs.length,
        augustInRange: augustCount,
        totalOvertime: total,
        pending: await OvertimeRecord.countDocuments({ status: 'PENDING_REVIEW' }),
        approved: await OvertimeRecord.countDocuments({ status: 'APPROVED' }),
        rejected: await OvertimeRecord.countDocuments({ status: 'REJECTED' }),
      },
      null,
      2
    )
  );

  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error(err);
  try {
    await mongoose.disconnect();
  } catch {
    /* ignore */
  }
  process.exit(1);
});
