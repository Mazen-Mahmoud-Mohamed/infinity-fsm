import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import assetsService from './assets.service.js';

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await assetsService.getDashboard(req.user, req.auth);
  sendSuccess(res, data);
});

export const listCategories = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, isActive } = req.query;
  const result = await assetsService.listCategories(req.user, req.auth, {
    page,
    limit,
    search,
    isActive,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getCategory = asyncHandler(async (req, res) => {
  const data = await assetsService.getCategoryById(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const createCategory = asyncHandler(async (req, res) => {
  const data = await assetsService.createCategory(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const updateCategory = asyncHandler(async (req, res) => {
  const data = await assetsService.updateCategory(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const deleteCategory = asyncHandler(async (req, res) => {
  const data = await assetsService.deleteCategory(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listAssets = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, status, categoryId, branchId } = req.query;
  const result = await assetsService.listAssets(req.user, req.auth, {
    page,
    limit,
    search,
    status,
    categoryId,
    branchId,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getAsset = asyncHandler(async (req, res) => {
  const data = await assetsService.getAssetById(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const createAsset = asyncHandler(async (req, res) => {
  const data = await assetsService.createAsset(
    req.user,
    req.auth,
    req.body,
    req.file || null
  );
  sendSuccess(res, data, 201);
});

export const updateAsset = asyncHandler(async (req, res) => {
  const data = await assetsService.updateAsset(
    req.user,
    req.auth,
    req.params.id,
    req.body,
    req.file || null
  );
  sendSuccess(res, data);
});

export const deleteAsset = asyncHandler(async (req, res) => {
  const data = await assetsService.deleteAsset(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const listHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, assetId, type, search } = req.query;
  const result = await assetsService.listHistory(req.user, req.auth, {
    page,
    limit,
    assetId,
    type,
    search,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const addHistory = asyncHandler(async (req, res) => {
  const data = await assetsService.addHistoryEvent(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});
