import { getCloudinary, isCloudinaryReady } from '../../../config/cloudinary.config.js';
import AppError from '../../../shared/errors/AppError.js';

export function uploadOvertimePhotoBuffer(buffer, { userId, photoType }) {
  if (!isCloudinaryReady()) {
    throw new AppError(
      'UPLOAD_UNAVAILABLE',
      'Photo upload service is currently unavailable',
      503
    );
  }

  const cloudinary = getCloudinary();

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `overtime/${photoType}`,
        public_id: `${userId}_${Date.now()}`,
        resource_type: 'image',
        format: 'jpg',
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload overtime photo', 502, {
              reason: error.message,
            })
          );
        }
        return resolve({
          url: result.secure_url,
          publicId: result.public_id,
        });
      }
    );

    stream.end(buffer);
  });
}

/**
 * Uploads an optional stage voice note.
 * Cloudinary stores audio under resource_type "video".
 */
export function uploadOvertimeVoiceNoteBuffer(buffer, { userId, stageKey, format }) {
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
        folder: `overtime/voice/${stageKey || 'stage'}`,
        public_id: `${userId}_voice_${Date.now()}`,
        resource_type: 'video',
        format: safeFormat,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload overtime voice note', 502, {
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
