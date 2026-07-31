import Company from './models/company.model.js';
import Branch from './models/branch.model.js';
import Department from './models/department.model.js';
import Team from './models/team.model.js';
import Position from './models/position.model.js';
import User from './models/user.model.js';
import WorkOrder from '../../business/work-orders/models/workOrder.model.js';
import { NotFoundError } from '../../../shared/errors/AppError.js';

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function mapStatus(isActive) {
  return isActive ? 'ACTIVE' : 'INACTIVE';
}

function mapTimestamps(doc) {
  return {
    createdAt: doc.createdAt?.toISOString?.() ?? null,
    updatedAt: doc.updatedAt?.toISOString?.() ?? null,
  };
}

class OrganizationService {
  async getMyContext(user) {
    const [company, branch, department, team, position] = await Promise.all([
      Company.findById(user.companyId),
      Branch.findOne({ _id: user.branchId, deletedAt: null }),
      Department.findOne({ _id: user.departmentId, deletedAt: null }),
      user.teamId ? Team.findOne({ _id: user.teamId, deletedAt: null }) : null,
      user.positionId
        ? Position.findOne({ _id: user.positionId, deletedAt: null })
        : null,
    ]);

    return {
      company: company ? this._mapCompany(company) : null,
      branch: branch ? this._mapBranch(branch) : null,
      department: department ? this._mapDepartment(department) : null,
      team: team ? this._mapTeam(team) : null,
      position: position ? this._mapPosition(position) : null,
    };
  }

  async getSummary(companyId) {
    const [
      employees,
      departments,
      teams,
      branches,
      positions,
      workOrders,
    ] = await Promise.all([
      User.countDocuments({ companyId, deletedAt: null, isActive: true }),
      Department.countDocuments({ companyId, deletedAt: null }),
      Team.countDocuments({ companyId, deletedAt: null }),
      Branch.countDocuments({ companyId, deletedAt: null }),
      Position.countDocuments({ companyId, deletedAt: null }),
      WorkOrder.countDocuments({ companyId, deletedAt: null }),
    ]);

    return {
      employees,
      departments,
      teams,
      branches,
      positions,
      assets: 0,
      workOrders,
      attendance: 0,
      overtime: 0,
    };
  }

  async listCompanies(companyId) {
    const company = await Company.findById(companyId);
    if (!company) {
      throw new NotFoundError('Company');
    }
    return [this._mapCompany(company)];
  }

  async getCompany(companyId, id) {
    if (companyId.toString() !== id.toString()) {
      throw new NotFoundError('Company');
    }
    const company = await Company.findById(id);
    if (!company) {
      throw new NotFoundError('Company');
    }
    return this._mapCompany(company);
  }

  async listBranches(companyId, { search } = {}) {
    const filter = { companyId, deletedAt: null };
    if (search) {
      filter.$or = [
        { name: new RegExp(search, 'i') },
        { code: new RegExp(search, 'i') },
      ];
    }
    const items = await Branch.find(filter).sort({ name: 1 });
    return items.map((item) => this._mapBranch(item));
  }

  async getBranch(companyId, id) {
    const item = await Branch.findOne({ _id: id, companyId, deletedAt: null });
    if (!item) {
      throw new NotFoundError('Branch');
    }
    return this._mapBranch(item);
  }

  async listDepartments(companyId, { search, branchId } = {}) {
    const filter = { companyId, deletedAt: null };
    if (branchId) {
      filter.branchId = branchId;
    }
    if (search) {
      filter.$or = [
        { name: new RegExp(search, 'i') },
        { code: new RegExp(search, 'i') },
      ];
    }
    const items = await Department.find(filter).sort({ name: 1 });
    return items.map((item) => this._mapDepartment(item));
  }

