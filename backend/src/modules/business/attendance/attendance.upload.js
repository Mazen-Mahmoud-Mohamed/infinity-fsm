import { getCloudinary, isCloudinaryReady } from '../../../config/cloudinary.config.js';
import AppError from '../../../shared/errors/AppError.js';

export function uploadSelfieBuffer(buffer, { userId, action }) {
  if (!isCloudinaryReady()) {
    throw new AppError(
      'UPLOAD_UNAVAILABLE',
      'Selfie upload service is currently unavailable',
      503
    );
  }

  const cloudinary = getCloudinary();

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `attendance/${action}`,
        public_id: `${userId}_${Date.now()}`,
        resource_type: 'image',
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload selfie', 502, {
              reason: error.message,
            })
          );
        }
        return resolve(result.secure_url);
      }
    );

    stream.end(buffer);
  });
}
