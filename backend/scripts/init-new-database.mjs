/**
 * Initialize the NEW empty Infinity FSM database + overtime test data.
 *
 * SAFETY:
 * - Uses ONLY process.env.MONGODB_URI from backend/.env
 * - Refuses to run unless the connected DB name is exactly `infinity_fsm`
 * - Refuses localhost URIs (this script targets the new Atlas empty DB)
 * - Does NOT hardcode any previous production URI
 *
 * Run:
 *   node scripts/init-new-database.mjs
 */
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import config from '../src/config/index.js';
import logger from '../src/shared/utils/logger.util.js';
import Company from '../src/modules/core/organization/models/company.model.js';
import Branch from '../src/modules/core/organization/models/branch.model.js';
import Region from '../src/modules/core/organization/models/region.model.js';
import City from '../src/modules/core/organization/models/city.model.js';
import Department from '../src/modules/core/organization/models/department.model.js';
import Team from '../src/modules/core/organization/models/team.model.js';
import Position from '../src/modules/core/organization/models/position.model.js';
import User from '../src/modules/core/organization/models/user.model.js';
import Setting from '../src/modules/core/settings/models/setting.model.js';
import OvertimeRecord from '../src/modules/business/overtime/models/overtimeRecord.model.js';
import rbacService from '../src/modules/core/rbac/rbac.service.js';
import { ROLES } from '../src/shared/constants/roles.constants.js';
import {
  calculateOvertimeDurations,
  zonedLocalToUtc,
} from '../src/modules/business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../src/modules/business/overtime/working-hours.policy.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const REQUIRED_DB_NAME = 'infinity_fsm';
const TZ = OFFICIAL_WORKING_HOURS.timeZone;

const DEFAULT_SETTINGS = [
  { key: 'working_hours.start', value: '09:00', group: 'working_hours', dataType: 'string' },
  { key: 'working_hours.end', value: '17:00', group: 'working_hours', dataType: 'string' },
  { key: 'working_hours.timezone', value: 'Africa/Cairo', group: 'working_hours', dataType: 'string' },
  { key: 'overtime.allowed_types', value: ['REGULAR', 'TRAVEL'], group: 'overtime', dataType: 'array' },
  { key: 'overtime.gps_accuracy_limit_meters', value: 100, group: 'overtime', dataType: 'number' },
  { key: 'overtime.voice_max_duration_seconds', value: 300, group: 'overtime', dataType: 'number' },
  { key: 'overtime.voice_recording_quality', value: 'medium', group: 'overtime', dataType: 'string' },
  { key: 'overtime.max_photo_size_mb', value: 2, group: 'overtime', dataType: 'number' },
  { key: 'overtime.upload_policy', value: 'immediately', group: 'overtime', dataType: 'string' },
  { key: 'media.max_image_size_mb', value: 5, group: 'media', dataType: 'number' },
  { key: 'offline.retention_days', value: 30, group: 'offline', dataType: 'number' },
];

/** Realistic Cairo-area locations. */
const LOCATIONS = [
  { name: 'New Cairo', address: '90th Street, New Cairo, Cairo', lat: 30.0074, lng: 31.4913 },
  { name: 'Nasr City', address: 'Abbas El-Akkad, Nasr City, Cairo', lat: 30.0500, lng: 31.3400 },
  { name: 'Heliopolis', address: 'Korba, Heliopolis, Cairo', lat: 30.0910, lng: 31.3240 },
  { name: 'Maadi', address: 'Road 9, Maadi, Cairo', lat: 29.9602, lng: 31.2569 },
  { name: '6th of October', address: 'Central Spine, 6th of October City', lat: 29.9285, lng: 30.9188 },
  { name: 'Sheikh Zayed', address: 'Boulevard, Sheikh Zayed City', lat: 30.0480, lng: 30.9760 },
  { name: 'Downtown', address: 'Tahrir Square Area, Downtown Cairo', lat: 30.0444, lng: 31.2357 },
  { name: 'Obour', address: 'Industrial Zone, El Obour City', lat: 30.2285, lng: 31.4590 },
  { name: 'Madinaty', address: 'Open Air Mall, Madinaty, Cairo', lat: 30.0870, lng: 31.6420 },
  { name: 'Rehab', address: 'First Settlement, El Rehab City', lat: 30.0620, lng: 31.4920 },
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
    batteryLevel: 55 + (seed.length % 40),
    networkStatus: 'wifi',
    notes,
  };
}

