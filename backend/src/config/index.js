import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

function optionalEnv(key, fallback = '') {
  return process.env[key] ?? fallback;
}

function parseList(value) {
  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

const nodeEnv = optionalEnv('NODE_ENV', 'development');

function resolveJwtSecret(keys, fallback) {
  for (const key of keys) {
    const value = process.env[key];
    if (value) {
      return value;
    }
  }

  if (nodeEnv === 'development' || nodeEnv === 'test') {
    return fallback;
  }

  throw new Error(
    `Missing required environment variable: ${keys.join(' or ')}`
  );
}

const port = parseInt(optionalEnv('PORT', '3000'), 10);

const config = Object.freeze({
  env: nodeEnv,
  isProduction: nodeEnv === 'production',
  isDevelopment: nodeEnv === 'development',
  isTest: nodeEnv === 'test',

  server: Object.freeze({
    port,
    apiVersion: optionalEnv('API_VERSION', 'v1'),
  }),

  mongodb: Object.freeze({
    uri: optionalEnv('MONGODB_URI', ''),
  }),

  jwt: Object.freeze({
    accessSecret: resolveJwtSecret(
      ['JWT_ACCESS_SECRET', 'JWT_SECRET'],
      'dev-access-secret-change-in-production-min-32-chars'
    ),
    refreshSecret: resolveJwtSecret(
      ['JWT_REFRESH_SECRET'],
      'dev-refresh-secret-change-in-production-min-32-chars'
    ),
    accessExpiry: optionalEnv('JWT_ACCESS_EXPIRY', '15m'),
    refreshExpiry: optionalEnv('JWT_REFRESH_EXPIRY', '7d'),
  }),

  cors: Object.freeze({
    origins: parseList(
      optionalEnv(
        'CORS_ORIGINS',
        'http://localhost:8080,http://localhost:5000,http://localhost:3000,http://127.0.0.1:8080,http://127.0.0.1:5000'
      )
    ),
  }),

  rateLimit: Object.freeze({
    windowMs: parseInt(optionalEnv('RATE_LIMIT_WINDOW_MS', '60000'), 10),
    max: parseInt(optionalEnv('RATE_LIMIT_MAX', '100'), 10),
    authMax: parseInt(optionalEnv('RATE_LIMIT_AUTH_MAX', '10'), 10),
  }),

  logging: Object.freeze({
    level: optionalEnv('LOG_LEVEL', nodeEnv === 'development' ? 'debug' : 'info'),
  }),

  cloudinary: Object.freeze({
    cloudName: optionalEnv('CLOUDINARY_CLOUD_NAME'),
    apiKey: optionalEnv('CLOUDINARY_API_KEY'),
    apiSecret: optionalEnv('CLOUDINARY_API_SECRET'),
    isConfigured() {
      return Boolean(this.cloudName && this.apiKey && this.apiSecret);
    },
  }),

  socket: Object.freeze({
    corsOrigins: parseList(
      optionalEnv('SOCKET_CORS_ORIGINS', optionalEnv('CORS_ORIGINS', 'http://localhost:8080'))
    ),
  }),

  attendance: Object.freeze({
    gpsAccuracyThresholdMeters: parseInt(
      optionalEnv('ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS', '100'),
      10
    ),
  }),

  overtime: Object.freeze({
    maxRequestHours: parseFloat(optionalEnv('OVERTIME_MAX_REQUEST_HOURS', '16')),
    minRequestHours: parseFloat(optionalEnv('OVERTIME_MIN_REQUEST_HOURS', '0.5')),
    /** Soft threshold: session still ends but flagged for manual review. */
    maxSessionHours: parseFloat(optionalEnv('OVERTIME_MAX_SESSION_HOURS', '16')),
    gpsAccuracyThresholdMeters: parseInt(
      optionalEnv('OVERTIME_GPS_ACCURACY_THRESHOLD_METERS', '100'),
      10
    ),
  }),

  security: Object.freeze({
    maxDeviceClockSkewSeconds: parseInt(
      optionalEnv('DEVICE_CLOCK_SKEW_SECONDS', '120'),
      10
    ),
  }),
});

export function validateConfig() {
  const errors = [];

  if (!Number.isInteger(config.server.port) || config.server.port < 1 || config.server.port > 65535) {
    errors.push('PORT must be a valid number between 1 and 65535');
  }

  if (!config.mongodb.uri) {
    errors.push('MONGODB_URI is required');
  }

  if (config.jwt.accessSecret.length < 32) {
    errors.push('JWT_ACCESS_SECRET (or JWT_SECRET) must be at least 32 characters');
  }

  if (config.jwt.refreshSecret.length < 32) {
    errors.push('JWT_REFRESH_SECRET must be at least 32 characters');
  }

  if (config.isProduction && !config.cloudinary.isConfigured()) {
    errors.push(
      'Cloudinary is required in production: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET'
    );
  }

  if (errors.length > 0) {
    throw new Error(`Configuration validation failed:\n- ${errors.join('\n- ')}`);
  }

  return config;
}

export default config;
