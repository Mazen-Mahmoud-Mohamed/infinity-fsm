import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import settingsService from './settings.service.js';

export const getOrganizationSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.getOrganizationSettings(req.user, req.auth);
  sendSuccess(res, data);
});

export const updateOrganizationSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.updateOrganizationSettings(
    req.user,
    req.auth,
    req.body
  );
  sendSuccess(res, data);
});

export const uploadOrganizationLogo = asyncHandler(async (req, res) => {
  const data = await settingsService.uploadOrganizationLogo(
    req.user,
    req.auth,
    req.file
  );
  sendSuccess(res, data);
});

export const getSystemInfo = asyncHandler(async (req, res) => {
  const data = await settingsService.getSystemInfo(req.user, req.auth);
  sendSuccess(res, data);
});

export const getOvertimeSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.getOvertimeSettings(req.user, req.auth);
  sendSuccess(res, data);
});

export const updateOvertimeSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.updateOvertimeSettings(
    req.user,
    req.auth,
    req.body
  );
  sendSuccess(res, data);
});

export const getOvertimeVoiceDurationConfig = asyncHandler(async (req, res) => {
  const data = await settingsService.getOvertimeVoiceDurationConfig(req.user);
  sendSuccess(res, data);
});

export const getOvertimeMediaConfig = asyncHandler(async (req, res) => {
  const data = await settingsService.getOvertimeMediaConfig(req.user);
  sendSuccess(res, data);
});
