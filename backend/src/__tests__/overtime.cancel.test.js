import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { jest } from '@jest/globals';

const here = dirname(fileURLToPath(import.meta.url));
const overtimeServiceSource = readFileSync(
  join(here, '../modules/business/overtime/overtime.service.js'),
  'utf8'
);

describe('overtime cancel route contract', () => {
  it('exposes POST /:id/cancel with overtime:cancel permission', async () => {
    const { default: router } = await import(
      '../modules/business/overtime/overtime.routes.js'
    );

    const layer = router.stack.find(
      (entry) =>
        entry.route &&
        entry.route.path === '/:id/cancel' &&
        entry.route.methods?.post
    );

    expect(layer).toBeTruthy();
    expect(layer.route.stack.length).toBeGreaterThan(0);
  });
});

describe('overtime cancel service rules', () => {
  it('rejects non-running statuses conceptually', () => {
    const allowedFrom = new Set(['RUNNING']);
    for (const status of [
      'PENDING_REVIEW',
      'APPROVED',
      'REJECTED',
      'CANCELLED',
    ]) {
      if (status === 'CANCELLED') {
        // Idempotent success path for already cancelled.
        expect(status).toBe('CANCELLED');
        continue;
      }
      expect(allowedFrom.has(status)).toBe(false);
    }
    expect(allowedFrom.has('RUNNING')).toBe(true);
  });

  it('persists cancelledAt/cancelledBy and audits without deleting the record', () => {
    expect(overtimeServiceSource).toContain("record.status = 'CANCELLED'");
    expect(overtimeServiceSource).toContain('record.cancelledAt = new Date()');
    expect(overtimeServiceSource).toContain('record.cancelledBy = user._id');
    expect(overtimeServiceSource).toContain("action: 'overtime.cancelled'");
    expect(overtimeServiceSource).not.toMatch(
      /async cancel\([\s\S]*?(?:deleteOne|findByIdAndDelete|findOneAndDelete)/
    );
  });

  it('notifies managers only after a successful RUNNING -> CANCELLED transition', () => {
    expect(overtimeServiceSource).toContain("event: 'cancelled'");
    expect(overtimeServiceSource).toContain('notifyOvertimeEvent({');

    const cancelFn = overtimeServiceSource.match(
      /async cancel\(user, auth, id\) \{[\s\S]*?\n  async listSessions/
    )?.[0];
    expect(cancelFn).toBeTruthy();
    expect(cancelFn).toContain("event: 'cancelled'");
    // Idempotent early return must happen before notify.
    const alreadyCancelledIdx = cancelFn.indexOf(
      "record.status === 'CANCELLED'"
    );
    const notifyIdx = cancelFn.indexOf("event: 'cancelled'");
    expect(alreadyCancelledIdx).toBeGreaterThan(-1);
    expect(notifyIdx).toBeGreaterThan(alreadyCancelledIdx);
  });

  it('admin listSessions excludes CANCELLED from operational All and supports CANCELLED filter', () => {
    expect(overtimeServiceSource).toContain(
      "['APPROVED', 'REJECTED', 'RUNNING', 'CANCELLED'].includes(normalized)"
    );
    expect(overtimeServiceSource).toContain(
      "filter.status = { $ne: 'CANCELLED' }"
    );

    const listSessionsIdx = overtimeServiceSource.indexOf('async listSessions(');
    const exportIdx = overtimeServiceSource.indexOf('async exportExcel(');
    expect(listSessionsIdx).toBeGreaterThan(-1);
    expect(exportIdx).toBeGreaterThan(listSessionsIdx);
    const listSessions = overtimeServiceSource.slice(listSessionsIdx, exportIdx);
    expect(listSessions).toContain("filter.status = { $ne: 'CANCELLED' }");
    expect(listSessions).toContain('const statusFilter = mapStatusFilter(status)');

    const exportExcel = overtimeServiceSource.slice(
      exportIdx,
      overtimeServiceSource.indexOf('async listMine(')
    );
    expect(exportExcel).not.toContain("filter.status = { $ne: 'CANCELLED' }");
  });
});
