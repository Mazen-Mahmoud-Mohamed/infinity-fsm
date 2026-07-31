import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import workOrdersService from './work-orders.service.js';

export const listWorkOrders = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, status, search } = req.query;
  const result = await workOrdersService.list(req.user, req.auth, {
    page,
    limit,
    status,
    search,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const listMyAssignments = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, status, search } = req.query;
  const result = await workOrdersService.listMyAssignments(req.user, {
    page,
    limit,
    status,
    search,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.getById(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const createWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.create(
    req.user,
    req.auth,
    req.body,
    req.files || []
  );
  sendSuccess(res, data, 201);
});

export const updateWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.update(
    req.user,
    req.auth,
    req.params.id,
    req.body,
    req.files || []
  );
  sendSuccess(res, data);
});

export const deleteWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.softDelete(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const assignWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.assign(req.user, req.auth, req.params.id, req.body);
  sendSuccess(res, data);
});

export const acceptWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.accept(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const rejectWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.reject(req.user, req.auth, req.params.id, {
    rejectionReason: req.body.rejectionReason,
  });
  sendSuccess(res, data);
});

export const startWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.start(req.user, req.auth, req.params.id, req.body);
  sendSuccess(res, data);
});

export const completeWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.complete(req.user, req.auth, req.params.id, req.body);
  sendSuccess(res, data);
});

export const cancelWorkOrder = asyncHandler(async (req, res) => {
  const data = await workOrdersService.cancel(req.user, req.auth, req.params.id, {
    cancellationReason: req.body.cancellationReason,
  });
  sendSuccess(res, data);
});

export const saveBeforeWork = asyncHandler(async (req, res) => {
  const data = await workOrdersService.saveBeforeWork(
    req.user,
    req.auth,
    req.params.id,
    req.body,
    req.files || []
  );
  sendSuccess(res, data);
});

export const addProgressNote = asyncHandler(async (req, res) => {
  const data = await workOrdersService.addProgressNote(req.user, req.auth, req.params.id, {
    text: req.body.text,
  });
  sendSuccess(res, data);
});

export const addProgressPhotos = asyncHandler(async (req, res) => {
  const data = await workOrdersService.addProgressPhotos(
    req.user,
    req.auth,
    req.params.id,
    req.files || []
  );
  sendSuccess(res, data);
});

export const addAfterPhotos = asyncHandler(async (req, res) => {
  const data = await workOrdersService.addAfterPhotos(
    req.user,
    req.auth,
    req.params.id,
    req.files || []
  );
  sendSuccess(res, data);
});

export const removePhoto = asyncHandler(async (req, res) => {
  const data = await workOrdersService.removePhoto(req.user, req.auth, req.params.id, {
    category: req.body.category,
    url: req.body.url,
  });
  sendSuccess(res, data);
});
