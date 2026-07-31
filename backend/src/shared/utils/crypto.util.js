import crypto from 'crypto';

export function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

export function generateSecureToken(bytes = 32) {
  return crypto.randomBytes(bytes).toString('hex');
}
