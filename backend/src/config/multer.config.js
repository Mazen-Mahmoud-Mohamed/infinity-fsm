import multer from 'multer';
import AppError from '../shared/errors/AppError.js';

const storage = multer.memoryStorage();

const IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const WORK_ORDER_MIME_TYPES = [
  ...IMAGE_MIME_TYPES,
  'application/pdf',
];

export const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 1,
  },
  fileFilter: (_req, file, cb) => {
    if (!IMAGE_MIME_TYPES.includes(file.mimetype)) {
      return cb(new AppError('INVALID_FILE_TYPE', 'Only JPEG, PNG, and WebP images are allowed', 400));
    }
    return cb(null, true);
  },
});

export const workOrderUpload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 5,
  },
  fileFilter: (_req, file, cb) => {
    if (!WORK_ORDER_MIME_TYPES.includes(file.mimetype)) {
      return cb(
        new AppError(
          'INVALID_FILE_TYPE',
          'Only JPEG, PNG, WebP images and PDF documents are allowed',
          400
        )
      );
    }
    return cb(null, true);
  },
});

export default upload;
