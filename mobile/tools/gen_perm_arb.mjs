import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

/**
 * Regenerates permission label/description ARB keys.
 * Prefer editing app_en.arb / app_ar.arb directly for UX wording polish;
 * re-running this script overwrites those refined descriptions.
 */

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const enPath = path.join(__dirname, '../lib/core/localization/l10n/app_en.arb');
const arPath = path.join(__dirname, '../lib/core/localization/l10n/app_ar.arb');

/** @type {Array<[string, string, string]>} id, en, ar */
const groups = [
  [
    'Dashboard',
    'Permissions for viewing system statistics and key performance indicators.',
    'الصلاحيات الخاصة بعرض إحصائيات النظام والمؤشرات الرئيسية.',
  ],
  [
    'Users',
    'Permissions for managing user accounts across the organization.',
    'الصلاحيات الخاصة بإدارة حسابات المستخدمين.',
  ],
  [
    'Roles',
    'Permissions for managing roles and assigning access rights.',
    'الصلاحيات الخاصة بإدارة الأدوار وتوزيع الصلاحيات.',
  ],
  [
    'Attendance',
    'Permissions for reviewing and managing employee attendance records.',
    'الصلاحيات الخاصة بإدارة ومراجعة سجلات حضور الموظفين.',
  ],
  [
    'Overtime',
    'Permissions for creating, approving, and managing overtime sessions.',
    'الصلاحيات الخاصة بإنشاء واعتماد وإدارة جلسات العمل الإضافي.',
  ],
  [
    'Inventory',
    'Permissions for managing inventory items and stock quantities.',
    'الصلاحيات الخاصة بإدارة الأصناف والكميات داخل المخزون.',
  ],
  [
    'Assets',
    'Permissions for managing and tracking organization assets.',
    'الصلاحيات الخاصة بإدارة وتتبع أصول المؤسسة.',
  ],
  [
    'Maintenance',
    'Permissions for maintenance plans and related operations.',
    'الصلاحيات الخاصة بخطط الصيانة والعمليات المرتبطة بها.',
  ],
  [
    'ServiceReports',
    'Permissions for viewing, generating, and downloading service reports.',
    'الصلاحيات الخاصة بعرض وإنشاء وتنزيل تقارير الخدمة.',
  ],
  [
    'WorkOrders',
    'Permissions for creating, managing, and completing work orders.',
    'الصلاحيات الخاصة بإنشاء وإدارة وتنفيذ أوامر العمل.',
  ],
  [
    'Settings',
    'Permissions for system and organization configuration settings.',
    'الصلاحيات الخاصة بإعدادات النظام والمؤسسة.',
  ],
  [
    'Profile',
    'Permissions for managing the signed-in user personal profile.',
    'الصلاحيات الخاصة بإدارة الملف الشخصي للمستخدم.',
  ],
  [
    'Notifications',
    'Permissions for sending, receiving, and managing notifications.',
    'الصلاحيات الخاصة بالإشعارات وإرسالها واستقبالها.',
  ],
  [
    'Organization',
    'Permissions for managing company structure, branches, and departments.',
    'الصلاحيات الخاصة بإدارة هيكل المؤسسة والفروع والأقسام.',
  ],
  [
    'Audit',
    'Permissions for reviewing activity history and system change logs.',
    'الصلاحيات الخاصة بمراجعة سجل الأنشطة والتغييرات.',
  ],
  [
    'General',
    'General platform permissions not tied to a specific module.',
    'صلاحيات عامة في المنصة غير مرتبطة بوحدة محددة.',
  ],
];

/**
 * [id, key, enLabel, arLabel, enDesc, arDesc]
 * Descriptions: one concise sentence (≈10–20 words) explaining real effect + scope.
 * @type {Array<[string, string, string, string, string, string]>}
 */
