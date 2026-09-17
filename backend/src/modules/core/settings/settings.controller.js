import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import settingsService from './settings.service.js';
import holidayService from './holiday.service.js';

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

export const getTechnicianInterfaceSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.getTechnicianInterfaceSettings(
    req.user,
    req.auth
  );
  sendSuccess(res, data);
});

export const updateTechnicianInterfaceSettings = asyncHandler(
  async (req, res) => {
    const data = await settingsService.updateTechnicianInterfaceSettings(
      req.user,
      req.auth,
      req.body
    );
    sendSuccess(res, data);
  }
);

export const getTechnicianInterfaceConfig = asyncHandler(async (req, res) => {
  const data = await settingsService.getTechnicianInterfaceConfig(req.user);
  sendSuccess(res, data);
});

export const listHolidays = asyncHandler(async (req, res) => {
  const data = await holidayService.listHolidays(req.user, req.auth, req.query);
  sendSuccess(res, data);
});

export const createHoliday = asyncHandler(async (req, res) => {
  const data = await holidayService.createHoliday(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const replaceHolidays = asyncHandler(async (req, res) => {
  const data = await holidayService.replaceHolidaysInRange(
    req.user,
    req.auth,
    req.body
  );
  sendSuccess(res, data);
});

export const deleteHoliday = asyncHandler(async (req, res) => {
  const data = await holidayService.deleteHolidayByDate(
    req.user,
    req.auth,
    req.params.date
  );
  sendSuccess(res, data);
});
