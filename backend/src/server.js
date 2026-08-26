import http from 'http';
import config, { validateConfig } from './config/index.js';
import logger from './shared/utils/logger.util.js';
import { createApp } from './app.js';
import { connectDatabase, disconnectDatabase } from './loaders/database.loader.js';
import { initializeSocket } from './loaders/socket.loader.js';
import { initializeCloudinary } from './config/cloudinary.config.js';
import { setSocketIo } from './shared/utils/socket.registry.js';

let isShuttingDown = false;

async function bootstrap() {
  validateConfig();

  await connectDatabase();
  initializeCloudinary();

  const app = createApp();
  const httpServer = http.createServer(app);
  const io = initializeSocket(httpServer);

  app.set('io', io);
  setSocketIo(io);

  httpServer.listen(config.server.port, '0.0.0.0', () => {
    logger.info(
      {
        port: config.server.port,
        host: '0.0.0.0',
        env: config.env,
        apiVersion: config.server.apiVersion,
      },
      'Infinity FSM API server started'
    );
  });

  const shutdown = async (signal) => {
    if (isShuttingDown) {
      return;
    }

    isShuttingDown = true;
    logger.info({ signal }, 'Shutdown signal received');

    await new Promise((resolve, reject) => {
      httpServer.close((error) => {
        if (error) {
          reject(error);
          return;
        }
        resolve();
      });
    });

    await new Promise((resolve) => {
      io.close(() => resolve());
    });

    await disconnectDatabase();
    logger.info('Server shut down gracefully');
    process.exit(0);
  };

  const forceShutdown = (error, origin) => {
    logger.error({ err: error, origin }, 'Fatal error — forcing shutdown');
    process.exit(1);
  };

  process.on('SIGTERM', () => {
    shutdown('SIGTERM').catch((error) => forceShutdown(error, 'SIGTERM'));
  });

  process.on('SIGINT', () => {
    shutdown('SIGINT').catch((error) => forceShutdown(error, 'SIGINT'));
  });

  process.on('unhandledRejection', (reason) => {
    forceShutdown(reason, 'unhandledRejection');
  });

  process.on('uncaughtException', (error) => {
    forceShutdown(error, 'uncaughtException');
  });
}

bootstrap().catch((error) => {
  logger.error({ err: error }, 'Failed to start server');
  process.exit(1);
});