function assertTargetDatabase() {
  const uri = process.env.MONGODB_URI || config.mongodb.uri;
  if (!uri) {
    throw new Error('MONGODB_URI is missing from environment');
  }
  if (/localhost|127\.0\.0\.1/i.test(uri)) {
    throw new Error('Refusing to run against localhost MongoDB');
  }
  logger.info({ uri: maskUri(uri) }, 'Using MONGODB_URI from current environment only');
  return uri;
}

async function assertConnectedDbIsNewTarget() {
  const dbName = mongoose.connection.name;
  if (dbName !== REQUIRED_DB_NAME) {
    throw new Error(
      `Refusing to continue: connected DB is "${dbName}", expected "${REQUIRED_DB_NAME}"`
    );
  }
  const host = mongoose.connection.host;
  logger.info({ dbName, host }, 'Connected database verified');
}

async function initSystemAndUsers() {
  const company = await Company.create({
    name: 'Infinity Tech',
    slug: 'infinity-tech',
    enabledModules: ['overtime', 'attendance', 'work_orders'],
  });

  const branch = await Branch.create({
    companyId: company._id,
    name: 'Cairo HQ',
    code: 'CAI-HQ',
    address: {
      city: 'Cairo',
      governorate: 'Cairo',
      country: 'Egypt',
    },
  });

  const region = await Region.create({
    companyId: company._id,
    branchId: branch._id,
    name: 'Greater Cairo',
    code: 'CAI',
  });

  const city = await City.create({
    companyId: company._id,
    branchId: branch._id,
    regionId: region._id,
    name: 'Cairo',
    code: 'CAI-CITY',
  });

  const department = await Department.create({
    companyId: company._id,
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    name: 'Field Operations',
    code: 'FIELD-OPS',
  });

  const team = await Team.create({
    companyId: company._id,
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    departmentId: department._id,
    name: 'Alpha Team',
    code: 'ALPHA',
  });

  const [adminPosition, technicianPosition] = await Position.insertMany([
    {
      companyId: company._id,
      name: 'System Administrator',
      code: 'SYS-ADMIN',
      description: 'Full platform administration',
    },
    {
      companyId: company._id,
      name: 'Field Technician',
      code: 'FIELD-TECH',
      description: 'Field service technician',
    },
  ]);

  await rbacService.ensureSystemRoles();

  const adminHash = await User.hashPassword('M@zen6550');
  const admin = await User.create({
    companyId: company._id,
    employeeId: 'EMP-001',
    email: 'mazen@gmail.com',
    passwordHash: adminHash,
    firstName: 'Mazen',
    lastName: 'Admin',
    phone: '+201000000001',
    roles: [ROLES.ADMIN],
    status: 'ACTIVE',
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    departmentId: department._id,
    teamId: team._id,
    positionId: adminPosition._id,
  });

  await department.updateOne({ $push: { supervisorIds: admin._id } });

  const techHash = await User.hashPassword('12345678');
  const technician = await User.create({
    companyId: company._id,
    employeeId: 'EMP-002',
    email: 'test@gmail.com',
    passwordHash: techHash,
    firstName: 'Field',
    lastName: 'Technician',
    phone: '+201000000002',
    roles: [ROLES.TECHNICIAN],
    status: 'ACTIVE',
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    departmentId: department._id,
    teamId: team._id,
    positionId: technicianPosition._id,
  });

  await Setting.insertMany(
    DEFAULT_SETTINGS.map((setting) => ({
      ...setting,
      companyId: company._id,
      updatedBy: admin._id,
    }))
  );

  return { company, branch, department, admin, technician };
}

/**
 * Build completed overtime scenarios (Cairo wall-clock), then run calculator.
 */
