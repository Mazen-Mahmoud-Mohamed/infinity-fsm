import multer from 'multer';
import AppError from '../shared/errors/AppError.js';

const storage = multer.memoryStorage();

const IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const AUDIO_MIME_TYPES = [
  'audio/mp4',
  'audio/m4a',
  'audio/aac',
  'audio/mpeg',
  'audio/mp3',
  'audio/wav',
  'audio/x-wav',
  'audio/webm',
  'audio/ogg',
  'video/mp4', // some Android AAC encoders report this
];
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

/** Overtime checkpoint multipart: required photo + optional voiceNote. */
export const overtimeUpload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024,
    files: 2,
  },
  fileFilter: (_req, file, cb) => {
    if (file.fieldname === 'photo') {
      if (!IMAGE_MIME_TYPES.includes(file.mimetype)) {
        return cb(
          new AppError('INVALID_FILE_TYPE', 'Only JPEG, PNG, and WebP images are allowed', 400)
        );
      }
      return cb(null, true);
    }
    if (file.fieldname === 'voiceNote') {
      if (!AUDIO_MIME_TYPES.includes(file.mimetype)) {
        return cb(
          new AppError(
            'INVALID_FILE_TYPE',
            'Only AAC/M4A/MP3/WAV/OGG audio voice notes are allowed',
            400
          )
        );
      }
      return cb(null, true);
    }
    return cb(new AppError('INVALID_FILE_TYPE', 'Unexpected upload field', 400));
  },
});

export const overtimeMultipart = overtimeUpload.fields([
  { name: 'photo', maxCount: 1 },
  { name: 'voiceNote', maxCount: 1 },
]);

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
