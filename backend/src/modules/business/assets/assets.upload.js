import { getCloudinary, isCloudinaryReady } from '../../../config/cloudinary.config.js';
import AppError from '../../../shared/errors/AppError.js';

export function uploadAssetImageBuffer(buffer, { companyId, assetNumber }) {
  if (!isCloudinaryReady()) {
    throw new AppError(
      'UPLOAD_UNAVAILABLE',
      'Photo upload service is currently unavailable',
      503
    );
  }

  const cloudinary = getCloudinary();
  const safeNumber = String(assetNumber || 'asset')
    .replace(/[^a-zA-Z0-9_-]/g, '_')
    .slice(0, 40);

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `assets/${companyId}`,
        public_id: `${safeNumber}_${Date.now()}`,
        resource_type: 'image',
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          return reject(
            new AppError('UPLOAD_FAILED', 'Failed to upload asset image', 502, {
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
