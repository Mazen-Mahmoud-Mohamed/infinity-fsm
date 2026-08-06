// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'INFINITY';

  @override
  String get companyName => 'Total-Com Solutions';

  @override
  String get splashLoading => 'Initializing...';

  @override
  String get login => 'Login';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Access your field service workspace';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get roleLabel => 'Role';

  @override
  String get companyLabel => 'Company';

  @override
  String get departmentLabel => 'Department';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get attendance => 'Attendance';

  @override
  String get overtime => 'Overtime';

  @override
  String get workOrders => 'Work Orders';

  @override
  String get assets => 'Assets';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsLoading => 'Loading notifications...';

  @override
  String get notificationsLoadFailed => 'Unable to load notifications.';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsSearchHint => 'Search notifications';

  @override
  String get notificationsSearchEmpty => 'No notifications match your search.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsUnread => 'Unread';

  @override
  String get notificationsRead => 'Read';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsCategoryGeneral => 'General';

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get globalSearch => 'Search';

  @override
  String get globalSearchHint => 'Search users, work orders, assets…';

  @override
  String get globalSearchPrompt =>
      'Type at least 2 characters to search across modules.';

  @override
  String get globalSearchEmpty => 'No results found.';

  @override
  String get globalSearchFailed => 'Unable to search right now.';

  @override
  String get globalSearchShortcutHint => 'Ctrl+K';

  @override
  String get reportsCenter => 'Reports Center';

  @override
  String get reportsCenterSearchHint => 'Search report records';

  @override
  String get reportsCenterFilters => 'Filters';

  @override
  String get reportsCenterApplyFilters => 'Apply filters';

  @override
  String get reportsCenterStatusFilter => 'Status';

  @override
  String get reportsCenterFilterAll => 'All';

  @override
  String get reportsCenterDateRange => 'Date range';

  @override
  String get reportsCenterCustomRange => 'Custom range';

  @override
  String get reportsCenterClearDates => 'Clear dates';

  @override
  String get reportsCenterEmployee => 'Employee';

  @override
  String get reportsCenterDepartment => 'Department';

  @override
  String get reportsCenterSort => 'Sort';

  @override
  String get reportsCenterSortTitleAsc => 'Title A–Z';

  @override
  String get reportsCenterSortTitleDesc => 'Title Z–A';

  @override
  String get reportsCenterSortDateAsc => 'Date oldest';

  @override
  String get reportsCenterSortDateDesc => 'Date newest';

  @override
  String get reportsCenterSortStatusAsc => 'Status A–Z';

  @override
  String get reportsCenterSortStatusDesc => 'Status Z–A';

  @override
  String get reportsCenterExport => 'Export';

  @override
  String get reportsCenterExportUnavailable => 'Export is not available yet.';

  @override
  String get reportsCenterFilterUnavailable =>
      'This filter is not supported by the current API.';

  @override
  String get reportsCenterEmpty => 'No records match the selected filters.';

  @override
  String get reportsCenterEmptyAttendance =>
      'No attendance records found for the selected filters.';

  @override
  String get reportsCenterEmptyOvertime =>
      'No overtime sessions found for the selected filters.';

  @override
  String get reportsCenterEmptyWorkOrders =>
      'No work orders found for the selected filters.';

  @override
  String get reportsCenterEmptyAssets =>
      'No assets found for the selected filters.';

  @override
  String get reportsCenterEmptyInventory =>
      'No inventory parts found for the selected filters.';

  @override
  String get reportsCenterEmptyPm =>
      'No maintenance plans found for the selected filters.';

  @override
  String get reportsCenterEmptyServiceReports =>
      'No service reports found for the selected filters.';

  @override
  String get reportsCenterLoadFailed => 'Unable to load report data.';

  @override
  String get reportsCenterNoAccess =>
      'You do not have access to any report modules.';

  @override
  String get reportsCenterColTitle => 'Title';

  @override
  String get reportsCenterColSubtitle => 'Reference';

  @override
  String get reportsCenterColDate => 'Date';

  @override
  String get reportsCenterColMeta => 'Details';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get add => 'Add';

  @override
  String get back => 'Back';

  @override
  String get update => 'Update';

  @override
  String get reject => 'Reject';

  @override
  String get retry => 'Retry';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get workOrderCreate => 'Create';

  @override
  String get workOrderEdit => 'Edit work order';

  @override
  String get workOrderDetails => 'Work order details';

  @override
  String get workOrderSearchHint => 'Search job, customer, or location';

  @override
  String get workOrderFilterAll => 'All';

  @override
  String get workOrderEmpty => 'No work orders found';

  @override
  String get workOrderLoadFailed => 'Failed to load work orders';

  @override
  String get workOrderLoading => 'Loading work orders...';

  @override
  String get workOrderJobTitle => 'Work order title';

  @override
  String get workOrderCustomer => 'Customer';

  @override
  String get workOrderLocation => 'Location';

  @override
  String get workOrderDescription => 'Problem description';

  @override
  String get workOrderNotes => 'Notes';

  @override
  String get workOrderPriority => 'Priority';

  @override
  String get workOrderScheduledDate => 'Scheduled date';

  @override
  String get workOrderTechnician => 'Technician';

  @override
  String get workOrderAttachments => 'Attachments';

  @override
  String get workOrderSave => 'Save';

  @override
  String get workOrderAccept => 'Accept';

  @override
  String get workOrderReject => 'Reject';

  @override
  String get workOrderStart => 'Start work';

  @override
  String get workOrderComplete => 'Complete';

  @override
  String get workOrderCancel => 'Cancel order';

  @override
  String get workOrderDelete => 'Delete';

  @override
  String get workOrderAssign => 'Assign technician';

  @override
  String get workOrderUnassigned => 'Unassigned';

  @override
  String get workOrderSelectTechnician => 'Select technician';

  @override
  String get workOrderAddPhoto => 'Add photo';

  @override
  String get inventory => 'Inventory';

  @override
  String get inventoryManage => 'Manage';

  @override
  String get inventoryLoading => 'Loading inventory...';

  @override
  String get inventoryLoadFailed => 'Failed to load inventory';

  @override
  String get inventoryTotalParts => 'Total Parts';

  @override
  String get inventoryLowStock => 'Low Stock';

  @override
  String get inventoryOutOfStock => 'Out of Stock';

  @override
  String get inventoryInStock => 'In Stock';

  @override
  String get inventoryWarehouses => 'Warehouses';

  @override
  String get inventorySpareParts => 'Spare Parts';

  @override
  String get inventoryStockHistory => 'Stock History';

  @override
  String get inventoryRecentMovements => 'Recent Movements';

  @override
  String get inventoryMovementsEmpty => 'No stock movements yet';

  @override
  String get inventoryWarehousesEmpty => 'No warehouses found';

  @override
  String get inventoryPartsEmpty => 'No spare parts found';

  @override
  String get inventoryCreateWarehouse => 'Add warehouse';

  @override
  String get inventoryEditWarehouse => 'Edit warehouse';

  @override
  String get inventoryCreatePart => 'Add spare part';

  @override
  String get inventoryEditPart => 'Edit spare part';

  @override
  String get inventoryPartDetails => 'Part details';

  @override
  String get inventorySearchWarehouses => 'Search warehouses';

  @override
  String get inventorySearchParts => 'Search parts, numbers, or barcodes';

  @override
  String get inventorySearchMovements => 'Search reason, notes, or user';

  @override
  String get inventoryFilterAll => 'All';

  @override
  String get inventoryName => 'Name';

  @override
  String get inventoryCode => 'Code';

  @override
  String get inventoryAddress => 'Address';

  @override
  String get inventoryDescription => 'Description';

  @override
  String get inventoryActive => 'Active';

  @override
  String get inventoryInactive => 'Inactive';

  @override
  String get inventoryPartNumber => 'Part number';

  @override
  String get inventoryCategory => 'Category';

  @override
  String get inventoryUnit => 'Unit';

  @override
  String get inventoryCurrentQuantity => 'Current quantity';

  @override
  String get inventoryMinimumQuantity => 'Minimum quantity';

  @override
  String get inventoryAvailableQuantity => 'Available quantity';

  @override
  String get inventoryBarcode => 'Barcode / QR';

  @override
  String get inventoryImage => 'Image';

  @override
  String get inventoryAddPhoto => 'Add photo';

  @override
  String get inventoryRemovePhoto => 'Remove photo';

  @override
  String get inventoryStockIn => 'Stock In';

  @override
  String get inventoryStockOut => 'Stock Out';

  @override
  String get inventoryTransfer => 'Transfer';

  @override
  String get inventoryAdjustment => 'Adjustment';

  @override
  String get inventoryQuantity => 'Quantity';

  @override
  String get inventoryReason => 'Reason';

  @override
  String get inventoryNotes => 'Notes';

  @override
  String get inventoryWarehouse => 'Warehouse';

  @override
  String get inventoryFromWarehouse => 'From warehouse';

  @override
  String get inventoryToWarehouse => 'To warehouse';

  @override
  String get inventoryDirection => 'Direction';

  @override
  String get inventoryIncrease => 'Increase';

  @override
  String get inventoryDecrease => 'Decrease';

  @override
  String get inventoryNoWarehouses =>
      'Create a warehouse before managing stock';

  @override
  String get inventoryNeedTwoWarehouses =>
      'Transfer requires at least two warehouses';

  @override
  String get inventoryCancel => 'Cancel';

  @override
  String get inventorySave => 'Save';

  @override
  String get inventoryRequired => 'This field is required';

  @override
  String get assetsLoading => 'Loading assets...';

  @override
  String get assetsLoadFailed => 'Failed to load assets';

  @override
  String get assetsTotal => 'Total Assets';

  @override
  String get assetsList => 'Assets list';

  @override
  String get assetsCategories => 'Categories';

  @override
  String get assetsHistory => 'Asset history';

  @override
  String get assetsCreate => 'Add asset';

  @override
  String get assetsEdit => 'Edit asset';

  @override
  String get assetsDetails => 'Asset details';

  @override
  String get assetsEmpty => 'No assets found';

  @override
  String get assetsCategoriesEmpty => 'No categories found';

  @override
  String get assetsHistoryEmpty => 'No history events yet';

  @override
  String get assetsCreateCategory => 'Add category';

  @override
  String get assetsEditCategory => 'Edit category';

  @override
  String get assetsSearchCategories => 'Search categories';

  @override
  String get assetsSearchHint => 'Search number, name, serial, or barcode';

  @override
  String get assetsSearchHistory => 'Search history title or notes';

  @override
  String get assetsFilterAll => 'All';

  @override
  String get assetsStatusActive => 'Active';

  @override
  String get assetsStatusMaintenance => 'Maintenance';

  @override
  String get assetsStatusOffline => 'Offline';

  @override
  String get assetsStatusRetired => 'Retired';

  @override
  String get assetsWarrantyExpiringSoon => 'Warranty expiring soon';

  @override
  String get assetsName => 'Name';

  @override
  String get assetsCode => 'Code';

  @override
  String get assetsIcon => 'Icon';

  @override
  String get assetsDescription => 'Description';

  @override
  String get assetsActive => 'Active';

  @override
  String get assetsInactive => 'Inactive';

  @override
  String get assetsNumber => 'Asset number';

  @override
  String get assetsCategory => 'Category';

  @override
  String get assetsStatus => 'Status';

  @override
  String get assetsSerialNumber => 'Serial number';

  @override
  String get assetsManufacturer => 'Manufacturer';

  @override
  String get assetsModel => 'Model';

  @override
  String get assetsCustomer => 'Customer';

  @override
  String get assetsInstallationDate => 'Installation date';

  @override
  String get assetsWarrantyExpiry => 'Warranty expiry';

  @override
  String get assetsLocation => 'Location';

  @override
  String get assetsNoLocation => 'No location set';

  @override
  String get assetsBranch => 'Branch';

  @override
  String get assetsRegion => 'Region';

  @override
  String get assetsCity => 'City';

  @override
  String get assetsLatitude => 'Latitude';

  @override
  String get assetsLongitude => 'Longitude';

  @override
  String get assetsQrCode => 'QR code';

  @override
  String get assetsBarcode => 'Barcode';

  @override
  String get assetsNotes => 'Notes';

  @override
  String get assetsTitle => 'Title';

  @override
  String get assetsAddPhoto => 'Add photo';

  @override
  String get assetsRemovePhoto => 'Remove photo';

  @override
  String get assetsAddHistory => 'Add history';

  @override
  String get assetsHistoryType => 'History type';

  @override
  String get assetsHistoryInstallation => 'Installation';

  @override
  String get assetsHistoryMaintenance => 'Maintenance';

  @override
  String get assetsHistoryRepair => 'Repair';

  @override
  String get assetsHistoryInspection => 'Inspection';

  @override
  String get assetsHistoryStatusChange => 'Status change';

  @override
  String get assetsHistoryCreated => 'Created';

  @override
  String get assetsHistoryUpdated => 'Updated';

  @override
  String get assetsViewFullHistory => 'View full history';

  @override
  String get assetsScanQr => 'Scan QR';

  @override
  String get assetsCancel => 'Cancel';

  @override
  String get assetsSave => 'Save';

  @override
  String get assetsRequired => 'This field is required';

  @override
  String get pmTitle => 'Preventive Maintenance';

  @override
  String get pmLoading => 'Loading preventive maintenance...';

  @override
  String get pmLoadFailed => 'Failed to load preventive maintenance';

  @override
  String get pmPlans => 'Plans';

  @override
  String get pmSchedules => 'Schedules';

  @override
  String get pmHistory => 'History';

  @override
  String get pmChecklist => 'Checklist';

  @override
  String get pmChecklistBuilder => 'Checklist Builder';

  @override
  String get pmPlanDetails => 'Plan Details';

  @override
  String get pmCreatePlan => 'Create plan';

  @override
  String get pmEditPlan => 'Edit plan';

  @override
  String get pmDeletePlan => 'Delete plan';

  @override
  String get pmDeletePlanConfirm =>
      'Are you sure you want to delete this maintenance plan?';

  @override
  String get pmPlansEmpty => 'No maintenance plans found';

  @override
  String get pmSchedulesEmpty => 'No schedules found';

  @override
  String get pmHistoryEmpty => 'No maintenance history yet';

  @override
  String get pmChecklistEmpty => 'No checklist items yet';

  @override
  String get pmSearchPlansHint => 'Search plans';

  @override
  String get pmSearchSchedulesHint => 'Search schedules';

  @override
  String get pmFilterAll => 'All';

  @override
  String get pmUpcoming => 'Upcoming';

  @override
  String get pmOverdue => 'Overdue';

  @override
  String get pmCompleted => 'Completed';

  @override
  String get pmCancelled => 'Cancelled';

  @override
  String get pmActivePlans => 'Active plans';

  @override
  String get pmRecentSchedules => 'Recent schedules';

  @override
  String get pmName => 'Name';

  @override
  String get pmCode => 'Code';

  @override
  String get pmDescription => 'Description';

  @override
  String get pmFrequency => 'Frequency';

  @override
  String get pmTrigger => 'Trigger';

  @override
  String get pmNextDueDate => 'Next due date';

  @override
  String get pmPriority => 'Priority';

  @override
  String get pmStatus => 'Status';

  @override
  String get pmEstimatedDuration => 'Estimated duration (minutes)';

  @override
  String get pmAssignedTeam => 'Assigned team';

  @override
  String get pmAssignedTechnician => 'Assigned technician';

  @override
  String get pmLinkedAsset => 'Linked asset';

  @override
  String get pmMeterThreshold => 'Meter threshold';

  @override
  String get pmCurrentMeterReading => 'Current meter reading';

  @override
  String get pmScheduledDate => 'Scheduled date';

  @override
  String get pmNotes => 'Notes';

  @override
  String get pmNone => 'None';

  @override
  String get pmCancel => 'Cancel';

  @override
  String get pmSave => 'Save';

  @override
  String get pmRequired => 'This field is required';

  @override
  String get pmStatusActive => 'Active';

  @override
  String get pmStatusInactive => 'Inactive';

  @override
  String get pmPriorityLow => 'Low';

  @override
  String get pmPriorityMedium => 'Medium';

  @override
  String get pmPriorityHigh => 'High';

  @override
  String get pmPriorityCritical => 'Critical';

  @override
  String get pmFrequencyDaily => 'Daily';

  @override
  String get pmFrequencyWeekly => 'Weekly';

  @override
  String get pmFrequencyMonthly => 'Monthly';

  @override
  String get pmFrequencyQuarterly => 'Quarterly';

  @override
  String get pmFrequencySemiAnnual => 'Semi Annual';

  @override
  String get pmFrequencyAnnual => 'Annual';

  @override
  String get pmTriggerTimeBased => 'Time Based';

  @override
  String get pmTriggerMeterBased => 'Meter Based';

  @override
  String get pmScheduleScheduled => 'Scheduled';

  @override
  String get pmScheduleOverdue => 'Overdue';

  @override
  String get pmScheduleCompleted => 'Completed';

  @override
  String get pmScheduleCancelled => 'Cancelled';

  @override
  String get pmGenerateSchedules => 'Generate schedules';

  @override
  String pmSchedulesGenerated(int count) {
    return '$count schedules generated';
  }

  @override
  String pmMinutes(int count) {
    return '$count min';
  }

  @override
  String get pmAddChecklistItem => 'Add item';

  @override
  String get pmEditChecklistItem => 'Edit item';

  @override
  String get pmChecklistItemTitle => 'Inspection item';

  @override
  String get pmChecklistItemDescription => 'Description';

  @override
  String get pmRequiresPassFail => 'Pass / Fail';

  @override
  String get pmRequiresNotes => 'Notes';

  @override
  String get pmPhotoRequired => 'Photo required';

  @override
  String get pmCompleteSchedule => 'Complete';

  @override
  String get pmCancelSchedule => 'Cancel schedule';

  @override
  String get reportsTitle => 'Service Reports';

  @override
  String get reportsLoading => 'Loading service reports...';

  @override
  String get reportsLoadFailed => 'Failed to load service reports';

  @override
  String get reportsEmpty => 'No service reports yet';

  @override
  String get reportsList => 'Reports';

  @override
  String get reportsTotal => 'Total reports';

  @override
  String get reportsSignatures => 'Signatures';

  @override
  String get reportsCaptureSignature => 'Customer signature';

  @override
  String get reportsGenerate => 'Generate report';

  @override
  String get reportsPreview => 'Report preview';

  @override
  String get reportsDetails => 'Report details';

  @override
  String get reportsDownload => 'Download report';

  @override
  String get reportsSearchHint => 'Search reports';

  @override
  String get reportsFilterAll => 'All';

  @override
  String get reportsStatusDraft => 'Draft';

  @override
  String get reportsStatusGenerated => 'Generated';

  @override
  String get reportsStatusDownloaded => 'Downloaded';

  @override
  String get reportsWorkOrderInfo => 'Work order information';

  @override
  String get reportsAssetInfo => 'Asset information';

  @override
  String get reportsTechnician => 'Technician';

  @override
  String get reportsJobNumber => 'Job number';

  @override
  String get reportsJobTitle => 'Job title';

  @override
  String get reportsCustomerName => 'Customer name';

  @override
  String get reportsCustomerPosition => 'Customer position';

  @override
  String get reportsCustomerAddress => 'Customer address';

  @override
  String get reportsAssetNumber => 'Asset number';

  @override
  String get reportsAssetName => 'Asset name';

  @override
  String get reportsSerialNumber => 'Serial number';

  @override
  String get reportsTechnicianName => 'Technician name';

  @override
  String get reportsStartTime => 'Start time';

  @override
  String get reportsEndTime => 'End time';

  @override
  String get reportsTotalDuration => 'Total duration (minutes)';

  @override
  String get reportsTechnicianNotes => 'Technician notes';

  @override
  String get reportsCustomerNotes => 'Customer notes';

  @override
  String get reportsCustomerSignature => 'Customer signature';

  @override
  String get reportsBeforePhotos => 'Before photos';

  @override
  String get reportsProgressPhotos => 'Progress photos';

  @override
  String get reportsAfterPhotos => 'After photos';

  @override
  String get reportsQrCode => 'Report QR code';

  @override
  String get reportsNotes => 'Notes';

  @override
  String get reportsWorkOrderNumberOptional => 'Work order number (optional)';

  @override
  String get reportsSignHere => 'Sign here';

  @override
  String get reportsClearSignature => 'Clear';

  @override
  String get reportsSaveSignature => 'Save signature';

  @override
  String get reportsSignatureRequired => 'Please provide a signature';

  @override
  String get reportsSignatureSaved => 'Signature saved';

  @override
  String get reportsSignatureUnavailable => 'Signature unavailable';

  @override
  String get reportsGeneratedSuccess => 'Service report generated';

  @override
  String get reportsNone => 'None';

  @override
  String get reportsRequired => 'This field is required';

  @override
  String reportsMinutes(int count) {
    return '$count min';
  }

  @override
  String reportsDownloaded(String fileName) {
    return 'Downloaded $fileName';
  }

  @override
  String get usersTitle => 'User Management';

  @override
  String get usersLoading => 'Loading users...';

  @override
  String get usersLoadFailed => 'Failed to load users';

  @override
  String get usersEmpty => 'No users found';

  @override
  String get usersList => 'Users';

  @override
  String get usersTotal => 'Total users';

  @override
  String get usersCreate => 'Create user';

  @override
  String get usersEdit => 'Edit user';

  @override
  String get usersDetails => 'User details';

  @override
  String get usersDelete => 'Delete user';

  @override
  String get usersDeleteConfirm => 'Are you sure you want to delete this user?';

  @override
  String get usersSearchHint => 'Search users';

  @override
  String get usersFilterAll => 'All';

  @override
  String get usersStatusActive => 'Active';

  @override
  String get usersStatusDisabled => 'Disabled';

  @override
  String get usersStatusLocked => 'Locked';

  @override
  String get usersStatus => 'Status';

  @override
  String get usersFirstName => 'First name';

  @override
  String get usersLastName => 'Last name';

  @override
  String get usersUsername => 'Username';

  @override
  String get usersEmail => 'Email';

  @override
  String get usersPhone => 'Phone number';

  @override
  String get usersJobTitle => 'Job title';

  @override
  String get usersEmployeeId => 'Employee ID';

  @override
  String get usersPassword => 'Password';

  @override
  String get usersRole => 'Role';

  @override
  String get usersDepartment => 'Department';

  @override
  String get usersBranch => 'Branch';

  @override
  String get usersLastLogin => 'Last login';

  @override
  String get usersLastActive => 'Last active';

  @override
  String get usersCreatedBy => 'Created by';

  @override
  String get usersUpdatedBy => 'Updated by';

  @override
  String get usersActivity => 'Recent activity';

  @override
  String get usersEnable => 'Enable';

  @override
  String get usersDisable => 'Disable';

  @override
  String get usersLock => 'Lock';

  @override
  String get usersChangePassword => 'Change password';

  @override
  String get usersResetPassword => 'Reset password';

  @override
  String get usersCurrentPassword => 'Current password';

  @override
  String get usersNewPassword => 'New password';

  @override
  String get usersConfirmPassword => 'Confirm password';

  @override
  String get usersPasswordMin => 'Password must be at least 8 characters';

  @override
  String get usersPasswordMismatch => 'Passwords do not match';

  @override
  String get usersPasswordChanged => 'Password changed successfully';

  @override
  String get usersPasswordResetSuccess => 'Password reset successfully';

  @override
  String get usersOrgRefsRequired =>
      'Selected department must include region and city';

  @override
  String get usersCancel => 'Cancel';

  @override
  String get usersSave => 'Save';

  @override
  String get usersRequired => 'This field is required';

  @override
  String get rolesTitle => 'Roles & Permissions';

  @override
  String get rolesLoading => 'Loading roles...';

  @override
  String get rolesLoadFailed => 'Failed to load roles';

  @override
  String get rolesEmpty => 'No roles found';

  @override
  String get rolesList => 'Roles';

  @override
  String get rolesTotal => 'Total roles';

  @override
  String get rolesActive => 'Active roles';

  @override
  String get rolesSystem => 'System roles';

  @override
  String get rolesCustom => 'Custom roles';

  @override
  String get rolesCreate => 'Create role';

  @override
  String get rolesEdit => 'Edit role';

  @override
  String get rolesDetails => 'Role details';

  @override
  String get rolesDelete => 'Delete role';

  @override
  String get rolesDeleteConfirm => 'Are you sure you want to delete this role?';

  @override
  String get rolesDeleted => 'Role deleted';

  @override
  String get rolesCreated => 'Role created';

  @override
  String get rolesUpdated => 'Role updated';

  @override
  String get rolesCloned => 'Role cloned';

  @override
  String get rolesClone => 'Clone role';

  @override
  String get rolesActivate => 'Activate';

  @override
  String get rolesDeactivate => 'Deactivate';

  @override
  String get rolesAssignUsers => 'Assign users';

  @override
  String get rolesAssign => 'Assign';

  @override
  String get rolesAssigned => 'Users assigned successfully';

  @override
  String get rolesSearchHint => 'Search roles';

  @override
  String get rolesSearchUsersHint => 'Search users';

  @override
  String get rolesSearchPermissions => 'Search permissions';

  @override
  String get rolesName => 'Role name';

  @override
  String get rolesNameRequired => 'Role name is required';

  @override
  String get rolesDescription => 'Description';

  @override
  String get rolesColor => 'Color';

  @override
  String get rolesPermissions => 'Permissions';

  @override
  String get rolesNoPermissions => 'No permissions selected';

  @override
  String get rolesPermissionsSearchEmpty =>
      'No permissions match your search. Try a different title or description.';

  @override
  String get rolesPermissionsCatalogEmpty =>
      'No permissions are available in the catalog.';

  @override
  String get rolesSave => 'Save role';

  @override
  String get rolesCancel => 'Cancel';

  @override
  String get rolesSystemBadge => 'System';

  @override
  String get rolesStatusActive => 'Active';

  @override
  String get rolesStatusInactive => 'Inactive';

  @override
  String get rolesAssignedUsersTitle => 'Assigned users';

  @override
  String get rolesNoAssignedUsers => 'No users assigned to this role';

  @override
  String get rolesNoUsersFound => 'No users found';

  @override
  String rolesAssignedUsers(int count) {
    return '$count users';
  }

  @override
  String rolesPermissionCount(int count) {
    return '$count permissions';
  }

  @override
  String rolesSelectedPermissions(int count) {
    return '$count selected';
  }

  @override
  String get dashboardLoadFailed => 'Unable to load the dashboard.';

  @override
  String get dashboardLoading => 'Loading dashboard...';

  @override
  String get dashboardOverview => 'Operations overview';

  @override
  String get dashboardTodayAttendance => 'Today\'s attendance';

  @override
  String get dashboardTodayWorkOrders => 'Today\'s work orders';

  @override
  String get dashboardUpcomingPm => 'Upcoming PM';

  @override
  String get dashboardLowStock => 'Low stock alerts';

  @override
  String get dashboardRecentNotifications => 'Recent notifications';

  @override
  String get dashboardNoNotifications => 'No recent notifications';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardQuickCreateWorkOrder => 'Create work order';

  @override
  String get dashboardQuickStartOvertime => 'Start overtime';

  @override
  String get dashboardPeriodToday => 'Today';

  @override
  String get dashboardPeriodWeek => 'This Week';

  @override
  String get dashboardPeriodMonth => 'This Month';

  @override
  String get dashboardPeriodYear => 'This Year';

  @override
  String get dashboardPeriodCustom => 'Custom';

  @override
  String get dashboardRangeUntilNow => 'Today';

  @override
  String dashboardRangeSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String dashboardReportLine(String range) {
    return 'Report: $range';
  }

  @override
  String get dashboardSectionKpis => 'Key metrics';

  @override
  String get dashboardSectionAttendance => 'Attendance';

  @override
  String get dashboardSectionOvertime => 'Overtime';

  @override
  String get dashboardSectionWorkOrders => 'Work orders';

  @override
  String get dashboardSectionPm => 'Preventive maintenance';

  @override
  String get dashboardSectionInventory => 'Inventory';

  @override
  String get dashboardSectionAssets => 'Assets';

  @override
  String get dashboardSectionLiveActivity => 'Live activity';

  @override
  String get dashboardSectionCharts => 'Trends';

  @override
  String get dashboardSectionTeamOverview => 'Team overview';

  @override
  String get dashboardSectionTeamAttendance => 'Team attendance';

  @override
  String get dashboardSectionTeamOvertime => 'Team overtime';

  @override
  String get dashboardSectionTeamWorkOrders => 'Team work orders';

  @override
  String get dashboardSectionTeamPm => 'Team PM';

  @override
  String get dashboardSectionTeamInventory => 'Team inventory alerts';

  @override
  String get dashboardSectionTeamActivity => 'Team activity';

  @override
  String get dashboardSectionTeamPerformance => 'Team performance';

  @override
  String get dashboardSectionLocation => 'Location';

  @override
  String get dashboardSectionPerformance => 'Performance';

  @override
  String get dashboardKpiTotalEmployees => 'Total employees';

  @override
  String get dashboardKpiActiveEmployees => 'Active employees';

  @override
  String get dashboardKpiCurrentlyWorking => 'Currently working';

  @override
  String get dashboardKpiOnOvertime => 'On overtime';

  @override
  String get dashboardKpiOnTravelOt => 'On travel OT';

  @override
  String get dashboardKpiTotalWorkingHours => 'Total working hours';

  @override
  String get dashboardKpiAverageWorkingHours => 'Average working hours';

  @override
  String get dashboardKpiAttendanceRate => 'Attendance rate';

  @override
  String get dashboardKpiOtHours => 'Overtime hours';

  @override
  String get dashboardKpiTravelOtHours => 'Travel OT hours';

  @override
  String get dashboardKpiAvgOtPerEmployee => 'Avg OT per employee';

  @override
  String get dashboardKpiWoTotal => 'Total work orders';

  @override
  String get dashboardKpiWoPending => 'Pending';

  @override
  String get dashboardKpiWoAssigned => 'Assigned';

  @override
  String get dashboardKpiWoInProgress => 'In progress';

  @override
  String get dashboardKpiWoCompleted => 'Completed';

  @override
  String get dashboardKpiWoCancelled => 'Cancelled';

  @override
  String get dashboardKpiPmDue => 'Due';

  @override
  String get dashboardKpiPmOverdue => 'Overdue';

  @override
  String get dashboardKpiPmCompleted => 'Completed';

  @override
  String get dashboardKpiPmAssigned => 'Assigned tasks';

  @override
  String get dashboardKpiOutOfStock => 'Out of stock';

  @override
  String get dashboardKpiAssetsTotal => 'Total assets';

  @override
  String get dashboardKpiAssetsActive => 'Active';

  @override
  String get dashboardKpiAssetsMaintenance => 'Under maintenance';

  @override
  String get dashboardKpiAssetsRetired => 'Retired';

  @override
  String get dashboardKpiTeamSize => 'Team size';

  @override
  String get dashboardKpiMembersPresent => 'Members present';

  @override
  String get dashboardKpiCompletionRate => 'Completion rate';

  @override
  String get dashboardKpiTodayWorkingHours => 'Today\'s working hours';

  @override
  String get dashboardKpiMonthlyWorkingHours => 'Period working hours';

  @override
  String get dashboardKpiMonthlyOtHours => 'Period OT hours';

  @override
  String get dashboardKpiMonthlyTravelOt => 'Period travel OT';

  @override
  String get dashboardKpiCompletedJobs => 'Completed work orders';

  @override
  String get dashboardKpiAvgCompletionHours => 'Avg completion hours';

  @override
  String get dashboardNoLiveActivity => 'No recent activity';

  @override
  String get dashboardSystemActor => 'System';

  @override
  String get dashboardLocationUnknown => 'Location unavailable';

  @override
  String dashboardLastSync(String date) {
    return 'Last sync: $date';
  }

  @override
  String dashboardHoursValue(String value) {
    return '$value h';
  }

  @override
  String dashboardPercentValue(String value) {
    return '$value%';
  }

  @override
  String get dashboardChartAttendance => 'Attendance trend';

  @override
  String get dashboardChartOvertime => 'Overtime trend';

  @override
  String get dashboardChartWorkOrders => 'Work orders trend';

  @override
  String get dashboardChartPm => 'PM trend';

  @override
  String get dashboardChartEmpty => 'No chart data';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String dashboardChartWindowDays(int days) {
    return '${days}d';
  }

  @override
  String get dashboardTrends => 'Trends';

  @override
  String get dashboardWorkforce => 'Workforce';

  @override
  String get dashboardOperations => 'Operations';

  @override
  String get dashboardResources => 'Resources';

  @override
  String get dashboardKeyMetrics => 'Key metrics';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsEmptySearch => 'No settings match your search';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionOrganization => 'Company';

  @override
  String get settingsSectionAdministration => 'Administration';

  @override
  String get settingsSectionSystem => 'System';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsMyProfile => 'My profile';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageArabic => 'Arabic';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsNotificationPreferences => 'Notification preferences';

  @override
  String get settingsPushNotifications => 'Push notifications';

  @override
  String get settingsEmailNotifications => 'Email notifications';

  @override
  String get settingsCompanyInformation => 'Company information';

  @override
  String get settingsOvertimeTitle => 'Overtime Settings';

  @override
  String get settingsOvertimeVoiceNotesTitle => 'Voice Notes';

  @override
  String get settingsOvertimeVoiceNotesSubtitle =>
      'Configure optional voice notes for overtime journey stages.';

  @override
  String get settingsOvertimeVoiceMaxDurationTitle =>
      'Maximum Voice Recording Duration';

  @override
  String get settingsOvertimeVoiceMaxDurationSubtitle =>
      'Maximum length allowed for each voice note recorded during an overtime stage.';

  @override
  String settingsOvertimeVoiceDurationMinutes(int minutes) {
    return '$minutes Minutes';
  }

  @override
  String settingsOvertimeVoiceCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String get settingsOvertimeVoiceQualityTitle => 'Voice Recording Quality';

  @override
  String get settingsOvertimeVoiceQualitySubtitle =>
      'Audio quality used when technicians record voice notes during overtime.';

  @override
  String get settingsOvertimeVoiceQualityHigh => 'High';

  @override
  String get settingsOvertimeVoiceQualityMedium => 'Medium';

  @override
  String get settingsOvertimeVoiceQualityLow => 'Low';

  @override
  String get settingsOvertimeMaxPhotoSizeTitle => 'Maximum Uploaded Photo Size';

  @override
  String get settingsOvertimeMaxPhotoSizeSubtitle =>
      'Photos are compressed before upload to stay within this limit whenever possible.';

  @override
  String settingsOvertimeMaxPhotoSizeMb(int size) {
    return '$size MB';
  }

  @override
  String get settingsOvertimeMaxPhotoSizeOriginal => 'Original';

  @override
  String get settingsOvertimeUploadPolicyTitle => 'Upload Policy';

  @override
  String get settingsOvertimeUploadPolicyImmediately => 'Immediately';

  @override
  String get settingsOvertimeUploadPolicyImmediatelyHint =>
      'Upload checkpoints as soon as a network connection is available.';

  @override
  String get settingsOvertimeUploadPolicyWifiPreferred => 'Wi-Fi Preferred';

  @override
  String get settingsOvertimeUploadPolicyWifiPreferredHint =>
      'Upload immediately on Wi-Fi. On mobile data, queue until Wi-Fi is available. Technicians can force upload manually.';

  @override
  String get settingsOvertimeUploadPolicyManual => 'Manual';

  @override
  String get settingsOvertimeUploadPolicyManualHint =>
      'Always queue uploads. Sync happens only when the technician presses Sync Now.';

  @override
  String get settingsOvertimeUploadPolicyWifiOnly => 'Wi-Fi Only';

  @override
  String get settingsOvertimeUploadPolicyWifiOnlyHint =>
      'Never upload using mobile data. Queue until Wi-Fi is available.';

  @override
  String get settingsOvertimeUploadPolicyAskEveryTime => 'Ask Every Time';

  @override
  String get settingsOvertimeUploadPolicyAskEveryTimeHint =>
      'When uploading on mobile data, ask the technician each time.';

  @override
  String settingsOvertimeQualityEstimatePerMinute(String size) {
    return '≈ $size / minute';
  }

  @override
  String settingsOvertimeEstimatedMaxFileSize(String size) {
    return 'Estimated Maximum File Size: ≈ $size';
  }

  @override
  String settingsOvertimeEstimateKb(int size) {
    return '≈ $size KB';
  }

  @override
  String settingsOvertimeEstimateMb(String size) {
    return '≈ $size MB';
  }

  @override
  String settingsOvertimeEstimateTotalMb(String size) {
    return '≈ $size MB';
  }

  @override
  String settingsOvertimeFileSizeKb(int size) {
    return '$size KB';
  }

  @override
  String settingsOvertimeFileSizeMb(String size) {
    return '$size MB';
  }

  @override
  String settingsOvertimeFileSizeBytes(int size) {
    return '$size bytes';
  }

  @override
  String get settingsOvertimeLargeRecordingWarning =>
      'Large recordings may increase upload time and mobile data usage.';

  @override
  String get settingsOvertimePresetTitle => 'Configuration Preset';

  @override
  String get settingsOvertimePresetSubtitle =>
      'Apply a recommended profile or customize individual settings.';

  @override
  String get settingsOvertimePresetOffice => 'Office';

  @override
  String get settingsOvertimePresetFieldService => 'Field Service';

  @override
  String get settingsOvertimePresetHeavyMaintenance => 'Heavy Maintenance';

  @override
  String get settingsOvertimePresetCustom => 'Custom';

  @override
  String get settingsOvertimeRestoreDefaults => 'Restore Defaults';

  @override
  String get settingsOvertimeRestoreDialogTitle => 'Restore Voice Settings?';

  @override
  String get settingsOvertimeRestoreDialogBody =>
      'This will restore:\n• Recording Duration: 5 Minutes\n• Recording Quality: Medium\n• Maximum Photo Size: 2 MB\n• Upload Policy: Immediately';

  @override
  String get settingsOvertimeRestoreConfirm => 'Restore';

  @override
  String get settingsOvertimeConfigTestingTitle => 'Configuration Testing';

  @override
  String get settingsOvertimeConfigTestingSubtitle =>
      'Preview the impact of current settings. Nothing is uploaded or saved.';

  @override
  String get settingsOvertimeVoiceTestTitle => 'Voice Recording Test';

  @override
  String get settingsOvertimeVoiceTestRecord => 'Test Voice Recording';

  @override
  String get settingsOvertimeVoiceTestPlay => 'Play';

  @override
  String get settingsOvertimeVoiceTestDelete => 'Delete';

  @override
  String get settingsOvertimeVoiceTestRecordAgain => 'Record Again';

  @override
  String settingsOvertimeVoiceTestTimer(String elapsed, String max) {
    return '$elapsed / $max';
  }

  @override
  String get settingsOvertimeVoiceTestDuration => 'Recording Duration';

  @override
  String get settingsOvertimeVoiceTestEstimatedSize => 'Estimated Size';

  @override
  String get settingsOvertimeVoiceTestActualSize => 'Actual File Size';

  @override
  String get settingsOvertimeVoiceTestEncoding => 'Encoding Format';

  @override
  String get settingsOvertimeVoiceTestBitrate => 'Bitrate';

  @override
  String get settingsOvertimeVoiceTestSampleRate => 'Sample Rate';

  @override
  String settingsOvertimeVoiceTestBitrateKbps(int rate) {
    return '$rate kbps';
  }

  @override
  String settingsOvertimeVoiceTestSampleRateKhz(int rate) {
    return '$rate kHz';
  }

  @override
  String get settingsOvertimePhotoTestTitle => 'Photo Compression Test';

  @override
  String get settingsOvertimePhotoTestCamera => 'Take Photo';

  @override
  String get settingsOvertimePhotoTestGallery => 'Choose from Gallery';

  @override
  String get settingsOvertimePhotoTestOriginal => 'Original';

  @override
  String get settingsOvertimePhotoTestCompressed => 'Compressed';

  @override
  String get settingsOvertimePhotoTestSplit => 'Split View';

  @override
  String settingsOvertimePhotoTestResolution(int width, int height) {
    return 'Resolution: $width × $height';
  }

  @override
  String settingsOvertimePhotoTestCompressionRatio(int percent) {
    return 'Compression Ratio: $percent%';
  }

  @override
  String settingsOvertimePhotoTestEstimatedUpload(String size) {
    return 'Estimated Upload Size: $size';
  }

  @override
  String get settingsOvertimePhotoTestChooseAnother => 'Choose Another Photo';

  @override
  String get settingsOvertimePhotoTestRetest => 'Retest';

  @override
  String get settingsOvertimePhotoTestDeletePreview => 'Delete Preview';

  @override
  String get settingsOvertimePerformanceInfoTitle => 'Performance Information';

  @override
  String get settingsOvertimePerformanceVoiceMaxDuration => 'Maximum Duration';

  @override
  String get settingsOvertimePerformanceVoiceMaxSize =>
      'Estimated Maximum Size';

  @override
  String get settingsOvertimePerformancePhotoMaxSize => 'Average Maximum Size';

  @override
  String settingsOvertimePerformancePhotoAverageMb(int size) {
    return '$size MB';
  }

  @override
  String get settingsOvertimePerformanceTotalUpload => 'Estimated Total Upload';

  @override
  String get overtimeVoiceSettingsInfoTitle => 'Voice Recording Settings';

  @override
  String get overtimeCellularUploadTitle => 'Upload Now?';

  @override
  String get overtimeCellularUploadMessage =>
      'You are using mobile data. How would you like to upload this checkpoint?';

  @override
  String get overtimeCellularUploadWifiOnly => 'Wi-Fi Only';

  @override
  String get overtimeCellularUploadMobileData => 'Mobile Data';

  @override
  String get overtimeCellularUploadLater => 'Later';

  @override
  String auditOvertimeVoiceDurationChanged(String before, String after) {
    return 'Changed voice recording duration from $before to $after';
  }

  @override
  String auditOvertimeVoiceQualityChanged(String before, String after) {
    return 'Changed voice quality from $before to $after';
  }

  @override
  String auditOvertimeUploadPolicyChanged(String before, String after) {
    return 'Changed upload policy from $before to $after';
  }

  @override
  String auditOvertimeMaxPhotoSizeChanged(String before, String after) {
    return 'Changed maximum photo size from $before to $after';
  }

  @override
  String auditOvertimePresetApplied(String preset) {
    return 'Applied configuration preset: $preset';
  }

  @override
  String get auditOvertimeRestoredDefaults =>
      'Restored voice settings to defaults';

  @override
  String get auditOvertimeVoiceDurationChangedGeneric =>
      'Changed voice recording duration';

  @override
  String get auditOvertimeVoiceQualityChangedGeneric =>
      'Changed voice recording quality';

  @override
  String get auditOvertimeUploadPolicyChangedGeneric => 'Changed upload policy';

  @override
  String get auditOvertimeMaxPhotoSizeChangedGeneric =>
      'Changed maximum photo size';

  @override
  String get auditOvertimePresetAppliedGeneric =>
      'Applied configuration preset';

  @override
  String get settingsCompanyLogo => 'Company logo';

  @override
  String get settingsCompanyName => 'Company name';

  @override
  String get settingsContactEmail => 'Contact email';

  @override
  String get settingsContactPhone => 'Contact phone';

  @override
  String get settingsAddress => 'Address';

  @override
  String get settingsAddressLine1 => 'Address line 1';

  @override
  String get settingsAddressLine2 => 'Address line 2';

  @override
  String get settingsCity => 'City';

  @override
  String get settingsGovernorate => 'Governorate';

  @override
  String get settingsCountry => 'Country';

  @override
  String get settingsPostalCode => 'Postal code';

  @override
  String get settingsWorkingHours => 'Working hours';

  @override
  String get settingsWorkingHoursStart => 'Start time';

  @override
  String get settingsWorkingHoursEnd => 'End time';

  @override
  String get settingsTimezone => 'Time zone';

  @override
  String get settingsBackupRestore => 'Backup & restore';

  @override
  String get settingsCacheManagement => 'Cache management';

  @override
  String get settingsSystemStatus => 'System status';

  @override
  String get settingsApiStatus => 'API status';

  @override
  String get settingsDatabaseStatus => 'Database status';

  @override
  String get settingsStorageUsage => 'Storage usage';

  @override
  String get settingsApiVersion => 'API version';

  @override
  String get settingsBackendVersion => 'Backend version';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsUptime => 'Uptime';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTermsOfService => 'Terms of service';

  @override
  String get settingsOpenSourceLicenses => 'Open source licenses';

  @override
  String get settingsPrivacyBody =>
      'INFINITY processes field service data to support operations for Total-Com Solutions. Personal data is used only for authentication, attendance, and work execution.';

  @override
  String get settingsTermsBody =>
      'Use of INFINITY is limited to authorized personnel. Unauthorized access, data misuse, or redistribution of company information is prohibited.';

  @override
  String get settingsUiOnly => 'UI only in this release';

  @override
  String get settingsComingSoonAction =>
      'This action will be available in a future release';

  @override
  String get settingsCacheCleared => 'Local cache acknowledged';

  @override
  String get settingsLoading => 'Loading settings...';

  @override
  String get settingsLoadFailed => 'Failed to load settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsLogoUpdated => 'Company logo updated';

  @override
  String get settingsSave => 'Save settings';

  @override
  String get serverMgmtTitle => 'Server Management';

  @override
  String get serverMgmtAccessDenied =>
      'Only administrators can manage the backend server.';

  @override
  String get serverMgmtConnectionSettings => 'Connection Settings';

  @override
  String get serverMgmtBackendUrl => 'Backend Server URL';

  @override
  String get serverMgmtUrlHelper =>
      'Accepts https://host or https://host/api/v1 — /api/v1 is applied automatically.';

  @override
  String get serverMgmtInvalidUrl => 'Enter a valid http:// or https:// URL.';

  @override
  String get serverMgmtTestConnection => 'Test Connection';

  @override
  String get serverMgmtPingServer => 'Ping Server';

  @override
  String get serverMgmtSave => 'Save';

  @override
  String get serverMgmtRestoreDefault => 'Restore Default';

  @override
  String get serverMgmtServerInformation => 'Server Information';

  @override
  String get serverMgmtCurrentServer => 'Current Server';

  @override
  String get serverMgmtStatus => 'Status';

  @override
  String get serverMgmtStatusConnected => 'Connected';

  @override
  String get serverMgmtStatusFailed => 'Connection Failed';

  @override
  String get serverMgmtStatusUnknown => 'Not tested yet';

  @override
  String get serverMgmtBackendVersion => 'Backend Version';

  @override
  String get serverMgmtEnvironment => 'Environment';

  @override
  String get serverMgmtResponseTime => 'Response Time';

  @override
  String get serverMgmtConnectionQuality => 'Connection Quality';

  @override
  String get serverMgmtLastSuccessful => 'Last Successful Connection';

  @override
  String get serverMgmtQualityExcellent => 'Excellent (<100 ms)';

  @override
  String get serverMgmtQualityGood => 'Good (100–250 ms)';

  @override
  String get serverMgmtQualityFair => 'Fair (250–500 ms)';

  @override
  String get serverMgmtQualityPoor => 'Poor (>1000 ms)';

  @override
  String get serverMgmtQualityUnreachable => 'Server Unreachable';

  @override
  String get serverMgmtAdvancedDiagnostics => 'Advanced Diagnostics';

  @override
  String get serverMgmtAppVersion => 'Application Version';

  @override
  String get serverMgmtBuildNumber => 'Build Number';

  @override
  String get serverMgmtPlatform => 'Platform';

  @override
  String get serverMgmtCurrentApiUrl => 'Current API URL';

  @override
  String get serverMgmtDeviceLocalTime => 'Device Local Time';

  @override
  String get serverMgmtServerTime => 'Server Time';

  @override
  String get serverMgmtClockDifference => 'Clock Difference';

  @override
  String get serverMgmtOnlineStatus => 'Online / Offline Status';

  @override
  String get serverMgmtOnline => 'Online';

  @override
  String get serverMgmtOffline => 'Offline';

  @override
  String get serverMgmtUserRole => 'Current User Role';

  @override
  String get serverMgmtLastSuccessfulSync => 'Last Successful Sync';

  @override
  String get serverMgmtPendingSyncQueue => 'Pending Sync Queue';

  @override
  String get serverMgmtNetworkType => 'Network Type';

  @override
  String get serverMgmtBackendReachable => 'Backend Reachable';

  @override
  String get serverMgmtApiHealth => 'API Health';

  @override
  String get serverMgmtDatabaseConnectivity => 'Database Connectivity';

  @override
  String get serverMgmtAvgLatency => 'Average Latency';

  @override
  String get serverMgmtMinLatency => 'Minimum Latency';

  @override
  String get serverMgmtMaxLatency => 'Maximum Latency';

  @override
  String get serverMgmtRequestTimeout => 'Request Timeout';

  @override
  String get serverMgmtAppUptime => 'Application Uptime';

  @override
  String get serverMgmtDeviceTimezone => 'Device Timezone';

  @override
  String get serverMgmtServerTimezone => 'Server Timezone';

  @override
  String get serverMgmtHealthHealthy => 'Healthy';

  @override
  String get serverMgmtHealthWarning => 'Warning';

  @override
  String get serverMgmtHealthError => 'Error';

  @override
  String get serverMgmtTestSuccess => 'Connected to backend successfully.';

  @override
  String get serverMgmtTestFailed =>
      'Connection failed. Check the URL and network.';

  @override
  String get serverMgmtPingSuccess => 'Ping completed.';

  @override
  String get serverMgmtPingFailed => 'Server unreachable.';

  @override
  String get serverMgmtSaveSuccess =>
      'Backend URL saved. New requests use this server immediately.';

  @override
  String get serverMgmtSaveFailed => 'Could not save the backend URL.';

  @override
  String get serverMgmtRestoreSuccess => 'Default production backend restored.';

  @override
  String get serverMgmtFutureHint =>
      'This page is ready for future options such as timeouts, retries, failover, and feature flags.';

  @override
  String get serverMgmtUnlockHint => 'Admin tools unlocked';

  @override
  String get serverMgmtBiometricReason =>
      'Authenticate to open Server Management';

  @override
  String get serverMgmtBiometricUnavailable =>
      'Device authentication is not available on this device.';

  @override
  String get serverMgmtTimeout => 'Connection timed out. Try again.';

  @override
  String get serverMgmtExportSuccess => 'Diagnostics exported.';

  @override
  String get serverMgmtExportFailed => 'Could not export diagnostics.';

  @override
  String get serverMgmtCopySuccess => 'Server info copied.';

  @override
  String get serverMgmtExportDiagnostics => 'Export Diagnostics';

  @override
  String get serverMgmtCopyServerInfo => 'Copy Server Info';

  @override
  String get serverMgmtClearUrl => 'Clear';

  @override
  String get serverMgmtPasteUrl => 'Paste';

  @override
  String get serverMgmtCopyUrl => 'Copy';

  @override
  String get serverMgmtRetry => 'Retry';

  @override
  String get serverMgmtServerUnreachable => 'Server Unreachable';

  @override
  String get serverMgmtUnknown => 'Unknown';

  @override
  String get serverMgmtQualitySlow => 'Slow (500–1000 ms)';

  @override
  String get serverMgmtRegion => 'Region';

  @override
  String get serverMgmtServerUptime => 'Uptime';

  @override
  String get serverMgmtDatabase => 'Database';

  @override
  String get serverMgmtApiUrlLabel => 'API URL';

  @override
  String get serverMgmtLatency => 'Latency';

  @override
  String get serverMgmtVersion => 'Version';

  @override
  String get serverMgmtHealth => 'Health';

  @override
  String get serverMgmtDeviceModel => 'Device Model';

  @override
  String get serverMgmtAndroidVersion => 'Android / OS Version';

  @override
  String get serverMgmtLastSuccessfulPing => 'Last Successful Ping';

  @override
  String get serverMgmtConnectedBadge => 'Connected';

  @override
  String serverMgmtVersionLabel(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get livePhotoRequired => 'A live photo is required.';

  @override
  String get deviceTimeIncorrect => 'Device time appears to be incorrect.';

  @override
  String get gpsAccuracyTooLow =>
      'Location accuracy is too low. Move to an open area and try again.';

  @override
  String get attendanceUpdated => 'Attendance updated successfully.';

  @override
  String get attendanceLoading => 'Loading attendance...';

  @override
  String get attendanceHistoryLoading => 'Loading history...';

  @override
  String get attendanceHistoryEmpty => 'No attendance history yet';

  @override
  String get attendanceTimeline => 'Timeline';

  @override
  String get attendanceHistoryTooltip => 'History';

  @override
  String get overtimeEnded =>
      'Overtime ended. Eligible overtime calculated automatically.';

  @override
  String get normalOvertimeStarted => 'Normal overtime started.';

  @override
  String get travelOvertimeStarted => 'Travel overtime started.';

  @override
  String get overtimeLoading => 'Loading overtime...';

  @override
  String get overtimeLoadFailed => 'Unable to load overtime.';

  @override
  String get overtimeMyTooltip => 'My Overtime';

  @override
  String get overtimeManageTooltip => 'Manage Overtime';

  @override
  String get attendanceClockIn => 'Clock In';

  @override
  String get attendanceClockOut => 'Clock Out';

  @override
  String get attendanceStartBreak => 'Start Break';

  @override
  String get attendanceEndBreak => 'End Break';

  @override
  String get attendanceShiftCompleted =>
      'You have completed your shift for today.';

  @override
  String get attendanceTodayStatus => 'Today\'s Status';

  @override
  String get attendanceWorkingHours => 'Working hours';

  @override
  String get attendanceBreaks => 'Breaks';

  @override
  String get attendanceTimelineEmpty =>
      'No attendance activity recorded yet today.';

  @override
  String get attendanceEventClockedIn => 'Clocked in';

  @override
  String get attendanceEventClockedOut => 'Clocked out';

  @override
  String get attendanceEventBreakStarted => 'Break started';

  @override
  String get attendanceEventBreakEnded => 'Break ended';

  @override
  String get attendanceSyncedOffline => 'Synced from offline record';

  @override
  String get attendanceHistoryTitle => 'Attendance History';

  @override
  String get attendanceStatusNotStarted => 'Not started';

  @override
  String get attendanceStatusWorking => 'Working';

  @override
  String get attendanceStatusOnBreak => 'On break';

  @override
  String get attendanceStatusClockedOut => 'Clocked out';

  @override
  String get attendanceStatusPresent => 'Present';

  @override
  String get attendanceStatusCheckedOut => 'Checked out';

  @override
  String get attendanceManagement => 'Attendance Management';

  @override
  String get attendanceManageTooltip => 'Manage attendance';

  @override
  String get attendanceSearchEmployee => 'Search employee name or email';

  @override
  String get attendanceAdminEmpty => 'No attendance records found.';

  @override
  String get attendanceAdminLoadFailed => 'Failed to load attendance records.';

  @override
  String get attendanceDetails => 'Attendance details';

  @override
  String get attendanceDetailsLoading => 'Loading attendance details...';

  @override
  String get attendanceDetailsLoadFailed =>
      'Failed to load attendance details.';

  @override
  String get attendanceEmployeeInfo => 'Employee information';

  @override
  String get attendanceSessionInfo => 'Session information';

  @override
  String get attendanceDeviceInfo => 'Device information';

  @override
  String get attendanceLocation => 'Location';

  @override
  String get attendanceDevice => 'Device';

  @override
  String get attendanceSyncSource => 'Sync source';

  @override
  String get attendanceLastUpdated => 'Last updated';

  @override
  String get attendanceSelfie => 'Selfie';

  @override
  String get attendanceDate => 'Date';

  @override
  String get attendanceOvertimeHours => 'Overtime hours';

  @override
  String get attendanceRoleAll => 'All roles';

  @override
  String get overtimeStartTitle => 'Start overtime journey';

  @override
  String get overtimeStartHint =>
      'Official hours are 09:00 AM – 05:00 PM. Time outside that window is calculated automatically. New sessions use four checkpoints; duration still runs from Start Journey to End Journey.';

  @override
  String get overtimeStartNormal => 'Start Journey — Normal';

  @override
  String get overtimeStartTravel => 'Start Journey — Travel';

  @override
  String get overtimeEnd => 'End Journey';

  @override
  String get overtimeArrivedAtWorkSite => 'Arrived at Work Site';

  @override
  String get overtimeFinishedWork => 'Finish Work';

  @override
  String get overtimeStageStartJourney => 'Start Journey';

  @override
  String get overtimeStageArrivedAtWorkSite => 'Arrived at Work Site';

  @override
  String get overtimeStageFinishedWork => 'Finished Work';

  @override
  String get overtimeStageEndJourney => 'End Journey';

  @override
  String get overtimeCheckpointCompleted => 'Completed';

  @override
  String get overtimeCheckpointNext => 'Next';

  @override
  String get overtimeCheckpointPending => 'Pending';

  @override
  String get overtimeJourneyTimeline => 'Journey timeline';

  @override
  String get overtimeJourneyOverview => 'Journey Overview';

  @override
  String get overtimeArrivedAtWorkSiteRecorded =>
      'Arrived at work site recorded.';

  @override
  String get overtimeFinishedWorkRecorded => 'Finished work recorded.';

  @override
  String get overtimeCompletePriorCheckpoints =>
      'Complete the previous checkpoints before ending the journey.';

  @override
  String get overtimeGpsAccuracy => 'GPS accuracy';

  @override
  String get overtimeDeviceId => 'Device ID';

  @override
  String get overtimeBatteryLevel => 'Battery';

  @override
  String get overtimeNetworkStatus => 'Network';

  @override
  String get overtimeNotes => 'Notes';

  @override
  String get overtimeNotesOptionalHint => 'Optional notes for this checkpoint';

  @override
  String get overtimeVoiceNote => 'Voice Note';

  @override
  String get overtimeVoiceRecord => 'Record Voice';

  @override
  String get overtimeVoiceStop => 'Stop';

  @override
  String get overtimeVoicePlay => 'Play';

  @override
  String get overtimeVoicePause => 'Pause';

  @override
  String get overtimeVoiceDelete => 'Delete';

  @override
  String get overtimeVoiceRerecord => 'Re-record';

  @override
  String overtimeVoiceMaxDurationHint(int minutes) {
    return 'Optional. Maximum $minutes minutes.';
  }

  @override
  String get overtimeVoiceLimitWarning => 'Recording will stop in 30 seconds.';

  @override
  String overtimeVoiceMaxRecordingInfo(int minutes) {
    return 'Maximum recording: $minutes minutes';
  }

  @override
  String get overtimeVoicePermissionDenied =>
      'Microphone permission is required to record a voice note.';

  @override
  String get overtimeVoiceRecording => 'Recording...';

  @override
  String get overtimeVoiceRecorded => 'Voice Recorded';

  @override
  String get overtimeVoiceMaxReached => 'Maximum recording length reached.';

  @override
  String get overtimeVoiceUploaded => 'Uploaded';

  @override
  String get overtimeVoiceWaitingSync => 'Waiting for synchronization';

  @override
  String get overtimeVoiceUploading => 'Uploading voice note…';

  @override
  String get overtimeVoicePlaybackFailed => 'Unable to play this recording.';

  @override
  String get overtimeExportExcel => 'Export Excel';

  @override
  String get overtimeExportDenied =>
      'Only administrators and supervisors can export overtime reports.';

  @override
  String get overtimeExportFiltersHint =>
      'Optional filters for the Excel report. Leave blank to export all accessible sessions.';

  @override
  String get overtimeExportStartDate => 'Start date';

  @override
  String get overtimeExportEndDate => 'End date';

  @override
  String get overtimeExportAll => 'All';

  @override
  String get overtimeExportEmployeeId => 'Employee user ID';

  @override
  String get overtimeExportDepartmentId => 'Department ID';

  @override
  String get overtimeExportBranchId => 'Branch ID';

  @override
  String get overtimeExportOptionalIdHint => 'Optional MongoDB ObjectId';

  @override
  String get overtimeExportModeLabel => 'Export type';

  @override
  String get overtimeExportModeSummary => 'Export Summary';

  @override
  String get overtimeExportModeSummaryHint =>
      'Statistics only — no GPS, photos, voice, or journey details.';

  @override
  String get overtimeExportModeDetailed => 'Export Detailed Report';

  @override
  String get overtimeExportModeDetailedHint =>
      'Complete overtime dataset with maps, voice, photos, and device info.';

  @override
  String get overtimeExportGenerate => 'Generate Excel';

  @override
  String get overtimeExportPreparing => 'Preparing export…';

  @override
  String get overtimeExportDownloading => 'Generating Excel report…';

  @override
  String get overtimeExportSaving => 'Saving file…';

  @override
  String get overtimeExportReady => 'Export ready';

  @override
  String overtimeExportRowCount(int count) {
    return '$count sessions exported';
  }

  @override
  String get overtimeExportOpen => 'Open';

  @override
  String get overtimeExportOpenFile => 'Open File';

  @override
  String get overtimeExportOpenFolder => 'Open Containing Folder';

  @override
  String get overtimeExportSaveAs => 'Save As';

  @override
  String get overtimeExportSave => 'Save';

  @override
  String get overtimeExportShare => 'Share';

  @override
  String overtimeExportSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get overtimeRequiresManualReview => 'Requires manual review';

  @override
  String get overtimeProgress => 'Progress';

  @override
  String get overtimeStatusLabel => 'Status';

  @override
  String get overtimeStartTime => 'Start time';

  @override
  String get overtimeLocation => 'Location';

  @override
  String get overtimeRunningTimer => 'Running timer';

  @override
  String get overtimeLastSessionSummary => 'Last session summary';

  @override
  String get overtimeEligible => 'Eligible overtime';

  @override
  String get overtimeTypeNormal => 'Normal Overtime';

  @override
  String get overtimeTypeTravel => 'Travel Overtime';

  @override
  String get overtimeContinueExistingSession =>
      'You already have a running overtime session.';

  @override
  String get overtimeContinueSession => 'Continue Existing Session';

  @override
  String get overtimeActiveSessionReminder =>
      'Your overtime session is still running. Don\'t forget to end it when you\'re done.';

  @override
  String overtimeProgressOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get overtimeSyncPending => 'Pending sync';

  @override
  String get overtimeSyncSynced => 'Synced';

  @override
  String get overtimeSyncFailed => 'Sync failed';

  @override
  String get overtimeSyncOffline => 'Offline — queued';

  @override
  String get overtimeShowMap => 'Show map';

  @override
  String get overtimeHideMap => 'Hide map';

  @override
  String get overtimeReviewNotes => 'Review notes';

  @override
  String get overtimeReviewNotesHint => 'Optional notes for this decision';

  @override
  String get overtimeGpsStatus => 'GPS status';

  @override
  String get overtimeSyncStatus => 'Sync status';

  @override
  String get overtimeCurrentStage => 'Current stage';

  @override
  String get overtimeLiveCameraRequired =>
      'Live camera capture is required — gallery selection is disabled.';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get loadingGeneric => 'Loading...';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get labelType => 'Type';

  @override
  String get labelName => 'Name';

  @override
  String get labelStart => 'Start';

  @override
  String get labelEnd => 'End';

  @override
  String get labelCreated => 'Created';

  @override
  String get filterPending => 'Pending';

  @override
  String get filterApproved => 'Approved';

  @override
  String get filterRejected => 'Rejected';

  @override
  String get approve => 'Approve';

  @override
  String get deviceRegistrationFailed =>
      'Device registration failed. Restart the app.';

  @override
  String get firstSignInRequiresInternet =>
      'Internet is required for the first sign-in.';

  @override
  String get attendanceOfflineCachedData =>
      'Offline mode — showing cached attendance data.';

  @override
  String attendancePendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attendance records pending sync.',
      one: '1 attendance record pending sync.',
    );
    return '$_temp0';
  }

  @override
  String attendancePendingOfflineRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending offline records',
      one: '1 pending offline record',
    );
    return '$_temp0';
  }

  @override
  String get profileLoading => 'Loading profile...';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePosition => 'Position';

  @override
  String get profileNoPermissions => 'No permissions assigned';

  @override
  String get orgTitle => 'Organization';

  @override
  String get orgCompanies => 'Companies';

  @override
  String get orgCompaniesSubtitle => 'Tenant company profile';

  @override
  String get orgSearchCompanies => 'Search companies';

  @override
  String get orgBranches => 'Branches';

  @override
  String get orgBranchesSubtitle => 'Branch locations';

  @override
  String get orgSearchBranches => 'Search branches';

  @override
  String get orgDepartments => 'Departments';

  @override
  String get orgDepartmentsSubtitle => 'Department structure';

  @override
  String get orgSearchDepartments => 'Search departments';

  @override
  String get orgTeams => 'Teams';

  @override
  String get orgTeamsSubtitle => 'Operational teams';

  @override
  String get orgSearchTeams => 'Search teams';

  @override
  String get orgPositions => 'Positions';

  @override
  String get orgPositionsSubtitle => 'Job positions';

  @override
  String get orgSearchPositions => 'Search positions';

  @override
  String get orgUserDirectory => 'User Directory';

  @override
  String get orgUserDirectorySubtitle => 'Employees and roles';

  @override
  String get orgSearchUsers => 'Search users';

  @override
  String get orgSearch => 'Search';

  @override
  String get orgEmpty => 'No records found';

  @override
  String get orgNoCachedData => 'No cached data yet.';

  @override
  String get usersRoleAdmin => 'Administrator';

  @override
  String get usersRoleSupervisor => 'Supervisor';

  @override
  String get usersRoleTechnician => 'Technician';

  @override
  String get usersRoleHr => 'HR';

  @override
  String get usersRoleWarehouse => 'Warehouse';

  @override
  String get usersRoleViewer => 'Viewer';

  @override
  String get usersRoleManager => 'Manager';

  @override
  String get permGroupDashboard => 'Dashboard';

  @override
  String get permGroupUsers => 'Users';

  @override
  String get permGroupRoles => 'Roles & Permissions';

  @override
  String get permGroupAttendance => 'Attendance';

  @override
  String get permGroupOvertime => 'Overtime';

  @override
  String get permGroupInventory => 'Inventory';

  @override
  String get permGroupAssets => 'Assets';

  @override
  String get permGroupMaintenance => 'Maintenance';

  @override
  String get permGroupServiceReports => 'Service Reports';

  @override
  String get permGroupWorkOrders => 'Work Orders';

  @override
  String get permGroupSettings => 'Settings';

  @override
  String get permGroupProfile => 'Profile';

  @override
  String get permGroupNotifications => 'Notifications';

  @override
  String get permGroupOrganization => 'Organization';

  @override
  String get permGroupAudit => 'Audit';

  @override
  String get permGroupGeneral => 'General';

  @override
  String get rolesNotLoaded => 'Role not loaded';

  @override
  String get rolesSelectAtLeastOneUser => 'Select at least one user';

  @override
  String get overtimeMyHistory => 'My Overtime';

  @override
  String get overtimeManagement => 'Overtime Management';

  @override
  String get overtimeDetails => 'Overtime Details';

  @override
  String get overtimeDetailsLoading => 'Loading details...';

  @override
  String get overtimeDetailsLoadFailed => 'Unable to load overtime details.';

  @override
  String get overtimeHistoryLoadFailed => 'Unable to load overtime history.';

  @override
  String get overtimeHistoryEmpty => 'No overtime history yet.';

  @override
  String get overtimeAdminEmpty => 'No overtime sessions found.';

  @override
  String get overtimeSearchTechnician => 'Search technician name or email';

  @override
  String get overtimeTechnicianInfo => 'Technician Information';

  @override
  String get overtimeSessionInfo => 'Session Information';

  @override
  String get overtimeEndTime => 'End time';

  @override
  String get overtimeTotalDuration => 'Total duration';

  @override
  String get overtimeWorkingDuration => 'Working duration';

  @override
  String get overtimeRejectionReason => 'Rejection reason';

  @override
  String overtimeRejectionReasonLine(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String get overtimeApprovedBy => 'Approved by';

  @override
  String get overtimeApprovedAt => 'Approved at';

  @override
  String get overtimeRejectedBy => 'Rejected by';

  @override
  String get overtimeRejectedAt => 'Rejected at';

  @override
  String get overtimeImages => 'Images';

  @override
  String get overtimeStartPhoto => 'Start photo';

  @override
  String get overtimeEndPhoto => 'End photo';

  @override
  String get overtimeDeviceInfo => 'Device Information';

  @override
  String get overtimeStartDevice => 'Start device';

  @override
  String get overtimeEndDevice => 'End device';

  @override
  String get overtimeNoPhotoAvailable => 'No photo available';

  @override
  String get overtimeRejectDialogTitle => 'Reject Overtime';

  @override
  String get overtimeRejectReasonHint => 'Optional rejection reason';

  @override
  String get overtimeApprovedMessage => 'Overtime approved.';

  @override
  String get overtimeRejectedMessage => 'Overtime rejected.';

  @override
  String overtimeDurationLine(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get overtimeStatusRunning => 'Running';

  @override
  String get overtimeStatusPendingReview => 'Pending review';

  @override
  String get overtimeStatusPendingSync => 'Pending Sync';

  @override
  String get overtimeStatusSynced => 'Synced';

  @override
  String get overtimeStatusApproved => 'Approved';

  @override
  String get overtimeStatusRejected => 'Rejected';

  @override
  String get overtimeStatusCancelled => 'Cancelled';

  @override
  String get overtimeStartLocation => 'Start Location';

  @override
  String get overtimeEndLocation => 'End Location';

  @override
  String get overtimeRoute => 'Route';

  @override
  String get overtimeStartAddress => 'Start Address';

  @override
  String get overtimeEndAddress => 'End Address';

  @override
  String get overtimeMapLoadFailed => 'Unable to load map tiles';

  @override
  String get overtimeMapCheckConnection =>
      'Check your connection and try again.';

  @override
  String get overtimeOpenInGoogleMaps => 'Open in Google Maps';

  @override
  String get overtimeOpenLiveLocation => 'Open Live Location';

  @override
  String get overtimeLocationUnavailable => 'Location unavailable';

  @override
  String get overtimeUnableOpenGoogleMaps => 'Unable to open Google Maps.';

  @override
  String get workOrderSaved => 'Saved';

  @override
  String get workOrderJobTitleRequired => 'Job title is required';

  @override
  String get workOrderJobTitleMaxLength =>
      'Job title must be at most 200 characters';

  @override
  String get workOrderUpdated => 'Work order updated';

  @override
  String get workOrderCreated => 'Work order created';

  @override
  String get workOrderNoPermission =>
      'You do not have permission to manage work orders.';

  @override
  String get workOrderOverview => 'Overview';

  @override
  String get workOrderOverviewSubtitle => 'Customer, location, and job details';

  @override
  String get workOrderViewOnMap => 'View on map';

  @override
  String get workOrderCouldNotOpenMaps => 'Could not open maps';

  @override
  String get workOrderWorkDescription => 'Work description';

  @override
  String get workOrderInternalNotes => 'Internal notes';

  @override
  String get workOrderDocument => 'Document';

  @override
  String get workOrderBeforeWork => 'Before work';

  @override
  String get workOrderBeforeWorkSubtitleEdit =>
      'Capture site photos and optional notes';

  @override
  String get workOrderBeforeWorkSubtitleView => 'Before-work evidence';

  @override
  String get workOrderBeforePhotos => 'Before photos';

  @override
  String get workOrderSavedBeforeNotes => 'Saved before notes';

  @override
  String get workOrderBeforeNotes => 'Before notes';

  @override
  String get workOrderBeforeNotesHint => 'Optional notes before starting work';

  @override
  String get workOrderInProgress => 'In progress';

  @override
  String get workOrderInProgressSubtitle => 'Progress photos and field notes';

  @override
  String get workOrderProgressPhotos => 'Progress photos';

  @override
  String get workOrderProgressNotes => 'Progress notes';

  @override
  String get workOrderNoProgressNotes => 'No progress notes yet';

  @override
  String get workOrderAddProgressNote => 'Add progress note';

  @override
  String get workOrderProgressNoteHint => 'What progress was made?';

  @override
  String get workOrderCompleteWork => 'Complete work';

  @override
  String get workOrderCompleteWorkSubtitleEdit =>
      'At least one after photo is required';

  @override
  String get workOrderCompleteWorkSubtitleView => 'Completion evidence';

  @override
  String get workOrderCompletionNotes => 'Completion notes';

  @override
  String get workOrderCompletionNotesHint => 'Optional notes when completing';

  @override
  String get workOrderCompletionNotesOptional => 'Completion notes (optional)';

  @override
  String get workOrderAfterPhotos => 'After photos';

  @override
  String get workOrderAfterPhotoRequired =>
      'Add at least one after photo before completing.';

  @override
  String get workOrderAfterPhotoRequiredSnackbar =>
      'Add at least one after photo before completing';

  @override
  String get workOrderCapturedLocations => 'Captured locations';

  @override
  String get workOrderCapturedLocationsSubtitle =>
      'GPS checkpoints from the field';

  @override
  String get workOrderLocationStarted => 'Started';

  @override
  String get workOrderLocationCompleted => 'Completed';

  @override
  String get workOrderOpenMap => 'Open map';

  @override
  String get workOrderSaveNotes => 'Save notes';

  @override
  String get workOrderTakePhoto => 'Take photo';

  @override
  String get workOrderChooseFromGallery => 'Choose from gallery';

  @override
  String workOrderHideNote(String title) {
    return 'Hide $title';
  }

  @override
  String get workOrderTimeline => 'Timeline';

  @override
  String get workOrderTimelineSubtitle => 'Read-only activity history';

  @override
  String get workOrderTimelineEmpty =>
      'Activity will appear as the work order progresses.';

  @override
  String get workOrderSystem => 'System';

  @override
  String get workOrderNoPhotosYet => 'No photos yet';

  @override
  String get workOrderDeleteConfirm =>
      'Are you sure you want to delete this work order?';

  @override
  String get workOrderRejectionReason => 'Rejection reason';

  @override
  String get workOrderReasonOptional => 'Reason (optional)';

  @override
  String get workOrderNoTechnicians => 'No technicians available';

  @override
  String get workOrderAccepted => 'Work order accepted';

  @override
  String get workOrderRejected => 'Work order rejected';

  @override
  String get workOrderStarted => 'Work started';

  @override
  String get workOrderCompletedMessage => 'Work order completed';

  @override
  String get workOrderCancelledMessage => 'Work order cancelled';

  @override
  String get workOrderTechnicianAssigned => 'Technician assigned';

  @override
  String get workOrderDeleted => 'Work order deleted';

  @override
  String get workOrderBeforeWorkSaved => 'Before-work details saved';

  @override
  String get workOrderProgressNoteAdded => 'Progress note added';

  @override
  String get workOrderProgressPhotoUploaded => 'Progress photo uploaded';

  @override
  String get workOrderAfterPhotoUploaded => 'After photo uploaded';

  @override
  String get workOrderPhotoRemoved => 'Photo removed';

  @override
  String get workOrderStatusPending => 'Pending';

  @override
  String get workOrderStatusAssigned => 'Assigned';

  @override
  String get workOrderStatusAccepted => 'Accepted';

  @override
  String get workOrderStatusRejected => 'Rejected';

  @override
  String get workOrderStatusInProgress => 'In Progress';

  @override
  String get workOrderStatusCompleted => 'Completed';

  @override
  String get workOrderStatusCancelled => 'Cancelled';

  @override
  String get workOrderPriorityLow => 'Low';

  @override
  String get workOrderPriorityMedium => 'Medium';

  @override
  String get workOrderPriorityHigh => 'High';

  @override
  String get workOrderPriorityCritical => 'Critical';

  @override
  String get workOrderTimelineCreated => 'Created';

  @override
  String get workOrderTimelineAssigned => 'Assigned';

  @override
  String get workOrderTimelineAccepted => 'Accepted';

  @override
  String get workOrderTimelineRejected => 'Rejected';

  @override
  String get workOrderTimelineStarted => 'Started';

  @override
  String get workOrderTimelineCompleted => 'Completed';

  @override
  String get workOrderTimelineCancelled => 'Cancelled';

  @override
  String get errorInvalidCredentials => 'Invalid email or password.';

  @override
  String get errorForbidden =>
      'You do not have permission to perform this action.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorRequestTimeout => 'Request timed out. Please try again.';

  @override
  String get errorUnableToReachServer => 'Unable to reach the server.';

  @override
  String get errorNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get errorSecureConnectionFailed =>
      'Secure connection failed. Please try again.';

  @override
  String get errorRequestFailed => 'Request failed';

  @override
  String get errorUnexpectedNetworkError =>
      'Unexpected network error. Please try again.';

  @override
  String get attendanceAlreadyClockedIn => 'You have already clocked in today.';

  @override
  String get attendanceMustClockInBeforeOut =>
      'You must clock in before clocking out.';

  @override
  String get attendanceEndBreakBeforeOut =>
      'End your current break before clocking out.';

  @override
  String get attendanceAlreadyClockedOut =>
      'You have already clocked out today.';

  @override
  String get attendanceMustClockInBeforeBreak =>
      'You must clock in before starting a break.';

  @override
  String get attendanceBreakAlreadyInProgress =>
      'A break is already in progress.';

  @override
  String get attendanceNoActiveBreak => 'There is no active break to end.';

  @override
  String attendanceGpsAccuracyExceeded(String accuracy, String threshold) {
    return 'Location accuracy (${accuracy}m) exceeds the allowed threshold (${threshold}m). Move to an open area and try again.';
  }

  @override
  String get attendanceWebOfflinePhotoRequired =>
      'Photo attendance requires an internet connection on web. Please reconnect and try again.';

  @override
  String get locationServicesDisabled =>
      'Location services are disabled. Enable GPS to continue.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to clock in or out.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission is permanently denied. Enable it from device settings.';

  @override
  String get locationTimeout =>
      'Could not determine your location in time. Try again.';

  @override
  String get cameraUnavailable =>
      'Camera is unavailable. A live photo is required.';

  @override
  String get authNoActiveSession => 'No active session.';

  @override
  String get authOfflineRestoreProfile =>
      'Offline Mode. Connect once to restore your profile.';

  @override
  String get overtimeNoRunningSession =>
      'No running overtime session found to end.';

  @override
  String get assetsQrScannerNotReady =>
      'QR scanning will be available in a future release.';

  @override
  String get orgStatusActive => 'Active';

  @override
  String get orgStatusInactive => 'Inactive';

  @override
  String get errorInvalidEmail => 'Invalid email or password.';

  @override
  String get errorInvalidPassword => 'Invalid password.';

  @override
  String get errorUserDisabled =>
      'This account is disabled. Contact your administrator.';

  @override
  String get errorClockSkew =>
      'Device time appears to be incorrect. Sync your clock and try again.';

  @override
  String get errorGpsRequired => 'Location is required to continue.';

  @override
  String get errorLivePhotoRequired => 'A live photo is required.';

  @override
  String get errorWorkOrderNotFound => 'Work order not found.';

  @override
  String get errorNotFound => 'The requested item was not found.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorValidation => 'Please check your input and try again.';

  @override
  String get errorGpsAccuracyTooLow =>
      'Location accuracy is too low. Move to an open area and try again.';

  @override
  String get errorDeviceRequired => 'Device identification is required.';

  @override
  String get errorClientRequestRequired => 'Request identifier is required.';

  @override
  String get errorInvalidTimestamp => 'Invalid date or time.';

  @override
  String get errorConflict => 'This action conflicts with the current state.';

  @override
  String get errorUserNotFound => 'User not found.';

  @override
  String get errorOvertimeNotFound => 'Overtime session not found.';

  @override
  String get errorTitleRequired => 'Title is required.';

  @override
  String get errorInvalidPriority => 'Invalid priority value.';

  @override
  String get errorInvalidDate => 'Invalid date value.';

  @override
  String get errorInvalidStatus => 'Invalid status value.';

  @override
  String get errorAvatarRequired => 'Avatar image is required.';

  @override
  String get errorUploadFailed => 'Upload failed. Please try again.';

  @override
  String get valueNotSet => 'Not set';

  @override
  String get workOrderAttachmentFallback => 'Attachment';

  @override
  String durationMinutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours:$minutes h';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navWorkOrders => 'Work Orders';

  @override
  String get navOvertime => 'Overtime';

  @override
  String get navProfile => 'Me';

  @override
  String get eventAuthLogin => 'Signed in successfully';

  @override
  String get eventAuthLoginFailed => 'Sign-in attempt failed';

  @override
  String get eventAuthLogout => 'Signed out';

  @override
  String get eventAuthTokenRefreshed => 'Session refreshed';

  @override
  String get eventAuthGeneric => 'Account activity';

  @override
  String get eventAttendanceGeneric => 'Attendance update';

  @override
  String get eventOvertimeGeneric => 'Overtime update';

  @override
  String get eventWorkOrderGeneric => 'Work order update';

  @override
  String get eventInventoryGeneric => 'Inventory update';

  @override
  String get eventAssetsGeneric => 'Asset update';

  @override
  String get eventPmGeneric => 'Maintenance update';

  @override
  String get eventReportsGeneric => 'Report update';

  @override
  String get eventUsersGeneric => 'User update';

  @override
  String get eventOrganizationGeneric => 'Organization update';

  @override
  String get eventSecurityGeneric => 'Security event';

  @override
  String get eventGenericActivity => 'System activity';

  @override
  String eventFeedActorLine(String module, String actor) {
    return '$module · $actor';
  }

  @override
  String get settingsAccountOverview => 'Account';

  @override
  String get settingsChangePhoto => 'Change photo';

  @override
  String get settingsPhotoPreview => 'Preview photo';

  @override
  String get settingsPhotoPreviewHint =>
      'Your photo will be saved as a square profile image.';

  @override
  String get settingsPhotoUpdated => 'Profile photo updated';

  @override
  String get settingsPhotoUnsupportedFormat =>
      'Please choose a JPG, PNG, or WebP image.';

  @override
  String get settingsPhotoDecodeFailed => 'Could not read the selected image.';

  @override
  String get settingsEmployeeId => 'Employee ID';

  @override
  String get settingsBranch => 'Branch';

  @override
  String get settingsDepartment => 'Department';

  @override
  String get settingsAccountCreated => 'Account created';

  @override
  String get settingsLastLogin => 'Last login';

  @override
  String get settingsNotAvailable => 'Not available';

  @override
  String get settingsEditablePrefs => 'Editable preferences';

  @override
  String get settingsSyncTitle => 'Sync';

  @override
  String get settingsLastSuccessfulSync => 'Last successful sync';

  @override
  String get settingsPendingUploads => 'Pending uploads';

  @override
  String get settingsPendingDownloads => 'Pending downloads';

  @override
  String get settingsSyncStatus => 'Sync status';

  @override
  String get settingsAutoSync => 'Auto sync';

  @override
  String get settingsWifiOnlySync => 'Wi‑Fi only';

  @override
  String get settingsSyncInterval => 'Sync interval';

  @override
  String get settingsManualSync => 'Sync now';

  @override
  String get settingsManualSyncDone => 'Sync requested';

  @override
  String get settingsNetworkRequirement => 'Network requirement';

  @override
  String get settingsStorageTitle => 'Storage';

  @override
  String get settingsCacheSize => 'Cache size';

  @override
  String get settingsImagesSize => 'Images cache';

  @override
  String get settingsTempFiles => 'Temporary files';

  @override
  String get settingsManagedByOs => 'Managed by the system';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsSupportTitle => 'Support';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsReportBug => 'Report a bug';

  @override
  String get settingsRequestFeature => 'Request a feature';

  @override
  String get settingsFaq => 'FAQ';

  @override
  String get settingsSecurityTitle => 'Security';

  @override
  String get settingsCurrentSession => 'Current session';

  @override
  String get settingsDeviceName => 'Device name';

  @override
  String get settingsBiometricStatus => 'Biometric login';

  @override
  String get settingsBiometricAvailable => 'Available on this device';

  @override
  String get settingsBiometricUnavailable => 'Not available';

  @override
  String get settingsLogoutAllDevices => 'Log out all devices';

  @override
  String get settingsApplicationTitle => 'Application';

  @override
  String get settingsPerformanceTitle => 'Performance';

  @override
  String get settingsMemoryUsage => 'Memory usage';

  @override
  String get settingsCacheUsage => 'Cache usage';

  @override
  String get settingsNetworkLatency => 'Network latency';

  @override
  String get settingsDatabaseConnection => 'Database connection';

  @override
  String get settingsServerHealth => 'Server health';

  @override
  String get settingsUseServerMgmt => 'See Server Management';

  @override
  String get settingsAccessibilityTitle => 'Accessibility';

  @override
  String get settingsLargeText => 'Large text';

  @override
  String get settingsReduceAnimations => 'Reduce animations';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsBackupUnavailable => 'Backup is not available yet.';

  @override
  String get settingsRestoreUnavailable => 'Restore is not available yet.';

  @override
  String get settingsDangerZone => 'Danger zone';

  @override
  String get settingsDangerZoneHint =>
      'These actions only reset local preferences and cache. Business data is never deleted.';

  @override
  String get settingsResetPreferences => 'Reset preferences';

  @override
  String get settingsResetPreferencesConfirm =>
      'Reset language, theme, notifications, sync, and accessibility preferences?';

  @override
  String get settingsClearCacheConfirm =>
      'Clear the local image cache? User data will not be deleted.';

  @override
  String get settingsRestoreDefaults => 'Restore default settings';

  @override
  String get settingsRestoreDefaultsConfirm =>
      'Restore all preference defaults and clear local cache?';

  @override
  String get settingsPrefsRestored => 'Preferences restored';

  @override
  String get settingsConfirm => 'Confirm';

  @override
  String get settingsUpdateCenter => 'Update center';

  @override
  String get settingsLatestVersion => 'Latest available version';

  @override
  String get settingsReleaseChannel => 'Release channel';

  @override
  String get settingsReleaseDate => 'Release date';

  @override
  String get settingsUpdateStatus => 'Update status';

  @override
  String get settingsUpdateIdle => 'Not checked yet';

  @override
  String get settingsUpdateChecking => 'Checking…';

  @override
  String get settingsUpdateUpToDate => 'Up to date';

  @override
  String get settingsUpdateAvailable => 'Update available';

  @override
  String get settingsUpdateFailed => 'Unable to check';

  @override
  String get settingsCheckForUpdates => 'Check for updates';

  @override
  String get settingsViewReleaseNotes => 'View release notes';

  @override
  String get settingsDownloadUpdate => 'Download update';

  @override
  String get settingsDownloadUpdateSoon =>
      'OTA downloads will be available in a future release.';

  @override
  String get settingsAdminLogs => 'Application logs';

  @override
  String get settingsSearchLogs => 'Search logs';

  @override
  String get settingsLogAll => 'All';

  @override
  String get settingsLogCategoryAll => 'All categories';

  @override
  String get settingsCopyLogs => 'Copy logs';

  @override
  String get settingsExportLogs => 'Export logs';

  @override
  String get settingsClearLogs => 'Clear logs';

  @override
  String get settingsLogsCopied => 'Logs copied';

  @override
  String get settingsLogEntries => 'Log entries';

  @override
  String get settingsNoLogs => 'No log entries yet';

  @override
  String get settingsDeveloperOptions => 'Developer options';

  @override
  String get settingsFeatureFlags => 'Feature flags';

  @override
  String get settingsReadOnly => 'Read-only';

  @override
  String get settingsNoFeatureFlags => 'No feature flags configured';

  @override
  String get settingsNotifAttendance => 'Attendance notifications';

  @override
  String get settingsNotifTasks => 'Work order notifications';

  @override
  String get settingsNotifOvertime => 'Overtime notifications';

  @override
  String get settingsNotifSync => 'Sync notifications';

  @override
  String get settingsNotifUpdates => 'Update notifications';

  @override
  String get settingsThemePreview => 'Theme preview';

  @override
  String get settingsThemePreviewBody =>
      'Example only — switch Light or Dark below to preview components. This does not change the app theme.';

  @override
  String get settingsAboutApp => 'About';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String settingsCopyright(String year, String company) {
    return 'Copyright © $year $company. All rights reserved.';
  }

  @override
  String get settingsOpenSourcePackages => 'Open source packages';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionSecurity => 'Security & privacy';

  @override
  String get settingsSectionSupport => 'Help & support';

  @override
  String get settingsSectionDeveloper => 'Developer';

  @override
  String get settingsDiagDevice => 'Device';

  @override
  String get settingsDiagNetwork => 'Network';

  @override
  String get settingsDiagServer => 'Server';

  @override
  String get settingsDiagApi => 'API';

  @override
  String get settingsDiagDatabase => 'Database';

  @override
  String get settingsDiagAuth => 'Authentication';

  @override
  String get settingsDiagPerformance => 'Performance';

  @override
  String get serverMgmtBadgeHttps => 'Secure HTTPS';

  @override
  String get serverMgmtBadgeLocal => 'Local';

  @override
  String get serverMgmtBadgeDevelopment => 'Development';

  @override
  String get serverMgmtBadgeProduction => 'Production';

  @override
  String get settingsLogLevelDebug => 'Debug';

  @override
  String get settingsLogLevelInfo => 'Info';

  @override
  String get settingsLogLevelWarning => 'Warning';

  @override
  String get settingsLogLevelError => 'Error';

  @override
  String get settingsLogCategoryNetwork => 'Network';

  @override
  String get settingsLogCategoryAuth => 'Authentication';

  @override
  String get settingsLogCategorySync => 'Synchronization';

  @override
  String get permGroupDashboardDesc =>
      'Permissions for viewing system statistics and key performance indicators.';

  @override
  String get permGroupUsersDesc =>
      'Permissions for managing user accounts across the organization.';

  @override
  String get permGroupRolesDesc =>
      'Permissions for managing roles and assigning access rights.';

  @override
  String get permGroupAttendanceDesc =>
      'Permissions for reviewing and managing employee attendance records.';

  @override
  String get permGroupOvertimeDesc =>
      'Permissions for creating, approving, and managing overtime sessions.';

  @override
  String get permGroupInventoryDesc =>
      'Permissions for managing inventory items and stock quantities.';

  @override
  String get permGroupAssetsDesc =>
      'Permissions for managing and tracking organization assets.';

  @override
  String get permGroupMaintenanceDesc =>
      'Permissions for maintenance plans and related operations.';

  @override
  String get permGroupServiceReportsDesc =>
      'Permissions for viewing, generating, and downloading service reports.';

  @override
  String get permGroupWorkOrdersDesc =>
      'Permissions for creating, managing, and completing work orders.';

  @override
  String get permGroupSettingsDesc =>
      'Permissions for system and organization configuration settings.';

  @override
  String get permGroupProfileDesc =>
      'Permissions for managing the signed-in user personal profile.';

  @override
  String get permGroupNotificationsDesc =>
      'Permissions for sending, receiving, and managing notifications.';

  @override
  String get permGroupOrganizationDesc =>
      'Permissions for managing company structure, branches, and departments.';

  @override
  String get permGroupAuditDesc =>
      'Permissions for reviewing activity history and system change logs.';

  @override
  String get permGroupGeneralDesc =>
      'General platform permissions not tied to a specific module.';

  @override
  String get permOrganizationView => 'View organization';

  @override
  String get permOrganizationViewDesc =>
      'Allows browsing company structure, branches, and directory screens.';

  @override
  String get permOrganizationManageBranches => 'Manage branches';

  @override
  String get permOrganizationManageBranchesDesc =>
      'Allows creating and editing company branches used across the organization.';

  @override
  String get permOrganizationManageRegions => 'Manage regions';

  @override
  String get permOrganizationManageRegionsDesc =>
      'Allows creating and editing geographic regions used for organization mapping.';

  @override
  String get permOrganizationManageCities => 'Manage cities';

  @override
  String get permOrganizationManageCitiesDesc =>
      'Allows creating and editing cities linked to branches and field operations.';

  @override
  String get permOrganizationManageDepartments => 'Manage departments';

  @override
  String get permOrganizationManageDepartmentsDesc =>
      'Allows creating and editing departments that organize users and teams.';

  @override
  String get permOrganizationManageTeams => 'Manage teams';

  @override
  String get permOrganizationManageTeamsDesc =>
      'Allows creating and editing operational teams and their membership.';

  @override
  String get permOrganizationManageUsers => 'Manage organization users';

  @override
  String get permOrganizationManageUsersDesc =>
      'Allows placing users into branches, departments, and teams.';

  @override
  String get permSettingsView => 'View settings';

  @override
  String get permSettingsViewDesc =>
      'Allows opening system settings screens without changing any values.';

  @override
  String get permSettingsManage => 'Manage system settings';

  @override
  String get permSettingsManageDesc =>
      'Allows changing general settings that affect all system users.';

  @override
  String get permSettingsUpdate => 'Update system settings';

  @override
  String get permSettingsUpdateDesc =>
      'Allows saving changes to system configuration values organization-wide.';

  @override
  String get permSettingsManageHolidays => 'Manage holidays';

  @override
  String get permSettingsManageHolidaysDesc =>
      'Allows defining company holidays that affect attendance and overtime.';

  @override
  String get permAuditView => 'View audit log';

  @override
  String get permAuditViewDesc =>
      'Allows reviewing activity and security change logs across the organization.';

  @override
  String get permDashboardView => 'View dashboard';

  @override
  String get permDashboardViewDesc =>
      'Allows viewing system statistics and key performance indicators.';

  @override
  String get permRbacManageRoles => 'Manage roles & permissions';

  @override
  String get permRbacManageRolesDesc =>
      'Allows full control of roles and which permissions each role receives.';

  @override
  String get permRbacManagePermissions => 'Manage permissions';

  @override
  String get permRbacManagePermissionsDesc =>
      'Allows controlling how permissions are assigned from the access catalog.';

  @override
  String get permRolesView => 'View roles';

  @override
  String get permRolesViewDesc =>
      'Allows opening the roles list and reviewing existing role definitions.';

  @override
  String get permRolesCreate => 'Create roles';

  @override
  String get permRolesCreateDesc =>
      'Allows creating new roles and choosing the permissions they include.';

  @override
  String get permRolesUpdate => 'Update roles';

  @override
  String get permRolesUpdateDesc =>
      'Allows changing names and permissions of existing roles.';

  @override
  String get permRolesDelete => 'Delete roles';

  @override
  String get permRolesDeleteDesc =>
      'Allows permanently removing roles that are no longer needed.';

  @override
  String get permRolesManage => 'Manage roles & permissions';

  @override
  String get permRolesManageDesc =>
      'Allows creating, editing, and assigning roles and their permission sets.';

  @override
  String get permAttendanceViewOwn => 'View own attendance';

  @override
  String get permAttendanceViewOwnDesc =>
      'Allows reviewing only personal attendance records.';

  @override
  String get permAttendanceViewTeam => 'View team attendance';

  @override
  String get permAttendanceViewTeamDesc =>
      'Allows viewing attendance records for members of the assigned team.';

  @override
  String get permAttendanceViewAll => 'View all attendance';

  @override
  String get permAttendanceViewAllDesc =>
      'Allows viewing every attendance record across the organization.';

  @override
  String get permAttendanceManageOwn => 'Manage own attendance';

  @override
  String get permAttendanceManageOwnDesc =>
      'Allows creating and updating only personal attendance punches.';

  @override
  String get permAttendanceView => 'View attendance';

  @override
  String get permAttendanceViewDesc =>
      'Allows opening attendance screens for records within the granted access scope.';

  @override
  String get permAttendanceUpdate => 'Manage attendance';

  @override
  String get permAttendanceUpdateDesc =>
      'Allows creating, editing, approving, and managing attendance records.';

  @override
  String get permAttendanceApprove => 'Approve attendance';

  @override
  String get permAttendanceApproveDesc =>
      'Allows approving attendance records before they are finalized.';

  @override
  String get permOvertimeViewOwn => 'View own overtime';

  @override
  String get permOvertimeViewOwnDesc =>
      'Allows reviewing only personal overtime sessions and status.';

  @override
  String get permOvertimeViewTeam => 'View team overtime';

  @override
  String get permOvertimeViewTeamDesc =>
      'Allows viewing overtime sessions belonging to assigned team members.';

  @override
  String get permOvertimeViewAll => 'View all overtime';

  @override
  String get permOvertimeViewAllDesc =>
      'Allows viewing every overtime session across the organization.';

  @override
  String get permOvertimeCreate => 'Create overtime';

  @override
  String get permOvertimeCreateDesc =>
      'Allows creating new overtime requests for employees.';

  @override
  String get permOvertimeStart => 'Start overtime';

  @override
  String get permOvertimeStartDesc =>
      'Allows starting an overtime session and recording its start time and location.';

  @override
  String get permOvertimeEnd => 'End overtime';

  @override
  String get permOvertimeEndDesc =>
      'Allows finishing an active overtime session and submitting its end details.';

  @override
  String get permOvertimeCancel => 'Cancel overtime';

  @override
  String get permOvertimeCancelDesc =>
      'Allows canceling an overtime session so it is not counted as worked time.';

  @override
  String get permOvertimeApprove => 'Approve overtime';

  @override
  String get permOvertimeApproveDesc =>
      'Allows approving overtime requests before they are counted.';

  @override
  String get permOvertimeReject => 'Reject overtime';

  @override
  String get permOvertimeRejectDesc =>
      'Allows rejecting overtime requests while keeping a record of the decision.';

  @override
  String get permOvertimeArchive => 'Archive overtime';

  @override
  String get permOvertimeArchiveDesc =>
      'Allows archiving completed overtime records to keep active lists focused.';

  @override
  String get permWorkOrdersViewOwn => 'View own work orders';

  @override
  String get permWorkOrdersViewOwnDesc =>
      'Allows viewing only work orders assigned to the signed-in user.';

  @override
  String get permWorkOrdersViewTeam => 'View team work orders';

  @override
  String get permWorkOrdersViewTeamDesc =>
      'Allows viewing work orders belonging to the assigned team.';

  @override
  String get permWorkOrdersViewAll => 'View all work orders';

  @override
  String get permWorkOrdersViewAllDesc =>
      'Allows viewing every work order across the organization.';

  @override
  String get permWorkOrdersCreate => 'Create work orders';

  @override
  String get permWorkOrdersCreateDesc =>
      'Allows creating new work orders and assigning them to staff.';

  @override
  String get permWorkOrdersUpdate => 'Update work orders';

  @override
  String get permWorkOrdersUpdateDesc =>
      'Allows editing details of existing work orders within allowed scope.';

  @override
  String get permWorkOrdersAssign => 'Assign work orders';

  @override
  String get permWorkOrdersAssignDesc =>
      'Allows assigning or reassigning technicians on work order screens.';

  @override
  String get permWorkOrdersComplete => 'Complete work orders';

  @override
  String get permWorkOrdersCompleteDesc =>
      'Allows marking a work order as completed after the job is finished.';

  @override
  String get permWorkOrdersCancel => 'Cancel work orders';

  @override
  String get permWorkOrdersCancelDesc =>
      'Allows canceling work orders so they are no longer active for field staff.';

  @override
  String get permWorkOrdersDelete => 'Delete work orders';

  @override
  String get permWorkOrdersDeleteDesc =>
      'Allows permanently deleting work orders from the organization records.';

  @override
  String get permInventoryView => 'View inventory';

  @override
  String get permInventoryViewDesc =>
      'Allows browsing inventory items and available stock quantities.';

  @override
  String get permInventoryCreate => 'Create inventory items';

  @override
  String get permInventoryCreateDesc =>
      'Allows registering new inventory items in the stock catalog.';

  @override
  String get permInventoryUpdate => 'Update inventory';

  @override
  String get permInventoryUpdateDesc =>
      'Allows editing inventory item details such as names and attributes.';

  @override
  String get permInventoryDelete => 'Delete inventory';

  @override
  String get permInventoryDeleteDesc =>
      'Allows removing inventory items from the organization catalog.';

  @override
  String get permInventoryStockManage => 'Manage stock quantities';

  @override
  String get permInventoryStockManageDesc =>
      'Allows updating available quantities and stock movements for items.';

  @override
  String get permAssetsView => 'View assets';

  @override
  String get permAssetsViewDesc =>
      'Allows browsing registered asset records in the system.';

  @override
  String get permAssetsCreate => 'Create assets';

  @override
  String get permAssetsCreateDesc =>
      'Allows registering new company assets in the asset register.';

  @override
  String get permAssetsUpdate => 'Update assets';

  @override
  String get permAssetsUpdateDesc =>
      'Allows editing asset details such as status, location, and attributes.';

  @override
  String get permAssetsDelete => 'Delete assets';

  @override
  String get permAssetsDeleteDesc =>
      'Allows permanently removing assets from the organization register.';

  @override
  String get permAssetsAssign => 'Assign assets';

  @override
  String get permAssetsAssignDesc =>
      'Allows assigning assets to users or locations within the organization.';

  @override
  String get permPmView => 'View maintenance';

  @override
  String get permPmViewDesc =>
      'Allows opening preventive maintenance plans and schedule screens.';

  @override
  String get permPmCreate => 'Create maintenance plans';

  @override
  String get permPmCreateDesc =>
      'Allows creating periodic maintenance schedules and plans for assets.';

  @override
  String get permPmUpdate => 'Update maintenance';

  @override
  String get permPmUpdateDesc =>
      'Allows editing existing maintenance plans, dates, and related details.';

  @override
  String get permPmDelete => 'Delete maintenance';

  @override
  String get permPmDeleteDesc =>
      'Allows deleting maintenance plans that are no longer required.';

  @override
  String get permPmManage => 'Manage maintenance';

  @override
  String get permPmManageDesc =>
      'Allows full management of preventive maintenance plans and schedules.';

  @override
  String get permMaintenanceManage => 'Manage maintenance operations';

  @override
  String get permMaintenanceManageDesc =>
      'Allows managing maintenance operations and related work schedules.';

  @override
  String get permReportsView => 'View service reports';

  @override
  String get permReportsViewDesc =>
      'Allows opening and reading completed service reports in the system.';

  @override
  String get permReportsGenerate => 'Generate service reports';

  @override
  String get permReportsGenerateDesc =>
      'Allows generating new service reports from completed field work.';

  @override
  String get permReportsDownload => 'Download service reports';

  @override
  String get permReportsDownloadDesc =>
      'Allows downloading service reports in shareable or printable formats.';

  @override
  String get permUsersView => 'View users';

  @override
  String get permUsersViewDesc =>
      'Allows opening the users list and viewing account details organization-wide.';

  @override
  String get permUsersCreate => 'Create users';

  @override
  String get permUsersCreateDesc =>
      'Allows creating new user accounts inside the organization.';

  @override
  String get permUsersUpdate => 'Update users';

  @override
  String get permUsersUpdateDesc =>
      'Allows editing user profile, contact, and account details.';

  @override
  String get permUsersDelete => 'Delete users';

  @override
  String get permUsersDeleteDesc =>
      'Allows permanently removing user accounts from the organization.';

  @override
  String get permUsersRead => 'View users';

  @override
  String get permUsersReadDesc =>
      'Allows opening the users list and viewing account details organization-wide.';

  @override
  String get permUsersResetPassword => 'Reset password';

  @override
  String get permUsersResetPasswordDesc =>
      'Allows resetting any user\'s password without knowing the current one.';
}
