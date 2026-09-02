import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import releasesService from './releases.service.js';

export const getLatestRelease = asyncHandler(async (req, res) => {
  const channel = req.query.channel || 'stable';
  const data = await releasesService.getLatestRelease(channel);

  sendSuccess(res, data ?? {
    version: null,
    build: null,
    channel,
    releaseDate: null,
    releaseNotes: null,
    windows: { available: false },
    android: { available: false },
  });
});
