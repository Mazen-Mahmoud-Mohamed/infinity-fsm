import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import pinoHttp from 'pino-http';
import config from './config/index.js';
import logger from './shared/utils/logger.util.js';
import requestIdMiddleware from './shared/middleware/requestId.middleware.js';
import { globalRateLimiter } from './shared/middleware/rateLimiter.middleware.js';
import errorHandler from './shared/middleware/errorHandler.middleware.js';
import notFoundHandler from './shared/middleware/notFound.middleware.js';
import apiRoutes from './routes/index.js';

export function createApp() {
  const app = express();

  app.locals.apiVersion = config.server.apiVersion;

  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(
    cors({
      origin: config.cors.origins,
      credentials: true,
    })
  );
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));
  app.use(requestIdMiddleware);
  app.use(
    pinoHttp({
      logger,
      genReqId: (req) => req.requestId,
      customProps: (req) => ({
        requestId: req.requestId,
      }),
      serializers: {
        req: (req) => ({
          method: req.method,
          url: req.url,
          requestId: req.requestId,
        }),
        res: (res) => ({
          statusCode: res.statusCode,
        }),
      },
    })
  );
  app.use(globalRateLimiter);

  app.use('/api', apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

export default createApp;
