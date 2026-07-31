import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import attendanceService from './attendance.service.js';

export const clockIn = asyncHandler(async (req, res) => {
  const data = await attendanceService.clockIn(req.user, req.body, req.file);
  sendSuccess(res, data, 201);
});

export const clockOut = asyncHandler(async (req, res) => {
  const data = await attendanceService.clockOut(req.user, req.body, req.file);
  sendSuccess(res, data, 200);
});

export const breakStart = asyncHandler(async (req, res) => {
  const data = await attendanceService.breakStart(req.user, req.body);
  sendSuccess(res, data, 201);
});

export const breakEnd = asyncHandler(async (req, res) => {
  const data = await attendanceService.breakEnd(req.user, req.body);
  sendSuccess(res, data, 200);
});

export const getStatus = asyncHandler(async (req, res) => {
  const data = await attendanceService.getStatus(req.user);
  sendSuccess(res, data);
});

export const getToday = asyncHandler(async (req, res) => {
  const data = await attendanceService.getToday(req.user);
  sendSuccess(res, data);
});

export const getHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, startDate, endDate } = req.query;
  const result = await attendanceService.getHistory(req.user, {
    page,
    limit,
    startDate,
    endDate,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const updateGpsAddress = asyncHandler(async (req, res) => {
  const data = await attendanceService.updateGpsAddress(req.user, req.body);
  sendSuccess(res, data);
});
