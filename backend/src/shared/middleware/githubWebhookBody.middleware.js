/**
 * GitHub release webhook HMAC requires the original raw request bytes.
 * Global express.json() must skip this path so express.raw() can read the stream.
 */
export const GITHUB_RELEASE_WEBHOOK_PATH =
  '/api/v1/releases/webhook/github';

export function isGithubReleaseWebhookRequest(req) {
  const path = String(req.originalUrl || req.url || '').split('?')[0];
  return path === GITHUB_RELEASE_WEBHOOK_PATH;
}
