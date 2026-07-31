import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import rbacService from './rbac.service.js';

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await rbacService.getDashboard(req.user);
  sendSuccess(res, data);
});

export const listRoles = asyncHandler(async (req, res) => {
  const result = await rbacService.listRoles(req.user, req.query);
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getPermissionCatalog = asyncHandler(async (_req, res) => {
  const data = rbacService.getPermissionCatalog();
  sendSuccess(res, data);
});

export const getRole = asyncHandler(async (req, res) => {
  const data = await rbacService.getRoleById(req.user, req.params.id);
  sendSuccess(res, data);
});

export const createRole = asyncHandler(async (req, res) => {
  const data = await rbacService.createRole(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const updateRole = asyncHandler(async (req, res) => {
  const data = await rbacService.updateRole(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const setRoleStatus = asyncHandler(async (req, res) => {
  const data = await rbacService.setRoleStatus(
    req.user,
    req.auth,
    req.params.id,
    req.body.isActive
  );
  sendSuccess(res, data);
});

export const deleteRole = asyncHandler(async (req, res) => {
  const data = await rbacService.deleteRole(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const cloneRole = asyncHandler(async (req, res) => {
  const data = await rbacService.cloneRole(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data, 201);
});

export const listRoleUsers = asyncHandler(async (req, res) => {
  const result = await rbacService.listRoleUsers(
    req.user,
    req.params.id,
    req.query
  );
  sendSuccess(
    res,
    { role: result.role, items: result.items },
    200,
    { pagination: result.pagination }
  );
});

export const assignRoleToUsers = asyncHandler(async (req, res) => {
  const data = await rbacService.assignRoleToUsers(
    req.user,
    req.auth,
    req.params.id,
    req.body.userIds
  );
  sendSuccess(res, data);
});
