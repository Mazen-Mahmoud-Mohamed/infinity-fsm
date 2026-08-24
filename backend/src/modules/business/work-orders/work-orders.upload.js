import { getCloudinary, isCloudinaryReady } from '../../../config/cloudinary.config.js';
import AppError from '../../../shared/errors/AppError.js';

export function uploadWorkOrderAttachmentBuffer(buffer, { companyId, fileName, mimeType }) {
  if (!isCloudinaryReady()) {
    throw new AppError(
      'UPLOAD_UNAVAILABLE',
      'Attachment upload service is currently unavailable',
      503
    );
  }

  const cloudinary = getCloudinary();
  const isPdf = mimeType === 'application/pdf';
  const resourceType = isPdf ? 'raw' : 'image';
  const safeName = (fileName || 'attachment')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .slice(0, 80);

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `work-orders/${companyId}`,
        public_id: `${Date.now()}_${safeName}`,
        resource_type: resourceType,
        // Force JPEG for images so Flutter Windows never receives AVIF/auto.
        ...(isPdf ? {} : { format: 'jpg' }),
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload work order attachment', 502, {
              reason: error.message,
            })
          );
        }
        return resolve({
          url: result.secure_url,
          publicId: result.public_id,
          fileName: fileName || null,
          mimeType: mimeType || null,
          uploadedAt: new Date(),
        });
      }
    );

    stream.end(buffer);
  });
}

/**
 * Uploads an optional work-order voice note.
 * Cloudinary stores audio under resource_type "video" (same as overtime).
 */
export function uploadWorkOrderVoiceNoteBuffer(buffer, { companyId, format }) {
  if (!isCloudinaryReady()) {
    throw new AppError(
      'UPLOAD_UNAVAILABLE',
      'Voice note upload service is currently unavailable',
      503
    );
  }

  const cloudinary = getCloudinary();
  const safeFormat =
    (format || 'm4a').replace(/[^a-z0-9]/gi, '').toLowerCase() || 'm4a';

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `work-orders/${companyId}/voice`,
        public_id: `voice_${Date.now()}`,
        resource_type: 'video',
        format: safeFormat,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload work order voice note', 502, {
              reason: error.message,
            })
          );
        }
        return resolve({
          url: result.secure_url,
          publicId: result.public_id,
          duration:
            typeof result.duration === 'number' && Number.isFinite(result.duration)
              ? result.duration
              : null,
          size:
            typeof result.bytes === 'number' && Number.isFinite(result.bytes)
              ? result.bytes
              : buffer?.length || null,
          format: result.format || safeFormat,
          uploadedAt: new Date(),
        });
      }
    );

    stream.end(buffer);
  });
}