function buildScenarios() {
  /** @type {Array<object>} */
  const scenarios = [];

  // Before working hours (weekday)
  scenarios.push({
    label: 'before-hours-short',
    type: 'NORMAL',
    start: cairo(2026, 6, 8, 5, 30), // Mon
    end: cairo(2026, 6, 8, 8, 30),
    status: 'APPROVED',
  });
  scenarios.push({
    label: 'before-hours-medium',
    type: 'NORMAL',
    start: cairo(2026, 6, 15, 6, 0),
    end: cairo(2026, 6, 15, 8, 45),
    status: 'PENDING_REVIEW',
  });

  // After working hours
  scenarios.push({
    label: 'after-hours-evening',
    type: 'NORMAL',
    start: cairo(2026, 6, 9, 18, 0),
    end: cairo(2026, 6, 9, 22, 30),
    status: 'APPROVED',
  });
  scenarios.push({
    label: 'after-hours-long',
    type: 'NORMAL',
    start: cairo(2026, 6, 16, 17, 30),
    end: cairo(2026, 6, 16, 23, 45),
    status: 'PENDING_REVIEW',
  });
  scenarios.push({
    label: 'after-hours-short',
    type: 'NORMAL',
    start: cairo(2026, 7, 1, 17, 15),
    end: cairo(2026, 7, 1, 18, 0),
    status: 'REJECTED',
    rejectionReason: 'Insufficient justification for after-hours overtime.',
  });

  // Cross midnight
  scenarios.push({
    label: 'cross-midnight',
    type: 'NORMAL',
    start: cairo(2026, 6, 10, 22, 0),
    end: cairo(2026, 6, 11, 3, 30),
    status: 'APPROVED',
  });
  scenarios.push({
    label: 'cross-midnight-travel',
    type: 'TRAVEL',
    start: cairo(2026, 7, 6, 21, 0),
    end: cairo(2026, 7, 7, 2, 15),
    status: 'PENDING_REVIEW',
  });

  // Friday full overtime
  scenarios.push({
    label: 'friday-full-day',
    type: 'NORMAL',
    start: cairo(2026, 6, 12, 9, 0), // Friday
    end: cairo(2026, 6, 12, 17, 0),
    status: 'APPROVED',
  });
  scenarios.push({
    label: 'friday-evening',
    type: 'TRAVEL',
    start: cairo(2026, 6, 19, 10, 0),
    end: cairo(2026, 6, 19, 18, 30),
    status: 'PENDING_REVIEW',
  });
  scenarios.push({
    label: 'friday-short',
    type: 'NORMAL',
    start: cairo(2026, 7, 3, 14, 0),
    end: cairo(2026, 7, 3, 16, 0),
    status: 'REJECTED',
    rejectionReason: 'Duplicate request already covered by another ticket.',
  });

  // Saturday overtime
  scenarios.push({
    label: 'saturday-morning',
    type: 'NORMAL',
    start: cairo(2026, 6, 13, 7, 0),
    end: cairo(2026, 6, 13, 12, 0),
    status: 'APPROVED',
  });
  scenarios.push({
    label: 'saturday-after-hours',
    type: 'TRAVEL',
    start: cairo(2026, 6, 20, 17, 30),
    end: cairo(2026, 6, 20, 21, 0),
    status: 'APPROVED',
  });

  // Long / short / mixed durations
  scenarios.push({
    label: '45-min',
    type: 'NORMAL',
    start: cairo(2026, 6, 22, 17, 0),
    end: cairo(2026, 6, 22, 17, 45),
    status: 'APPROVED',
  });
  scenarios.push({
    label: '1-hour',
    type: 'NORMAL',
    start: cairo(2026, 6, 23, 18, 0),
    end: cairo(2026, 6, 23, 19, 0),
    status: 'PENDING_REVIEW',
  });
  scenarios.push({
    label: '2-hours',
    type: 'TRAVEL',
    start: cairo(2026, 6, 24, 18, 0),
    end: cairo(2026, 6, 24, 20, 0),
    status: 'APPROVED',
  });
  scenarios.push({
    label: '5-hours',
    type: 'NORMAL',
    start: cairo(2026, 6, 25, 17, 0),
    end: cairo(2026, 6, 25, 22, 0),
    status: 'APPROVED',
  });
  scenarios.push({
    label: '8-hours',
    type: 'TRAVEL',
    start: cairo(2026, 6, 28, 8, 0), // Sunday
    end: cairo(2026, 6, 28, 16, 0),
    status: 'PENDING_REVIEW',
  });
  scenarios.push({
    label: '12-hours',
    type: 'NORMAL',
    start: cairo(2026, 6, 29, 8, 0),
    end: cairo(2026, 6, 29, 20, 0),
    status: 'REJECTED',
    rejectionReason: 'Exceeds approved overtime policy without prior authorization.',
    requiresManualReview: true,
    reviewReason: 'Soft policy exceeded',
  });

  // More travel journeys across Cairo areas (last ~60 days)
  const travelDays = [
    [2026, 6, 2],
    [2026, 6, 4],
    [2026, 6, 7],
    [2026, 6, 11],
    [2026, 6, 14],
    [2026, 6, 17],
    [2026, 6, 21],
    [2026, 6, 26],
    [2026, 6, 30],
    [2026, 7, 2],
    [2026, 7, 5],
    [2026, 7, 8],
    [2026, 7, 12],
    [2026, 7, 15],
    [2026, 7, 19],
    [2026, 7, 22],
    [2026, 7, 26],
    [2026, 7, 29],
  ];

  const statuses = ['PENDING_REVIEW', 'APPROVED', 'APPROVED', 'REJECTED', 'PENDING_REVIEW'];
  travelDays.forEach(([y, m, d], index) => {
    const startHour = index % 2 === 0 ? 7 : 17;
    const durationHours = [2, 3, 4, 5, 6][index % 5];
    const start = cairo(y, m, d, startHour, index % 2 === 0 ? 15 : 0);
    const end = addMinutes(start, durationHours * 60);
    scenarios.push({
      label: `travel-route-${index + 1}`,
      type: 'TRAVEL',
      start,
      end,
      status: statuses[index % statuses.length],
      rejectionReason:
        statuses[index % statuses.length] === 'REJECTED'
          ? 'Travel overtime not pre-approved for this customer visit.'
          : undefined,
      route: true,
    });
  });

  return scenarios;
}

