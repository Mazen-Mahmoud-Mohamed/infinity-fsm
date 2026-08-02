import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import config from '../src/config/index.js';
import logger from '../src/shared/utils/logger.util.js';
import Company from '../src/modules/core/organization/models/company.model.js';
import Branch from '../src/modules/core/organization/models/branch.model.js';
import Region from '../src/modules/core/organization/models/region.model.js';
import City from '../src/modules/core/organization/models/city.model.js';
import Department from '../src/modules/core/organization/models/department.model.js';
import Team from '../src/modules/core/organization/models/team.model.js';
import Position from '../src/modules/core/organization/models/position.model.js';
import User from '../src/modules/core/organization/models/user.model.js';
import Setting from '../src/modules/core/settings/models/setting.model.js';
import Role from '../src/modules/core/rbac/models/role.model.js';
import rbacService from '../src/modules/core/rbac/rbac.service.js';
import { ROLES } from '../src/shared/constants/roles.constants.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const DEFAULT_SETTINGS = [
  { key: 'working_hours.start', value: '09:00', group: 'working_hours', dataType: 'string' },
  { key: 'working_hours.end', value: '17:00', group: 'working_hours', dataType: 'string' },
  { key: 'working_hours.timezone', value: 'Africa/Cairo', group: 'working_hours', dataType: 'string' },
  { key: 'overtime.allowed_types', value: ['REGULAR', 'TRAVEL'], group: 'overtime', dataType: 'array' },
  { key: 'overtime.gps_accuracy_limit_meters', value: 100, group: 'overtime', dataType: 'number' },
  { key: 'media.max_image_size_mb', value: 5, group: 'media', dataType: 'number' },
  { key: 'offline.retention_days', value: 30, group: 'offline', dataType: 'number' },
];

async function seed() {
  await mongoose.connect(config.mongodb.uri);
  logger.info('Connected to MongoDB for seeding');

  await Promise.all([
    Company.deleteMany({}),
    Branch.deleteMany({}),
    Region.deleteMany({}),
    City.deleteMany({}),
    Department.deleteMany({}),
    Team.deleteMany({}),
    Position.deleteMany({}),
    User.deleteMany({}),
    Setting.deleteMany({}),
    Role.deleteMany({}),
  ]);

  const company = await Company.create({
    name: 'Infinity Tech',
    slug: 'infinity-tech',
    enabledModules: ['overtime'],
  });

  const branch = await Branch.create({
    companyId: company._id,
    name: 'Baghdad HQ',
    code: 'BGW-HQ',
    address: {
      city: 'Baghdad',
      governorate: 'Baghdad',
      country: 'Iraq',
    },
  });

  const region = await Region.create({
    companyId: company._id,
    branchId: branch._id,
    name: 'Central Region',
    code: 'CENTRAL',
  });

  const city = await City.create({
    companyId: company._id,
    branchId: branch._id,
    regionId: region._id,
    name: 'Baghdad',
    code: 'BGW',
  });

  const department = await Department.create({
    companyId: company._id,
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    name: 'Field Operations',
    code: 'FIELD-OPS',
  });

  const team = await Team.create({
    companyId: company._id,
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    departmentId: department._id,
    name: 'Alpha Team',
    code: 'ALPHA',
  });

  const [adminPosition, technicianPosition] = await Position.insertMany([
    {
      companyId: company._id,
      name: 'System Administrator',
      code: 'SYS-ADMIN',
      description: 'Full platform administration',
    },
    {
      companyId: company._id,
      name: 'Field Technician',
      code: 'FIELD-TECH',
      description: 'Field service technician',
    },
    {
      companyId: company._id,
      name: 'Operations Supervisor',
      code: 'OPS-SUP',
      description: 'Field operations supervisor',
    },
  ]);

  const passwordHash = await User.hashPassword('Admin@12345');

  const admin = await User.create({
    companyId: company._id,
    employeeId: 'EMP-001',
    email: 'admin@infinity-tech.com',
    passwordHash,
    firstName: 'System',
    lastName: 'Admin',
    phone: '+9647700000001',
    roles: [ROLES.ADMIN],
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    departmentId: department._id,
    teamId: team._id,
    positionId: adminPosition._id,
  });

  await department.updateOne({ $push: { supervisorIds: admin._id } });

  const technicianPasswordHash = await User.hashPassword('Tech@12345');

  await User.create({
    companyId: company._id,
    employeeId: 'EMP-002',
    email: 'technician@infinity-tech.com',
    passwordHash: technicianPasswordHash,
    firstName: 'Field',
    lastName: 'Technician',
    phone: '+9647700000002',
    roles: [ROLES.TECHNICIAN],
    branchId: branch._id,
    regionId: region._id,
    cityId: city._id,
    departmentId: department._id,
    teamId: team._id,
    positionId: technicianPosition._id,
  });

  await Setting.insertMany(
    DEFAULT_SETTINGS.map((setting) => ({
      ...setting,
      companyId: company._id,
      updatedBy: admin._id,
    }))
  );

  await rbacService.ensureSystemRoles();

  logger.info('Seed completed successfully');
  logger.info('Admin login: admin@infinity-tech.com / Admin@12345');
  logger.info('Technician login: technician@infinity-tech.com / Tech@12345');

  await mongoose.disconnect();
}

seed().catch(async (error) => {
  logger.error({ err: error }, 'Seed failed');
  await mongoose.disconnect();
  process.exit(1);
});
