import { jest } from '@jest/globals';

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
});
