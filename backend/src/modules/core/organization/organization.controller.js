import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import organizationService from './organization.service.js';

export const getMyContext = asyncHandler(async (req, res) => {
  const data = await organizationService.getMyContext(req.user);
  sendSuccess(res, data);
});

export const getSummary = asyncHandler(async (req, res) => {
  const data = await organizationService.getSummary(req.auth.companyId);
  sendSuccess(res, data);
});

export const listCompanies = asyncHandler(async (req, res) => {
  const data = await organizationService.listCompanies(req.auth.companyId);
  sendSuccess(res, data);
});

export const getCompany = asyncHandler(async (req, res) => {
  const data = await organizationService.getCompany(
    req.auth.companyId,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listBranches = asyncHandler(async (req, res) => {
  const data = await organizationService.listBranches(req.auth.companyId, {
    search: req.query.search,
  });
  sendSuccess(res, data);
});

export const getBranch = asyncHandler(async (req, res) => {
  const data = await organizationService.getBranch(
    req.auth.companyId,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listDepartments = asyncHandler(async (req, res) => {
  const data = await organizationService.listDepartments(req.auth.companyId, {
    search: req.query.search,
    branchId: req.query.branchId,
  });
  sendSuccess(res, data);
});

export const getDepartment = asyncHandler(async (req, res) => {
  const data = await organizationService.getDepartment(
    req.auth.companyId,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listTeams = asyncHandler(async (req, res) => {
  const data = await organizationService.listTeams(req.auth.companyId, {
    search: req.query.search,
    departmentId: req.query.departmentId,
  });
  sendSuccess(res, data);
});

export const getTeam = asyncHandler(async (req, res) => {
  const data = await organizationService.getTeam(
    req.auth.companyId,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listPositions = asyncHandler(async (req, res) => {
  const data = await organizationService.listPositions(req.auth.companyId, {
    search: req.query.search,
  });
  sendSuccess(res, data);
});

export const getPosition = asyncHandler(async (req, res) => {
  const data = await organizationService.getPosition(
    req.auth.companyId,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listUsers = asyncHandler(async (req, res) => {
  const data = await organizationService.listUsers(req.auth.companyId, {
    search: req.query.search,
    branchId: req.query.branchId,
    departmentId: req.query.departmentId,
    teamId: req.query.teamId,
  });
  sendSuccess(res, data);
});

export const getUser = asyncHandler(async (req, res) => {
  const data = await organizationService.getUser(
    req.auth.companyId,
    req.params.id
  );
  sendSuccess(res, data);
});
