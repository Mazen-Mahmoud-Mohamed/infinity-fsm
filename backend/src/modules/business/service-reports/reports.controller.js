import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import reportsService from './reports.service.js';

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await reportsService.getDashboard(req.user);
  sendSuccess(res, data);
});

export const listReports = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, status } = req.query;
  const result = await reportsService.listReports(req.user, {
    page,
    limit,
    search,
    status,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getReport = asyncHandler(async (req, res) => {
  const data = await reportsService.getReportById(req.user, req.params.id);
  sendSuccess(res, data);
});

export const generateReport = asyncHandler(async (req, res) => {
  const data = await reportsService.generateReport(
    req.user,
    req.auth,
    req.body
  );
  sendSuccess(res, data, 201);
});

export const downloadReport = asyncHandler(async (req, res) => {
  const data = await reportsService.downloadReport(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});

export const listSignatures = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search } = req.query;
  const result = await reportsService.listSignatures(req.user, {
    page,
    limit,
    search,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getSignature = asyncHandler(async (req, res) => {
  const data = await reportsService.getSignatureById(req.user, req.params.id);
  sendSuccess(res, data);
});

export const createSignature = asyncHandler(async (req, res) => {
  const data = await reportsService.createSignature(
    req.user,
    req.auth,
    req.body,
    req.file || null
  );
  sendSuccess(res, data, 201);
});

export const deleteSignature = asyncHandler(async (req, res) => {
  const data = await reportsService.deleteSignature(
    req.user,
    req.auth,
    req.params.id
  );
  sendSuccess(res, data);
});
