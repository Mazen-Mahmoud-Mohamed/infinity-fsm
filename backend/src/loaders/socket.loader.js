import { Server as SocketServer } from 'socket.io';
import jwt from 'jsonwebtoken';
import config from '../config/index.js';
import logger from '../shared/utils/logger.util.js';

export function initializeSocket(httpServer) {
  const io = new SocketServer(httpServer, {
    cors: {
      origin: config.socket.corsOrigins,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;

    if (!token) {
      return next(new Error('Authentication token is required'));
    }

    try {
      const decoded = jwt.verify(token, config.jwt.accessSecret);

      if (decoded.type !== 'access') {
        return next(new Error('Invalid token type'));
      }

      socket.user = {
        userId: decoded.sub,
        companyId: decoded.companyId,
        roles: decoded.roles,
      };

      return next();
    } catch {
      return next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket) => {
    const { userId, companyId } = socket.user;

    socket.join(`user:${userId}`);
    socket.join(`company:${companyId}`);

    logger.debug({ userId, socketId: socket.id }, 'Socket connected');

    socket.on('ping', () => {
      socket.emit('pong', { serverTime: new Date().toISOString() });
    });

    socket.on('disconnect', (reason) => {
      logger.debug({ userId, reason }, 'Socket disconnected');
    });
  });

  logger.info('Socket.IO initialized');
  return io;
}

export default { initializeSocket };
