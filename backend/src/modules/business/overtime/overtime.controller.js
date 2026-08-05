import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import overtimeService from './overtime.service.js';

function pickMultipartFiles(req) {
  // Compatible with multer.fields (req.files) and legacy single (req.file).
  const photo = req.files?.photo?.[0] || req.file || null;
  const voiceNote = req.files?.voiceNote?.[0] || null;
  return { photo, voiceNote };
}

export const getRunning = asyncHandler(async (req, res) => {
  const data = await overtimeService.getRunning(req.user);
  sendSuccess(res, data);
});

export const startSession = asyncHandler(async (req, res) => {
  const { photo, voiceNote } = pickMultipartFiles(req);
  const data = await overtimeService.start(req.user, req.body, photo, voiceNote);
  sendSuccess(res, data, 201);
});

export const endSession = asyncHandler(async (req, res) => {
  const { photo, voiceNote } = pickMultipartFiles(req);
  const data = await overtimeService.end(
    req.user,
    req.params.id,
    req.body,
    photo,
    voiceNote
  );
  sendSuccess(res, data);
});

export const recordArrivedAtWorkSite = asyncHandler(async (req, res) => {
  const { photo, voiceNote } = pickMultipartFiles(req);
  const data = await overtimeService.recordCheckpoint(
    req.user,
    req.params.id,
    'arrivedAtWorkSite',
    req.body,
    photo,
    voiceNote
  );
  sendSuccess(res, data);
});

export const recordFinishedWork = asyncHandler(async (req, res) => {
  const { photo, voiceNote } = pickMultipartFiles(req);
  const data = await overtimeService.recordCheckpoint(
    req.user,
    req.params.id,
    'finishedWork',
    req.body,
    photo,
    voiceNote
  );
  sendSuccess(res, data);
});

export const listSessions = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, status, search } = req.query;
  const result = await overtimeService.listSessions(req.user, req.auth, {
    page,
    limit,
    status,
    search,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const exportExcel = asyncHandler(async (req, res) => {
  const result = await overtimeService.exportExcel(req.user, req.auth, req.query);
  res.setHeader('Content-Type', result.mimeType);
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${result.fileName}"`
  );
  res.setHeader('X-Export-Row-Count', String(result.rowCount));
  res.status(200).send(result.buffer);
});

export const listMine = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, status } = req.query;
  const result = await overtimeService.listMine(req.user, {
    page,
    limit,
    status,
  });
  sendSuccess(res, result.items, 200, { pagination: result.pagination });
});

export const getSession = asyncHandler(async (req, res) => {
  const data = await overtimeService.getById(req.user, req.auth, req.params.id);
  sendSuccess(res, data);
});

export const approveSession = asyncHandler(async (req, res) => {
  const data = await overtimeService.approve(req.user, req.auth, req.params.id, {
    reviewNotes: req.body.reviewNotes,
  });
  sendSuccess(res, data);
});

export const rejectSession = asyncHandler(async (req, res) => {
  const data = await overtimeService.reject(req.user, req.auth, req.params.id, {
    rejectionReason: req.body.rejectionReason,
    reviewNotes: req.body.reviewNotes,
  });
  sendSuccess(res, data);
});

export const getDashboardStats = asyncHandler(async (req, res) => {
  const data = await overtimeService.getDashboardStats(req.auth);
  sendSuccess(res, data);
});

export const updateGpsAddress = asyncHandler(async (req, res) => {
  const data = await overtimeService.updateGpsAddress(
    req.user,
    req.params.id,
    req.body
  );
  sendSuccess(res, data);
});
