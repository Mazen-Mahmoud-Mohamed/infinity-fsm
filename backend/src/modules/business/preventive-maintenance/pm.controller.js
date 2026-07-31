import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import pmService from './pm.service.js';

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await pmService.getDashboard(req.user, req.auth);
  sendSuccess(res, data);
});

export const listPlans = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, status, frequency, priority } = req.query;
  const result = await pmService.listPlans(req.user, req.auth, {
    page,
    limit,
    search,
    status,
    frequency,
    priority,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getPlan = asyncHandler(async (req, res) => {
  const data = await pmService.getPlanById(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const createPlan = asyncHandler(async (req, res) => {
  const data = await pmService.createPlan(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const updatePlan = asyncHandler(async (req, res) => {
  const data = await pmService.updatePlan(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const deletePlan = asyncHandler(async (req, res) => {
  const data = await pmService.deletePlan(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const updateChecklist = asyncHandler(async (req, res) => {
  const data = await pmService.updateChecklist(
    req.user,
    req.auth,
    req.params.id,
    req.body.checklistItems
  );
  sendSuccess(res, data);
});

export const generateSchedules = asyncHandler(async (req, res) => {
  const data = await pmService.generateSchedules(
    req.user,
    req.auth,
    req.params.id,
    { count: req.body.count }
  );
  sendSuccess(res, data, 201);
});

export const listSchedules = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, status, planId, from, to } = req.query;
  const result = await pmService.listSchedules(req.user, req.auth, {
    page,
    limit,
    search,
    status,
    planId,
    from,
    to,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getSchedule = asyncHandler(async (req, res) => {
  const data = await pmService.getScheduleById(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const completeSchedule = asyncHandler(async (req, res) => {
  const data = await pmService.completeSchedule(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const cancelSchedule = asyncHandler(async (req, res) => {
  const data = await pmService.cancelSchedule(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const listHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, planId } = req.query;
  const result = await pmService.listHistory(req.user, req.auth, {
    page,
    limit,
    search,
    planId,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});
