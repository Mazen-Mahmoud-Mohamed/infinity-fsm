import pino from 'pino';
import config from '../../config/index.js';

const transport =
  config.isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined;

const logger = pino(
  {
    level: config.logging.level,
    base: { service: 'infinity-fsm-api' },
    redact: {
      paths: ['req.headers.authorization', 'password', 'passwordHash', 'refreshToken'],
      remove: true,
    },
  },
  transport ? pino.transport(transport) : undefined
);

export default logger;
