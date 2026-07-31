import AppError from '../../../shared/errors/AppError.js';

export function displayUserName(user) {
  if (!user) {
    return null;
  }
  return `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email || null;
}

export function pushTimeline(record, { type, user, note = null, at = new Date() }) {
  if (!Array.isArray(record.timeline)) {
    record.timeline = [];
  }
  record.timeline.push({
    type,
    at,
    userId: user?._id || null,
    userName: displayUserName(user),
    note: note?.toString?.()?.trim?.() || null,
  });
}

export function parseFieldLocation(body, { required = false } = {}) {
  const hasCoords =
    body.latitude !== undefined &&
    body.latitude !== '' &&
    body.longitude !== undefined &&
    body.longitude !== '';

  if (!hasCoords) {
    if (required) {
      throw new AppError(
        'LOCATION_REQUIRED',
        'latitude and longitude are required',
        422
      );
    }
    return null;
  }

  const latitude = Number(body.latitude);
  const longitude = Number(body.longitude);
  if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
    throw new AppError('INVALID_LOCATION', 'Invalid GPS coordinates', 422);
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw new AppError('INVALID_LOCATION', 'GPS coordinates out of range', 422);
  }

  let recordedAt = new Date();
  if (body.recordedAt) {
    const parsed = new Date(body.recordedAt);
    if (Number.isNaN(parsed.getTime())) {
      throw new AppError('INVALID_DATE', 'recordedAt must be a valid ISO date', 422);
    }
    recordedAt = parsed;
  }

  return {
    latitude,
    longitude,
    accuracy:
      body.accuracy !== undefined && body.accuracy !== ''
        ? Number(body.accuracy)
        : null,
    address: body.address?.toString?.()?.trim?.() || null,
    recordedAt,
  };
}

export function mapPhoto(item) {
  return {
    url: item.url,
    publicId: item.publicId || null,
    fileName: item.fileName || null,
    mimeType: item.mimeType || null,
    uploadedAt: item.uploadedAt?.toISOString?.() || null,
    uploadedBy: item.uploadedBy?.toString?.() || null,
  };
}

export function mapFieldLocation(loc) {
  if (!loc) {
    return null;
  }
  return {
    latitude: loc.latitude,
    longitude: loc.longitude,
    accuracy: loc.accuracy ?? null,
    address: loc.address || null,
    recordedAt: loc.recordedAt?.toISOString?.() || null,
  };
}

export function mapProgressNote(note) {
  return {
    id: note._id?.toString?.() || null,
    text: note.text,
    createdAt: note.createdAt?.toISOString?.() || null,
    createdBy: note.createdBy?.toString?.() || null,
    createdByName: note.createdByName || null,
  };
}

export function mapTimelineEvent(event) {
  return {
    type: event.type,
    at: event.at?.toISOString?.() || null,
    userId: event.userId?.toString?.() || null,
    userName: event.userName || null,
    note: event.note || null,
  };
}

export const PHOTO_CATEGORIES = Object.freeze(['before', 'progress', 'after']);

export function photoFieldForCategory(category) {
  switch (category) {
    case 'before':
      return 'beforePhotos';
    case 'progress':
      return 'progressPhotos';
    case 'after':
      return 'afterPhotos';
    default:
      throw new AppError('INVALID_CATEGORY', 'Invalid photo category', 422);
  }
}
