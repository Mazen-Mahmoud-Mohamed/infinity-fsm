import { getCloudinary, isCloudinaryReady } from '../../../config/cloudinary.config.js';
import AppError from '../../../shared/errors/AppError.js';

export function uploadCompanyLogoBuffer(buffer, { companyId }) {
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
        folder: `companies/${companyId}/logo`,
        public_id: `logo_${Date.now()}`,
        resource_type: 'image',
        overwrite: true,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload company logo', 502, {
              reason: error.message,
            })
          );
        }
        return resolve({
          url: result.secure_url,
          publicId: result.public_id,
          bytes: result.bytes || 0,
        });
      }
    );

    stream.end(buffer);
  });
}
