import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import usersService from './users.service.js';

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await usersService.getDashboard(req.user);
  sendSuccess(res, data);
});

export const listUsers = asyncHandler(async (req, res) => {
  const {
    page = 1,
    limit = 20,
    search,
    status,
    role,
    departmentId,
    branchId,
  } = req.query;
  const result = await usersService.listUsers(req.user, {
    page,
    limit,
    search,
    status,
    role,
    departmentId,
    branchId,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getUser = asyncHandler(async (req, res) => {
  const data = await usersService.getUserById(req.user, req.params.id);
  sendSuccess(res, data);
});

export const createUser = asyncHandler(async (req, res) => {
  const data = await usersService.createUser(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const updateUser = asyncHandler(async (req, res) => {
  const data = await usersService.updateUser(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const setUserStatus = asyncHandler(async (req, res) => {
  const data = await usersService.setUserStatus(
    req.user,
    req.auth,
    req.params.id,
    req.body.status
  );
  sendSuccess(res, data);
});

export const deleteUser = asyncHandler(async (req, res) => {
  const data = await usersService.deleteUser(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const resetPassword = asyncHandler(async (req, res) => {
  const data = await usersService.resetPassword(
    req.user,
    req.auth,
    req.params.id,
    req.body.newPassword
  );
  sendSuccess(res, data);
});

export const changeOwnPassword = asyncHandler(async (req, res) => {
  const data = await usersService.changeOwnPassword(req.user, req.auth, req.body);
  sendSuccess(res, data);
});

export const uploadAvatar = asyncHandler(async (req, res) => {
  const data = await usersService.uploadAvatar(
    req.user,
    req.auth,
    req.params.id,
    req.file || null
  );
  sendSuccess(res, data);
});

export const listActivity = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, userId } = req.query;
  const result = await usersService.listActivity(req.user, {
    page,
    limit,
    userId,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});
