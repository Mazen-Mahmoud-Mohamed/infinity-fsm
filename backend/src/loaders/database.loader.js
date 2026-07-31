import mongoose from 'mongoose';
import config from '../config/index.js';
import logger from '../shared/utils/logger.util.js';

export async function connectDatabase() {
  mongoose.set('strictQuery', true);

  mongoose.connection.on('error', (error) => {
    logger.error({ err: error }, 'MongoDB connection error');
  });

  mongoose.connection.on('disconnected', () => {
    logger.warn('MongoDB disconnected');
  });

  await mongoose.connect(config.mongodb.uri, {
    autoIndex: config.isDevelopment,
  });

  logger.info('MongoDB connected');

  return mongoose.connection;
}

export async function disconnectDatabase() {
  if (mongoose.connection.readyState === 0) {
    return;
  }

  await mongoose.disconnect();
  logger.info('MongoDB disconnected gracefully');
}

export default { connectDatabase, disconnectDatabase };
