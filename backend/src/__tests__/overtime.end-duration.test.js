import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import config from '../config/index.js';

const here = dirname(fileURLToPath(import.meta.url));
const overtimeServiceSource = readFileSync(
  join(here, '../modules/business/overtime/overtime.service.js'),
  'utf8'
);

describe('overtime END duration policy', () => {
  it('does not reject END with SESSION_TOO_LONG', () => {
    expect(overtimeServiceSource).not.toContain('SESSION_TOO_LONG');
    expect(overtimeServiceSource).not.toContain('absoluteMaxSessionHours');
    expect(overtimeServiceSource).not.toContain(
      'exceeds the absolute maximum'
    );
  });

  it('keeps the 16-hour soft review threshold and has no hard 48-hour cap', () => {
    expect(config.overtime.maxSessionHours).toBe(16);
    expect(config.overtime.absoluteMaxSessionHours).toBeUndefined();
  });

  it('still applies the soft 16-hour check in end()', () => {
    expect(overtimeServiceSource).toContain('exceedsSoftPolicy');
    expect(overtimeServiceSource).toContain('requiresManualReview');
    expect(overtimeServiceSource).toContain(
      'Session duration exceeded company policy of ${softMaxHours} hours'
    );
  });
});