async function seedOvertime({ company, branch, department, admin, technician }) {
  const scenarios = buildScenarios();
  const deviceId = 'android-tech-seed-01';
  const docs = [];

  for (let i = 0; i < scenarios.length; i += 1) {
    const s = scenarios[i];
    const startLoc = LOCATIONS[i % LOCATIONS.length];
    const siteLoc = LOCATIONS[(i + 3) % LOCATIONS.length];
    const endLoc = s.route ? LOCATIONS[(i + 1) % LOCATIONS.length] : startLoc;

    const startAt = s.start;
    const endAt = s.end;
    const spanMs = endAt.getTime() - startAt.getTime();
    const arrivedAt = new Date(startAt.getTime() + Math.floor(spanMs * 0.22));
    const finishedAt = new Date(startAt.getTime() + Math.floor(spanMs * 0.78));

    const calculated = calculateOvertimeDurations(startAt, endAt);
    const clientRequestId = `seed-ot-${String(i + 1).padStart(3, '0')}-${s.label}`;

    const startCp = checkpoint({
      at: startAt,
      location: startLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-start`,
      seed: `${i}-start`,
      notes: s.type === 'TRAVEL' ? 'Start journey from home/base' : 'Start overtime',
    });
    const arrivedCp = checkpoint({
      at: arrivedAt,
      location: siteLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-arrived`,
      seed: `${i}-arrived`,
      notes: 'Arrived at work site',
    });
    const finishedCp = checkpoint({
      at: finishedAt,
      location: siteLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-finished`,
      seed: `${i}-finished`,
      notes: 'Finished on-site work',
    });
    const endCp = checkpoint({
      at: endAt,
      location: endLoc,
      deviceId,
      clientRequestId: `${clientRequestId}-end`,
      seed: `${i}-end`,
      notes: s.type === 'TRAVEL' ? 'Returned home / end journey' : 'End overtime',
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
      requiresManualReview: Boolean(s.requiresManualReview),
      reviewReason: s.reviewReason || null,
      rejectionReason: s.rejectionReason || null,
      reviewNotes:
        s.status === 'APPROVED'
          ? 'Approved after verifying GPS timeline and duration.'
          : s.status === 'REJECTED'
            ? s.rejectionReason
            : null,
    };

    if (s.status === 'APPROVED') {
      doc.approvedBy = admin._id;
      doc.approvedAt = addMinutes(endAt, 120);
    }
    if (s.status === 'REJECTED') {
      doc.rejectedBy = admin._id;
      doc.rejectedAt = addMinutes(endAt, 180);
    }

    docs.push(doc);
  }

  await OvertimeRecord.insertMany(docs);
  return docs.length;
}

async function validate({ admin, technician }) {
  const checks = {
    company: await Company.countDocuments(),
    branch: await Branch.countDocuments(),
    roles: (await mongoose.connection.db.collection('roles').countDocuments()),
    settings: await Setting.countDocuments(),
    users: await User.countDocuments(),
    overtime: await OvertimeRecord.countDocuments(),
    pending: await OvertimeRecord.countDocuments({ status: 'PENDING_REVIEW' }),
    approved: await OvertimeRecord.countDocuments({ status: 'APPROVED' }),
    rejected: await OvertimeRecord.countDocuments({ status: 'REJECTED' }),
    normal: await OvertimeRecord.countDocuments({ type: 'NORMAL' }),
    travel: await OvertimeRecord.countDocuments({ type: 'TRAVEL' }),
    adminEmail: admin.email,
    techEmail: technician.email,
  };

  const apiBase = process.env.API_BASE || 'http://127.0.0.1:3000/api/v1';
  const loginResults = {};
  for (const account of [
    { key: 'admin', email: 'mazen@gmail.com', password: 'M@zen6550' },
    { key: 'tech', email: 'test@gmail.com', password: '12345678' },
  ]) {
    try {
      const res = await fetch(`${apiBase}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: account.email,
          password: account.password,
          deviceId: 'init-validation',
        }),
      });
      const json = await res.json().catch(() => ({}));
      loginResults[account.key] = {
        status: res.status,
        ok: res.ok,
        hasToken: Boolean(
          json?.data?.tokens?.accessToken || json?.data?.accessToken
        ),
      };
    } catch (error) {
      loginResults[account.key] = {
        status: 0,
        ok: false,
        error: String(error.message || error),
      };
    }
  }

  return { checks, loginResults, apiBase };
}