const perms = [
  [
    'OrganizationView',
    'organization:view',
    'View organization',
    'عرض المؤسسة',
    'Lets the user browse company structure, branches, and directory screens.',
    'يسمح للمستخدم بالاطلاع على هيكل المؤسسة والفروع وشاشات الدليل.',
  ],
  [
    'OrganizationManageBranches',
    'organization:manage_branches',
    'Manage branches',
    'إدارة الفروع',
    'Lets the user create and edit company branches used across the organization.',
    'يسمح بإنشاء وتعديل فروع الشركة المستخدمة على مستوى المؤسسة.',
  ],
  [
    'OrganizationManageRegions',
    'organization:manage_regions',
    'Manage regions',
    'إدارة المناطق',
    'Lets the user create and edit geographic regions used for organization mapping.',
    'يسمح بإنشاء وتعديل المناطق الجغرافية المستخدمة في هيكل المؤسسة.',
  ],
  [
    'OrganizationManageCities',
    'organization:manage_cities',
    'Manage cities',
    'إدارة المدن',
    'Lets the user create and edit cities linked to branches and field operations.',
    'يسمح بإنشاء وتعديل المدن المرتبطة بالفروع والعمليات الميدانية.',
  ],
  [
    'OrganizationManageDepartments',
    'organization:manage_departments',
    'Manage departments',
    'إدارة الأقسام',
    'Lets the user create and edit departments that organize users and teams.',
    'يسمح بإنشاء وتعديل الأقسام التي تنظّم المستخدمين والفرق.',
  ],
  [
    'OrganizationManageTeams',
    'organization:manage_teams',
    'Manage teams',
    'إدارة الفرق',
    'Lets the user create and edit operational teams and their membership.',
    'يسمح بإنشاء وتعديل فرق العمل وأعضائها التشغيليين.',
  ],
  [
    'OrganizationManageUsers',
    'organization:manage_users',
    'Manage organization users',
    'إدارة مستخدمي المؤسسة',
    'Lets the user place users into branches, departments, and teams.',
    'يسمح بتعيين المستخدمين ضمن الفروع والأقسام والفرق.',
  ],
  [
    'SettingsView',
    'settings:view',
    'View settings',
    'عرض الإعدادات',
    'Lets the user open system settings screens without changing any values.',
    'يسمح بفتح شاشات إعدادات النظام دون تعديل أي قيم.',
  ],
  [
    'SettingsManage',
    'settings:manage',
    'Manage system settings',
    'إدارة إعدادات النظام',
    'Lets the user change general settings that affect all system users.',
    'يسمح بتعديل الإعدادات العامة التي تؤثر على جميع مستخدمي النظام.',
  ],
  [
    'SettingsUpdate',
    'settings:update',
    'Update system settings',
    'تعديل إعدادات النظام',
    'Lets the user save changes to system configuration values organization-wide.',
    'يسمح بحفظ تعديلات قيم إعدادات النظام على مستوى المؤسسة.',
  ],
  [
    'SettingsManageHolidays',
    'settings:manage_holidays',
    'Manage holidays',
    'إدارة العطل',
    'Lets the user define company holidays that affect attendance and overtime.',
    'يسمح بتعريف عطل الشركة التي تؤثر على الحضور والعمل الإضافي.',
  ],
  [
    'AuditView',
    'audit:view',
    'View audit log',
    'عرض سجل التدقيق',
    'Lets the user review activity and security change logs across the organization.',
    'يسمح بمراجعة سجل الأنشطة والتغييرات الأمنية على مستوى المؤسسة.',
  ],
  [
    'DashboardView',
    'dashboard:view',
    'View dashboard',
    'عرض لوحة التحكم',
    'Lets the user see system statistics and key performance indicators.',
    'يسمح للمستخدم بمشاهدة الإحصائيات والمؤشرات الرئيسية الخاصة بالنظام.',
  ],
  [
    'RbacManageRoles',
    'rbac:manage_roles',
    'Manage roles & permissions',
    'إدارة الأدوار والصلاحيات',
    'Lets the user fully control roles and which permissions each role receives.',
    'يسمح بالتحكم الكامل في الأدوار والصلاحيات المعينة لكل دور.',
  ],
  [
    'RbacManagePermissions',
    'rbac:manage_permissions',
    'Manage permissions',
    'إدارة الصلاحيات',
    'Lets the user control how permissions are assigned from the access catalog.',
    'يسمح بالتحكم في كيفية تعيين الصلاحيات من كتالوج الوصول.',
  ],
  [
    'RolesView',
    'roles:view',
    'View roles',
    'عرض الأدوار',
    'Lets the user open the roles list and review existing role definitions.',
    'يسمح بفتح قائمة الأدوار ومراجعة تعريفات الأدوار الحالية.',
  ],
  [
    'RolesCreate',
    'roles:create',
    'Create roles',
    'إضافة الأدوار',
    'Lets the user create new roles and choose the permissions they include.',
    'يسمح بإنشاء أدوار جديدة وتحديد الصلاحيات الخاصة بها.',
  ],
  [
    'RolesUpdate',
    'roles:update',
    'Update roles',
    'تعديل الأدوار',
    'Lets the user change names and permissions of existing roles.',
    'يسمح بتعديل صلاحيات وأسماء الأدوار الموجودة.',
  ],
  [
    'RolesDelete',
    'roles:delete',
    'Delete roles',
    'حذف الأدوار',
    'Lets the user permanently remove roles that are no longer needed.',
    'يسمح بحذف الأدوار التي لم يعد هناك حاجة إليها بشكل دائم.',
  ],
  [
    'RolesManage',
    'roles:manage',
    'Manage roles & permissions',
    'إدارة الأدوار والصلاحيات',
    'Lets the user create, edit, and assign roles and their permission sets.',
    'يسمح بإنشاء وتعديل وتعيين الأدوار ومجموعات صلاحياتها.',
  ],
  [
    'AttendanceViewOwn',
    'attendance:view_own',
    'View own attendance',
    'عرض الحضور الخاص',
    'Lets the user review only their own personal attendance records.',
    'يسمح للمستخدم بمراجعة سجلات حضوره الشخصي فقط.',
  ],
  [
    'AttendanceViewTeam',
    'attendance:view_team',
    'View team attendance',
    'عرض حضور الفريق',
    'Lets the user see attendance records for members of their own team.',
    'يسمح للمستخدم بالاطلاع على سجلات حضور أعضاء الفريق التابع له.',
  ],
  [
    'AttendanceViewAll',
    'attendance:view_all',
    'View all attendance',
    'عرض كل الحضور',
    'Lets the user view every attendance record across the organization.',
    'يسمح للمستخدم بعرض جميع سجلات الحضور داخل المؤسسة.',
  ],
  [
    'AttendanceManageOwn',
    'attendance:manage_own',
    'Manage own attendance',
    'إدارة الحضور الخاص',
    'Lets the user create and update only their own attendance punches.',
    'يسمح بإنشاء وتعديل سجلات الحضور الشخصية للمستخدم فقط.',
  ],
  [
    'AttendanceView',
    'attendance:view',
    'View attendance',
    'عرض الحضور',
    'Lets the user open attendance screens for records within their access scope.',
    'يسمح بفتح شاشات الحضور للسجلات ضمن نطاق صلاحية المستخدم.',
  ],
  [
    'AttendanceUpdate',
    'attendance:update',
    'Manage attendance',
    'إدارة الحضور',
    'Lets the user create, edit, approve, and manage attendance records.',
    'يسمح بإنشاء وتعديل واعتماد وإدارة سجلات الحضور.',
  ],
  [
    'AttendanceApprove',
    'attendance:approve',
    'Approve attendance',
    'اعتماد الحضور',
    'Lets the user approve attendance records before they are finalized.',
    'يسمح باعتماد سجلات الحضور قبل تثبيتها بشكل نهائي.',
  ],
  [
    'OvertimeViewOwn',
    'overtime:view_own',
    'View own overtime',
    'عرض العمل الإضافي الخاص',
    'Lets the user review only their own overtime sessions and status.',
    'يسمح بمراجعة جلسات العمل الإضافي الخاصة بالمستخدم وحالتها فقط.',
  ],
  [
    'OvertimeViewTeam',
    'overtime:view_team',
    'View team overtime',
    'عرض العمل الإضافي للفريق',
    'Lets the user see overtime sessions belonging to their team members.',
    'يسمح بالاطلاع على جلسات العمل الإضافي الخاصة بأعضاء الفريق.',
  ],
  [
    'OvertimeViewAll',
    'overtime:view_all',
    'View all overtime',
    'عرض كل العمل الإضافي',
    'Lets the user view every overtime session across the organization.',
    'يسمح بعرض جميع جلسات العمل الإضافي داخل المؤسسة.',
  ],
  [
    'OvertimeCreate',
    'overtime:create',
    'Create overtime',
    'إنشاء العمل الإضافي',
    'Lets the user create new overtime requests for employees.',
    'يسمح بإنشاء طلبات عمل إضافي جديدة للموظفين.',
  ],
  [
    'OvertimeStart',
    'overtime:start',
    'Start overtime',
    'بدء العمل الإضافي',
    'Lets the user begin an overtime session and record its start time and location.',
    'يسمح ببدء جلسة عمل إضافي وتسجيل وقت وموقع البداية.',
  ],
  [
    'OvertimeEnd',
    'overtime:end',
    'End overtime',
    'إنهاء العمل الإضافي',
    'Lets the user finish an active overtime session and submit its end details.',
    'يسمح بإنهاء جلسة عمل إضافي نشطة وتسليم تفاصيل الإغلاق.',
  ],
  [
    'OvertimeCancel',
    'overtime:cancel',
    'Cancel overtime',
    'إلغاء العمل الإضافي',
    'Lets the user cancel an overtime session so it is not counted as worked time.',
    'يسمح بإلغاء جلسة عمل إضافي حتى لا تُحتسب ضمن وقت العمل.',
  ],
  [
    'OvertimeApprove',
    'overtime:approve',
    'Approve overtime',
    'اعتماد العمل الإضافي',
    'Lets the user approve overtime requests before they are counted.',
    'يسمح بالموافقة على طلبات العمل الإضافي قبل احتسابها.',
  ],
  [
    'OvertimeReject',
    'overtime:reject',
    'Reject overtime',
    'رفض العمل الإضافي',
    'Lets the user reject overtime requests while keeping a record of the decision.',
    'يسمح برفض طلبات العمل الإضافي مع الاحتفاظ بسجل القرار.',
  ],
  [
    'OvertimeArchive',
    'overtime:archive',
    'Archive overtime',
    'أرشفة العمل الإضافي',
    'Lets the user archive completed overtime records to keep active lists focused.',
    'يسمح بأرشفة سجلات العمل الإضافي المكتملة لإبقاء القوائم النشطة مرتبة.',
  ],
  [
    'WorkOrdersViewOwn',
    'work_orders:view_own',
    'View own work orders',
    'عرض أوامر العمل الخاصة',
    'Lets the user see only work orders assigned to them.',
    'يسمح بعرض أوامر العمل المعينة للمستخدم فقط.',
  ],
  [
    'WorkOrdersViewTeam',
    'work_orders:view_team',
    'View team work orders',
    'عرض أوامر عمل الفريق',
    'Lets the user see work orders belonging to their team.',
    'يسمح بالاطلاع على أوامر العمل الخاصة بالفريق التابع للمستخدم.',
  ],
  [
    'WorkOrdersViewAll',
    'work_orders:view_all',
    'View all work orders',
    'عرض كل أوامر العمل',
    'Lets the user view every work order across the organization.',
    'يسمح بعرض جميع أوامر العمل داخل المؤسسة.',
  ],
  [
    'WorkOrdersCreate',
    'work_orders:create',
    'Create work orders',
    'إنشاء أوامر العمل',
    'Lets the user create new work orders and assign them to staff.',
    'يسمح بإنشاء أوامر عمل جديدة وتعيينها للموظفين.',
  ],
  [
    'WorkOrdersUpdate',
    'work_orders:update',
    'Update work orders',
    'تعديل أوامر العمل',
    'Lets the user edit details of existing work orders within allowed scope.',
    'يسمح بتعديل تفاصيل أوامر العمل الحالية ضمن النطاق المسموح.',
  ],
  [
    'WorkOrdersAssign',
    'work_orders:assign',
    'Assign work orders',
    'تعيين أوامر العمل',
    'Lets the user assign or reassign technicians on work order screens.',
    'يسمح بتعيين أو إعادة تعيين الفنيين من شاشات أوامر العمل.',
  ],
  [
    'WorkOrdersComplete',
    'work_orders:complete',
    'Complete work orders',
    'إكمال أوامر العمل',
    'Lets the user mark a work order as completed after the job is finished.',
    'يسمح بتغيير حالة أمر العمل إلى مكتمل بعد الانتهاء منه.',
  ],
  [
    'WorkOrdersCancel',
    'work_orders:cancel',
    'Cancel work orders',
    'إلغاء أوامر العمل',
    'Lets the user cancel work orders so they are no longer active for field staff.',
    'يسمح بإلغاء أوامر العمل حتى تتوقف عن الظهور كنشيطة للفريق الميداني.',
  ],
  [
    'WorkOrdersDelete',
    'work_orders:delete',
    'Delete work orders',
    'حذف أوامر العمل',
    'Lets the user permanently delete work orders from the organization records.',
    'يسمح بحذف أوامر العمل نهائياً من سجلات المؤسسة.',
  ],
  [
    'InventoryView',
    'inventory:view',
    'View inventory',
    'عرض المخزون',
    'Lets the user browse inventory items and available stock quantities.',
    'يسمح بالاطلاع على أصناف المخزون والكميات المتوفرة.',
  ],
  [
    'InventoryCreate',
    'inventory:create',
    'Create inventory items',
    'إضافة المخزون',
    'Lets the user register new inventory items in the stock catalog.',
    'يسمح بتسجيل أصناف مخزون جديدة في دليل المخزون.',
  ],
  [
    'InventoryUpdate',
    'inventory:update',
    'Update inventory',
    'تعديل المخزون',
    'Lets the user edit inventory item details such as names and attributes.',
    'يسمح بتعديل تفاصيل أصناف المخزون مثل الأسماء والخصائص.',
  ],
  [
    'InventoryDelete',
    'inventory:delete',
    'Delete inventory',
    'حذف المخزون',
    'Lets the user remove inventory items from the organization catalog.',
    'يسمح بحذف أصناف المخزون من دليل المؤسسة.',
  ],
  [
    'InventoryStockManage',
    'inventory:stock_manage',
    'Manage stock quantities',
    'إدارة المخزون والكميات',
    'Lets the user update available quantities and stock movements for items.',
    'يسمح بتحديث الكميات المتوفرة وحركة الأصناف داخل المخزون.',
  ],
  [
    'AssetsView',
    'assets:view',
    'View assets',
    'عرض الأصول',
    'Lets the user browse registered asset records in the system.',
    'يسمح بالاطلاع على بيانات الأصول المسجلة في النظام.',
  ],
  [
    'AssetsCreate',
    'assets:create',
    'Create assets',
    'إضافة الأصول',
    'Lets the user register new company assets in the asset register.',
    'يسمح بتسجيل أصول جديدة للشركة في سجل الأصول.',
  ],
  [
    'AssetsUpdate',
    'assets:update',
    'Update assets',
    'تعديل الأصول',
    'Lets the user edit asset details such as status, location, and attributes.',
    'يسمح بتعديل بيانات الأصول مثل الحالة والموقع والخصائص.',
  ],
  [
    'AssetsDelete',
    'assets:delete',
    'Delete assets',
    'حذف الأصول',
    'Lets the user permanently remove assets from the organization register.',
    'يسمح بحذف الأصول نهائياً من سجل المؤسسة.',
  ],
  [
    'AssetsAssign',
    'assets:assign',
    'Assign assets',
    'تخصيص الأصول',
    'Lets the user assign assets to users or locations within the organization.',
    'يسمح بتخصيص الأصول للمستخدمين أو المواقع داخل المؤسسة.',
  ],
  [
    'PmView',
    'pm:view',
    'View maintenance',
    'عرض الصيانة',
    'Lets the user open preventive maintenance plans and schedule screens.',
    'يسمح بفتح شاشات خطط وجداول الصيانة الوقائية.',
  ],
  [
    'PmCreate',
    'pm:create',
    'Create maintenance plans',
    'إنشاء خطط الصيانة',
    'Lets the user create periodic maintenance schedules and plans for assets.',
    'يسمح بإنشاء جداول وخطط الصيانة الدورية للأصول.',
  ],
  [
    'PmUpdate',
    'pm:update',
    'Update maintenance',
    'تعديل الصيانة',
    'Lets the user edit existing maintenance plans, dates, and related details.',
    'يسمح بتعديل خطط الصيانة الحالية ومواعيدها وتفاصيلها.',
  ],
  [
    'PmDelete',
    'pm:delete',
    'Delete maintenance',
    'حذف الصيانة',
    'Lets the user delete maintenance plans that are no longer required.',
    'يسمح بحذف خطط الصيانة التي لم يعد هناك حاجة إليها.',
  ],
  [
    'PmManage',
    'pm:manage',
    'Manage maintenance',
    'إدارة الصيانة',
    'Lets the user fully manage preventive maintenance plans and schedules.',
    'يسمح بالإدارة الكاملة لخطط وجداول الصيانة الوقائية.',
  ],
  [
    'MaintenanceManage',
    'maintenance:manage',
    'Manage maintenance operations',
    'إدارة عمليات الصيانة',
    'Lets the user manage maintenance operations and related work schedules.',
    'يسمح بإدارة عمليات الصيانة والجداول المرتبطة بها.',
  ],
  [
    'ReportsView',
    'reports:view',
    'View service reports',
    'عرض تقارير الخدمة',
    'Lets the user open and read completed service reports in the system.',
    'يسمح بفتح وقراءة تقارير الخدمة المكتملة داخل النظام.',
  ],
  [
    'ReportsGenerate',
    'reports:generate',
    'Generate service reports',
    'إنشاء تقارير الخدمة',
    'Lets the user generate new service reports from completed field work.',
    'يسمح بإنشاء تقارير خدمة جديدة من الأعمال الميدانية المكتملة.',
  ],
  [
    'ReportsDownload',
    'reports:download',
    'Download service reports',
    'تنزيل تقارير الخدمة',
    'Lets the user download service reports in shareable or printable formats.',
    'يسمح بتنزيل تقارير الخدمة بصيغ قابلة للمشاركة أو الطباعة.',
  ],
  [
    'UsersView',
    'users:view',
    'View users',
    'عرض المستخدمين',
    'Lets the user open the users list and view account details organization-wide.',
    'يسمح بفتح قائمة المستخدمين وعرض تفاصيل الحسابات على مستوى المؤسسة.',
  ],
  [
    'UsersCreate',
    'users:create',
    'Create users',
    'إضافة المستخدمين',
    'Lets the user create new user accounts inside the organization.',
    'يسمح بإنشاء حسابات مستخدمين جديدة داخل المؤسسة.',
  ],
  [
    'UsersUpdate',
    'users:update',
    'Update users',
    'تعديل المستخدمين',
    'Lets the user edit user profile, contact, and account details.',
    'يسمح بتعديل بيانات الملف الشخصي والاتصال وحساب المستخدم.',
  ],
  [
    'UsersDelete',
    'users:delete',
    'Delete users',
    'حذف المستخدمين',
    'Lets the user permanently remove user accounts from the organization.',
    'يسمح بحذف حسابات المستخدمين نهائياً من المؤسسة.',
  ],
  [
    'UsersRead',
    'users:read',
    'View users',
    'عرض المستخدمين',
    'Lets the user open the users list and view account details organization-wide.',
    'يسمح بفتح قائمة المستخدمين وعرض تفاصيل الحسابات على مستوى المؤسسة.',
  ],
  [
    'UsersResetPassword',
    'users:reset_password',
    'Reset password',
    'إعادة تعيين كلمة المرور',
    'Lets the user reset any user\'s password without knowing the current one.',
    'يسمح بإعادة تعيين كلمة مرور أي مستخدم دون معرفة كلمة المرور الحالية.',
  ],
];

