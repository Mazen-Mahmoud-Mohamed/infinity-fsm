import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import dashboardService from './dashboard.service.js';

export const getSummary = asyncHandler(async (req, res) => {
  const data = await dashboardService.getSummary(req.auth, req.query);
  return sendSuccess(res, data);
});