  async getDepartment(companyId, id) {
    const item = await Department.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    });
    if (!item) {
      throw new NotFoundError('Department');
    }
    return this._mapDepartment(item);
  }

  async listTeams(companyId, { search, departmentId } = {}) {
    const filter = { companyId, deletedAt: null };
    if (departmentId) {
      filter.departmentId = departmentId;
    }
    if (search) {
      filter.$or = [
        { name: new RegExp(search, 'i') },
        { code: new RegExp(search, 'i') },
      ];
    }
    const items = await Team.find(filter).sort({ name: 1 });
    return items.map((item) => this._mapTeam(item));
  }

  async getTeam(companyId, id) {
    const item = await Team.findOne({ _id: id, companyId, deletedAt: null });
    if (!item) {
      throw new NotFoundError('Team');
    }
    return this._mapTeam(item);
  }

  async listPositions(companyId, { search } = {}) {
    const filter = { companyId, deletedAt: null };
    if (search) {
      filter.$or = [
        { name: new RegExp(search, 'i') },
        { code: new RegExp(search, 'i') },
      ];
    }
    const items = await Position.find(filter).sort({ name: 1 });
    return items.map((item) => this._mapPosition(item));
  }

  async getPosition(companyId, id) {
    const item = await Position.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    });
    if (!item) {
      throw new NotFoundError('Position');
    }
    return this._mapPosition(item);
  }

  async listUsers(companyId, { search, branchId, departmentId, teamId } = {}) {
    const filter = { companyId, deletedAt: null };
    if (branchId) {
      filter.branchId = branchId;
    }
    if (departmentId) {
      filter.departmentId = departmentId;
    }
    if (teamId) {
      filter.teamId = teamId;
    }
    if (search) {
      filter.$or = [
        { firstName: new RegExp(search, 'i') },
        { lastName: new RegExp(search, 'i') },
        { email: new RegExp(search, 'i') },
        { employeeId: new RegExp(search, 'i') },
      ];
    }

    const items = await User.find(filter)
      .select('-passwordHash -permissionOverrides')
      .sort({ firstName: 1, lastName: 1 });

    return items.map((item) => this._mapUserSummary(item));
  }

  async getUser(companyId, id) {
    const item = await User.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    }).select('-passwordHash -permissionOverrides');

    if (!item) {
      throw new NotFoundError('User');
    }
    return this._mapUserSummary(item);
  }

  _mapCompany(doc) {
    return {
      id: toId(doc._id),
      code: doc.slug,
      name: doc.name,
      status: mapStatus(doc.isActive),
      logoUrl: doc.logoUrl,
      contactEmail: doc.contactEmail || null,
      contactPhone: doc.contactPhone || null,
      address: doc.address || null,
      timezone: doc.timezone || null,
      enabledModules: doc.enabledModules || [],
      ...mapTimestamps(doc),
    };
  }

  _mapBranch(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      code: doc.code,
      name: doc.name,
      status: mapStatus(doc.isActive),
      address: doc.address || null,
      ...mapTimestamps(doc),
    };
  }

  _mapDepartment(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      branchId: toId(doc.branchId),
      regionId: toId(doc.regionId),
      cityId: toId(doc.cityId),
      code: doc.code,
      name: doc.name,
      status: mapStatus(doc.isActive),
      supervisorIds: (doc.supervisorIds || []).map(toId),
      ...mapTimestamps(doc),
    };
  }

  _mapTeam(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      branchId: toId(doc.branchId),
      regionId: toId(doc.regionId),
      cityId: toId(doc.cityId),
      departmentId: toId(doc.departmentId),
      code: doc.code,
      name: doc.name,
      status: mapStatus(doc.isActive),
      leadId: toId(doc.leadId),
      ...mapTimestamps(doc),
    };
  }

  _mapPosition(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      code: doc.code,
      name: doc.name,
      status: mapStatus(doc.isActive),
      description: doc.description,
      ...mapTimestamps(doc),
    };
  }

  _mapUserSummary(doc) {
    const status =
      doc.status === 'LOCKED'
        ? 'LOCKED'
        : doc.status === 'DISABLED'
          ? 'INACTIVE'
          : doc.status === 'ACTIVE'
            ? 'ACTIVE'
            : mapStatus(doc.isActive);
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      code: doc.employeeId,
      name: doc.fullName || `${doc.firstName} ${doc.lastName}`,
      status,
      employeeId: doc.employeeId,
      email: doc.email,
      firstName: doc.firstName,
      lastName: doc.lastName,
      fullName: doc.fullName || `${doc.firstName} ${doc.lastName}`,
      phone: doc.phone,
      avatarUrl: doc.avatarUrl,
      roles: doc.roles || [],
      branchId: toId(doc.branchId),
      regionId: toId(doc.regionId),
      cityId: toId(doc.cityId),
      departmentId: toId(doc.departmentId),
      teamId: toId(doc.teamId),
      positionId: toId(doc.positionId),
      ...mapTimestamps(doc),
    };
  }
}

export default new OrganizationService();
