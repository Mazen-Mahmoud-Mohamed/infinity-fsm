import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import {
  handleGithubReleaseWebhook,
  verifyGithubSignature,
} from './releases.webhook.js';

export const githubReleaseWebhook = asyncHandler(async (req, res) => {
  const rawBody = req.rawBody;
  if (!Buffer.isBuffer(rawBody) || rawBody.length === 0) {
    res.status(400).json({
      success: false,
      message: 'Missing raw request body',
    });
    return;
  }

  const signatureHeader = req.headers['x-hub-signature-256'];
  if (!signatureHeader) {
    res.status(401).json({
      success: false,
      message: 'Invalid webhook signature',
    });
    return;
  }

  if (!verifyGithubSignature(rawBody, signatureHeader)) {
    res.status(401).json({
      success: false,
      message: 'Invalid webhook signature',
    });
    return;
  }

  let payload;
  try {
    payload = JSON.parse(rawBody.toString('utf8'));
  } catch {
    res.status(400).json({
      success: false,
      message: 'Invalid JSON payload',
    });
    return;
  }

  const result = await handleGithubReleaseWebhook({
    payload,
    io: req.app.get('io'),
  });

  sendSuccess(res, result);
});