async function main() {
  const uri = assertTargetDatabase();
  await mongoose.connect(uri);
  await assertConnectedDbIsNewTarget();

  // Empty DB expected — refuse if users already exist to avoid accidental wipe.
  const existingUsers = await User.countDocuments();
  const existingCompanies = await Company.countDocuments();
  if (existingUsers > 0 || existingCompanies > 0) {
    throw new Error(
      `Database is not empty (users=${existingUsers}, companies=${existingCompanies}). Aborting to avoid overwrite.`
    );
  }

  logger.info('Initializing system configuration on new empty database...');
  const ctx = await initSystemAndUsers();
  logger.info('System users created: mazen@gmail.com (ADMIN), test@gmail.com (TECHNICIAN)');

  logger.info('Seeding realistic overtime test data via calculator...');
  const overtimeCount = await seedOvertime(ctx);
  logger.info({ overtimeCount }, 'Overtime records inserted');

  const validation = await validate(ctx);
  logger.info(validation, 'Validation summary');

  console.log('\n=== INIT COMPLETE ===');
  console.log(JSON.stringify(validation, null, 2));
  console.log('\nAccounts:');
  console.log('  Admin: mazen@gmail.com / M@zen6550');
  console.log('  Tech:  test@gmail.com / 12345678');

  await mongoose.disconnect();
}

main().catch(async (error) => {
  logger.error({ err: error }, 'init-new-database failed');
  try {
    await mongoose.disconnect();
  } catch {
    // ignore
  }
  process.exit(1);
});
