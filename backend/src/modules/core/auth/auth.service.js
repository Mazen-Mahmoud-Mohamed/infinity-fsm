import jwt from 'jsonwebtoken';
import config from '../../../config/index.js';
import User from '../organization/models/user.model.js';
import RefreshToken from './models/refreshToken.model.js';
import { UnauthorizedError } from '../../../shared/errors/AppError.js';
import { sha256, generateSecureToken } from '../../../shared/utils/crypto.util.js';
import auditService from '../audit/audit.service.js';
import rbacService from '../rbac/rbac.service.js';

function parseExpiryToMs(expiry) {
  if (/^\d+$/.test(String(expiry))) {
    return parseInt(expiry, 10) * 1000;
  }

  const match = /^(\d+)([smhd])$/.exec(expiry);
  if (!match) {
    throw new Error(`Invalid JWT expiry format: ${expiry}`);
  }

  const value = parseInt(match[1], 10);
  const multipliers = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
  return value * multipliers[match[2]];
}

function buildAccessToken(user) {
  return jwt.sign(
    {
      sub: user._id.toString(),
      companyId: user.companyId.toString(),
      roles: user.roles,
      type: 'access',
    },
    config.jwt.accessSecret,
    { expiresIn: config.jwt.accessExpiry }
  );
}

function getRefreshExpiryDate() {
  const expiryMs = parseExpiryToMs(config.jwt.refreshExpiry);
  return new Date(Date.now() + expiryMs);
}

function getAccessExpirySeconds() {
  return Math.floor(parseExpiryToMs(config.jwt.accessExpiry) / 1000);
}

class AuthService {
  async login({ email, password, deviceId, deviceInfo }, req) {
    const normalizedEmail = email.toLowerCase();
    const user = await User.findOne({
      email: normalizedEmail,
      deletedAt: null,
    }).select('+passwordHash');

    if (!user || !(await user.comparePassword(password))) {
      await auditService.log({
        companyId: user?.companyId || null,
        actorId: user?._id || null,
        action: 'auth.login_failed',
        module: 'auth',
        resourceType: 'user',
        metadata: { email: normalizedEmail },
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });
      throw new UnauthorizedError('Invalid email or password', 'INVALID_EMAIL');
    }

    if (
      !user.isActive ||
      user.status === 'DISABLED' ||
      user.status === 'LOCKED'
    ) {
      await auditService.log({
        companyId: user.companyId,
        actorId: user._id,
        action: 'auth.login_failed',
        module: 'auth',
        resourceType: 'user',
        metadata: { email: normalizedEmail, reason: 'USER_DISABLED' },
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });
      throw new UnauthorizedError(
        'User account is inactive or does not exist',
        'USER_DISABLED'
      );
    }

    const tokens = await this._issueTokenPair(user, deviceId, deviceInfo);

    user.lastLoginAt = new Date();
    user.lastSeenAt = new Date();
    await user.save();

    await auditService.logAuthEvent(req, {
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'auth.login',
      metadata: { deviceId },
    });

    return {
      tokens,
      user: await this._mapUser(user),
    };
  }

  async refresh({ refreshToken, deviceId }, req) {
    const tokenHash = sha256(refreshToken);

    const storedToken = await RefreshToken.findOne({
      tokenHash,
      revokedAt: null,
    });

    if (!storedToken || storedToken.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired refresh token', 'UNAUTHORIZED');
    }

    if (storedToken.deviceId !== deviceId) {
      await RefreshToken.updateOne({ _id: storedToken._id }, { revokedAt: new Date() });
      throw new UnauthorizedError('Refresh token device mismatch', 'UNAUTHORIZED');
    }

    const user = await User.findOne({
      _id: storedToken.userId,
      isActive: true,
      deletedAt: null,
    });

    if (!user) {
      throw new UnauthorizedError(
        'User account is inactive or does not exist',
        'USER_DISABLED'
      );
    }

    storedToken.revokedAt = new Date();
    await storedToken.save();

    const tokens = await this._issueTokenPair(user, deviceId, storedToken.deviceInfo);

    await auditService.logAuthEvent(req, {
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'auth.token_refreshed',
      metadata: { deviceId },
    });

    return {
      tokens,
    };
  }

  async logout({ refreshToken, deviceId }, req, user) {
    if (refreshToken) {
      const tokenHash = sha256(refreshToken);
      await RefreshToken.updateOne(
        {
          tokenHash,
          userId: user._id,
          deviceId,
          revokedAt: null,
        },
        { revokedAt: new Date() }
      );
    } else {
      await RefreshToken.updateMany(
        { userId: user._id, deviceId, revokedAt: null },
        { revokedAt: new Date() }
      );
    }

    await auditService.logAuthEvent(req, {
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'auth.logout',
      metadata: { deviceId },
    });
  }

  async getMe(userId) {
    const user = await User.findOne({
      _id: userId,
      isActive: true,
      deletedAt: null,
    });

    if (!user) {
      throw new UnauthorizedError(
        'User account is inactive or does not exist',
        'USER_DISABLED'
      );
    }

    return await this._mapUser(user, true);
  }

  async _issueTokenPair(user, deviceId, deviceInfo) {
    const accessToken = buildAccessToken(user);
    const refreshToken = generateSecureToken(48);
    const tokenHash = sha256(refreshToken);

    await RefreshToken.create({
      userId: user._id,
      tokenHash,
      deviceId,
      deviceInfo: deviceInfo || null,
      expiresAt: getRefreshExpiryDate(),
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: getAccessExpirySeconds(),
    };
  }

  async _mapUser(user, includePermissions = false) {
    const mapped = {
      id: user._id.toString(),
      companyId: user.companyId.toString(),
      employeeId: user.employeeId,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      fullName: user.fullName,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      roles: user.roles,
      organization: {
        branchId: user.branchId?.toString(),
        regionId: user.regionId?.toString(),
        cityId: user.cityId?.toString(),
        departmentId: user.departmentId?.toString(),
        teamId: user.teamId?.toString() || null,
        positionId: user.positionId?.toString() || null,
      },
      lastLoginAt: user.lastLoginAt,
    };

    if (includePermissions) {
      try {
        mapped.permissions = await rbacService.resolveUserPermissions(user);
      } catch {
        mapped.permissions = user.getPermissions();
      }
    }

    return mapped;
  }
}

export default new AuthService();
