import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import inventoryService from './inventory.service.js';

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await inventoryService.getDashboard(req.user, req.auth);
  sendSuccess(res, data);
});

export const listWarehouses = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, isActive } = req.query;
  const result = await inventoryService.listWarehouses(req.user, req.auth, {
    page,
    limit,
    search,
    isActive,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getWarehouse = asyncHandler(async (req, res) => {
  const data = await inventoryService.getWarehouseById(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const createWarehouse = asyncHandler(async (req, res) => {
  const data = await inventoryService.createWarehouse(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const updateWarehouse = asyncHandler(async (req, res) => {
  const data = await inventoryService.updateWarehouse(
    req.user,
    req.auth,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});

export const deleteWarehouse = asyncHandler(async (req, res) => {
  const data = await inventoryService.deleteWarehouse(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listSpareParts = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, category, stockStatus, isActive } = req.query;
  const result = await inventoryService.listSpareParts(req.user, req.auth, {
    page,
    limit,
    search,
    category,
    stockStatus,
    isActive,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getSparePart = asyncHandler(async (req, res) => {
  const data = await inventoryService.getSparePartById(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const createSparePart = asyncHandler(async (req, res) => {
  const data = await inventoryService.createSparePart(
    req.user,
    req.auth,
    req.body,
    req.file || null
  );
  sendSuccess(res, data, 201);
});

export const updateSparePart = asyncHandler(async (req, res) => {
  const data = await inventoryService.updateSparePart(
    req.user,
    req.auth,
    req.params.id,
    req.body,
    req.file || null
  );
  sendSuccess(res, data);
});

export const deleteSparePart = asyncHandler(async (req, res) => {
  const data = await inventoryService.deleteSparePart(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listMovements = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, sparePartId, type, warehouseId, search } = req.query;
  const result = await inventoryService.listMovements(req.user, req.auth, {
    page,
    limit,
    sparePartId,
    type,
    warehouseId,
    search,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const stockIn = asyncHandler(async (req, res) => {
  const data = await inventoryService.stockIn(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const stockOut = asyncHandler(async (req, res) => {
  const data = await inventoryService.stockOut(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const transfer = asyncHandler(async (req, res) => {
  const data = await inventoryService.transfer(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});

export const adjustment = asyncHandler(async (req, res) => {
  const data = await inventoryService.adjustment(req.user, req.auth, req.body);
  sendSuccess(res, data, 201);
});
