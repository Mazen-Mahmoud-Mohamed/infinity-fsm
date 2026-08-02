/**
 * One-time migration: recalculate historical overtime duration fields using
 * the current official-hours overlap algorithm (incl. Friday = full OT).
 *
 * Usage:
 *   node scripts/migrate-overtime-durations.js                      # dry-run
 *   node scripts/migrate-overtime-durations.js --apply              # write
 *   node scripts/migrate-overtime-durations.js --apply --validate-sample=50
 *
 * Safe / idempotent:
 * - Only updates duration calculation fields (+ calculationVersion / calculatedAt)
 * - Does not touch createdAt / updatedAt (timestamps: false)
 * - Skips records without valid startAt/endAt
 * - Skips records already matching current calculationVersion + values
 * - Cursor-based batches — safe to re-run after interruption
 *
 * NOT run on server startup.
 */
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import config from '../src/config/index.js';
import {
  CALCULATION_VERSION,
  calculateOvertimeDurations,
} from '../src/modules/business/overtime/overtime.calculation.js';
import OvertimeRecord from '../src/modules/business/overtime/models/overtimeRecord.model.js';
import Company from '../src/modules/core/organization/models/company.model.js';
import Setting from '../src/modules/core/settings/models/setting.model.js';
import { OFFICIAL_WORKING_HOURS } from '../src/modules/business/overtime/working-hours.policy.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const BATCH_SIZE = 200;
const COMPANY_TIMEZONE = OFFICIAL_WORKING_HOURS.timeZone;

function parseArgs(argv) {
  const apply = argv.includes('--apply');
  const validateArg = argv.find((a) => a.startsWith('--validate-sample='));
  let validateSample = 50;
  if (validateArg) {
    validateSample = Math.max(0, Number(validateArg.split('=')[1]) || 0);
  }
  return { apply, dryRun: !apply, validateSample };
}

function sameNumber(a, b) {
  const left = a == null ? null : Number(a);
  const right = b == null ? null : Number(b);
  return left === right;
}

function alreadyMigrated(doc, calculated) {
  return (
    doc.calculationVersion === CALCULATION_VERSION &&
    sameNumber(doc.totalDurationMinutes, calculated.totalDurationMinutes) &&
    sameNumber(doc.workingDurationMinutes, calculated.workingDurationMinutes) &&
    sameNumber(doc.eligibleOvertimeMinutes, calculated.eligibleOvertimeMinutes)
  );
}

function pickRandom(items, count) {
  if (items.length <= count) {
    return [...items];
  }
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, count);
}

async function validateAgainstAlgorithm(filter, sampleSize) {
  const total = await OvertimeRecord.countDocuments(filter);
  const size = Math.min(sampleSize, total);
  if (size <= 0) {
    return { sampleOk: 0, sampleFail: 0, mismatches: [], sampleSize: 0 };
  }

  const sample = await OvertimeRecord.aggregate([
    { $match: filter },
    { $sample: { size } },
    {
      $project: {
        startAt: 1,
        endAt: 1,
        status: 1,
        totalDurationMinutes: 1,
        workingDurationMinutes: 1,
        eligibleOvertimeMinutes: 1,
        calculationVersion: 1,
      },
    },
  ]);

  let sampleOk = 0;
  let sampleFail = 0;
  const mismatches = [];

  for (const doc of sample) {
    const startAt = new Date(doc.startAt);
    const endAt = new Date(doc.endAt);
    if (
      Number.isNaN(startAt.getTime()) ||
      Number.isNaN(endAt.getTime()) ||
      endAt <= startAt
    ) {
      sampleFail += 1;
      mismatches.push({ id: String(doc._id), reason: 'invalid_timestamps' });
      continue;
    }

    const expected = calculateOvertimeDurations(startAt, endAt);
    const ok = alreadyMigrated(doc, expected);
    if (ok) {
      sampleOk += 1;
    } else {
      sampleFail += 1;
      mismatches.push({
        id: String(doc._id),
        status: doc.status,
        old: {
          totalDurationMinutes: doc.totalDurationMinutes,
          workingDurationMinutes: doc.workingDurationMinutes,
          eligibleOvertimeMinutes: doc.eligibleOvertimeMinutes,
          calculationVersion: doc.calculationVersion,
        },
        expected: {
          totalDurationMinutes: expected.totalDurationMinutes,
          workingDurationMinutes: expected.workingDurationMinutes,
          eligibleOvertimeMinutes: expected.eligibleOvertimeMinutes,
          calculationVersion: expected.calculationVersion,
        },
      });
    }
  }

  return { sampleOk, sampleFail, mismatches, sampleSize: sample.length };
}

