import asyncHandler from '../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../shared/utils/apiResponse.util.js';
import * as notificationsService from './notifications.service.js';
import * as deviceTokenService from './deviceToken.service.js';

export const listNotifications = asyncHandler(async (req, res) => {
  const data = await notificationsService.listNotifications(req.user, req.auth, {
    page: req.query.page,
    limit: req.query.limit,
  });
  sendSuccess(res, data.items, 200, {
    pagination: data.pagination,
    unreadCount: data.unreadCount,
  });
});

export const unreadCount = asyncHandler(async (req, res) => {
  const data = await notificationsService.getUnreadCount(req.user, req.auth);
  sendSuccess(res, data);
});

export const markRead = asyncHandler(async (req, res) => {
  const data = await notificationsService.markAsRead(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const markAllRead = asyncHandler(async (req, res) => {
  const data = await notificationsService.markAllAsRead(req.user, req.auth);
  sendSuccess(res, data);
});

export const registerDeviceToken = asyncHandler(async (req, res) => {
  const data = await deviceTokenService.registerDeviceToken(
    req.user,
    req.auth,
    req.body
  );
  sendSuccess(res, data, 201);
});

export const deactivateDeviceToken = asyncHandler(async (req, res) => {
  const token = req.body?.token || req.params.token;
  const data = await deviceTokenService.deactivateDeviceToken(
    req.user,
    req.auth,
    token
  );
  sendSuccess(res, data);
});
