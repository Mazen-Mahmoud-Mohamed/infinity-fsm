import DevicePushToken from './models/devicePushToken.model.js';

const PLATFORMS = new Set(['android', 'ios', 'windows', 'web', 'unknown']);

function normalizeLocale(locale) {
  const value = String(locale || '').trim().toLowerCase();
  if (value.startsWith('en')) return 'en';
  return 'ar';
}

function normalizePlatform(platform) {
  const value = String(platform || '').trim().toLowerCase();
  return PLATFORMS.has(value) ? value : 'unknown';
}

/**
 * Register or refresh a device push token for the authenticated user.
 * Multi-device: unique by token; reassigns ownership if token moved devices.
 */
export async function registerDeviceToken(user, auth, body) {
  const token = String(body.token || '').trim();
  if (!token || token.length < 20) {
    const error = new Error('A valid push token is required');
    error.statusCode = 422;
    error.code = 'VALIDATION_ERROR';
    error.isOperational = true;
    throw error;
  }

  const platform = normalizePlatform(body.platform);
  const locale = normalizeLocale(body.locale);
  const deviceId = body.deviceId ? String(body.deviceId).trim() : null;

  const existing = await DevicePushToken.findOne({ token });
  if (existing) {
    existing.userId = user._id;
    existing.companyId = auth.companyId;
    existing.platform = platform;
    existing.locale = locale;
    existing.deviceId = deviceId || existing.deviceId;
    existing.active = true;
    existing.deactivatedAt = null;
    existing.deactivationReason = null;
    existing.lastSeenAt = new Date();
    await existing.save();
    return mapToken(existing);
  }

  const created = await DevicePushToken.create({
    companyId: auth.companyId,
    userId: user._id,
    token,
    platform,
    locale,
    deviceId,
    active: true,
    lastSeenAt: new Date(),
  });

  return mapToken(created);
}

/**
 * Deactivate the caller's token (logout). Auth user must own the token.
 */
export async function deactivateDeviceToken(user, auth, tokenValue) {
  const token = String(tokenValue || '').trim();
  if (!token) {
    return { deactivated: false };
  }

  const result = await DevicePushToken.updateOne(
    {
      token,
      userId: user._id,
      companyId: auth.companyId,
      active: true,
    },
    {
      $set: {
        active: false,
        deactivatedAt: new Date(),
        deactivationReason: 'logout',
      },
    }
  );

  return { deactivated: result.modifiedCount > 0 };
}

/**
 * Deactivate all active tokens for the authenticated user (optional full logout).
 */
export async function deactivateAllDeviceTokens(user, auth) {
  const result = await DevicePushToken.updateMany(
    {
      userId: user._id,
      companyId: auth.companyId,
      active: true,
    },
    {
      $set: {
        active: false,
        deactivatedAt: new Date(),
        deactivationReason: 'logout_all',
      },
    }
  );
  return { deactivated: result.modifiedCount };
}

export async function listActiveTokensForUsers(userIds) {
  const ids = (userIds || []).filter(Boolean);
  if (!ids.length) return [];

  return DevicePushToken.find({
    userId: { $in: ids },
    active: true,
  })
    .select('token platform locale userId')
    .lean();
}

function mapToken(doc) {
  return {
    id: doc._id.toString(),
    platform: doc.platform,
    locale: doc.locale,
    deviceId: doc.deviceId,
    active: doc.active,
    lastSeenAt: doc.lastSeenAt,
  };
}

export default {
  registerDeviceToken,
  deactivateDeviceToken,
  deactivateAllDeviceTokens,
  listActiveTokensForUsers,
};
