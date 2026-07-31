import { getCloudinary, isCloudinaryReady } from '../../../config/cloudinary.config.js';
import AppError from '../../../shared/errors/AppError.js';

export function uploadSignatureImageBuffer(buffer, { companyId }) {
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
        folder: `service-reports/${companyId}/signatures`,
        public_id: `sig_${Date.now()}`,
        resource_type: 'image',
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError(
              'UPLOAD_FAILED',
              'Failed to upload signature image',
              502,
              { reason: error.message }
            )
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
