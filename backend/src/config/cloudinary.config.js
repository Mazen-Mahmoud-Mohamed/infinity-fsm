import { v2 as cloudinary } from 'cloudinary';
import config from './index.js';
import logger from '../shared/utils/logger.util.js';

let isInitialized = false;

export function initializeCloudinary() {
  if (!config.cloudinary.isConfigured()) {
    logger.warn('Cloudinary is not configured — image uploads will be unavailable');
    return null;
  }

  cloudinary.config({
    cloud_name: config.cloudinary.cloudName,
    api_key: config.cloudinary.apiKey,
    api_secret: config.cloudinary.apiSecret,
    secure: true,
  });

  isInitialized = true;
  logger.info('Cloudinary configured successfully');
  return cloudinary;
}

export function getCloudinary() {
  if (!isInitialized) {
    throw new Error('Cloudinary has not been initialized');
  }
  return cloudinary;
}

export function isCloudinaryReady() {
  return isInitialized;
}

export default { initializeCloudinary, getCloudinary, isCloudinaryReady };
