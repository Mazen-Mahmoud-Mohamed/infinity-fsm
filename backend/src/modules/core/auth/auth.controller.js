import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import authService from './auth.service.js';

export const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body, req);
  sendSuccess(res, result, 200);
});

export const refresh = asyncHandler(async (req, res) => {
  const result = await authService.refresh(req.body, req);
  sendSuccess(res, result, 200);
});

export const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.body, req, req.user);
  sendSuccess(res, { message: 'Logged out successfully' }, 200);
});

export const getMe = asyncHandler(async (req, res) => {
  const user = await authService.getMe(req.user._id);
  sendSuccess(res, user, 200);
});