function stripGeneratedBlock(text) {
  // Remove from first generated group-desc key through end of object.
  return text.replace(/,\n  "permGroupDashboardDesc"[\s\S]*\n\}\s*$/, '\n}\n');
}

function appendToArb(filePath, isAr) {
  let text = fs.readFileSync(filePath, 'utf8');
  text = stripGeneratedBlock(text);

  const lines = [];
  for (const [id, enDesc, arDesc] of groups) {
    lines.push(
      `  "permGroup${id}Desc": ${JSON.stringify(isAr ? arDesc : enDesc)},`,
    );
  }
  for (const [id, , enLabel, arLabel, enDesc, arDesc] of perms) {
    lines.push(`  "perm${id}": ${JSON.stringify(isAr ? arLabel : enLabel)},`);
    lines.push(
      `  "perm${id}Desc": ${JSON.stringify(isAr ? arDesc : enDesc)},`,
    );
  }
  if (lines.length > 0) {
    lines[lines.length - 1] = lines[lines.length - 1].replace(/,$/, '');
  }

  let before = text.replace(/\}\s*$/, '').trimEnd();
  if (!before.endsWith(',')) before += ',';
  const next = `${before}\n${lines.join('\n')}\n}\n`;
  fs.writeFileSync(filePath, next);
  console.log('Updated', filePath);
}

appendToArb(enPath, false);
appendToArb(arPath, true);
console.log(`Wrote ${perms.length} permissions and ${groups.length} group descriptions.`);