async function migrate() {
  const { apply, dryRun, validateSample } = parseArgs(process.argv.slice(2));

  console.log('=== Overtime duration migration ===');
  console.log(`Mode: ${dryRun ? 'DRY-RUN (no writes)' : 'APPLY'}`);
  console.log(`Target calculationVersion: ${CALCULATION_VERSION}`);
  console.log(`Company timezone: ${COMPANY_TIMEZONE}`);
  console.log(`Batch size: ${BATCH_SIZE}`);

  await mongoose.connect(config.mongodb.uri);
  console.log('Connected to MongoDB');

  // Keep organization timezone aligned with OT policy (Africa/Cairo).
  if (!dryRun) {
    const companyResult = await Company.updateMany(
      { timezone: { $ne: COMPANY_TIMEZONE } },
      { $set: { timezone: COMPANY_TIMEZONE } },
      { timestamps: false }
    );
    const settingResult = await Setting.updateMany(
      {
        key: 'working_hours.timezone',
        value: { $ne: COMPANY_TIMEZONE },
      },
      { $set: { value: COMPANY_TIMEZONE } },
      { timestamps: false }
    );
    console.log(
      `Timezone sync: companies matched=${companyResult.matchedCount} modified=${companyResult.modifiedCount}; settings matched=${settingResult.matchedCount} modified=${settingResult.modifiedCount}`
    );
  } else {
    const companiesNeedingTz = await Company.countDocuments({
      timezone: { $ne: COMPANY_TIMEZONE },
    });
    const settingsNeedingTz = await Setting.countDocuments({
      key: 'working_hours.timezone',
      value: { $ne: COMPANY_TIMEZONE },
    });
    console.log(
      `DRY-RUN timezone sync needed: companies=${companiesNeedingTz}, settings=${settingsNeedingTz}`
    );
  }

  const filter = {
    startAt: { $exists: true, $ne: null },
    endAt: { $exists: true, $ne: null },
  };

  const totalEligible = await OvertimeRecord.countDocuments(filter);
  console.log(`Records with startAt+endAt: ${totalEligible}`);

  const summary = {
    scanned: 0,
    updated: 0,
    skippedAlreadyCurrent: 0,
    skippedInvalid: 0,
    failed: 0,
    versionBumpOnly: 0,
  };

  const changeExamples = [];
  const failures = [];

  let lastId = null;

  while (true) {
    const pageFilter = lastId ? { ...filter, _id: { $gt: lastId } } : { ...filter };
    const batch = await OvertimeRecord.find(pageFilter)
      .sort({ _id: 1 })
      .limit(BATCH_SIZE)
      .select({
        _id: 1,
        startAt: 1,
        endAt: 1,
        status: 1,
        totalDurationMinutes: 1,
        workingDurationMinutes: 1,
        eligibleOvertimeMinutes: 1,
        calculationVersion: 1,
      })
      .lean();

    if (batch.length === 0) {
      break;
    }

    for (const doc of batch) {
      summary.scanned += 1;
      lastId = doc._id;

      const startAt =
        doc.startAt instanceof Date ? doc.startAt : new Date(doc.startAt);
      const endAt = doc.endAt instanceof Date ? doc.endAt : new Date(doc.endAt);

      if (
        Number.isNaN(startAt.getTime()) ||
        Number.isNaN(endAt.getTime()) ||
        endAt.getTime() <= startAt.getTime()
      ) {
        summary.skippedInvalid += 1;
        failures.push({
          id: String(doc._id),
          reason: 'invalid_timestamps',
          startAt: doc.startAt,
          endAt: doc.endAt,
        });
        continue;
      }

      let calculated;
      try {
        calculated = calculateOvertimeDurations(startAt, endAt);
      } catch (error) {
        summary.failed += 1;
        failures.push({
          id: String(doc._id),
          reason: 'calculation_error',
          message: error?.message || String(error),
        });
        continue;
      }

      if (alreadyMigrated(doc, calculated)) {
        summary.skippedAlreadyCurrent += 1;
        continue;
      }

      const valuesUnchanged =
        sameNumber(doc.totalDurationMinutes, calculated.totalDurationMinutes) &&
        sameNumber(
          doc.workingDurationMinutes,
          calculated.workingDurationMinutes
        ) &&
        sameNumber(
          doc.eligibleOvertimeMinutes,
          calculated.eligibleOvertimeMinutes
        );

      if (valuesUnchanged) {
        summary.versionBumpOnly += 1;
      }

      if (changeExamples.length < 25) {
        changeExamples.push({
          id: String(doc._id),
          status: doc.status,
          old: {
            totalDurationMinutes: doc.totalDurationMinutes,
            workingDurationMinutes: doc.workingDurationMinutes,
            eligibleOvertimeMinutes: doc.eligibleOvertimeMinutes,
            calculationVersion: doc.calculationVersion,
          },
          next: {
            totalDurationMinutes: calculated.totalDurationMinutes,
            workingDurationMinutes: calculated.workingDurationMinutes,
            eligibleOvertimeMinutes: calculated.eligibleOvertimeMinutes,
            calculationVersion: calculated.calculationVersion,
          },
        });
      }

      if (dryRun) {
        summary.updated += 1;
        continue;
      }

      try {
        const result = await OvertimeRecord.updateOne(
          { _id: doc._id },
          {
            $set: {
              totalDurationMinutes: calculated.totalDurationMinutes,
              workingDurationMinutes: calculated.workingDurationMinutes,
              eligibleOvertimeMinutes: calculated.eligibleOvertimeMinutes,
              calculationVersion: calculated.calculationVersion,
              calculatedAt: calculated.calculatedAt,
            },
          },
          { timestamps: false }
        );

        if (result.matchedCount !== 1) {
          summary.failed += 1;
          failures.push({
            id: String(doc._id),
            reason: 'update_not_matched',
          });
        } else {
          summary.updated += 1;
        }
      } catch (error) {
        summary.failed += 1;
        failures.push({
          id: String(doc._id),
          reason: 'update_error',
          message: error?.message || String(error),
        });
      }
    }

    console.log(
      `Progress: ${summary.scanned}/${totalEligible} | wouldUpdate/updated=${summary.updated} skippedCurrent=${summary.skippedAlreadyCurrent} invalid=${summary.skippedInvalid} failed=${summary.failed}`
    );
  }

  console.log('\n=== Migration summary ===');
  console.log(JSON.stringify(summary, null, 2));
  console.log('\nExample old → next (up to 25):');
  console.log(JSON.stringify(changeExamples, null, 2));

  if (failures.length > 0) {
    console.log('\n=== Failed / invalid records ===');
    console.log(JSON.stringify(failures.slice(0, 100), null, 2));
    if (failures.length > 100) {
      console.log(`... and ${failures.length - 100} more`);
    }
  }

  if (validateSample > 0) {
    console.log(`\n=== Validation sample (${validateSample}) ===`);
    if (apply) {
      const result = await validateAgainstAlgorithm(filter, validateSample);
      console.log(
        JSON.stringify(
          {
            note: 'After APPLY: sample must match algorithm + calculationVersion',
            sampleSize: result.sampleSize,
            sampleOk: result.sampleOk,
            sampleFail: result.sampleFail,
            mismatches: result.mismatches.slice(0, 20),
          },
          null,
          2
        )
      );
      if (result.sampleFail > 0) {
        process.exitCode = 1;
      }
    } else {
      const sample = await OvertimeRecord.aggregate([
        { $match: filter },
        { $sample: { size: Math.min(validateSample, Math.max(totalEligible, 1)) } },
        {
          $project: {
            startAt: 1,
            endAt: 1,
            status: 1,
            totalDurationMinutes: 1,
            workingDurationMinutes: 1,
            eligibleOvertimeMinutes: 1,
            calculationVersion: 1,
          },
        },
      ]);

      const preview = [];
      for (const doc of sample) {
        const calculated = calculateOvertimeDurations(
          new Date(doc.startAt),
          new Date(doc.endAt)
        );
        preview.push({
          id: String(doc._id),
          status: doc.status,
          old: {
            totalDurationMinutes: doc.totalDurationMinutes,
            workingDurationMinutes: doc.workingDurationMinutes,
            eligibleOvertimeMinutes: doc.eligibleOvertimeMinutes,
            calculationVersion: doc.calculationVersion,
          },
          expected: {
            totalDurationMinutes: calculated.totalDurationMinutes,
            workingDurationMinutes: calculated.workingDurationMinutes,
            eligibleOvertimeMinutes: calculated.eligibleOvertimeMinutes,
            calculationVersion: calculated.calculationVersion,
          },
          needsUpdate: !alreadyMigrated(doc, calculated),
        });
      }

      const needingUpdate = preview.filter((p) => p.needsUpdate).length;
      console.log(
        JSON.stringify(
          {
            note: 'DRY-RUN: comparing stored vs newly computed (no writes)',
            sampleSize: preview.length,
            needingUpdate,
            alreadyCurrent: preview.length - needingUpdate,
            examples: pickRandom(preview, Math.min(10, preview.length)),
          },
          null,
          2
        )
      );
    }
  }

  await mongoose.disconnect();
  console.log('\nDone.');

  if (summary.failed > 0) {
    process.exitCode = 1;
  }
}

migrate().catch(async (error) => {
  console.error('Migration crashed:', error);
  try {
    await mongoose.disconnect();
  } catch {
    // ignore
  }
  process.exit(1);
});
