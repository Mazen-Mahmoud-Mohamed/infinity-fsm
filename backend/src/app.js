import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import pinoHttp from 'pino-http';
import config from './config/index.js';
import logger from './shared/utils/logger.util.js';
import requestIdMiddleware from './shared/middleware/requestId.middleware.js';
import { globalRateLimiter } from './shared/middleware/rateLimiter.middleware.js';
import { isGithubReleaseWebhookRequest } from './shared/middleware/githubWebhookBody.middleware.js';
import errorHandler from './shared/middleware/errorHandler.middleware.js';
import notFoundHandler from './shared/middleware/notFound.middleware.js';
import apiRoutes from './routes/index.js';

const jsonBodyParser = express.json({ limit: '10mb' });
const urlencodedBodyParser = express.urlencoded({
  extended: true,
  limit: '10mb',
});

/**
 * Skip body parsers that consume the stream for the GitHub release webhook.
 * That route uses express.raw() so HMAC can verify the original bytes.
 */
function skipGithubWebhookBodyParsers(parser) {
  return (req, res, next) => {
    if (isGithubReleaseWebhookRequest(req)) {
      return next();
    }
    return parser(req, res, next);
  };
}

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
  app.use(skipGithubWebhookBodyParsers(jsonBodyParser));
  app.use(skipGithubWebhookBodyParsers(urlencodedBodyParser));
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
