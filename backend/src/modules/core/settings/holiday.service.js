import Holiday from './models/holiday.model.js';
import AppError, {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from '../../../shared/errors/AppError.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import {
  compareYmdStrings,
  isValidYmdDate,
  normalizeYmdDate,
  normalizeYmdDateList,
} from './holiday.date.js';

function mapHoliday(doc) {
  if (!doc) return null;
  return {
    id: doc._id?.toString?.() || String(doc._id),
    date: doc.date,
    name: doc.name || null,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

class HolidayService {
  _assertPermission(auth, permission) {
    if (!auth?.permissions?.includes(permission)) {
      throw new ForbiddenError('Missing required permissions', {
        requiredPermissions: [permission],
      });
    }
  }

  _companyId(user) {
    const companyId = user?.companyId;
    if (!companyId) {
      throw new AppError('COMPANY_REQUIRED', 'User has no company', 400);
    }
    return companyId;
  }

  /**
   * Authenticated company read (technicians included).
   */
  async listHolidays(user, _auth, query = {}) {
    const companyId = this._companyId(user);
    const from = query.from ? normalizeYmdDate(query.from) : null;
    const to = query.to ? normalizeYmdDate(query.to) : null;

    if (query.from && !from) {
      throw new ValidationError([
        { field: 'from', message: 'from must be YYYY-MM-DD', code: 'INVALID_DATE' },
      ]);
    }
    if (query.to && !to) {
      throw new ValidationError([
        { field: 'to', message: 'to must be YYYY-MM-DD', code: 'INVALID_DATE' },
      ]);
    }
    if (from && to && compareYmdStrings(from, to) > 0) {
      throw new ValidationError([
        { field: 'to', message: 'to must be on or after from', code: 'INVALID_RANGE' },
      ]);
    }

    const filter = { companyId };
    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = from;
      if (to) filter.date.$lte = to;
    }

    const docs = await Holiday.find(filter).sort({ date: 1 }).lean();
    return {
      holidays: docs.map(mapHoliday),
      dates: docs.map((d) => d.date),
    };
  }

  /**
   * Replace all holidays in [from, to] with the provided dates set.
   * Dates outside the range are rejected.
   */
  async replaceHolidaysInRange(user, auth, body = {}) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE_HOLIDAYS);
    const companyId = this._companyId(user);

    const from = normalizeYmdDate(body.from);
    const to = normalizeYmdDate(body.to);
    if (!from || !to) {
      throw new ValidationError([
        {
          field: !from ? 'from' : 'to',
          message: 'from and to must be YYYY-MM-DD',
          code: 'INVALID_DATE',
        },
      ]);
    }
    if (compareYmdStrings(from, to) > 0) {
      throw new ValidationError([
        { field: 'to', message: 'to must be on or after from', code: 'INVALID_RANGE' },
      ]);
    }

    const rawDates = Array.isArray(body.dates) ? body.dates : null;
    if (!rawDates) {
      throw new ValidationError([
        { field: 'dates', message: 'dates must be an array', code: 'VALIDATION_ERROR' },
      ]);
    }

    const { dates, invalid } = normalizeYmdDateList(rawDates);
    if (invalid.length > 0) {
      throw new ValidationError([
        {
          field: 'dates',
          message: 'One or more dates are invalid',
          code: 'INVALID_DATE',
          details: invalid.slice(0, 20),
        },
      ]);
    }

    for (const date of dates) {
      if (compareYmdStrings(date, from) < 0 || compareYmdStrings(date, to) > 0) {
        throw new ValidationError([
          {
            field: 'dates',
            message: `Date ${date} is outside the from/to range`,
            code: 'DATE_OUT_OF_RANGE',
          },
        ]);
      }
    }

    await Holiday.deleteMany({
      companyId,
      date: { $gte: from, $lte: to },
    });

    if (dates.length > 0) {
      const docs = dates.map((date) => ({
        companyId,
        date,
        name: null,
        createdBy: user._id,
      }));
      try {
        await Holiday.insertMany(docs, { ordered: true });
      } catch (error) {
        if (error?.code === 11000) {
          throw new ValidationError([
            {
              field: 'dates',
              message: 'Duplicate holiday date',
              code: 'DUPLICATE_HOLIDAY',
            },
          ]);
        }
        throw error;
      }
    }

    return this.listHolidays(user, auth, { from, to });
  }

  async createHoliday(user, auth, body = {}) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE_HOLIDAYS);
    const companyId = this._companyId(user);
    const date = normalizeYmdDate(body.date);
    if (!date) {
      throw new ValidationError([
        { field: 'date', message: 'date must be YYYY-MM-DD', code: 'INVALID_DATE' },
      ]);
    }

    const name =
      typeof body.name === 'string' && body.name.trim()
        ? body.name.trim().slice(0, 200)
        : null;

    try {
      const doc = await Holiday.create({
        companyId,
        date,
        name,
        createdBy: user._id,
      });
      return mapHoliday(doc.toObject());
    } catch (error) {
      if (error?.code === 11000) {
        throw new ValidationError([
          {
            field: 'date',
            message: 'Holiday already exists for this date',
            code: 'DUPLICATE_HOLIDAY',
          },
        ]);
      }
      throw error;
    }
  }

  async deleteHolidayByDate(user, auth, dateParam) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE_HOLIDAYS);
    const companyId = this._companyId(user);
    const date = normalizeYmdDate(dateParam);
    if (!date) {
      throw new ValidationError([
        { field: 'date', message: 'date must be YYYY-MM-DD', code: 'INVALID_DATE' },
      ]);
    }

    const deleted = await Holiday.findOneAndDelete({ companyId, date }).lean();
    if (!deleted) {
      throw new NotFoundError('Holiday');
    }
    return mapHoliday(deleted);
  }

  /**
   * Lightweight loader for overtime/Excel — returns YYYY-MM-DD strings only.
   * @param {import('mongoose').Types.ObjectId|string} companyId
   * @param {string} [from]
   * @param {string} [to]
   * @returns {Promise<string[]>}
   */
  async getDateKeysForCompany(companyId, from, to) {
    if (!companyId) return [];
    const filter = { companyId };
    if (from || to) {
      filter.date = {};
      if (from && isValidYmdDate(from)) filter.date.$gte = from;
      if (to && isValidYmdDate(to)) filter.date.$lte = to;
    }
    const docs = await Holiday.find(filter).select('date').sort({ date: 1 }).lean();
    return docs.map((d) => d.date);
  }
}

const holidayService = new HolidayService();
export default holidayService;
