import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'INFINITY'**
  String get appTitle;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Total-Com Solutions'**
  String get companyName;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get splashLoading;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your field service workspace'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMinLength;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @companyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyLabel;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @workOrders.
  ///
  /// In en, this message translates to:
  /// **'Work Orders'**
  String get workOrders;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get notificationsLoading;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications.'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get notificationsSearchHint;

  /// No description provided for @notificationsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications match your search.'**
  String get notificationsSearchEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnread;

  /// No description provided for @notificationsRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationsRead;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notificationsCategoryGeneral;

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread notification} other{{count} unread notifications}}'**
  String notificationsUnreadCount(int count);

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get globalSearch;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users, work orders, assets…'**
  String get globalSearchHint;

  /// No description provided for @globalSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search across modules.'**
  String get globalSearchPrompt;

  /// No description provided for @globalSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get globalSearchEmpty;

  /// No description provided for @globalSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to search right now.'**
  String get globalSearchFailed;

  /// No description provided for @globalSearchShortcutHint.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+K'**
  String get globalSearchShortcutHint;

  /// No description provided for @reportsCenter.
  ///
  /// In en, this message translates to:
  /// **'Reports Center'**
  String get reportsCenter;

  /// No description provided for @reportsCenterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search report records'**
  String get reportsCenterSearchHint;

  /// No description provided for @reportsCenterFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportsCenterFilters;

  /// No description provided for @reportsCenterApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get reportsCenterApplyFilters;

  /// No description provided for @reportsCenterStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reportsCenterStatusFilter;

  /// No description provided for @reportsCenterFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsCenterFilterAll;

  /// No description provided for @reportsCenterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get reportsCenterDateRange;

  /// No description provided for @reportsCenterCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get reportsCenterCustomRange;

  /// No description provided for @reportsCenterClearDates.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get reportsCenterClearDates;

  /// No description provided for @reportsCenterEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get reportsCenterEmployee;

  /// No description provided for @reportsCenterDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get reportsCenterDepartment;

  /// No description provided for @reportsCenterSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get reportsCenterSort;

  /// No description provided for @reportsCenterSortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get reportsCenterSortTitleAsc;

  /// No description provided for @reportsCenterSortTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Title Z–A'**
  String get reportsCenterSortTitleDesc;

  /// No description provided for @reportsCenterSortDateAsc.
  ///
  /// In en, this message translates to:
  /// **'Date oldest'**
  String get reportsCenterSortDateAsc;

  /// No description provided for @reportsCenterSortDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Date newest'**
  String get reportsCenterSortDateDesc;

  /// No description provided for @reportsCenterSortStatusAsc.
  ///
  /// In en, this message translates to:
  /// **'Status A–Z'**
  String get reportsCenterSortStatusAsc;

  /// No description provided for @reportsCenterSortStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Status Z–A'**
  String get reportsCenterSortStatusDesc;

  /// No description provided for @reportsCenterExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get reportsCenterExport;

  /// No description provided for @reportsCenterExportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Export is not available yet.'**
  String get reportsCenterExportUnavailable;

  /// No description provided for @reportsCenterFilterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This filter is not supported by the current API.'**
  String get reportsCenterFilterUnavailable;

  /// No description provided for @reportsCenterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records match the selected filters.'**
  String get reportsCenterEmpty;

  /// No description provided for @reportsCenterEmptyAttendance.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found for the selected filters.'**
  String get reportsCenterEmptyAttendance;

  /// No description provided for @reportsCenterEmptyOvertime.
  ///
  /// In en, this message translates to:
  /// **'No overtime sessions found for the selected filters.'**
  String get reportsCenterEmptyOvertime;

  /// No description provided for @reportsCenterEmptyWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'No work orders found for the selected filters.'**
  String get reportsCenterEmptyWorkOrders;

  /// No description provided for @reportsCenterEmptyAssets.
  ///
  /// In en, this message translates to:
  /// **'No assets found for the selected filters.'**
  String get reportsCenterEmptyAssets;

  /// No description provided for @reportsCenterEmptyInventory.
  ///
  /// In en, this message translates to:
  /// **'No inventory parts found for the selected filters.'**
  String get reportsCenterEmptyInventory;

  /// No description provided for @reportsCenterEmptyPm.
  ///
  /// In en, this message translates to:
  /// **'No maintenance plans found for the selected filters.'**
  String get reportsCenterEmptyPm;

  /// No description provided for @reportsCenterEmptyServiceReports.
  ///
  /// In en, this message translates to:
  /// **'No service reports found for the selected filters.'**
  String get reportsCenterEmptyServiceReports;

  /// No description provided for @reportsCenterLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load report data.'**
  String get reportsCenterLoadFailed;

  /// No description provided for @reportsCenterNoAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to any report modules.'**
  String get reportsCenterNoAccess;

  /// No description provided for @reportsCenterColTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportsCenterColTitle;

  /// No description provided for @reportsCenterColSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reportsCenterColSubtitle;

  /// No description provided for @reportsCenterColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsCenterColDate;

  /// No description provided for @reportsCenterColMeta.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportsCenterColMeta;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @workOrderCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get workOrderCreate;

  /// No description provided for @workOrderEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit work order'**
  String get workOrderEdit;

  /// No description provided for @workOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Work order details'**
  String get workOrderDetails;

  /// No description provided for @workOrderSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search job, customer, or location'**
  String get workOrderSearchHint;

  /// No description provided for @workOrderFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get workOrderFilterAll;

  /// No description provided for @workOrderEmpty.
  ///
  /// In en, this message translates to:
  /// **'No work orders found'**
  String get workOrderEmpty;

  /// No description provided for @workOrderLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load work orders'**
  String get workOrderLoadFailed;

  /// No description provided for @workOrderLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading work orders...'**
  String get workOrderLoading;

  /// No description provided for @workOrderJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Work order title'**
  String get workOrderJobTitle;

  /// No description provided for @workOrderCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get workOrderCustomer;

  /// No description provided for @workOrderLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get workOrderLocation;

  /// No description provided for @workOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Problem description'**
  String get workOrderDescription;

  /// No description provided for @workOrderNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workOrderNotes;

  /// No description provided for @workOrderPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get workOrderPriority;

  /// No description provided for @workOrderScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled date'**
  String get workOrderScheduledDate;

  /// No description provided for @workOrderTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get workOrderTechnician;

  /// No description provided for @workOrderAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get workOrderAttachments;

  /// No description provided for @workOrderSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get workOrderSave;

  /// No description provided for @workOrderAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get workOrderAccept;

  /// No description provided for @workOrderReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get workOrderReject;

  /// No description provided for @workOrderStart.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get workOrderStart;

  /// No description provided for @workOrderComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get workOrderComplete;

  /// No description provided for @workOrderCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get workOrderCancel;

  /// No description provided for @workOrderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get workOrderDelete;

  /// No description provided for @workOrderAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign technician'**
  String get workOrderAssign;

  /// No description provided for @workOrderUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get workOrderUnassigned;

  /// No description provided for @workOrderSelectTechnician.
  ///
  /// In en, this message translates to:
  /// **'Select technician'**
  String get workOrderSelectTechnician;

  /// No description provided for @workOrderAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get workOrderAddPhoto;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @inventoryManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get inventoryManage;

  /// No description provided for @inventoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading inventory...'**
  String get inventoryLoading;

  /// No description provided for @inventoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inventory'**
  String get inventoryLoadFailed;

  /// No description provided for @inventoryTotalParts.
  ///
  /// In en, this message translates to:
  /// **'Total Parts'**
  String get inventoryTotalParts;

  /// No description provided for @inventoryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get inventoryLowStock;

  /// No description provided for @inventoryOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get inventoryOutOfStock;

  /// No description provided for @inventoryInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inventoryInStock;

  /// No description provided for @inventoryWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get inventoryWarehouses;

  /// No description provided for @inventorySpareParts.
  ///
  /// In en, this message translates to:
  /// **'Spare Parts'**
  String get inventorySpareParts;

  /// No description provided for @inventoryStockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock History'**
  String get inventoryStockHistory;

  /// No description provided for @inventoryRecentMovements.
  ///
  /// In en, this message translates to:
  /// **'Recent Movements'**
  String get inventoryRecentMovements;

  /// No description provided for @inventoryMovementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stock movements yet'**
  String get inventoryMovementsEmpty;

  /// No description provided for @inventoryWarehousesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No warehouses found'**
  String get inventoryWarehousesEmpty;

  /// No description provided for @inventoryPartsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spare parts found'**
  String get inventoryPartsEmpty;

  /// No description provided for @inventoryCreateWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Add warehouse'**
  String get inventoryCreateWarehouse;

  /// No description provided for @inventoryEditWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Edit warehouse'**
  String get inventoryEditWarehouse;

  /// No description provided for @inventoryCreatePart.
  ///
  /// In en, this message translates to:
  /// **'Add spare part'**
  String get inventoryCreatePart;

  /// No description provided for @inventoryEditPart.
  ///
  /// In en, this message translates to:
  /// **'Edit spare part'**
  String get inventoryEditPart;

  /// No description provided for @inventoryPartDetails.
  ///
  /// In en, this message translates to:
  /// **'Part details'**
  String get inventoryPartDetails;

  /// No description provided for @inventorySearchWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Search warehouses'**
  String get inventorySearchWarehouses;

  /// No description provided for @inventorySearchParts.
  ///
  /// In en, this message translates to:
  /// **'Search parts, numbers, or barcodes'**
  String get inventorySearchParts;

  /// No description provided for @inventorySearchMovements.
  ///
  /// In en, this message translates to:
  /// **'Search reason, notes, or user'**
  String get inventorySearchMovements;

  /// No description provided for @inventoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryFilterAll;

  /// No description provided for @inventoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryName;

  /// No description provided for @inventoryCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get inventoryCode;

  /// No description provided for @inventoryAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get inventoryAddress;

  /// No description provided for @inventoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get inventoryDescription;

  /// No description provided for @inventoryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get inventoryActive;

  /// No description provided for @inventoryInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inventoryInactive;

  /// No description provided for @inventoryPartNumber.
  ///
  /// In en, this message translates to:
  /// **'Part number'**
  String get inventoryPartNumber;

  /// No description provided for @inventoryCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryCategory;

  /// No description provided for @inventoryUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inventoryUnit;

  /// No description provided for @inventoryCurrentQuantity.
  ///
  /// In en, this message translates to:
  /// **'Current quantity'**
  String get inventoryCurrentQuantity;

  /// No description provided for @inventoryMinimumQuantity.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity'**
  String get inventoryMinimumQuantity;

  /// No description provided for @inventoryAvailableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Available quantity'**
  String get inventoryAvailableQuantity;

  /// No description provided for @inventoryBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode / QR'**
  String get inventoryBarcode;

  /// No description provided for @inventoryImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get inventoryImage;

  /// No description provided for @inventoryAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get inventoryAddPhoto;

  /// No description provided for @inventoryRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get inventoryRemovePhoto;

  /// No description provided for @inventoryStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock In'**
  String get inventoryStockIn;

  /// No description provided for @inventoryStockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock Out'**
  String get inventoryStockOut;

  /// No description provided for @inventoryTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get inventoryTransfer;

  /// No description provided for @inventoryAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get inventoryAdjustment;

  /// No description provided for @inventoryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryQuantity;

  /// No description provided for @inventoryReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get inventoryReason;

  /// No description provided for @inventoryNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get inventoryNotes;

  /// No description provided for @inventoryWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get inventoryWarehouse;

  /// No description provided for @inventoryFromWarehouse.
  ///
  /// In en, this message translates to:
  /// **'From warehouse'**
  String get inventoryFromWarehouse;

  /// No description provided for @inventoryToWarehouse.
  ///
  /// In en, this message translates to:
  /// **'To warehouse'**
  String get inventoryToWarehouse;

  /// No description provided for @inventoryDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get inventoryDirection;

  /// No description provided for @inventoryIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get inventoryIncrease;

  /// No description provided for @inventoryDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get inventoryDecrease;

  /// No description provided for @inventoryNoWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Create a warehouse before managing stock'**
  String get inventoryNoWarehouses;

  /// No description provided for @inventoryNeedTwoWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Transfer requires at least two warehouses'**
  String get inventoryNeedTwoWarehouses;

  /// No description provided for @inventoryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get inventoryCancel;

  /// No description provided for @inventorySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get inventorySave;

  /// No description provided for @inventoryRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get inventoryRequired;

  /// No description provided for @assetsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading assets...'**
  String get assetsLoading;

  /// No description provided for @assetsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load assets'**
  String get assetsLoadFailed;

  /// No description provided for @assetsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get assetsTotal;

  /// No description provided for @assetsList.
  ///
  /// In en, this message translates to:
  /// **'Assets list'**
  String get assetsList;

  /// No description provided for @assetsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get assetsCategories;

  /// No description provided for @assetsHistory.
  ///
  /// In en, this message translates to:
  /// **'Asset history'**
  String get assetsHistory;

  /// No description provided for @assetsCreate.
  ///
  /// In en, this message translates to:
  /// **'Add asset'**
  String get assetsCreate;

  /// No description provided for @assetsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit asset'**
  String get assetsEdit;

  /// No description provided for @assetsDetails.
  ///
  /// In en, this message translates to:
  /// **'Asset details'**
  String get assetsDetails;

  /// No description provided for @assetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assets found'**
  String get assetsEmpty;

  /// No description provided for @assetsCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get assetsCategoriesEmpty;

  /// No description provided for @assetsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history events yet'**
  String get assetsHistoryEmpty;

  /// No description provided for @assetsCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get assetsCreateCategory;

  /// No description provided for @assetsEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get assetsEditCategory;

  /// No description provided for @assetsSearchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get assetsSearchCategories;

  /// No description provided for @assetsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search number, name, serial, or barcode'**
  String get assetsSearchHint;

  /// No description provided for @assetsSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history title or notes'**
  String get assetsSearchHistory;

  /// No description provided for @assetsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get assetsFilterAll;

  /// No description provided for @assetsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get assetsStatusActive;

  /// No description provided for @assetsStatusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get assetsStatusMaintenance;

  /// No description provided for @assetsStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get assetsStatusOffline;

  /// No description provided for @assetsStatusRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get assetsStatusRetired;

  /// No description provided for @assetsWarrantyExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Warranty expiring soon'**
  String get assetsWarrantyExpiringSoon;

  /// No description provided for @assetsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get assetsName;

  /// No description provided for @assetsCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get assetsCode;

  /// No description provided for @assetsIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get assetsIcon;

  /// No description provided for @assetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get assetsDescription;

  /// No description provided for @assetsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get assetsActive;

  /// No description provided for @assetsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get assetsInactive;

  /// No description provided for @assetsNumber.
  ///
  /// In en, this message translates to:
  /// **'Asset number'**
  String get assetsNumber;

  /// No description provided for @assetsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get assetsCategory;

  /// No description provided for @assetsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get assetsStatus;

  /// No description provided for @assetsSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get assetsSerialNumber;

  /// No description provided for @assetsManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get assetsManufacturer;

  /// No description provided for @assetsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get assetsModel;

  /// No description provided for @assetsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get assetsCustomer;

  /// No description provided for @assetsInstallationDate.
  ///
  /// In en, this message translates to:
  /// **'Installation date'**
  String get assetsInstallationDate;

  /// No description provided for @assetsWarrantyExpiry.
  ///
  /// In en, this message translates to:
  /// **'Warranty expiry'**
  String get assetsWarrantyExpiry;

  /// No description provided for @assetsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get assetsLocation;

  /// No description provided for @assetsNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get assetsNoLocation;

  /// No description provided for @assetsBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get assetsBranch;

  /// No description provided for @assetsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get assetsRegion;

  /// No description provided for @assetsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get assetsCity;

  /// No description provided for @assetsLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get assetsLatitude;

  /// No description provided for @assetsLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get assetsLongitude;

  /// No description provided for @assetsQrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get assetsQrCode;

  /// No description provided for @assetsBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get assetsBarcode;

  /// No description provided for @assetsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get assetsNotes;

  /// No description provided for @assetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get assetsTitle;

  /// No description provided for @assetsAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get assetsAddPhoto;

  /// No description provided for @assetsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get assetsRemovePhoto;

  /// No description provided for @assetsAddHistory.
  ///
  /// In en, this message translates to:
  /// **'Add history'**
  String get assetsAddHistory;

  /// No description provided for @assetsHistoryType.
  ///
  /// In en, this message translates to:
  /// **'History type'**
  String get assetsHistoryType;

  /// No description provided for @assetsHistoryInstallation.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get assetsHistoryInstallation;

  /// No description provided for @assetsHistoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get assetsHistoryMaintenance;

  /// No description provided for @assetsHistoryRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get assetsHistoryRepair;

  /// No description provided for @assetsHistoryInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get assetsHistoryInspection;

  /// No description provided for @assetsHistoryStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Status change'**
  String get assetsHistoryStatusChange;

  /// No description provided for @assetsHistoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get assetsHistoryCreated;

  /// No description provided for @assetsHistoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get assetsHistoryUpdated;

  /// No description provided for @assetsViewFullHistory.
  ///
  /// In en, this message translates to:
  /// **'View full history'**
  String get assetsViewFullHistory;

  /// No description provided for @assetsScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get assetsScanQr;

  /// No description provided for @assetsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get assetsCancel;

  /// No description provided for @assetsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get assetsSave;

  /// No description provided for @assetsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get assetsRequired;

  /// No description provided for @pmTitle.
  ///
  /// In en, this message translates to:
  /// **'Preventive Maintenance'**
  String get pmTitle;

  /// No description provided for @pmLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading preventive maintenance...'**
  String get pmLoading;

  /// No description provided for @pmLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preventive maintenance'**
  String get pmLoadFailed;

  /// No description provided for @pmPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get pmPlans;

  /// No description provided for @pmSchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get pmSchedules;

  /// No description provided for @pmHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get pmHistory;

  /// No description provided for @pmChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get pmChecklist;

  /// No description provided for @pmChecklistBuilder.
  ///
  /// In en, this message translates to:
  /// **'Checklist Builder'**
  String get pmChecklistBuilder;

  /// No description provided for @pmPlanDetails.
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get pmPlanDetails;

  /// No description provided for @pmCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get pmCreatePlan;

  /// No description provided for @pmEditPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get pmEditPlan;

  /// No description provided for @pmDeletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get pmDeletePlan;

  /// No description provided for @pmDeletePlanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this maintenance plan?'**
  String get pmDeletePlanConfirm;

  /// No description provided for @pmPlansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No maintenance plans found'**
  String get pmPlansEmpty;

  /// No description provided for @pmSchedulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No schedules found'**
  String get pmSchedulesEmpty;

  /// No description provided for @pmHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No maintenance history yet'**
  String get pmHistoryEmpty;

  /// No description provided for @pmChecklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checklist items yet'**
  String get pmChecklistEmpty;

  /// No description provided for @pmSearchPlansHint.
  ///
  /// In en, this message translates to:
  /// **'Search plans'**
  String get pmSearchPlansHint;

  /// No description provided for @pmSearchSchedulesHint.
  ///
  /// In en, this message translates to:
  /// **'Search schedules'**
  String get pmSearchSchedulesHint;

  /// No description provided for @pmFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pmFilterAll;

  /// No description provided for @pmUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get pmUpcoming;

  /// No description provided for @pmOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get pmOverdue;

  /// No description provided for @pmCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pmCompleted;

  /// No description provided for @pmCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pmCancelled;

  /// No description provided for @pmActivePlans.
  ///
  /// In en, this message translates to:
  /// **'Active plans'**
  String get pmActivePlans;

  /// No description provided for @pmRecentSchedules.
  ///
  /// In en, this message translates to:
  /// **'Recent schedules'**
  String get pmRecentSchedules;

  /// No description provided for @pmName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pmName;

  /// No description provided for @pmCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get pmCode;

  /// No description provided for @pmDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get pmDescription;

  /// No description provided for @pmFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get pmFrequency;

  /// No description provided for @pmTrigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get pmTrigger;

  /// No description provided for @pmNextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get pmNextDueDate;

  /// No description provided for @pmPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get pmPriority;

  /// No description provided for @pmStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pmStatus;

  /// No description provided for @pmEstimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration (minutes)'**
  String get pmEstimatedDuration;

  /// No description provided for @pmAssignedTeam.
  ///
  /// In en, this message translates to:
  /// **'Assigned team'**
  String get pmAssignedTeam;

  /// No description provided for @pmAssignedTechnician.
  ///
  /// In en, this message translates to:
  /// **'Assigned technician'**
  String get pmAssignedTechnician;

  /// No description provided for @pmLinkedAsset.
  ///
  /// In en, this message translates to:
  /// **'Linked asset'**
  String get pmLinkedAsset;

  /// No description provided for @pmMeterThreshold.
  ///
  /// In en, this message translates to:
  /// **'Meter threshold'**
  String get pmMeterThreshold;

  /// No description provided for @pmCurrentMeterReading.
  ///
  /// In en, this message translates to:
  /// **'Current meter reading'**
  String get pmCurrentMeterReading;

  /// No description provided for @pmScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled date'**
  String get pmScheduledDate;

  /// No description provided for @pmNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pmNotes;

  /// No description provided for @pmNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pmNone;

  /// No description provided for @pmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pmCancel;

  /// No description provided for @pmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pmSave;

  /// No description provided for @pmRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get pmRequired;

  /// No description provided for @pmStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get pmStatusActive;

  /// No description provided for @pmStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get pmStatusInactive;

  /// No description provided for @pmPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get pmPriorityLow;

  /// No description provided for @pmPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get pmPriorityMedium;

  /// No description provided for @pmPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get pmPriorityHigh;

  /// No description provided for @pmPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get pmPriorityCritical;

  /// No description provided for @pmFrequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get pmFrequencyDaily;

  /// No description provided for @pmFrequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get pmFrequencyWeekly;

  /// No description provided for @pmFrequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get pmFrequencyMonthly;

  /// No description provided for @pmFrequencyQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get pmFrequencyQuarterly;

  /// No description provided for @pmFrequencySemiAnnual.
  ///
  /// In en, this message translates to:
  /// **'Semi Annual'**
  String get pmFrequencySemiAnnual;

  /// No description provided for @pmFrequencyAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get pmFrequencyAnnual;

  /// No description provided for @pmTriggerTimeBased.
  ///
  /// In en, this message translates to:
  /// **'Time Based'**
  String get pmTriggerTimeBased;

  /// No description provided for @pmTriggerMeterBased.
  ///
  /// In en, this message translates to:
  /// **'Meter Based'**
  String get pmTriggerMeterBased;

  /// No description provided for @pmScheduleScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get pmScheduleScheduled;

  /// No description provided for @pmScheduleOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get pmScheduleOverdue;

  /// No description provided for @pmScheduleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pmScheduleCompleted;

  /// No description provided for @pmScheduleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pmScheduleCancelled;

  /// No description provided for @pmGenerateSchedules.
  ///
  /// In en, this message translates to:
  /// **'Generate schedules'**
  String get pmGenerateSchedules;

  /// No description provided for @pmSchedulesGenerated.
  ///
  /// In en, this message translates to:
  /// **'{count} schedules generated'**
  String pmSchedulesGenerated(int count);

  /// No description provided for @pmMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String pmMinutes(int count);

  /// No description provided for @pmAddChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get pmAddChecklistItem;

  /// No description provided for @pmEditChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get pmEditChecklistItem;

  /// No description provided for @pmChecklistItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection item'**
  String get pmChecklistItemTitle;

  /// No description provided for @pmChecklistItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get pmChecklistItemDescription;

  /// No description provided for @pmRequiresPassFail.
  ///
  /// In en, this message translates to:
  /// **'Pass / Fail'**
  String get pmRequiresPassFail;

  /// No description provided for @pmRequiresNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pmRequiresNotes;

  /// No description provided for @pmPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo required'**
  String get pmPhotoRequired;

  /// No description provided for @pmCompleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get pmCompleteSchedule;

  /// No description provided for @pmCancelSchedule.
  ///
  /// In en, this message translates to:
  /// **'Cancel schedule'**
  String get pmCancelSchedule;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Reports'**
  String get reportsTitle;

  /// No description provided for @reportsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading service reports...'**
  String get reportsLoading;

  /// No description provided for @reportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load service reports'**
  String get reportsLoadFailed;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No service reports yet'**
  String get reportsEmpty;

  /// No description provided for @reportsList.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsList;

  /// No description provided for @reportsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total reports'**
  String get reportsTotal;

  /// No description provided for @reportsSignatures.
  ///
  /// In en, this message translates to:
  /// **'Signatures'**
  String get reportsSignatures;

  /// No description provided for @reportsCaptureSignature.
  ///
  /// In en, this message translates to:
  /// **'Customer signature'**
  String get reportsCaptureSignature;

  /// No description provided for @reportsGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get reportsGenerate;

  /// No description provided for @reportsPreview.
  ///
  /// In en, this message translates to:
  /// **'Report preview'**
  String get reportsPreview;

  /// No description provided for @reportsDetails.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportsDetails;

  /// No description provided for @reportsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download report'**
  String get reportsDownload;

  /// No description provided for @reportsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reports'**
  String get reportsSearchHint;

  /// No description provided for @reportsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsFilterAll;

  /// No description provided for @reportsStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get reportsStatusDraft;

  /// No description provided for @reportsStatusGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get reportsStatusGenerated;

  /// No description provided for @reportsStatusDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get reportsStatusDownloaded;

  /// No description provided for @reportsWorkOrderInfo.
  ///
  /// In en, this message translates to:
  /// **'Work order information'**
  String get reportsWorkOrderInfo;

  /// No description provided for @reportsAssetInfo.
  ///
  /// In en, this message translates to:
  /// **'Asset information'**
  String get reportsAssetInfo;

  /// No description provided for @reportsTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get reportsTechnician;

  /// No description provided for @reportsJobNumber.
  ///
  /// In en, this message translates to:
  /// **'Job number'**
  String get reportsJobNumber;

  /// No description provided for @reportsJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get reportsJobTitle;

  /// No description provided for @reportsCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get reportsCustomerName;

  /// No description provided for @reportsCustomerPosition.
  ///
  /// In en, this message translates to:
  /// **'Customer position'**
  String get reportsCustomerPosition;

  /// No description provided for @reportsCustomerAddress.
  ///
  /// In en, this message translates to:
  /// **'Customer address'**
  String get reportsCustomerAddress;

  /// No description provided for @reportsAssetNumber.
  ///
  /// In en, this message translates to:
  /// **'Asset number'**
  String get reportsAssetNumber;

  /// No description provided for @reportsAssetName.
  ///
  /// In en, this message translates to:
  /// **'Asset name'**
  String get reportsAssetName;

  /// No description provided for @reportsSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get reportsSerialNumber;

  /// No description provided for @reportsTechnicianName.
  ///
  /// In en, this message translates to:
  /// **'Technician name'**
  String get reportsTechnicianName;

  /// No description provided for @reportsStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get reportsStartTime;

  /// No description provided for @reportsEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get reportsEndTime;

  /// No description provided for @reportsTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration (minutes)'**
  String get reportsTotalDuration;

  /// No description provided for @reportsTechnicianNotes.
  ///
  /// In en, this message translates to:
  /// **'Technician notes'**
  String get reportsTechnicianNotes;

  /// No description provided for @reportsCustomerNotes.
  ///
  /// In en, this message translates to:
  /// **'Customer notes'**
  String get reportsCustomerNotes;

  /// No description provided for @reportsCustomerSignature.
  ///
  /// In en, this message translates to:
  /// **'Customer signature'**
  String get reportsCustomerSignature;

  /// No description provided for @reportsBeforePhotos.
  ///
  /// In en, this message translates to:
  /// **'Before photos'**
  String get reportsBeforePhotos;

  /// No description provided for @reportsProgressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Progress photos'**
  String get reportsProgressPhotos;

  /// No description provided for @reportsAfterPhotos.
  ///
  /// In en, this message translates to:
  /// **'After photos'**
  String get reportsAfterPhotos;

  /// No description provided for @reportsQrCode.
  ///
  /// In en, this message translates to:
  /// **'Report QR code'**
  String get reportsQrCode;

  /// No description provided for @reportsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get reportsNotes;

  /// No description provided for @reportsWorkOrderNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Work order number (optional)'**
  String get reportsWorkOrderNumberOptional;

  /// No description provided for @reportsSignHere.
  ///
  /// In en, this message translates to:
  /// **'Sign here'**
  String get reportsSignHere;

  /// No description provided for @reportsClearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reportsClearSignature;

  /// No description provided for @reportsSaveSignature.
  ///
  /// In en, this message translates to:
  /// **'Save signature'**
  String get reportsSaveSignature;

  /// No description provided for @reportsSignatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a signature'**
  String get reportsSignatureRequired;

  /// No description provided for @reportsSignatureSaved.
  ///
  /// In en, this message translates to:
  /// **'Signature saved'**
  String get reportsSignatureSaved;

  /// No description provided for @reportsSignatureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Signature unavailable'**
  String get reportsSignatureUnavailable;

  /// No description provided for @reportsGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service report generated'**
  String get reportsGeneratedSuccess;

  /// No description provided for @reportsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reportsNone;

  /// No description provided for @reportsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get reportsRequired;

  /// No description provided for @reportsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String reportsMinutes(int count);

  /// No description provided for @reportsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {fileName}'**
  String reportsDownloaded(String fileName);

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get usersTitle;

  /// No description provided for @usersLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading users...'**
  String get usersLoading;

  /// No description provided for @usersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get usersLoadFailed;

  /// No description provided for @usersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get usersEmpty;

  /// No description provided for @usersList.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersList;

  /// No description provided for @usersTotal.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get usersTotal;

  /// No description provided for @usersCreate.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get usersCreate;

  /// No description provided for @usersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get usersEdit;

  /// No description provided for @usersDetails.
  ///
  /// In en, this message translates to:
  /// **'User details'**
  String get usersDetails;

  /// No description provided for @usersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get usersDelete;

  /// No description provided for @usersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get usersDeleteConfirm;

  /// No description provided for @usersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get usersSearchHint;

  /// No description provided for @usersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get usersFilterAll;

  /// No description provided for @usersStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get usersStatusActive;

  /// No description provided for @usersStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get usersStatusDisabled;

  /// No description provided for @usersStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get usersStatusLocked;

  /// No description provided for @usersStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get usersStatus;

  /// No description provided for @usersFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get usersFirstName;

  /// No description provided for @usersLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get usersLastName;

  /// No description provided for @usersUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usersUsername;

  /// No description provided for @usersEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get usersEmail;

  /// No description provided for @usersPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get usersPhone;

  /// No description provided for @usersJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get usersJobTitle;

  /// No description provided for @usersEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get usersEmployeeId;

  /// No description provided for @usersPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get usersPassword;

  /// No description provided for @usersRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get usersRole;

  /// No description provided for @usersDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get usersDepartment;

  /// No description provided for @usersBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get usersBranch;

  /// No description provided for @usersLastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get usersLastLogin;

  /// No description provided for @usersLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get usersLastActive;

  /// No description provided for @usersCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get usersCreatedBy;

  /// No description provided for @usersUpdatedBy.
  ///
  /// In en, this message translates to:
  /// **'Updated by'**
  String get usersUpdatedBy;

  /// No description provided for @usersActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get usersActivity;

  /// No description provided for @usersEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get usersEnable;

  /// No description provided for @usersDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get usersDisable;

  /// No description provided for @usersLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get usersLock;

  /// No description provided for @usersChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get usersChangePassword;

  /// No description provided for @usersResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get usersResetPassword;

  /// No description provided for @usersCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get usersCurrentPassword;

  /// No description provided for @usersNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get usersNewPassword;

  /// No description provided for @usersConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get usersConfirmPassword;

  /// No description provided for @usersPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get usersPasswordMin;

  /// No description provided for @usersPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get usersPasswordMismatch;

  /// No description provided for @usersPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get usersPasswordChanged;

  /// No description provided for @usersPasswordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get usersPasswordResetSuccess;

  /// No description provided for @usersOrgRefsRequired.
  ///
  /// In en, this message translates to:
  /// **'Selected department must include region and city'**
  String get usersOrgRefsRequired;

  /// No description provided for @usersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get usersCancel;

  /// No description provided for @usersSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get usersSave;

  /// No description provided for @usersRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get usersRequired;

  /// No description provided for @rolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get rolesTitle;

  /// No description provided for @rolesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading roles...'**
  String get rolesLoading;

  /// No description provided for @rolesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load roles'**
  String get rolesLoadFailed;

  /// No description provided for @rolesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No roles found'**
  String get rolesEmpty;

  /// No description provided for @rolesList.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get rolesList;

  /// No description provided for @rolesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total roles'**
  String get rolesTotal;

  /// No description provided for @rolesActive.
  ///
  /// In en, this message translates to:
  /// **'Active roles'**
  String get rolesActive;

  /// No description provided for @rolesSystem.
  ///
  /// In en, this message translates to:
  /// **'System roles'**
  String get rolesSystem;

  /// No description provided for @rolesCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom roles'**
  String get rolesCustom;

  /// No description provided for @rolesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create role'**
  String get rolesCreate;

  /// No description provided for @rolesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit role'**
  String get rolesEdit;

  /// No description provided for @rolesDetails.
  ///
  /// In en, this message translates to:
  /// **'Role details'**
  String get rolesDetails;

  /// No description provided for @rolesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete role'**
  String get rolesDelete;

  /// No description provided for @rolesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this role?'**
  String get rolesDeleteConfirm;

  /// No description provided for @rolesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Role deleted'**
  String get rolesDeleted;

  /// No description provided for @rolesCreated.
  ///
  /// In en, this message translates to:
  /// **'Role created'**
  String get rolesCreated;

  /// No description provided for @rolesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get rolesUpdated;

  /// No description provided for @rolesCloned.
  ///
  /// In en, this message translates to:
  /// **'Role cloned'**
  String get rolesCloned;

  /// No description provided for @rolesClone.
  ///
  /// In en, this message translates to:
  /// **'Clone role'**
  String get rolesClone;

  /// No description provided for @rolesActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get rolesActivate;

  /// No description provided for @rolesDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get rolesDeactivate;

  /// No description provided for @rolesAssignUsers.
  ///
  /// In en, this message translates to:
  /// **'Assign users'**
  String get rolesAssignUsers;

  /// No description provided for @rolesAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get rolesAssign;

  /// No description provided for @rolesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Users assigned successfully'**
  String get rolesAssigned;

  /// No description provided for @rolesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search roles'**
  String get rolesSearchHint;

  /// No description provided for @rolesSearchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get rolesSearchUsersHint;

  /// No description provided for @rolesSearchPermissions.
  ///
  /// In en, this message translates to:
  /// **'Search permissions'**
  String get rolesSearchPermissions;

  /// No description provided for @rolesName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get rolesName;

  /// No description provided for @rolesNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Role name is required'**
  String get rolesNameRequired;

  /// No description provided for @rolesDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get rolesDescription;

  /// No description provided for @rolesColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get rolesColor;

  /// No description provided for @rolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get rolesPermissions;

  /// No description provided for @rolesNoPermissions.
  ///
  /// In en, this message translates to:
  /// **'No permissions selected'**
  String get rolesNoPermissions;

  /// No description provided for @rolesPermissionsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No permissions match your search. Try a different title or description.'**
  String get rolesPermissionsSearchEmpty;

  /// No description provided for @rolesPermissionsCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No permissions are available in the catalog.'**
  String get rolesPermissionsCatalogEmpty;

  /// No description provided for @rolesSave.
  ///
  /// In en, this message translates to:
  /// **'Save role'**
  String get rolesSave;

  /// No description provided for @rolesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get rolesCancel;

  /// No description provided for @rolesSystemBadge.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get rolesSystemBadge;

  /// No description provided for @rolesStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get rolesStatusActive;

  /// No description provided for @rolesStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get rolesStatusInactive;

  /// No description provided for @rolesAssignedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned users'**
  String get rolesAssignedUsersTitle;

  /// No description provided for @rolesNoAssignedUsers.
  ///
  /// In en, this message translates to:
  /// **'No users assigned to this role'**
  String get rolesNoAssignedUsers;

  /// No description provided for @rolesNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get rolesNoUsersFound;

  /// No description provided for @rolesAssignedUsers.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String rolesAssignedUsers(int count);

  /// No description provided for @rolesPermissionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions'**
  String rolesPermissionCount(int count);

  /// No description provided for @rolesSelectedPermissions.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String rolesSelectedPermissions(int count);

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the dashboard.'**
  String get dashboardLoadFailed;

  /// No description provided for @dashboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get dashboardLoading;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Operations overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardTodayAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s attendance'**
  String get dashboardTodayAttendance;

  /// No description provided for @dashboardTodayWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s work orders'**
  String get dashboardTodayWorkOrders;

  /// No description provided for @dashboardUpcomingPm.
  ///
  /// In en, this message translates to:
  /// **'Upcoming PM'**
  String get dashboardUpcomingPm;

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock alerts'**
  String get dashboardLowStock;

  /// No description provided for @dashboardRecentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent notifications'**
  String get dashboardRecentNotifications;

  /// No description provided for @dashboardNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No recent notifications'**
  String get dashboardNoNotifications;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardQuickCreateWorkOrder.
  ///
  /// In en, this message translates to:
  /// **'Create work order'**
  String get dashboardQuickCreateWorkOrder;

  /// No description provided for @dashboardQuickStartOvertime.
  ///
  /// In en, this message translates to:
  /// **'Start overtime'**
  String get dashboardQuickStartOvertime;

  /// No description provided for @dashboardPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardPeriodToday;

  /// No description provided for @dashboardPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get dashboardPeriodWeek;

  /// No description provided for @dashboardPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardPeriodMonth;

  /// No description provided for @dashboardPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get dashboardPeriodYear;

  /// No description provided for @dashboardPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dashboardPeriodCustom;

  /// No description provided for @dashboardPeriodFrom.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get dashboardPeriodFrom;

  /// No description provided for @dashboardPeriodTo.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get dashboardPeriodTo;

  /// No description provided for @dashboardPeriodApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dashboardPeriodApply;

  /// No description provided for @dashboardRangeUntilNow.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardRangeUntilNow;

  /// No description provided for @dashboardRangeSpan.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String dashboardRangeSpan(String from, String to);

  /// No description provided for @dashboardReportLine.
  ///
  /// In en, this message translates to:
  /// **'Report: {range}'**
  String dashboardReportLine(String range);

  /// No description provided for @dashboardSectionKpis.
  ///
  /// In en, this message translates to:
  /// **'Key metrics'**
  String get dashboardSectionKpis;

  /// No description provided for @dashboardSectionAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get dashboardSectionAttendance;

  /// No description provided for @dashboardSectionOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get dashboardSectionOvertime;

  /// No description provided for @dashboardSectionWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Work orders'**
  String get dashboardSectionWorkOrders;

  /// No description provided for @dashboardSectionPm.
  ///
  /// In en, this message translates to:
  /// **'Preventive maintenance'**
  String get dashboardSectionPm;

  /// No description provided for @dashboardSectionInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get dashboardSectionInventory;

  /// No description provided for @dashboardSectionAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get dashboardSectionAssets;

  /// No description provided for @dashboardSectionLiveActivity.
  ///
  /// In en, this message translates to:
  /// **'Live activity'**
  String get dashboardSectionLiveActivity;

  /// No description provided for @dashboardSectionCharts.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashboardSectionCharts;

  /// No description provided for @dashboardSectionTeamOverview.
  ///
  /// In en, this message translates to:
  /// **'Team overview'**
  String get dashboardSectionTeamOverview;

  /// No description provided for @dashboardSectionTeamAttendance.
  ///
  /// In en, this message translates to:
  /// **'Team attendance'**
  String get dashboardSectionTeamAttendance;

  /// No description provided for @dashboardSectionTeamOvertime.
  ///
  /// In en, this message translates to:
  /// **'Team overtime'**
  String get dashboardSectionTeamOvertime;

  /// No description provided for @dashboardSectionTeamWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Team work orders'**
  String get dashboardSectionTeamWorkOrders;

  /// No description provided for @dashboardSectionTeamPm.
  ///
  /// In en, this message translates to:
  /// **'Team PM'**
  String get dashboardSectionTeamPm;

  /// No description provided for @dashboardSectionTeamInventory.
  ///
  /// In en, this message translates to:
  /// **'Team inventory alerts'**
  String get dashboardSectionTeamInventory;

  /// No description provided for @dashboardSectionTeamActivity.
  ///
  /// In en, this message translates to:
  /// **'Team activity'**
  String get dashboardSectionTeamActivity;

  /// No description provided for @dashboardSectionTeamPerformance.
  ///
  /// In en, this message translates to:
  /// **'Team performance'**
  String get dashboardSectionTeamPerformance;

  /// No description provided for @dashboardSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get dashboardSectionLocation;

  /// No description provided for @dashboardSectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get dashboardSectionPerformance;

  /// No description provided for @dashboardKpiTotalEmployees.
  ///
  /// In en, this message translates to:
  /// **'Total employees'**
  String get dashboardKpiTotalEmployees;

  /// No description provided for @dashboardKpiActiveEmployees.
  ///
  /// In en, this message translates to:
  /// **'Active employees'**
  String get dashboardKpiActiveEmployees;

  /// No description provided for @dashboardKpiCurrentlyWorking.
  ///
  /// In en, this message translates to:
  /// **'Currently working'**
  String get dashboardKpiCurrentlyWorking;

  /// No description provided for @dashboardKpiOnOvertime.
  ///
  /// In en, this message translates to:
  /// **'On overtime'**
  String get dashboardKpiOnOvertime;

  /// No description provided for @dashboardKpiOnTravelOt.
  ///
  /// In en, this message translates to:
  /// **'On travel OT'**
  String get dashboardKpiOnTravelOt;

  /// No description provided for @dashboardKpiTotalWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Total working hours'**
  String get dashboardKpiTotalWorkingHours;

  /// No description provided for @dashboardKpiAverageWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Average working hours'**
  String get dashboardKpiAverageWorkingHours;

  /// No description provided for @dashboardKpiAttendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get dashboardKpiAttendanceRate;

  /// No description provided for @dashboardKpiOtHours.
  ///
  /// In en, this message translates to:
  /// **'Overtime hours'**
  String get dashboardKpiOtHours;

  /// No description provided for @dashboardKpiTravelOtHours.
  ///
  /// In en, this message translates to:
  /// **'Travel OT hours'**
  String get dashboardKpiTravelOtHours;

  /// No description provided for @dashboardKpiTotalApprovedHours.
  ///
  /// In en, this message translates to:
  /// **'Total Approved Hours'**
  String get dashboardKpiTotalApprovedHours;

  /// No description provided for @dashboardKpiTotalOvertimeHours.
  ///
  /// In en, this message translates to:
  /// **'Total Overtime Hours'**
  String get dashboardKpiTotalOvertimeHours;

  /// No description provided for @dashboardKpiTotalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get dashboardKpiTotalTrips;

  /// No description provided for @dashboardKpiOvernightTrips.
  ///
  /// In en, this message translates to:
  /// **'Overnight Trips'**
  String get dashboardKpiOvernightTrips;

  /// No description provided for @dashboardKpiOtTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Total Technicians'**
  String get dashboardKpiOtTechnicians;

  /// No description provided for @dashboardKpiAvgHoursPerTrip.
  ///
  /// In en, this message translates to:
  /// **'Average Hours per Trip'**
  String get dashboardKpiAvgHoursPerTrip;

  /// No description provided for @dashboardOvertimeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Overtime Analytics'**
  String get dashboardOvertimeAnalytics;

  /// No description provided for @dashboardTechnicianSummary.
  ///
  /// In en, this message translates to:
  /// **'Technician Summary'**
  String get dashboardTechnicianSummary;

  /// No description provided for @dashboardChartHoursPerTechnician.
  ///
  /// In en, this message translates to:
  /// **'Hours per Technician'**
  String get dashboardChartHoursPerTechnician;

  /// No description provided for @dashboardChartTripsPerTechnician.
  ///
  /// In en, this message translates to:
  /// **'Trips per Technician'**
  String get dashboardChartTripsPerTechnician;

  /// No description provided for @dashboardChartHoursOverTime.
  ///
  /// In en, this message translates to:
  /// **'Hours over Time'**
  String get dashboardChartHoursOverTime;

  /// No description provided for @dashboardKpiAvgOtPerEmployee.
  ///
  /// In en, this message translates to:
  /// **'Avg OT per employee'**
  String get dashboardKpiAvgOtPerEmployee;

  /// No description provided for @dashboardKpiWoTotal.
  ///
  /// In en, this message translates to:
  /// **'Total work orders'**
  String get dashboardKpiWoTotal;

  /// No description provided for @dashboardKpiWoPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dashboardKpiWoPending;

  /// No description provided for @dashboardKpiWoAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get dashboardKpiWoAssigned;

  /// No description provided for @dashboardKpiWoInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get dashboardKpiWoInProgress;

  /// No description provided for @dashboardKpiWoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardKpiWoCompleted;

  /// No description provided for @dashboardKpiWoCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dashboardKpiWoCancelled;

  /// No description provided for @dashboardKpiPmDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dashboardKpiPmDue;

  /// No description provided for @dashboardKpiPmOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardKpiPmOverdue;

  /// No description provided for @dashboardKpiPmCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardKpiPmCompleted;

  /// No description provided for @dashboardKpiPmAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned tasks'**
  String get dashboardKpiPmAssigned;

  /// No description provided for @dashboardKpiOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get dashboardKpiOutOfStock;

  /// No description provided for @dashboardKpiAssetsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total assets'**
  String get dashboardKpiAssetsTotal;

  /// No description provided for @dashboardKpiAssetsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardKpiAssetsActive;

  /// No description provided for @dashboardKpiAssetsMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get dashboardKpiAssetsMaintenance;

  /// No description provided for @dashboardKpiAssetsRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get dashboardKpiAssetsRetired;

  /// No description provided for @dashboardKpiTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get dashboardKpiTeamSize;

  /// No description provided for @dashboardKpiMembersPresent.
  ///
  /// In en, this message translates to:
  /// **'Members present'**
  String get dashboardKpiMembersPresent;

  /// No description provided for @dashboardKpiCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get dashboardKpiCompletionRate;

  /// No description provided for @dashboardKpiTodayWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Today\'s working hours'**
  String get dashboardKpiTodayWorkingHours;

  /// No description provided for @dashboardKpiMonthlyWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Period working hours'**
  String get dashboardKpiMonthlyWorkingHours;

  /// No description provided for @dashboardKpiMonthlyOtHours.
  ///
  /// In en, this message translates to:
  /// **'Period OT hours'**
  String get dashboardKpiMonthlyOtHours;

  /// No description provided for @dashboardKpiMonthlyTravelOt.
  ///
  /// In en, this message translates to:
  /// **'Period travel OT'**
  String get dashboardKpiMonthlyTravelOt;

  /// No description provided for @dashboardKpiCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed work orders'**
  String get dashboardKpiCompletedJobs;

  /// No description provided for @dashboardKpiAvgCompletionHours.
  ///
  /// In en, this message translates to:
  /// **'Avg completion hours'**
  String get dashboardKpiAvgCompletionHours;

  /// No description provided for @dashboardNoLiveActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get dashboardNoLiveActivity;

  /// No description provided for @dashboardSystemActor.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get dashboardSystemActor;

  /// No description provided for @dashboardLocationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get dashboardLocationUnknown;

  /// No description provided for @dashboardLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String dashboardLastSync(String date);

  /// No description provided for @dashboardHoursValue.
  ///
  /// In en, this message translates to:
  /// **'{value} h'**
  String dashboardHoursValue(String value);

  /// No description provided for @dashboardPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String dashboardPercentValue(String value);

  /// No description provided for @dashboardChartAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance trend'**
  String get dashboardChartAttendance;

  /// No description provided for @dashboardChartOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime trend'**
  String get dashboardChartOvertime;

  /// No description provided for @dashboardChartWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Work orders trend'**
  String get dashboardChartWorkOrders;

  /// No description provided for @dashboardChartPm.
  ///
  /// In en, this message translates to:
  /// **'PM trend'**
  String get dashboardChartPm;

  /// No description provided for @dashboardChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chart data'**
  String get dashboardChartEmpty;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// No description provided for @dashboardChartWindowDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String dashboardChartWindowDays(int days);

  /// No description provided for @dashboardTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashboardTrends;

  /// No description provided for @dashboardWorkforce.
  ///
  /// In en, this message translates to:
  /// **'Workforce'**
  String get dashboardWorkforce;

  /// No description provided for @dashboardOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get dashboardOperations;

  /// No description provided for @dashboardResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get dashboardResources;

  /// No description provided for @dashboardKeyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Key metrics'**
  String get dashboardKeyMetrics;

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// No description provided for @settingsEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No settings match your search'**
  String get settingsEmptySearch;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionOrganization.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get settingsSectionOrganization;

  /// No description provided for @settingsSectionAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get settingsSectionAdministration;

  /// No description provided for @settingsSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSectionSystem;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get settingsMyProfile;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get settingsNotificationPreferences;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get settingsEmailNotifications;

  /// No description provided for @settingsCompanyInformation.
  ///
  /// In en, this message translates to:
  /// **'Company information'**
  String get settingsCompanyInformation;

  /// No description provided for @settingsOvertimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Overtime Settings'**
  String get settingsOvertimeTitle;

  /// No description provided for @settingsOvertimeVoiceNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Notes'**
  String get settingsOvertimeVoiceNotesTitle;

  /// No description provided for @settingsOvertimeVoiceNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure optional voice notes for overtime journey stages.'**
  String get settingsOvertimeVoiceNotesSubtitle;

  /// No description provided for @settingsOvertimeVoiceMaxDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum Voice Recording Duration'**
  String get settingsOvertimeVoiceMaxDurationTitle;

  /// No description provided for @settingsOvertimeVoiceMaxDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum length allowed for each voice note recorded during an overtime stage.'**
  String get settingsOvertimeVoiceMaxDurationSubtitle;

  /// No description provided for @settingsOvertimeVoiceDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} Minutes'**
  String settingsOvertimeVoiceDurationMinutes(int minutes);

  /// No description provided for @settingsOvertimeVoiceCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value: {value}'**
  String settingsOvertimeVoiceCurrentValue(String value);

  /// No description provided for @settingsOvertimeVoiceQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Recording Quality'**
  String get settingsOvertimeVoiceQualityTitle;

  /// No description provided for @settingsOvertimeVoiceQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Audio quality used when technicians record voice notes during overtime.'**
  String get settingsOvertimeVoiceQualitySubtitle;

  /// No description provided for @settingsOvertimeVoiceQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsOvertimeVoiceQualityHigh;

  /// No description provided for @settingsOvertimeVoiceQualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsOvertimeVoiceQualityMedium;

  /// No description provided for @settingsOvertimeVoiceQualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsOvertimeVoiceQualityLow;

  /// No description provided for @settingsOvertimeMaxPhotoSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum Uploaded Photo Size'**
  String get settingsOvertimeMaxPhotoSizeTitle;

  /// No description provided for @settingsOvertimeMaxPhotoSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos are compressed before upload to stay within this limit whenever possible.'**
  String get settingsOvertimeMaxPhotoSizeSubtitle;

  /// No description provided for @settingsOvertimeMaxPhotoSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String settingsOvertimeMaxPhotoSizeMb(int size);

  /// No description provided for @settingsOvertimeMaxPhotoSizeOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get settingsOvertimeMaxPhotoSizeOriginal;

  /// No description provided for @settingsOvertimeUploadPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Policy'**
  String get settingsOvertimeUploadPolicyTitle;

  /// No description provided for @settingsOvertimeUploadPolicyImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get settingsOvertimeUploadPolicyImmediately;

  /// No description provided for @settingsOvertimeUploadPolicyImmediatelyHint.
  ///
  /// In en, this message translates to:
  /// **'Upload checkpoints as soon as a network connection is available.'**
  String get settingsOvertimeUploadPolicyImmediatelyHint;

  /// No description provided for @settingsOvertimeUploadPolicyWifiPreferred.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Preferred'**
  String get settingsOvertimeUploadPolicyWifiPreferred;

  /// No description provided for @settingsOvertimeUploadPolicyWifiPreferredHint.
  ///
  /// In en, this message translates to:
  /// **'Upload immediately on Wi-Fi. On mobile data, queue until Wi-Fi is available. Technicians can force upload manually.'**
  String get settingsOvertimeUploadPolicyWifiPreferredHint;

  /// No description provided for @settingsOvertimeUploadPolicyManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get settingsOvertimeUploadPolicyManual;

  /// No description provided for @settingsOvertimeUploadPolicyManualHint.
  ///
  /// In en, this message translates to:
  /// **'Always queue uploads. Sync happens only when the technician presses Sync Now.'**
  String get settingsOvertimeUploadPolicyManualHint;

  /// No description provided for @settingsOvertimeUploadPolicyWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Only'**
  String get settingsOvertimeUploadPolicyWifiOnly;

  /// No description provided for @settingsOvertimeUploadPolicyWifiOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Never upload using mobile data. Queue until Wi-Fi is available.'**
  String get settingsOvertimeUploadPolicyWifiOnlyHint;

  /// No description provided for @settingsOvertimeUploadPolicyAskEveryTime.
  ///
  /// In en, this message translates to:
  /// **'Ask Every Time'**
  String get settingsOvertimeUploadPolicyAskEveryTime;

  /// No description provided for @settingsOvertimeUploadPolicyAskEveryTimeHint.
  ///
  /// In en, this message translates to:
  /// **'When uploading on mobile data, ask the technician each time.'**
  String get settingsOvertimeUploadPolicyAskEveryTimeHint;

  /// No description provided for @settingsOvertimeQualityEstimatePerMinute.
  ///
  /// In en, this message translates to:
  /// **'≈ {size} / minute'**
  String settingsOvertimeQualityEstimatePerMinute(String size);

  /// No description provided for @settingsOvertimeEstimatedMaxFileSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Maximum File Size: ≈ {size}'**
  String settingsOvertimeEstimatedMaxFileSize(String size);

  /// No description provided for @settingsOvertimeEstimateKb.
  ///
  /// In en, this message translates to:
  /// **'≈ {size} KB'**
  String settingsOvertimeEstimateKb(int size);

  /// No description provided for @settingsOvertimeEstimateMb.
  ///
  /// In en, this message translates to:
  /// **'≈ {size} MB'**
  String settingsOvertimeEstimateMb(String size);

  /// No description provided for @settingsOvertimeEstimateTotalMb.
  ///
  /// In en, this message translates to:
  /// **'≈ {size} MB'**
  String settingsOvertimeEstimateTotalMb(String size);

  /// No description provided for @settingsOvertimeFileSizeKb.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String settingsOvertimeFileSizeKb(int size);

  /// No description provided for @settingsOvertimeFileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String settingsOvertimeFileSizeMb(String size);

  /// No description provided for @settingsOvertimeFileSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{size} bytes'**
  String settingsOvertimeFileSizeBytes(int size);

  /// No description provided for @settingsOvertimeLargeRecordingWarning.
  ///
  /// In en, this message translates to:
  /// **'Large recordings may increase upload time and mobile data usage.'**
  String get settingsOvertimeLargeRecordingWarning;

  /// No description provided for @settingsOvertimePresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration Preset'**
  String get settingsOvertimePresetTitle;

  /// No description provided for @settingsOvertimePresetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply a recommended profile or customize individual settings.'**
  String get settingsOvertimePresetSubtitle;

  /// No description provided for @settingsOvertimePresetOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get settingsOvertimePresetOffice;

  /// No description provided for @settingsOvertimePresetFieldService.
  ///
  /// In en, this message translates to:
  /// **'Field Service'**
  String get settingsOvertimePresetFieldService;

  /// No description provided for @settingsOvertimePresetHeavyMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Heavy Maintenance'**
  String get settingsOvertimePresetHeavyMaintenance;

  /// No description provided for @settingsOvertimePresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsOvertimePresetCustom;

  /// No description provided for @settingsOvertimeRestoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore Defaults'**
  String get settingsOvertimeRestoreDefaults;

  /// No description provided for @settingsOvertimeRestoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Voice Settings?'**
  String get settingsOvertimeRestoreDialogTitle;

  /// No description provided for @settingsOvertimeRestoreDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will restore:\n• Recording Duration: 5 Minutes\n• Recording Quality: Medium\n• Maximum Photo Size: 2 MB\n• Upload Policy: Immediately'**
  String get settingsOvertimeRestoreDialogBody;

  /// No description provided for @settingsOvertimeRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsOvertimeRestoreConfirm;

  /// No description provided for @settingsOvertimeConfigTestingTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration Testing'**
  String get settingsOvertimeConfigTestingTitle;

  /// No description provided for @settingsOvertimeConfigTestingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview the impact of current settings. Nothing is uploaded or saved.'**
  String get settingsOvertimeConfigTestingSubtitle;

  /// No description provided for @settingsOvertimeVoiceTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Recording Test'**
  String get settingsOvertimeVoiceTestTitle;

  /// No description provided for @settingsOvertimeVoiceTestRecord.
  ///
  /// In en, this message translates to:
  /// **'Test Voice Recording'**
  String get settingsOvertimeVoiceTestRecord;

  /// No description provided for @settingsOvertimeVoiceTestPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get settingsOvertimeVoiceTestPlay;

  /// No description provided for @settingsOvertimeVoiceTestDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsOvertimeVoiceTestDelete;

  /// No description provided for @settingsOvertimeVoiceTestRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record Again'**
  String get settingsOvertimeVoiceTestRecordAgain;

  /// No description provided for @settingsOvertimeVoiceTestTimer.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} / {max}'**
  String settingsOvertimeVoiceTestTimer(String elapsed, String max);

  /// No description provided for @settingsOvertimeVoiceTestDuration.
  ///
  /// In en, this message translates to:
  /// **'Recording Duration'**
  String get settingsOvertimeVoiceTestDuration;

  /// No description provided for @settingsOvertimeVoiceTestEstimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Size'**
  String get settingsOvertimeVoiceTestEstimatedSize;

  /// No description provided for @settingsOvertimeVoiceTestActualSize.
  ///
  /// In en, this message translates to:
  /// **'Actual File Size'**
  String get settingsOvertimeVoiceTestActualSize;

  /// No description provided for @settingsOvertimeVoiceTestEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding Format'**
  String get settingsOvertimeVoiceTestEncoding;

  /// No description provided for @settingsOvertimeVoiceTestBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get settingsOvertimeVoiceTestBitrate;

  /// No description provided for @settingsOvertimeVoiceTestSampleRate.
  ///
  /// In en, this message translates to:
  /// **'Sample Rate'**
  String get settingsOvertimeVoiceTestSampleRate;

  /// No description provided for @settingsOvertimeVoiceTestBitrateKbps.
  ///
  /// In en, this message translates to:
  /// **'{rate} kbps'**
  String settingsOvertimeVoiceTestBitrateKbps(int rate);

  /// No description provided for @settingsOvertimeVoiceTestSampleRateKhz.
  ///
  /// In en, this message translates to:
  /// **'{rate} kHz'**
  String settingsOvertimeVoiceTestSampleRateKhz(int rate);

  /// No description provided for @settingsOvertimePhotoTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Compression Test'**
  String get settingsOvertimePhotoTestTitle;

  /// No description provided for @settingsOvertimePhotoTestCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get settingsOvertimePhotoTestCamera;

  /// No description provided for @settingsOvertimePhotoTestGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get settingsOvertimePhotoTestGallery;

  /// No description provided for @settingsOvertimePhotoTestOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get settingsOvertimePhotoTestOriginal;

  /// No description provided for @settingsOvertimePhotoTestCompressed.
  ///
  /// In en, this message translates to:
  /// **'Compressed'**
  String get settingsOvertimePhotoTestCompressed;

  /// No description provided for @settingsOvertimePhotoTestSplit.
  ///
  /// In en, this message translates to:
  /// **'Split View'**
  String get settingsOvertimePhotoTestSplit;

  /// No description provided for @settingsOvertimePhotoTestCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get settingsOvertimePhotoTestCompare;

  /// No description provided for @settingsOvertimePhotoTestCompareShort.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get settingsOvertimePhotoTestCompareShort;

  /// No description provided for @settingsOvertimePhotoTestOriginalShort.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get settingsOvertimePhotoTestOriginalShort;

  /// No description provided for @settingsOvertimePhotoTestCompressedShort.
  ///
  /// In en, this message translates to:
  /// **'Compressed'**
  String get settingsOvertimePhotoTestCompressedShort;

  /// No description provided for @settingsOvertimePhotoTestMobileStackHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to compare Original and Compressed side by side.'**
  String get settingsOvertimePhotoTestMobileStackHint;

  /// No description provided for @settingsOvertimePhotoTestFullscreenSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe between Original, Compressed, and Split comparison.'**
  String get settingsOvertimePhotoTestFullscreenSwipeHint;

  /// No description provided for @settingsOvertimePhotoTestNoCompressionApplied.
  ///
  /// In en, this message translates to:
  /// **'No compression applied (Original policy)'**
  String get settingsOvertimePhotoTestNoCompressionApplied;

  /// No description provided for @settingsOvertimePhotoTestResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {width} × {height}'**
  String settingsOvertimePhotoTestResolution(int width, int height);

  /// No description provided for @settingsOvertimePhotoTestCompressionRatio.
  ///
  /// In en, this message translates to:
  /// **'Compression Ratio: {percent}%'**
  String settingsOvertimePhotoTestCompressionRatio(int percent);

  /// No description provided for @settingsOvertimePhotoTestEstimatedUpload.
  ///
  /// In en, this message translates to:
  /// **'Estimated Upload Size: {size}'**
  String settingsOvertimePhotoTestEstimatedUpload(String size);

  /// No description provided for @settingsOvertimePhotoTestChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose Another Photo'**
  String get settingsOvertimePhotoTestChooseAnother;

  /// No description provided for @settingsOvertimePhotoTestRetest.
  ///
  /// In en, this message translates to:
  /// **'Retest'**
  String get settingsOvertimePhotoTestRetest;

  /// No description provided for @settingsOvertimePhotoTestDeletePreview.
  ///
  /// In en, this message translates to:
  /// **'Delete Preview'**
  String get settingsOvertimePhotoTestDeletePreview;

  /// No description provided for @settingsOvertimePhotoTestOriginalSize.
  ///
  /// In en, this message translates to:
  /// **'Original Size'**
  String get settingsOvertimePhotoTestOriginalSize;

  /// No description provided for @settingsOvertimePhotoTestCompressedSize.
  ///
  /// In en, this message translates to:
  /// **'Compressed Size'**
  String get settingsOvertimePhotoTestCompressedSize;

  /// No description provided for @settingsOvertimePhotoTestEstimatedCloudinaryUsage.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cloudinary Storage'**
  String get settingsOvertimePhotoTestEstimatedCloudinaryUsage;

  /// No description provided for @settingsOvertimePhotoTestEstimatedUploadTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Upload Time'**
  String get settingsOvertimePhotoTestEstimatedUploadTime;

  /// No description provided for @settingsOvertimePhotoTestOriginalResolution.
  ///
  /// In en, this message translates to:
  /// **'Original Resolution'**
  String get settingsOvertimePhotoTestOriginalResolution;

  /// No description provided for @settingsOvertimePhotoTestCompressedResolution.
  ///
  /// In en, this message translates to:
  /// **'Compressed Resolution'**
  String get settingsOvertimePhotoTestCompressedResolution;

  /// No description provided for @settingsOvertimePhotoTestJpegQuality.
  ///
  /// In en, this message translates to:
  /// **'JPEG Quality'**
  String get settingsOvertimePhotoTestJpegQuality;

  /// No description provided for @settingsOvertimePhotoTestJpegQualityValue.
  ///
  /// In en, this message translates to:
  /// **'{quality}%'**
  String settingsOvertimePhotoTestJpegQualityValue(int quality);

  /// No description provided for @settingsOvertimePhotoTestNoCompression.
  ///
  /// In en, this message translates to:
  /// **'No compression (original policy)'**
  String get settingsOvertimePhotoTestNoCompression;

  /// No description provided for @settingsOvertimePhotoTestUnderPolicyLimit.
  ///
  /// In en, this message translates to:
  /// **'Under policy limit'**
  String get settingsOvertimePhotoTestUnderPolicyLimit;

  /// No description provided for @settingsOvertimePhotoTestSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the slider to compare. Pinch or double-tap to zoom.'**
  String get settingsOvertimePhotoTestSplitHint;

  /// No description provided for @settingsOvertimePhotoTestOpenFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Open fullscreen'**
  String get settingsOvertimePhotoTestOpenFullscreen;

  /// No description provided for @settingsOvertimePhotoTestEstimatedUploadSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Upload Size'**
  String get settingsOvertimePhotoTestEstimatedUploadSize;

  /// No description provided for @settingsOvertimePerformanceInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Information'**
  String get settingsOvertimePerformanceInfoTitle;

  /// No description provided for @settingsOvertimePerformanceVoiceMaxDuration.
  ///
  /// In en, this message translates to:
  /// **'Maximum Duration'**
  String get settingsOvertimePerformanceVoiceMaxDuration;

  /// No description provided for @settingsOvertimePerformanceVoiceMaxSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Maximum Size'**
  String get settingsOvertimePerformanceVoiceMaxSize;

  /// No description provided for @settingsOvertimePerformancePhotoMaxSize.
  ///
  /// In en, this message translates to:
  /// **'Average Maximum Size'**
  String get settingsOvertimePerformancePhotoMaxSize;

  /// No description provided for @settingsOvertimePerformancePhotoAverageMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String settingsOvertimePerformancePhotoAverageMb(int size);

  /// No description provided for @settingsOvertimePerformanceTotalUpload.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total Upload'**
  String get settingsOvertimePerformanceTotalUpload;

  /// No description provided for @settingsOvertimePerformanceCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get settingsOvertimePerformanceCompression;

  /// No description provided for @settingsOvertimeStorageCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage Calculator'**
  String get settingsOvertimeStorageCalculatorTitle;

  /// No description provided for @settingsOvertimeStorageEstimatedVoiceSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Voice Size'**
  String get settingsOvertimeStorageEstimatedVoiceSize;

  /// No description provided for @settingsOvertimeStorageEstimatedImageSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated Image Size'**
  String get settingsOvertimeStorageEstimatedImageSize;

  /// No description provided for @settingsOvertimeStorageEstimatedUploadPerSession.
  ///
  /// In en, this message translates to:
  /// **'Estimated Upload Per Session'**
  String get settingsOvertimeStorageEstimatedUploadPerSession;

  /// No description provided for @settingsOvertimeStorageEstimatedUploadPerTechnician.
  ///
  /// In en, this message translates to:
  /// **'Estimated Upload Per Technician'**
  String get settingsOvertimeStorageEstimatedUploadPerTechnician;

  /// No description provided for @settingsOvertimeStorageEstimatedDailyUsage.
  ///
  /// In en, this message translates to:
  /// **'Estimated Daily Usage'**
  String get settingsOvertimeStorageEstimatedDailyUsage;

  /// No description provided for @settingsOvertimeStorageEstimatedMonthlyUsage.
  ///
  /// In en, this message translates to:
  /// **'Estimated Monthly Usage'**
  String get settingsOvertimeStorageEstimatedMonthlyUsage;

  /// No description provided for @settingsOvertimeStorageEstimatedCloudinaryStorage.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cloudinary Storage'**
  String get settingsOvertimeStorageEstimatedCloudinaryStorage;

  /// No description provided for @settingsOvertimeStorageEstimatedBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Estimated Bandwidth'**
  String get settingsOvertimeStorageEstimatedBandwidth;

  /// No description provided for @overtimeVoiceSettingsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Recording Settings'**
  String get overtimeVoiceSettingsInfoTitle;

  /// No description provided for @overtimeCellularUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Now?'**
  String get overtimeCellularUploadTitle;

  /// No description provided for @overtimeCellularUploadMessage.
  ///
  /// In en, this message translates to:
  /// **'You are using mobile data. How would you like to upload this checkpoint?'**
  String get overtimeCellularUploadMessage;

  /// No description provided for @overtimeCellularUploadWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Only'**
  String get overtimeCellularUploadWifiOnly;

  /// No description provided for @overtimeCellularUploadMobileData.
  ///
  /// In en, this message translates to:
  /// **'Mobile Data'**
  String get overtimeCellularUploadMobileData;

  /// No description provided for @overtimeCellularUploadLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get overtimeCellularUploadLater;

  /// No description provided for @auditOvertimeVoiceDurationChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed voice recording duration from {before} to {after}'**
  String auditOvertimeVoiceDurationChanged(String before, String after);

  /// No description provided for @auditOvertimeVoiceQualityChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed voice quality from {before} to {after}'**
  String auditOvertimeVoiceQualityChanged(String before, String after);

  /// No description provided for @auditOvertimeUploadPolicyChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed upload policy from {before} to {after}'**
  String auditOvertimeUploadPolicyChanged(String before, String after);

  /// No description provided for @auditOvertimeMaxPhotoSizeChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed maximum photo size from {before} to {after}'**
  String auditOvertimeMaxPhotoSizeChanged(String before, String after);

  /// No description provided for @auditOvertimePresetApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied configuration preset: {preset}'**
  String auditOvertimePresetApplied(String preset);

  /// No description provided for @auditOvertimeRestoredDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restored voice settings to defaults'**
  String get auditOvertimeRestoredDefaults;

  /// No description provided for @auditOvertimeVoiceDurationChangedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Changed voice recording duration'**
  String get auditOvertimeVoiceDurationChangedGeneric;

  /// No description provided for @auditOvertimeVoiceQualityChangedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Changed voice recording quality'**
  String get auditOvertimeVoiceQualityChangedGeneric;

  /// No description provided for @auditOvertimeUploadPolicyChangedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Changed upload policy'**
  String get auditOvertimeUploadPolicyChangedGeneric;

  /// No description provided for @auditOvertimeMaxPhotoSizeChangedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Changed maximum photo size'**
  String get auditOvertimeMaxPhotoSizeChangedGeneric;

  /// No description provided for @auditOvertimePresetAppliedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Applied configuration preset'**
  String get auditOvertimePresetAppliedGeneric;

  /// No description provided for @settingsCompanyLogo.
  ///
  /// In en, this message translates to:
  /// **'Company logo'**
  String get settingsCompanyLogo;

  /// No description provided for @settingsCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get settingsCompanyName;

  /// No description provided for @settingsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get settingsContactEmail;

  /// No description provided for @settingsContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get settingsContactPhone;

  /// No description provided for @settingsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get settingsAddress;

  /// No description provided for @settingsAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get settingsAddressLine1;

  /// No description provided for @settingsAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get settingsAddressLine2;

  /// No description provided for @settingsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get settingsCity;

  /// No description provided for @settingsGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get settingsGovernorate;

  /// No description provided for @settingsCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get settingsCountry;

  /// No description provided for @settingsPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get settingsPostalCode;

  /// No description provided for @settingsWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get settingsWorkingHours;

  /// No description provided for @settingsWorkingHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get settingsWorkingHoursStart;

  /// No description provided for @settingsWorkingHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get settingsWorkingHoursEnd;

  /// No description provided for @settingsTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsTimezone;

  /// No description provided for @settingsBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackupRestore;

  /// No description provided for @settingsCacheManagement.
  ///
  /// In en, this message translates to:
  /// **'Cache management'**
  String get settingsCacheManagement;

  /// No description provided for @settingsSystemStatus.
  ///
  /// In en, this message translates to:
  /// **'System status'**
  String get settingsSystemStatus;

  /// No description provided for @settingsApiStatus.
  ///
  /// In en, this message translates to:
  /// **'API status'**
  String get settingsApiStatus;

  /// No description provided for @settingsDatabaseStatus.
  ///
  /// In en, this message translates to:
  /// **'Database status'**
  String get settingsDatabaseStatus;

  /// No description provided for @settingsStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage usage'**
  String get settingsStorageUsage;

  /// No description provided for @settingsApiVersion.
  ///
  /// In en, this message translates to:
  /// **'API version'**
  String get settingsApiVersion;

  /// No description provided for @settingsBackendVersion.
  ///
  /// In en, this message translates to:
  /// **'Backend version'**
  String get settingsBackendVersion;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @settingsUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get settingsUptime;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsOpenSourceLicenses;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'INFINITY processes field service data to support operations for Total-Com Solutions. Personal data is used only for authentication, attendance, and work execution.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsTermsBody.
  ///
  /// In en, this message translates to:
  /// **'Use of INFINITY is limited to authorized personnel. Unauthorized access, data misuse, or redistribution of company information is prohibited.'**
  String get settingsTermsBody;

  /// No description provided for @settingsUiOnly.
  ///
  /// In en, this message translates to:
  /// **'UI only in this release'**
  String get settingsUiOnly;

  /// No description provided for @settingsComingSoonAction.
  ///
  /// In en, this message translates to:
  /// **'This action will be available in a future release'**
  String get settingsComingSoonAction;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Local cache acknowledged'**
  String get settingsCacheCleared;

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get settingsLoading;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings'**
  String get settingsLoadFailed;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsLogoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Company logo updated'**
  String get settingsLogoUpdated;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settingsSave;

  /// No description provided for @serverMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Management'**
  String get serverMgmtTitle;

  /// No description provided for @serverMgmtAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Only administrators can manage the backend server.'**
  String get serverMgmtAccessDenied;

  /// No description provided for @serverMgmtConnectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection Settings'**
  String get serverMgmtConnectionSettings;

  /// No description provided for @serverMgmtBackendUrl.
  ///
  /// In en, this message translates to:
  /// **'Backend Server URL'**
  String get serverMgmtBackendUrl;

  /// No description provided for @serverMgmtUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Accepts https://host or https://host/api/v1 — /api/v1 is applied automatically.'**
  String get serverMgmtUrlHelper;

  /// No description provided for @serverMgmtInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http:// or https:// URL.'**
  String get serverMgmtInvalidUrl;

  /// No description provided for @serverMgmtTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get serverMgmtTestConnection;

  /// No description provided for @serverMgmtPingServer.
  ///
  /// In en, this message translates to:
  /// **'Ping Server'**
  String get serverMgmtPingServer;

  /// No description provided for @serverMgmtSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get serverMgmtSave;

  /// No description provided for @serverMgmtRestoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore Default'**
  String get serverMgmtRestoreDefault;

  /// No description provided for @serverMgmtServerInformation.
  ///
  /// In en, this message translates to:
  /// **'Server Information'**
  String get serverMgmtServerInformation;

  /// No description provided for @serverMgmtCurrentServer.
  ///
  /// In en, this message translates to:
  /// **'Current Server'**
  String get serverMgmtCurrentServer;

  /// No description provided for @serverMgmtStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get serverMgmtStatus;

  /// No description provided for @serverMgmtStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get serverMgmtStatusConnected;

  /// No description provided for @serverMgmtStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get serverMgmtStatusFailed;

  /// No description provided for @serverMgmtStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not tested yet'**
  String get serverMgmtStatusUnknown;

  /// No description provided for @serverMgmtBackendVersion.
  ///
  /// In en, this message translates to:
  /// **'Backend Version'**
  String get serverMgmtBackendVersion;

  /// No description provided for @serverMgmtEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get serverMgmtEnvironment;

  /// No description provided for @serverMgmtResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get serverMgmtResponseTime;

  /// No description provided for @serverMgmtConnectionQuality.
  ///
  /// In en, this message translates to:
  /// **'Connection Quality'**
  String get serverMgmtConnectionQuality;

  /// No description provided for @serverMgmtLastSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Last Successful Connection'**
  String get serverMgmtLastSuccessful;

  /// No description provided for @serverMgmtQualityExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent (<100 ms)'**
  String get serverMgmtQualityExcellent;

  /// No description provided for @serverMgmtQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good (100–250 ms)'**
  String get serverMgmtQualityGood;

  /// No description provided for @serverMgmtQualityFair.
  ///
  /// In en, this message translates to:
  /// **'Fair (250–500 ms)'**
  String get serverMgmtQualityFair;

  /// No description provided for @serverMgmtQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor (>1000 ms)'**
  String get serverMgmtQualityPoor;

  /// No description provided for @serverMgmtQualityUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server Unreachable'**
  String get serverMgmtQualityUnreachable;

  /// No description provided for @serverMgmtAdvancedDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Diagnostics'**
  String get serverMgmtAdvancedDiagnostics;

  /// No description provided for @serverMgmtAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Application Version'**
  String get serverMgmtAppVersion;

  /// No description provided for @serverMgmtBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get serverMgmtBuildNumber;

  /// No description provided for @serverMgmtPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get serverMgmtPlatform;

  /// No description provided for @serverMgmtCurrentApiUrl.
  ///
  /// In en, this message translates to:
  /// **'Current API URL'**
  String get serverMgmtCurrentApiUrl;

  /// No description provided for @serverMgmtDeviceLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Device Local Time'**
  String get serverMgmtDeviceLocalTime;

  /// No description provided for @serverMgmtServerTime.
  ///
  /// In en, this message translates to:
  /// **'Server Time'**
  String get serverMgmtServerTime;

  /// No description provided for @serverMgmtClockDifference.
  ///
  /// In en, this message translates to:
  /// **'Clock Difference'**
  String get serverMgmtClockDifference;

  /// No description provided for @serverMgmtOnlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online / Offline Status'**
  String get serverMgmtOnlineStatus;

  /// No description provided for @serverMgmtOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get serverMgmtOnline;

  /// No description provided for @serverMgmtOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get serverMgmtOffline;

  /// No description provided for @serverMgmtUserRole.
  ///
  /// In en, this message translates to:
  /// **'Current User Role'**
  String get serverMgmtUserRole;

  /// No description provided for @serverMgmtLastSuccessfulSync.
  ///
  /// In en, this message translates to:
  /// **'Last Successful Sync'**
  String get serverMgmtLastSuccessfulSync;

  /// No description provided for @serverMgmtPendingSyncQueue.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync Queue'**
  String get serverMgmtPendingSyncQueue;

  /// No description provided for @serverMgmtNetworkType.
  ///
  /// In en, this message translates to:
  /// **'Network Type'**
  String get serverMgmtNetworkType;

  /// No description provided for @serverMgmtBackendReachable.
  ///
  /// In en, this message translates to:
  /// **'Backend Reachable'**
  String get serverMgmtBackendReachable;

  /// No description provided for @serverMgmtApiHealth.
  ///
  /// In en, this message translates to:
  /// **'API Health'**
  String get serverMgmtApiHealth;

  /// No description provided for @serverMgmtDatabaseConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Database Connectivity'**
  String get serverMgmtDatabaseConnectivity;

  /// No description provided for @serverMgmtAvgLatency.
  ///
  /// In en, this message translates to:
  /// **'Average Latency'**
  String get serverMgmtAvgLatency;

  /// No description provided for @serverMgmtMinLatency.
  ///
  /// In en, this message translates to:
  /// **'Minimum Latency'**
  String get serverMgmtMinLatency;

  /// No description provided for @serverMgmtMaxLatency.
  ///
  /// In en, this message translates to:
  /// **'Maximum Latency'**
  String get serverMgmtMaxLatency;

  /// No description provided for @serverMgmtRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request Timeout'**
  String get serverMgmtRequestTimeout;

  /// No description provided for @serverMgmtAppUptime.
  ///
  /// In en, this message translates to:
  /// **'Application Uptime'**
  String get serverMgmtAppUptime;

  /// No description provided for @serverMgmtDeviceTimezone.
  ///
  /// In en, this message translates to:
  /// **'Device Timezone'**
  String get serverMgmtDeviceTimezone;

  /// No description provided for @serverMgmtServerTimezone.
  ///
  /// In en, this message translates to:
  /// **'Server Timezone'**
  String get serverMgmtServerTimezone;

  /// No description provided for @serverMgmtHealthHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get serverMgmtHealthHealthy;

  /// No description provided for @serverMgmtHealthWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get serverMgmtHealthWarning;

  /// No description provided for @serverMgmtHealthError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get serverMgmtHealthError;

  /// No description provided for @serverMgmtTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected to backend successfully.'**
  String get serverMgmtTestSuccess;

  /// No description provided for @serverMgmtTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check the URL and network.'**
  String get serverMgmtTestFailed;

  /// No description provided for @serverMgmtPingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ping completed.'**
  String get serverMgmtPingSuccess;

  /// No description provided for @serverMgmtPingFailed.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable.'**
  String get serverMgmtPingFailed;

  /// No description provided for @serverMgmtSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backend URL saved. New requests use this server immediately.'**
  String get serverMgmtSaveSuccess;

  /// No description provided for @serverMgmtSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the backend URL.'**
  String get serverMgmtSaveFailed;

  /// No description provided for @serverMgmtRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Default production backend restored.'**
  String get serverMgmtRestoreSuccess;

  /// No description provided for @serverMgmtFutureHint.
  ///
  /// In en, this message translates to:
  /// **'This page is ready for future options such as timeouts, retries, failover, and feature flags.'**
  String get serverMgmtFutureHint;

  /// No description provided for @serverMgmtUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Admin tools unlocked'**
  String get serverMgmtUnlockHint;

  /// No description provided for @serverMgmtBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to open Server Management'**
  String get serverMgmtBiometricReason;

  /// No description provided for @serverMgmtBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device authentication is not available on this device.'**
  String get serverMgmtBiometricUnavailable;

  /// No description provided for @serverMgmtTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Try again.'**
  String get serverMgmtTimeout;

  /// No description provided for @serverMgmtExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics exported.'**
  String get serverMgmtExportSuccess;

  /// No description provided for @serverMgmtExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export diagnostics.'**
  String get serverMgmtExportFailed;

  /// No description provided for @serverMgmtCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Server info copied.'**
  String get serverMgmtCopySuccess;

  /// No description provided for @serverMgmtExportDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Export Diagnostics'**
  String get serverMgmtExportDiagnostics;

  /// No description provided for @serverMgmtCopyServerInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy Server Info'**
  String get serverMgmtCopyServerInfo;

  /// No description provided for @serverMgmtClearUrl.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get serverMgmtClearUrl;

  /// No description provided for @serverMgmtPasteUrl.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get serverMgmtPasteUrl;

  /// No description provided for @serverMgmtCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get serverMgmtCopyUrl;

  /// No description provided for @serverMgmtRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get serverMgmtRetry;

  /// No description provided for @serverMgmtServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server Unreachable'**
  String get serverMgmtServerUnreachable;

  /// No description provided for @serverMgmtUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get serverMgmtUnknown;

  /// No description provided for @serverMgmtQualitySlow.
  ///
  /// In en, this message translates to:
  /// **'Slow (500–1000 ms)'**
  String get serverMgmtQualitySlow;

  /// No description provided for @serverMgmtRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get serverMgmtRegion;

  /// No description provided for @serverMgmtServerUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get serverMgmtServerUptime;

  /// No description provided for @serverMgmtDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get serverMgmtDatabase;

  /// No description provided for @serverMgmtApiUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get serverMgmtApiUrlLabel;

  /// No description provided for @serverMgmtLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get serverMgmtLatency;

  /// No description provided for @serverMgmtVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get serverMgmtVersion;

  /// No description provided for @serverMgmtHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get serverMgmtHealth;

  /// No description provided for @serverMgmtDeviceModel.
  ///
  /// In en, this message translates to:
  /// **'Device Model'**
  String get serverMgmtDeviceModel;

  /// No description provided for @serverMgmtAndroidVersion.
  ///
  /// In en, this message translates to:
  /// **'Android / OS Version'**
  String get serverMgmtAndroidVersion;

  /// No description provided for @serverMgmtLastSuccessfulPing.
  ///
  /// In en, this message translates to:
  /// **'Last Successful Ping'**
  String get serverMgmtLastSuccessfulPing;

  /// No description provided for @serverMgmtConnectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get serverMgmtConnectedBadge;

  /// No description provided for @serverMgmtVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String serverMgmtVersionLabel(String version, String build);

  /// No description provided for @livePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'A live photo is required.'**
  String get livePhotoRequired;

  /// No description provided for @deviceTimeIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Device time appears to be incorrect.'**
  String get deviceTimeIncorrect;

  /// No description provided for @gpsAccuracyTooLow.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy is too low. Move to an open area and try again.'**
  String get gpsAccuracyTooLow;

  /// No description provided for @attendanceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Attendance updated successfully.'**
  String get attendanceUpdated;

  /// No description provided for @attendanceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading attendance...'**
  String get attendanceLoading;

  /// No description provided for @attendanceHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get attendanceHistoryLoading;

  /// No description provided for @attendanceHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance history yet'**
  String get attendanceHistoryEmpty;

  /// No description provided for @attendanceTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get attendanceTimeline;

  /// No description provided for @attendanceHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get attendanceHistoryTooltip;

  /// No description provided for @overtimeEnded.
  ///
  /// In en, this message translates to:
  /// **'Overtime ended. Eligible overtime calculated automatically.'**
  String get overtimeEnded;

  /// No description provided for @normalOvertimeStarted.
  ///
  /// In en, this message translates to:
  /// **'Normal overtime started.'**
  String get normalOvertimeStarted;

  /// No description provided for @travelOvertimeStarted.
  ///
  /// In en, this message translates to:
  /// **'Travel overtime started.'**
  String get travelOvertimeStarted;

  /// No description provided for @overtimeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading overtime...'**
  String get overtimeLoading;

  /// No description provided for @overtimeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load overtime.'**
  String get overtimeLoadFailed;

  /// No description provided for @overtimeMyTooltip.
  ///
  /// In en, this message translates to:
  /// **'My Overtime'**
  String get overtimeMyTooltip;

  /// No description provided for @overtimeManageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage Overtime'**
  String get overtimeManageTooltip;

  /// No description provided for @attendanceClockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock In'**
  String get attendanceClockIn;

  /// No description provided for @attendanceClockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get attendanceClockOut;

  /// No description provided for @attendanceStartBreak.
  ///
  /// In en, this message translates to:
  /// **'Start Break'**
  String get attendanceStartBreak;

  /// No description provided for @attendanceEndBreak.
  ///
  /// In en, this message translates to:
  /// **'End Break'**
  String get attendanceEndBreak;

  /// No description provided for @attendanceShiftCompleted.
  ///
  /// In en, this message translates to:
  /// **'You have completed your shift for today.'**
  String get attendanceShiftCompleted;

  /// No description provided for @attendanceTodayStatus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Status'**
  String get attendanceTodayStatus;

  /// No description provided for @attendanceWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get attendanceWorkingHours;

  /// No description provided for @attendanceBreaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get attendanceBreaks;

  /// No description provided for @attendanceTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance activity recorded yet today.'**
  String get attendanceTimelineEmpty;

  /// No description provided for @attendanceEventClockedIn.
  ///
  /// In en, this message translates to:
  /// **'Clocked in'**
  String get attendanceEventClockedIn;

  /// No description provided for @attendanceEventClockedOut.
  ///
  /// In en, this message translates to:
  /// **'Clocked out'**
  String get attendanceEventClockedOut;

  /// No description provided for @attendanceEventBreakStarted.
  ///
  /// In en, this message translates to:
  /// **'Break started'**
  String get attendanceEventBreakStarted;

  /// No description provided for @attendanceEventBreakEnded.
  ///
  /// In en, this message translates to:
  /// **'Break ended'**
  String get attendanceEventBreakEnded;

  /// No description provided for @attendanceSyncedOffline.
  ///
  /// In en, this message translates to:
  /// **'Synced from offline record'**
  String get attendanceSyncedOffline;

  /// No description provided for @attendanceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistoryTitle;

  /// No description provided for @attendanceStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get attendanceStatusNotStarted;

  /// No description provided for @attendanceStatusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get attendanceStatusWorking;

  /// No description provided for @attendanceStatusOnBreak.
  ///
  /// In en, this message translates to:
  /// **'On break'**
  String get attendanceStatusOnBreak;

  /// No description provided for @attendanceStatusClockedOut.
  ///
  /// In en, this message translates to:
  /// **'Clocked out'**
  String get attendanceStatusClockedOut;

  /// No description provided for @attendanceStatusPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendanceStatusPresent;

  /// No description provided for @attendanceStatusCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get attendanceStatusCheckedOut;

  /// No description provided for @attendanceManagement.
  ///
  /// In en, this message translates to:
  /// **'Attendance Management'**
  String get attendanceManagement;

  /// No description provided for @attendanceManageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage attendance'**
  String get attendanceManageTooltip;

  /// No description provided for @attendanceSearchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search employee name or email'**
  String get attendanceSearchEmployee;

  /// No description provided for @attendanceAdminEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found.'**
  String get attendanceAdminEmpty;

  /// No description provided for @attendanceAdminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attendance records.'**
  String get attendanceAdminLoadFailed;

  /// No description provided for @attendanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Attendance details'**
  String get attendanceDetails;

  /// No description provided for @attendanceDetailsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading attendance details...'**
  String get attendanceDetailsLoading;

  /// No description provided for @attendanceDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attendance details.'**
  String get attendanceDetailsLoadFailed;

  /// No description provided for @attendanceEmployeeInfo.
  ///
  /// In en, this message translates to:
  /// **'Employee information'**
  String get attendanceEmployeeInfo;

  /// No description provided for @attendanceSessionInfo.
  ///
  /// In en, this message translates to:
  /// **'Session information'**
  String get attendanceSessionInfo;

  /// No description provided for @attendanceDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device information'**
  String get attendanceDeviceInfo;

  /// No description provided for @attendanceLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get attendanceLocation;

  /// No description provided for @attendanceDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get attendanceDevice;

  /// No description provided for @attendanceSyncSource.
  ///
  /// In en, this message translates to:
  /// **'Sync source'**
  String get attendanceSyncSource;

  /// No description provided for @attendanceLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get attendanceLastUpdated;

  /// No description provided for @attendanceSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get attendanceSelfie;

  /// No description provided for @attendanceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get attendanceDate;

  /// No description provided for @attendanceOvertimeHours.
  ///
  /// In en, this message translates to:
  /// **'Overtime hours'**
  String get attendanceOvertimeHours;

  /// No description provided for @attendanceRoleAll.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get attendanceRoleAll;

  /// No description provided for @overtimeStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start overtime journey'**
  String get overtimeStartTitle;

  /// No description provided for @overtimeStartHint.
  ///
  /// In en, this message translates to:
  /// **'Official hours are 09:00 AM – 05:00 PM. Time outside that window is calculated automatically. New sessions use four checkpoints; duration still runs from Start Journey to End Journey.'**
  String get overtimeStartHint;

  /// No description provided for @overtimeStartNormal.
  ///
  /// In en, this message translates to:
  /// **'Start Journey — Normal'**
  String get overtimeStartNormal;

  /// No description provided for @overtimeStartTravel.
  ///
  /// In en, this message translates to:
  /// **'Start Journey — Travel'**
  String get overtimeStartTravel;

  /// No description provided for @overtimeStart.
  ///
  /// In en, this message translates to:
  /// **'Start Overtime'**
  String get overtimeStart;

  /// No description provided for @overtimeTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get overtimeTravel;

  /// No description provided for @overtimeOvernightStay.
  ///
  /// In en, this message translates to:
  /// **'Overnight Stay'**
  String get overtimeOvernightStay;

  /// No description provided for @overtimeOvernight.
  ///
  /// In en, this message translates to:
  /// **'Overnight'**
  String get overtimeOvernight;

  /// No description provided for @overtimeEnd.
  ///
  /// In en, this message translates to:
  /// **'End Journey'**
  String get overtimeEnd;

  /// No description provided for @overtimeArrivedAtWorkSite.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Work Site'**
  String get overtimeArrivedAtWorkSite;

  /// No description provided for @overtimeFinishedWork.
  ///
  /// In en, this message translates to:
  /// **'Finish Work'**
  String get overtimeFinishedWork;

  /// No description provided for @overtimeStageStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Journey'**
  String get overtimeStageStartJourney;

  /// No description provided for @overtimeStageArrivedAtWorkSite.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Work Site'**
  String get overtimeStageArrivedAtWorkSite;

  /// No description provided for @overtimeStageFinishedWork.
  ///
  /// In en, this message translates to:
  /// **'Finished Work'**
  String get overtimeStageFinishedWork;

  /// No description provided for @overtimeStageEndJourney.
  ///
  /// In en, this message translates to:
  /// **'End Journey'**
  String get overtimeStageEndJourney;

  /// No description provided for @overtimeCheckpointCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get overtimeCheckpointCompleted;

  /// No description provided for @overtimeCheckpointNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get overtimeCheckpointNext;

  /// No description provided for @overtimeCheckpointPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get overtimeCheckpointPending;

  /// No description provided for @overtimeJourneyTimeline.
  ///
  /// In en, this message translates to:
  /// **'Journey timeline'**
  String get overtimeJourneyTimeline;

  /// No description provided for @overtimeJourneyOverview.
  ///
  /// In en, this message translates to:
  /// **'Journey Overview'**
  String get overtimeJourneyOverview;

  /// No description provided for @overtimeArrivedAtWorkSiteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Arrived at work site recorded.'**
  String get overtimeArrivedAtWorkSiteRecorded;

  /// No description provided for @overtimeFinishedWorkRecorded.
  ///
  /// In en, this message translates to:
  /// **'Finished work recorded.'**
  String get overtimeFinishedWorkRecorded;

  /// No description provided for @overtimeCompletePriorCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous checkpoints before ending the journey.'**
  String get overtimeCompletePriorCheckpoints;

  /// No description provided for @overtimeGpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy'**
  String get overtimeGpsAccuracy;

  /// No description provided for @overtimeDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get overtimeDeviceId;

  /// No description provided for @overtimeBatteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get overtimeBatteryLevel;

  /// No description provided for @overtimeNetworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get overtimeNetworkStatus;

  /// No description provided for @overtimeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get overtimeNotes;

  /// No description provided for @overtimeNotesOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for this checkpoint'**
  String get overtimeNotesOptionalHint;

  /// No description provided for @overtimeVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get overtimeVoiceNote;

  /// No description provided for @overtimeVoiceRecord.
  ///
  /// In en, this message translates to:
  /// **'Record Voice'**
  String get overtimeVoiceRecord;

  /// No description provided for @overtimeVoiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get overtimeVoiceStop;

  /// No description provided for @overtimeVoicePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get overtimeVoicePlay;

  /// No description provided for @overtimeVoicePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get overtimeVoicePause;

  /// No description provided for @overtimeVoiceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get overtimeVoiceDelete;

  /// No description provided for @overtimeVoiceRerecord.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get overtimeVoiceRerecord;

  /// No description provided for @overtimeVoiceMaxDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Maximum {minutes} minutes.'**
  String overtimeVoiceMaxDurationHint(int minutes);

  /// No description provided for @overtimeVoiceLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'Recording will stop in 30 seconds.'**
  String get overtimeVoiceLimitWarning;

  /// No description provided for @overtimeVoiceMaxRecordingInfo.
  ///
  /// In en, this message translates to:
  /// **'Maximum recording: {minutes} minutes'**
  String overtimeVoiceMaxRecordingInfo(int minutes);

  /// No description provided for @overtimeVoicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record a voice note.'**
  String get overtimeVoicePermissionDenied;

  /// No description provided for @overtimeVoiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get overtimeVoiceRecording;

  /// No description provided for @overtimeVoiceRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice Recorded'**
  String get overtimeVoiceRecorded;

  /// No description provided for @overtimeVoiceMaxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum recording length reached.'**
  String get overtimeVoiceMaxReached;

  /// No description provided for @overtimeVoiceUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get overtimeVoiceUploaded;

  /// No description provided for @overtimeVoiceWaitingSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting for synchronization'**
  String get overtimeVoiceWaitingSync;

  /// No description provided for @overtimeVoiceUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading voice note…'**
  String get overtimeVoiceUploading;

  /// No description provided for @overtimeVoicePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to play this recording.'**
  String get overtimeVoicePlaybackFailed;

  /// No description provided for @overtimeExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get overtimeExportExcel;

  /// No description provided for @overtimeExportDenied.
  ///
  /// In en, this message translates to:
  /// **'Only administrators and supervisors can export overtime reports.'**
  String get overtimeExportDenied;

  /// No description provided for @overtimeExportFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Optional filters for the Excel report. Leave blank to export all accessible sessions.'**
  String get overtimeExportFiltersHint;

  /// No description provided for @overtimeExportStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get overtimeExportStartDate;

  /// No description provided for @overtimeExportEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get overtimeExportEndDate;

  /// No description provided for @overtimeExportAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get overtimeExportAll;

  /// No description provided for @overtimeExportEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee user ID'**
  String get overtimeExportEmployeeId;

  /// No description provided for @overtimeExportOptionalIdHint.
  ///
  /// In en, this message translates to:
  /// **'Optional MongoDB ObjectId'**
  String get overtimeExportOptionalIdHint;

  /// No description provided for @overtimeExportModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Export type'**
  String get overtimeExportModeLabel;

  /// No description provided for @overtimeExportReportLanguage.
  ///
  /// In en, this message translates to:
  /// **'Report language'**
  String get overtimeExportReportLanguage;

  /// No description provided for @overtimeExportLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get overtimeExportLanguageEnglish;

  /// No description provided for @overtimeExportLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get overtimeExportLanguageArabic;

  /// No description provided for @overtimeExportModeSummary.
  ///
  /// In en, this message translates to:
  /// **'Export Summary'**
  String get overtimeExportModeSummary;

  /// No description provided for @overtimeExportModeSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Statistics only — no GPS, photos, voice, or journey details.'**
  String get overtimeExportModeSummaryHint;

  /// No description provided for @overtimeExportModeDetailed.
  ///
  /// In en, this message translates to:
  /// **'Export Detailed Report'**
  String get overtimeExportModeDetailed;

  /// No description provided for @overtimeExportModeDetailedHint.
  ///
  /// In en, this message translates to:
  /// **'Complete overtime dataset with maps, voice, photos, and device info.'**
  String get overtimeExportModeDetailedHint;

  /// No description provided for @overtimeExportGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate Excel'**
  String get overtimeExportGenerate;

  /// No description provided for @overtimeExportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing export…'**
  String get overtimeExportPreparing;

  /// No description provided for @overtimeExportDownloading.
  ///
  /// In en, this message translates to:
  /// **'Generating Excel report…'**
  String get overtimeExportDownloading;

  /// No description provided for @overtimeExportSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving file…'**
  String get overtimeExportSaving;

  /// No description provided for @overtimeExportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get overtimeExportReady;

  /// No description provided for @overtimeExportRowCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions exported'**
  String overtimeExportRowCount(int count);

  /// No description provided for @overtimeExportOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get overtimeExportOpen;

  /// No description provided for @overtimeExportOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get overtimeExportOpenFile;

  /// No description provided for @overtimeExportOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Containing Folder'**
  String get overtimeExportOpenFolder;

  /// No description provided for @overtimeExportSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get overtimeExportSaveAs;

  /// No description provided for @overtimeExportSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get overtimeExportSave;

  /// No description provided for @overtimeExportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get overtimeExportShare;

  /// No description provided for @overtimeExportSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String overtimeExportSavedTo(String path);

  /// No description provided for @overtimeExportSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the Excel file. Please try again.'**
  String get overtimeExportSaveFailed;

  /// No description provided for @overtimeExportOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file. Please try again.'**
  String get overtimeExportOpenFailed;

  /// No description provided for @overtimeExportOpenFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the containing folder.'**
  String get overtimeExportOpenFolderFailed;

  /// No description provided for @overtimeRequiresManualReview.
  ///
  /// In en, this message translates to:
  /// **'Requires manual review'**
  String get overtimeRequiresManualReview;

  /// No description provided for @overtimeProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get overtimeProgress;

  /// No description provided for @overtimeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get overtimeStatusLabel;

  /// No description provided for @overtimeStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get overtimeStartTime;

  /// No description provided for @overtimeLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get overtimeLocation;

  /// No description provided for @overtimeRunningTimer.
  ///
  /// In en, this message translates to:
  /// **'Running timer'**
  String get overtimeRunningTimer;

  /// No description provided for @overtimeLastSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Last session summary'**
  String get overtimeLastSessionSummary;

  /// No description provided for @overtimeEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible overtime'**
  String get overtimeEligible;

  /// No description provided for @overtimeWorkedHours.
  ///
  /// In en, this message translates to:
  /// **'Worked Hours'**
  String get overtimeWorkedHours;

  /// No description provided for @overtimeApprovedHours.
  ///
  /// In en, this message translates to:
  /// **'Accepted hours'**
  String get overtimeApprovedHours;

  /// No description provided for @overtimeApprovePartial.
  ///
  /// In en, this message translates to:
  /// **'Approve Partial'**
  String get overtimeApprovePartial;

  /// No description provided for @overtimeApprovePartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Partial Hours'**
  String get overtimeApprovePartialTitle;

  /// No description provided for @overtimeApprovedHoursHint.
  ///
  /// In en, this message translates to:
  /// **'14:30'**
  String get overtimeApprovedHoursHint;

  /// No description provided for @overtimeApprovedHoursHelper.
  ///
  /// In en, this message translates to:
  /// **'Example: 14 hours and 30 minutes'**
  String get overtimeApprovedHoursHelper;

  /// No description provided for @overtimeApprovedHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration as HH:MM (minutes 0–59) that does not exceed worked hours.'**
  String get overtimeApprovedHoursInvalid;

  /// No description provided for @overtimeTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Overtime'**
  String get overtimeTypeNormal;

  /// No description provided for @overtimeTypeTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel Overtime'**
  String get overtimeTypeTravel;

  /// No description provided for @overtimeContinueExistingSession.
  ///
  /// In en, this message translates to:
  /// **'You already have a running overtime session.'**
  String get overtimeContinueExistingSession;

  /// No description provided for @overtimeContinueSession.
  ///
  /// In en, this message translates to:
  /// **'Continue Existing Session'**
  String get overtimeContinueSession;

  /// No description provided for @overtimeActiveSessionReminder.
  ///
  /// In en, this message translates to:
  /// **'Your overtime session is still running. Don\'t forget to end it when you\'re done.'**
  String get overtimeActiveSessionReminder;

  /// No description provided for @overtimeProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String overtimeProgressOf(int current, int total);

  /// No description provided for @overtimeSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get overtimeSyncPending;

  /// No description provided for @overtimeSyncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get overtimeSyncSynced;

  /// No description provided for @overtimeSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get overtimeSyncFailed;

  /// No description provided for @overtimeSyncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — queued'**
  String get overtimeSyncOffline;

  /// No description provided for @overtimeShowMap.
  ///
  /// In en, this message translates to:
  /// **'Show map'**
  String get overtimeShowMap;

  /// No description provided for @overtimeHideMap.
  ///
  /// In en, this message translates to:
  /// **'Hide map'**
  String get overtimeHideMap;

  /// No description provided for @overtimeReviewNotes.
  ///
  /// In en, this message translates to:
  /// **'Review notes'**
  String get overtimeReviewNotes;

  /// No description provided for @overtimeReviewNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for this decision'**
  String get overtimeReviewNotesHint;

  /// No description provided for @overtimeGpsStatus.
  ///
  /// In en, this message translates to:
  /// **'GPS status'**
  String get overtimeGpsStatus;

  /// No description provided for @overtimeSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get overtimeSyncStatus;

  /// No description provided for @overtimeCurrentStage.
  ///
  /// In en, this message translates to:
  /// **'Current stage'**
  String get overtimeCurrentStage;

  /// No description provided for @overtimeLiveCameraRequired.
  ///
  /// In en, this message translates to:
  /// **'Live camera capture is required — gallery selection is disabled.'**
  String get overtimeLiveCameraRequired;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @loadingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingGeneric;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelName;

  /// No description provided for @labelStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get labelStart;

  /// No description provided for @labelEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get labelEnd;

  /// No description provided for @labelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get labelCreated;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterApproved;

  /// No description provided for @filterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get filterRejected;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @deviceRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Device registration failed. Restart the app.'**
  String get deviceRegistrationFailed;

  /// No description provided for @firstSignInRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet is required for the first sign-in.'**
  String get firstSignInRequiresInternet;

  /// No description provided for @attendanceOfflineCachedData.
  ///
  /// In en, this message translates to:
  /// **'Offline mode — showing cached attendance data.'**
  String get attendanceOfflineCachedData;

  /// No description provided for @attendancePendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attendance record pending sync.} other{{count} attendance records pending sync.}}'**
  String attendancePendingSync(int count);

  /// No description provided for @attendancePendingOfflineRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending offline record} other{{count} pending offline records}}'**
  String attendancePendingOfflineRecords(int count);

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get profileLoading;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profilePosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get profilePosition;

  /// No description provided for @profileNoPermissions.
  ///
  /// In en, this message translates to:
  /// **'No permissions assigned'**
  String get profileNoPermissions;

  /// No description provided for @orgTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get orgTitle;

  /// No description provided for @orgCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get orgCompanies;

  /// No description provided for @orgCompaniesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tenant company profile'**
  String get orgCompaniesSubtitle;

  /// No description provided for @orgSearchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies'**
  String get orgSearchCompanies;

  /// No description provided for @orgBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get orgBranches;

  /// No description provided for @orgBranchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Branch locations'**
  String get orgBranchesSubtitle;

  /// No description provided for @orgSearchBranches.
  ///
  /// In en, this message translates to:
  /// **'Search branches'**
  String get orgSearchBranches;

  /// No description provided for @orgDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get orgDepartments;

  /// No description provided for @orgDepartmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Department structure'**
  String get orgDepartmentsSubtitle;

  /// No description provided for @orgSearchDepartments.
  ///
  /// In en, this message translates to:
  /// **'Search departments'**
  String get orgSearchDepartments;

  /// No description provided for @orgTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get orgTeams;

  /// No description provided for @orgTeamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Operational teams'**
  String get orgTeamsSubtitle;

  /// No description provided for @orgSearchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search teams'**
  String get orgSearchTeams;

  /// No description provided for @orgPositions.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get orgPositions;

  /// No description provided for @orgPositionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Job positions'**
  String get orgPositionsSubtitle;

  /// No description provided for @orgSearchPositions.
  ///
  /// In en, this message translates to:
  /// **'Search positions'**
  String get orgSearchPositions;

  /// No description provided for @orgUserDirectory.
  ///
  /// In en, this message translates to:
  /// **'User Directory'**
  String get orgUserDirectory;

  /// No description provided for @orgUserDirectorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Employees and roles'**
  String get orgUserDirectorySubtitle;

  /// No description provided for @orgSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get orgSearchUsers;

  /// No description provided for @orgSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get orgSearch;

  /// No description provided for @orgEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get orgEmpty;

  /// No description provided for @orgNoCachedData.
  ///
  /// In en, this message translates to:
  /// **'No cached data yet.'**
  String get orgNoCachedData;

  /// No description provided for @usersRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get usersRoleAdmin;

  /// No description provided for @usersRoleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get usersRoleSupervisor;

  /// No description provided for @usersRoleTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get usersRoleTechnician;

  /// No description provided for @usersRoleHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get usersRoleHr;

  /// No description provided for @usersRoleWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get usersRoleWarehouse;

  /// No description provided for @usersRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get usersRoleViewer;

  /// No description provided for @usersRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get usersRoleManager;

  /// No description provided for @permGroupDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get permGroupDashboard;

  /// No description provided for @permGroupUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get permGroupUsers;

  /// No description provided for @permGroupRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get permGroupRoles;

  /// No description provided for @permGroupAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get permGroupAttendance;

  /// No description provided for @permGroupOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get permGroupOvertime;

  /// No description provided for @permGroupInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get permGroupInventory;

  /// No description provided for @permGroupAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get permGroupAssets;

  /// No description provided for @permGroupMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get permGroupMaintenance;

  /// No description provided for @permGroupServiceReports.
  ///
  /// In en, this message translates to:
  /// **'Service Reports'**
  String get permGroupServiceReports;

  /// No description provided for @permGroupWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Work Orders'**
  String get permGroupWorkOrders;

  /// No description provided for @permGroupSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get permGroupSettings;

  /// No description provided for @permGroupProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get permGroupProfile;

  /// No description provided for @permGroupNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permGroupNotifications;

  /// No description provided for @permGroupOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get permGroupOrganization;

  /// No description provided for @permGroupAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get permGroupAudit;

  /// No description provided for @permGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get permGroupGeneral;

  /// No description provided for @rolesNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Role not loaded'**
  String get rolesNotLoaded;

  /// No description provided for @rolesSelectAtLeastOneUser.
  ///
  /// In en, this message translates to:
  /// **'Select at least one user'**
  String get rolesSelectAtLeastOneUser;

  /// No description provided for @overtimeMyHistory.
  ///
  /// In en, this message translates to:
  /// **'My Overtime'**
  String get overtimeMyHistory;

  /// No description provided for @overtimeManagement.
  ///
  /// In en, this message translates to:
  /// **'Overtime Management'**
  String get overtimeManagement;

  /// No description provided for @overtimeDetails.
  ///
  /// In en, this message translates to:
  /// **'Overtime Details'**
  String get overtimeDetails;

  /// No description provided for @overtimeDetailsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading details...'**
  String get overtimeDetailsLoading;

  /// No description provided for @overtimeDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load overtime details.'**
  String get overtimeDetailsLoadFailed;

  /// No description provided for @overtimeHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load overtime history.'**
  String get overtimeHistoryLoadFailed;

  /// No description provided for @overtimeHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No overtime history yet.'**
  String get overtimeHistoryEmpty;

  /// No description provided for @overtimeAdminEmpty.
  ///
  /// In en, this message translates to:
  /// **'No overtime sessions found.'**
  String get overtimeAdminEmpty;

  /// No description provided for @overtimeSearchTechnician.
  ///
  /// In en, this message translates to:
  /// **'Search technician name or email'**
  String get overtimeSearchTechnician;

  /// No description provided for @overtimeTechnicianInfo.
  ///
  /// In en, this message translates to:
  /// **'Technician Information'**
  String get overtimeTechnicianInfo;

  /// No description provided for @overtimeSessionInfo.
  ///
  /// In en, this message translates to:
  /// **'Session Information'**
  String get overtimeSessionInfo;

  /// No description provided for @overtimeEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get overtimeEndTime;

  /// No description provided for @overtimeTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get overtimeTotalDuration;

  /// No description provided for @overtimeWorkingDuration.
  ///
  /// In en, this message translates to:
  /// **'Working duration'**
  String get overtimeWorkingDuration;

  /// No description provided for @overtimeRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get overtimeRejectionReason;

  /// No description provided for @overtimeRejectionReasonLine.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason: {reason}'**
  String overtimeRejectionReasonLine(String reason);

  /// No description provided for @overtimeApprovedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get overtimeApprovedBy;

  /// No description provided for @overtimeApprovedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved at'**
  String get overtimeApprovedAt;

  /// No description provided for @overtimeRejectedBy.
  ///
  /// In en, this message translates to:
  /// **'Rejected by'**
  String get overtimeRejectedBy;

  /// No description provided for @overtimeRejectedAt.
  ///
  /// In en, this message translates to:
  /// **'Rejected at'**
  String get overtimeRejectedAt;

  /// No description provided for @overtimeImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get overtimeImages;

  /// No description provided for @overtimeStartPhoto.
  ///
  /// In en, this message translates to:
  /// **'Start photo'**
  String get overtimeStartPhoto;

  /// No description provided for @overtimeEndPhoto.
  ///
  /// In en, this message translates to:
  /// **'End photo'**
  String get overtimeEndPhoto;

  /// No description provided for @overtimeDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get overtimeDeviceInfo;

  /// No description provided for @overtimeStartDevice.
  ///
  /// In en, this message translates to:
  /// **'Start device'**
  String get overtimeStartDevice;

  /// No description provided for @overtimeEndDevice.
  ///
  /// In en, this message translates to:
  /// **'End device'**
  String get overtimeEndDevice;

  /// No description provided for @overtimeNoPhotoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No photo available'**
  String get overtimeNoPhotoAvailable;

  /// No description provided for @overtimeRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Overtime'**
  String get overtimeRejectDialogTitle;

  /// No description provided for @overtimeRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Optional rejection reason'**
  String get overtimeRejectReasonHint;

  /// No description provided for @overtimeApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Overtime approved.'**
  String get overtimeApprovedMessage;

  /// No description provided for @overtimeRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Overtime rejected.'**
  String get overtimeRejectedMessage;

  /// No description provided for @overtimeDurationLine.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String overtimeDurationLine(String duration);

  /// No description provided for @overtimeStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get overtimeStatusRunning;

  /// No description provided for @overtimeStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get overtimeStatusPendingReview;

  /// No description provided for @overtimeStatusPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get overtimeStatusPendingSync;

  /// No description provided for @overtimeStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get overtimeStatusSynced;

  /// No description provided for @overtimeStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get overtimeStatusApproved;

  /// No description provided for @overtimeStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get overtimeStatusRejected;

  /// No description provided for @overtimeStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get overtimeStatusCancelled;

  /// No description provided for @overtimeStartLocation.
  ///
  /// In en, this message translates to:
  /// **'Start Location'**
  String get overtimeStartLocation;

  /// No description provided for @overtimeEndLocation.
  ///
  /// In en, this message translates to:
  /// **'End Location'**
  String get overtimeEndLocation;

  /// No description provided for @overtimeRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get overtimeRoute;

  /// No description provided for @overtimeStartAddress.
  ///
  /// In en, this message translates to:
  /// **'Start Address'**
  String get overtimeStartAddress;

  /// No description provided for @overtimeEndAddress.
  ///
  /// In en, this message translates to:
  /// **'End Address'**
  String get overtimeEndAddress;

  /// No description provided for @overtimeMapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load map tiles'**
  String get overtimeMapLoadFailed;

  /// No description provided for @overtimeMapCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get overtimeMapCheckConnection;

  /// No description provided for @overtimeOpenInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get overtimeOpenInGoogleMaps;

  /// No description provided for @overtimeOpenLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Open Live Location'**
  String get overtimeOpenLiveLocation;

  /// No description provided for @overtimeLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get overtimeLocationUnavailable;

  /// No description provided for @overtimeUnableOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Google Maps.'**
  String get overtimeUnableOpenGoogleMaps;

  /// No description provided for @workOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get workOrderSaved;

  /// No description provided for @workOrderJobTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Job title is required'**
  String get workOrderJobTitleRequired;

  /// No description provided for @workOrderJobTitleMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Job title must be at most 200 characters'**
  String get workOrderJobTitleMaxLength;

  /// No description provided for @workOrderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Work order updated'**
  String get workOrderUpdated;

  /// No description provided for @workOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Work order created'**
  String get workOrderCreated;

  /// No description provided for @workOrderNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to manage work orders.'**
  String get workOrderNoPermission;

  /// No description provided for @workOrderOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get workOrderOverview;

  /// No description provided for @workOrderOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer, location, and job details'**
  String get workOrderOverviewSubtitle;

  /// No description provided for @workOrderViewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get workOrderViewOnMap;

  /// No description provided for @workOrderCouldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps'**
  String get workOrderCouldNotOpenMaps;

  /// No description provided for @workOrderWorkDescription.
  ///
  /// In en, this message translates to:
  /// **'Work description'**
  String get workOrderWorkDescription;

  /// No description provided for @workOrderInternalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal notes'**
  String get workOrderInternalNotes;

  /// No description provided for @workOrderDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get workOrderDocument;

  /// No description provided for @workOrderBeforeWork.
  ///
  /// In en, this message translates to:
  /// **'Before work'**
  String get workOrderBeforeWork;

  /// No description provided for @workOrderBeforeWorkSubtitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Capture site photos and optional notes'**
  String get workOrderBeforeWorkSubtitleEdit;

  /// No description provided for @workOrderBeforeWorkSubtitleView.
  ///
  /// In en, this message translates to:
  /// **'Before-work evidence'**
  String get workOrderBeforeWorkSubtitleView;

  /// No description provided for @workOrderBeforePhotos.
  ///
  /// In en, this message translates to:
  /// **'Before photos'**
  String get workOrderBeforePhotos;

  /// No description provided for @workOrderSavedBeforeNotes.
  ///
  /// In en, this message translates to:
  /// **'Saved before notes'**
  String get workOrderSavedBeforeNotes;

  /// No description provided for @workOrderBeforeNotes.
  ///
  /// In en, this message translates to:
  /// **'Before notes'**
  String get workOrderBeforeNotes;

  /// No description provided for @workOrderBeforeNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes before starting work'**
  String get workOrderBeforeNotesHint;

  /// No description provided for @workOrderInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get workOrderInProgress;

  /// No description provided for @workOrderInProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress photos and field notes'**
  String get workOrderInProgressSubtitle;

  /// No description provided for @workOrderProgressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Progress photos'**
  String get workOrderProgressPhotos;

  /// No description provided for @workOrderProgressNotes.
  ///
  /// In en, this message translates to:
  /// **'Progress notes'**
  String get workOrderProgressNotes;

  /// No description provided for @workOrderNoProgressNotes.
  ///
  /// In en, this message translates to:
  /// **'No progress notes yet'**
  String get workOrderNoProgressNotes;

  /// No description provided for @workOrderAddProgressNote.
  ///
  /// In en, this message translates to:
  /// **'Add progress note'**
  String get workOrderAddProgressNote;

  /// No description provided for @workOrderProgressNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What progress was made?'**
  String get workOrderProgressNoteHint;

  /// No description provided for @workOrderCompleteWork.
  ///
  /// In en, this message translates to:
  /// **'Complete work'**
  String get workOrderCompleteWork;

  /// No description provided for @workOrderCompleteWorkSubtitleEdit.
  ///
  /// In en, this message translates to:
  /// **'At least one after photo is required'**
  String get workOrderCompleteWorkSubtitleEdit;

  /// No description provided for @workOrderCompleteWorkSubtitleView.
  ///
  /// In en, this message translates to:
  /// **'Completion evidence'**
  String get workOrderCompleteWorkSubtitleView;

  /// No description provided for @workOrderCompletionNotes.
  ///
  /// In en, this message translates to:
  /// **'Completion notes'**
  String get workOrderCompletionNotes;

  /// No description provided for @workOrderCompletionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes when completing'**
  String get workOrderCompletionNotesHint;

  /// No description provided for @workOrderCompletionNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Completion notes (optional)'**
  String get workOrderCompletionNotesOptional;

  /// No description provided for @workOrderAfterPhotos.
  ///
  /// In en, this message translates to:
  /// **'After photos'**
  String get workOrderAfterPhotos;

  /// No description provided for @workOrderAfterPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one after photo before completing.'**
  String get workOrderAfterPhotoRequired;

  /// No description provided for @workOrderAfterPhotoRequiredSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Add at least one after photo before completing'**
  String get workOrderAfterPhotoRequiredSnackbar;

  /// No description provided for @workOrderCapturedLocations.
  ///
  /// In en, this message translates to:
  /// **'Captured locations'**
  String get workOrderCapturedLocations;

  /// No description provided for @workOrderCapturedLocationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GPS checkpoints from the field'**
  String get workOrderCapturedLocationsSubtitle;

  /// No description provided for @workOrderLocationStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get workOrderLocationStarted;

  /// No description provided for @workOrderLocationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get workOrderLocationCompleted;

  /// No description provided for @workOrderOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get workOrderOpenMap;

  /// No description provided for @workOrderSaveNotes.
  ///
  /// In en, this message translates to:
  /// **'Save notes'**
  String get workOrderSaveNotes;

  /// No description provided for @workOrderTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get workOrderTakePhoto;

  /// No description provided for @workOrderChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get workOrderChooseFromGallery;

  /// No description provided for @workOrderHideNote.
  ///
  /// In en, this message translates to:
  /// **'Hide {title}'**
  String workOrderHideNote(String title);

  /// No description provided for @workOrderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get workOrderTimeline;

  /// No description provided for @workOrderTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read-only activity history'**
  String get workOrderTimelineSubtitle;

  /// No description provided for @workOrderTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Activity will appear as the work order progresses.'**
  String get workOrderTimelineEmpty;

  /// No description provided for @workOrderSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get workOrderSystem;

  /// No description provided for @workOrderNoPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get workOrderNoPhotosYet;

  /// No description provided for @workOrderDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this work order?'**
  String get workOrderDeleteConfirm;

  /// No description provided for @workOrderRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get workOrderRejectionReason;

  /// No description provided for @workOrderReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get workOrderReasonOptional;

  /// No description provided for @workOrderNoTechnicians.
  ///
  /// In en, this message translates to:
  /// **'No technicians available'**
  String get workOrderNoTechnicians;

  /// No description provided for @workOrderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Work order accepted'**
  String get workOrderAccepted;

  /// No description provided for @workOrderRejected.
  ///
  /// In en, this message translates to:
  /// **'Work order rejected'**
  String get workOrderRejected;

  /// No description provided for @workOrderStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get workOrderStarted;

  /// No description provided for @workOrderCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Work order completed'**
  String get workOrderCompletedMessage;

  /// No description provided for @workOrderCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Work order cancelled'**
  String get workOrderCancelledMessage;

  /// No description provided for @workOrderTechnicianAssigned.
  ///
  /// In en, this message translates to:
  /// **'Technician assigned'**
  String get workOrderTechnicianAssigned;

  /// No description provided for @workOrderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Work order deleted'**
  String get workOrderDeleted;

  /// No description provided for @workOrderBeforeWorkSaved.
  ///
  /// In en, this message translates to:
  /// **'Before-work details saved'**
  String get workOrderBeforeWorkSaved;

  /// No description provided for @workOrderProgressNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Progress note added'**
  String get workOrderProgressNoteAdded;

  /// No description provided for @workOrderProgressPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Progress photo uploaded'**
  String get workOrderProgressPhotoUploaded;

  /// No description provided for @workOrderAfterPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'After photo uploaded'**
  String get workOrderAfterPhotoUploaded;

  /// No description provided for @workOrderPhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get workOrderPhotoRemoved;

  /// No description provided for @workOrderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get workOrderStatusPending;

  /// No description provided for @workOrderStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get workOrderStatusAssigned;

  /// No description provided for @workOrderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get workOrderStatusAccepted;

  /// No description provided for @workOrderStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get workOrderStatusRejected;

  /// No description provided for @workOrderStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get workOrderStatusInProgress;

  /// No description provided for @workOrderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get workOrderStatusCompleted;

  /// No description provided for @workOrderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get workOrderStatusCancelled;

  /// No description provided for @workOrderPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get workOrderPriorityLow;

  /// No description provided for @workOrderPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get workOrderPriorityMedium;

  /// No description provided for @workOrderPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get workOrderPriorityHigh;

  /// No description provided for @workOrderPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get workOrderPriorityCritical;

  /// No description provided for @workOrderTimelineCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get workOrderTimelineCreated;

  /// No description provided for @workOrderTimelineAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get workOrderTimelineAssigned;

  /// No description provided for @workOrderTimelineAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get workOrderTimelineAccepted;

  /// No description provided for @workOrderTimelineRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get workOrderTimelineRejected;

  /// No description provided for @workOrderTimelineStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get workOrderTimelineStarted;

  /// No description provided for @workOrderTimelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get workOrderTimelineCompleted;

  /// No description provided for @workOrderTimelineCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get workOrderTimelineCancelled;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get errorForbidden;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorRequestTimeout;

  /// No description provided for @errorUnableToReachServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server.'**
  String get errorUnableToReachServer;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNoInternet;

  /// No description provided for @errorSecureConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Secure connection failed. Please try again.'**
  String get errorSecureConnectionFailed;

  /// No description provided for @errorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get errorRequestFailed;

  /// No description provided for @errorUnexpectedNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected network error. Please try again.'**
  String get errorUnexpectedNetworkError;

  /// No description provided for @attendanceAlreadyClockedIn.
  ///
  /// In en, this message translates to:
  /// **'You have already clocked in today.'**
  String get attendanceAlreadyClockedIn;

  /// No description provided for @attendanceMustClockInBeforeOut.
  ///
  /// In en, this message translates to:
  /// **'You must clock in before clocking out.'**
  String get attendanceMustClockInBeforeOut;

  /// No description provided for @attendanceEndBreakBeforeOut.
  ///
  /// In en, this message translates to:
  /// **'End your current break before clocking out.'**
  String get attendanceEndBreakBeforeOut;

  /// No description provided for @attendanceAlreadyClockedOut.
  ///
  /// In en, this message translates to:
  /// **'You have already clocked out today.'**
  String get attendanceAlreadyClockedOut;

  /// No description provided for @attendanceMustClockInBeforeBreak.
  ///
  /// In en, this message translates to:
  /// **'You must clock in before starting a break.'**
  String get attendanceMustClockInBeforeBreak;

  /// No description provided for @attendanceBreakAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'A break is already in progress.'**
  String get attendanceBreakAlreadyInProgress;

  /// No description provided for @attendanceNoActiveBreak.
  ///
  /// In en, this message translates to:
  /// **'There is no active break to end.'**
  String get attendanceNoActiveBreak;

  /// No description provided for @attendanceGpsAccuracyExceeded.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy ({accuracy}m) exceeds the allowed threshold ({threshold}m). Move to an open area and try again.'**
  String attendanceGpsAccuracyExceeded(String accuracy, String threshold);

  /// No description provided for @attendanceWebOfflinePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo attendance requires an internet connection on web. Please reconnect and try again.'**
  String get attendanceWebOfflinePhotoRequired;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Enable GPS to continue.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to clock in or out.'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Enable it from device settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location in time. Try again.'**
  String get locationTimeout;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable. A live photo is required.'**
  String get cameraUnavailable;

  /// No description provided for @authNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session.'**
  String get authNoActiveSession;

  /// No description provided for @authOfflineRestoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode. Connect once to restore your profile.'**
  String get authOfflineRestoreProfile;

  /// No description provided for @overtimeNoRunningSession.
  ///
  /// In en, this message translates to:
  /// **'No running overtime session found to end.'**
  String get overtimeNoRunningSession;

  /// No description provided for @assetsQrScannerNotReady.
  ///
  /// In en, this message translates to:
  /// **'QR scanning will be available in a future release.'**
  String get assetsQrScannerNotReady;

  /// No description provided for @orgStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get orgStatusActive;

  /// No description provided for @orgStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get orgStatusInactive;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get errorInvalidEmail;

  /// No description provided for @errorInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password.'**
  String get errorInvalidPassword;

  /// No description provided for @errorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Contact your administrator.'**
  String get errorUserDisabled;

  /// No description provided for @errorClockSkew.
  ///
  /// In en, this message translates to:
  /// **'Device time appears to be incorrect. Sync your clock and try again.'**
  String get errorClockSkew;

  /// No description provided for @errorGpsRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required to continue.'**
  String get errorGpsRequired;

  /// No description provided for @errorLivePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'A live photo is required.'**
  String get errorLivePhotoRequired;

  /// No description provided for @errorWorkOrderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Work order not found.'**
  String get errorWorkOrderNotFound;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested item was not found.'**
  String get errorNotFound;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get errorValidation;

  /// No description provided for @errorGpsAccuracyTooLow.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy is too low. Move to an open area and try again.'**
  String get errorGpsAccuracyTooLow;

  /// No description provided for @errorDeviceRequired.
  ///
  /// In en, this message translates to:
  /// **'Device identification is required.'**
  String get errorDeviceRequired;

  /// No description provided for @errorClientRequestRequired.
  ///
  /// In en, this message translates to:
  /// **'Request identifier is required.'**
  String get errorClientRequestRequired;

  /// No description provided for @errorInvalidTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Invalid date or time.'**
  String get errorInvalidTimestamp;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This action conflicts with the current state.'**
  String get errorConflict;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get errorUserNotFound;

  /// No description provided for @errorOvertimeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Overtime session not found.'**
  String get errorOvertimeNotFound;

  /// No description provided for @errorTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get errorTitleRequired;

  /// No description provided for @errorInvalidPriority.
  ///
  /// In en, this message translates to:
  /// **'Invalid priority value.'**
  String get errorInvalidPriority;

  /// No description provided for @errorInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date value.'**
  String get errorInvalidDate;

  /// No description provided for @errorInvalidStatus.
  ///
  /// In en, this message translates to:
  /// **'Invalid status value.'**
  String get errorInvalidStatus;

  /// No description provided for @errorAvatarRequired.
  ///
  /// In en, this message translates to:
  /// **'Avatar image is required.'**
  String get errorAvatarRequired;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get errorUploadFailed;

  /// No description provided for @valueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get valueNotSet;

  /// No description provided for @workOrderAttachmentFallback.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get workOrderAttachmentFallback;

  /// No description provided for @durationMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{0 minutes} =1{1 minute} other{{minutes} minutes}}'**
  String durationMinutesOnly(int minutes);

  /// No description provided for @durationHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String durationHoursOnly(int hours);

  /// No description provided for @durationHoursAndMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}} {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String durationHoursAndMinutes(int hours, int minutes);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}:{minutes} h'**
  String durationHoursMinutes(String hours, String minutes);

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get navAttendance;

  /// No description provided for @navWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Work Orders'**
  String get navWorkOrders;

  /// No description provided for @navOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get navOvertime;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navProfile;

  /// No description provided for @eventAuthLogin.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get eventAuthLogin;

  /// No description provided for @eventAuthLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in attempt failed'**
  String get eventAuthLoginFailed;

  /// No description provided for @eventAuthLogout.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get eventAuthLogout;

  /// No description provided for @eventAuthTokenRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Session refreshed'**
  String get eventAuthTokenRefreshed;

  /// No description provided for @eventAuthGeneric.
  ///
  /// In en, this message translates to:
  /// **'Account activity'**
  String get eventAuthGeneric;

  /// No description provided for @eventAttendanceGeneric.
  ///
  /// In en, this message translates to:
  /// **'Attendance update'**
  String get eventAttendanceGeneric;

  /// No description provided for @eventOvertimeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Overtime update'**
  String get eventOvertimeGeneric;

  /// No description provided for @eventWorkOrderGeneric.
  ///
  /// In en, this message translates to:
  /// **'Work order update'**
  String get eventWorkOrderGeneric;

  /// No description provided for @eventInventoryGeneric.
  ///
  /// In en, this message translates to:
  /// **'Inventory update'**
  String get eventInventoryGeneric;

  /// No description provided for @eventAssetsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Asset update'**
  String get eventAssetsGeneric;

  /// No description provided for @eventPmGeneric.
  ///
  /// In en, this message translates to:
  /// **'Maintenance update'**
  String get eventPmGeneric;

  /// No description provided for @eventReportsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Report update'**
  String get eventReportsGeneric;

  /// No description provided for @eventUsersGeneric.
  ///
  /// In en, this message translates to:
  /// **'User update'**
  String get eventUsersGeneric;

  /// No description provided for @eventOrganizationGeneric.
  ///
  /// In en, this message translates to:
  /// **'Organization update'**
  String get eventOrganizationGeneric;

  /// No description provided for @eventSecurityGeneric.
  ///
  /// In en, this message translates to:
  /// **'Security event'**
  String get eventSecurityGeneric;

  /// No description provided for @eventGenericActivity.
  ///
  /// In en, this message translates to:
  /// **'System activity'**
  String get eventGenericActivity;

  /// No description provided for @eventFeedActorLine.
  ///
  /// In en, this message translates to:
  /// **'{module} · {actor}'**
  String eventFeedActorLine(String module, String actor);

  /// No description provided for @settingsAccountOverview.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountOverview;

  /// No description provided for @settingsChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get settingsChangePhoto;

  /// No description provided for @settingsPhotoPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview photo'**
  String get settingsPhotoPreview;

  /// No description provided for @settingsPhotoPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Your photo will be saved as a square profile image.'**
  String get settingsPhotoPreviewHint;

  /// No description provided for @settingsPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get settingsPhotoUpdated;

  /// No description provided for @settingsPhotoUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Please choose a JPG, PNG, or WebP image.'**
  String get settingsPhotoUnsupportedFormat;

  /// No description provided for @settingsPhotoDecodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected image.'**
  String get settingsPhotoDecodeFailed;

  /// No description provided for @settingsEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get settingsEmployeeId;

  /// No description provided for @settingsBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get settingsBranch;

  /// No description provided for @settingsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get settingsDepartment;

  /// No description provided for @settingsAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get settingsAccountCreated;

  /// No description provided for @settingsLastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get settingsLastLogin;

  /// No description provided for @settingsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get settingsNotAvailable;

  /// No description provided for @settingsEditablePrefs.
  ///
  /// In en, this message translates to:
  /// **'Editable preferences'**
  String get settingsEditablePrefs;

  /// No description provided for @settingsSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSyncTitle;

  /// No description provided for @settingsLastSuccessfulSync.
  ///
  /// In en, this message translates to:
  /// **'Last successful sync'**
  String get settingsLastSuccessfulSync;

  /// No description provided for @settingsPendingUploads.
  ///
  /// In en, this message translates to:
  /// **'Pending uploads'**
  String get settingsPendingUploads;

  /// No description provided for @settingsPendingDownloads.
  ///
  /// In en, this message translates to:
  /// **'Pending downloads'**
  String get settingsPendingDownloads;

  /// No description provided for @settingsSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get settingsSyncStatus;

  /// No description provided for @settingsAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto sync'**
  String get settingsAutoSync;

  /// No description provided for @settingsWifiOnlySync.
  ///
  /// In en, this message translates to:
  /// **'Wi‑Fi only'**
  String get settingsWifiOnlySync;

  /// No description provided for @settingsSyncInterval.
  ///
  /// In en, this message translates to:
  /// **'Sync interval'**
  String get settingsSyncInterval;

  /// No description provided for @settingsManualSync.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settingsManualSync;

  /// No description provided for @settingsManualSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Sync requested'**
  String get settingsManualSyncDone;

  /// No description provided for @settingsNetworkRequirement.
  ///
  /// In en, this message translates to:
  /// **'Network requirement'**
  String get settingsNetworkRequirement;

  /// No description provided for @settingsStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorageTitle;

  /// No description provided for @settingsCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size'**
  String get settingsCacheSize;

  /// No description provided for @settingsImagesSize.
  ///
  /// In en, this message translates to:
  /// **'Images cache'**
  String get settingsImagesSize;

  /// No description provided for @settingsTempFiles.
  ///
  /// In en, this message translates to:
  /// **'Temporary files'**
  String get settingsTempFiles;

  /// No description provided for @settingsManagedByOs.
  ///
  /// In en, this message translates to:
  /// **'Managed by the system'**
  String get settingsManagedByOs;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupportTitle;

  /// No description provided for @settingsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsContactSupport;

  /// No description provided for @settingsReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get settingsReportBug;

  /// No description provided for @settingsRequestFeature.
  ///
  /// In en, this message translates to:
  /// **'Request a feature'**
  String get settingsRequestFeature;

  /// No description provided for @settingsFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settingsFaq;

  /// No description provided for @settingsSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurityTitle;

  /// No description provided for @settingsCurrentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get settingsCurrentSession;

  /// No description provided for @settingsDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get settingsDeviceName;

  /// No description provided for @settingsBiometricStatus.
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get settingsBiometricStatus;

  /// No description provided for @settingsBiometricAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available on this device'**
  String get settingsBiometricAvailable;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsLogoutAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Log out all devices'**
  String get settingsLogoutAllDevices;

  /// No description provided for @settingsApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsApplicationTitle;

  /// No description provided for @settingsPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get settingsPerformanceTitle;

  /// No description provided for @settingsMemoryUsage.
  ///
  /// In en, this message translates to:
  /// **'Memory usage'**
  String get settingsMemoryUsage;

  /// No description provided for @settingsCacheUsage.
  ///
  /// In en, this message translates to:
  /// **'Cache usage'**
  String get settingsCacheUsage;

  /// No description provided for @settingsNetworkLatency.
  ///
  /// In en, this message translates to:
  /// **'Network latency'**
  String get settingsNetworkLatency;

  /// No description provided for @settingsDatabaseConnection.
  ///
  /// In en, this message translates to:
  /// **'Database connection'**
  String get settingsDatabaseConnection;

  /// No description provided for @settingsServerHealth.
  ///
  /// In en, this message translates to:
  /// **'Server health'**
  String get settingsServerHealth;

  /// No description provided for @settingsUseServerMgmt.
  ///
  /// In en, this message translates to:
  /// **'See Server Management'**
  String get settingsUseServerMgmt;

  /// No description provided for @settingsAccessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibilityTitle;

  /// No description provided for @settingsLargeText.
  ///
  /// In en, this message translates to:
  /// **'Large text'**
  String get settingsLargeText;

  /// No description provided for @settingsReduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduce animations'**
  String get settingsReduceAnimations;

  /// No description provided for @settingsHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get settingsHighContrast;

  /// No description provided for @settingsBackupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Backup is not available yet.'**
  String get settingsBackupUnavailable;

  /// No description provided for @settingsRestoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restore is not available yet.'**
  String get settingsRestoreUnavailable;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsDangerZoneHint.
  ///
  /// In en, this message translates to:
  /// **'These actions only reset local preferences and cache. Business data is never deleted.'**
  String get settingsDangerZoneHint;

  /// No description provided for @settingsResetPreferences.
  ///
  /// In en, this message translates to:
  /// **'Reset preferences'**
  String get settingsResetPreferences;

  /// No description provided for @settingsResetPreferencesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset language, theme, notifications, sync, and accessibility preferences?'**
  String get settingsResetPreferencesConfirm;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear the local image cache? User data will not be deleted.'**
  String get settingsClearCacheConfirm;

  /// No description provided for @settingsRestoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore default settings'**
  String get settingsRestoreDefaults;

  /// No description provided for @settingsRestoreDefaultsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore all preference defaults and clear local cache?'**
  String get settingsRestoreDefaultsConfirm;

  /// No description provided for @settingsPrefsRestored.
  ///
  /// In en, this message translates to:
  /// **'Preferences restored'**
  String get settingsPrefsRestored;

  /// No description provided for @settingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsConfirm;

  /// No description provided for @settingsUpdateCenter.
  ///
  /// In en, this message translates to:
  /// **'Update center'**
  String get settingsUpdateCenter;

  /// No description provided for @settingsLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest available version'**
  String get settingsLatestVersion;

  /// No description provided for @settingsReleaseChannel.
  ///
  /// In en, this message translates to:
  /// **'Release channel'**
  String get settingsReleaseChannel;

  /// No description provided for @settingsReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get settingsReleaseDate;

  /// No description provided for @settingsUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get settingsUpdateStatus;

  /// No description provided for @settingsUpdateIdle.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get settingsUpdateIdle;

  /// No description provided for @settingsUpdateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settingsUpdateChecking;

  /// No description provided for @settingsUpdateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get settingsUpdateUpToDate;

  /// No description provided for @settingsUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get settingsUpdateAvailable;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to check'**
  String get settingsUpdateFailed;

  /// No description provided for @settingsCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdates;

  /// No description provided for @settingsViewReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'View release notes'**
  String get settingsViewReleaseNotes;

  /// No description provided for @settingsDownloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get settingsDownloadUpdate;

  /// No description provided for @settingsDownloadUpdateSoon.
  ///
  /// In en, this message translates to:
  /// **'OTA downloads will be available in a future release.'**
  String get settingsDownloadUpdateSoon;

  /// No description provided for @settingsAdminLogs.
  ///
  /// In en, this message translates to:
  /// **'Application logs'**
  String get settingsAdminLogs;

  /// No description provided for @settingsSearchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search logs'**
  String get settingsSearchLogs;

  /// No description provided for @settingsLogAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get settingsLogAll;

  /// No description provided for @settingsLogCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get settingsLogCategoryAll;

  /// No description provided for @settingsCopyLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy logs'**
  String get settingsCopyLogs;

  /// No description provided for @settingsExportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get settingsExportLogs;

  /// No description provided for @settingsClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get settingsClearLogs;

  /// No description provided for @settingsLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied'**
  String get settingsLogsCopied;

  /// No description provided for @settingsLogEntries.
  ///
  /// In en, this message translates to:
  /// **'Log entries'**
  String get settingsLogEntries;

  /// No description provided for @settingsNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No log entries yet'**
  String get settingsNoLogs;

  /// No description provided for @settingsDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get settingsDeveloperOptions;

  /// No description provided for @settingsFeatureFlags.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get settingsFeatureFlags;

  /// No description provided for @settingsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get settingsReadOnly;

  /// No description provided for @settingsNoFeatureFlags.
  ///
  /// In en, this message translates to:
  /// **'No feature flags configured'**
  String get settingsNoFeatureFlags;

  /// No description provided for @settingsNotifAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance notifications'**
  String get settingsNotifAttendance;

  /// No description provided for @settingsNotifTasks.
  ///
  /// In en, this message translates to:
  /// **'Work order notifications'**
  String get settingsNotifTasks;

  /// No description provided for @settingsNotifOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime notifications'**
  String get settingsNotifOvertime;

  /// No description provided for @settingsNotifSync.
  ///
  /// In en, this message translates to:
  /// **'Sync notifications'**
  String get settingsNotifSync;

  /// No description provided for @settingsNotifUpdates.
  ///
  /// In en, this message translates to:
  /// **'Update notifications'**
  String get settingsNotifUpdates;

  /// No description provided for @settingsThemePreview.
  ///
  /// In en, this message translates to:
  /// **'Theme preview'**
  String get settingsThemePreview;

  /// No description provided for @settingsThemePreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Example only — switch Light or Dark below to preview components. This does not change the app theme.'**
  String get settingsThemePreviewBody;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutApp;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @settingsCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright © {year} {company}. All rights reserved.'**
  String settingsCopyright(String year, String company);

  /// No description provided for @settingsOpenSourcePackages.
  ///
  /// In en, this message translates to:
  /// **'Open source packages'**
  String get settingsOpenSourcePackages;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & privacy'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsSectionDeveloper;

  /// No description provided for @settingsDiagDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsDiagDevice;

  /// No description provided for @settingsDiagNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsDiagNetwork;

  /// No description provided for @settingsDiagServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsDiagServer;

  /// No description provided for @settingsDiagApi.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get settingsDiagApi;

  /// No description provided for @settingsDiagDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get settingsDiagDatabase;

  /// No description provided for @settingsDiagAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get settingsDiagAuth;

  /// No description provided for @settingsDiagPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get settingsDiagPerformance;

  /// No description provided for @serverMgmtBadgeHttps.
  ///
  /// In en, this message translates to:
  /// **'Secure HTTPS'**
  String get serverMgmtBadgeHttps;

  /// No description provided for @serverMgmtBadgeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get serverMgmtBadgeLocal;

  /// No description provided for @serverMgmtBadgeDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get serverMgmtBadgeDevelopment;

  /// No description provided for @serverMgmtBadgeProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get serverMgmtBadgeProduction;

  /// No description provided for @settingsLogLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settingsLogLevelDebug;

  /// No description provided for @settingsLogLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get settingsLogLevelInfo;

  /// No description provided for @settingsLogLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get settingsLogLevelWarning;

  /// No description provided for @settingsLogLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get settingsLogLevelError;

  /// No description provided for @settingsLogCategoryNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsLogCategoryNetwork;

  /// No description provided for @settingsLogCategoryAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get settingsLogCategoryAuth;

  /// No description provided for @settingsLogCategorySync.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get settingsLogCategorySync;

  /// No description provided for @permGroupDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for viewing system statistics and key performance indicators.'**
  String get permGroupDashboardDesc;

  /// No description provided for @permGroupUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for managing user accounts across the organization.'**
  String get permGroupUsersDesc;

  /// No description provided for @permGroupRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for managing roles and assigning access rights.'**
  String get permGroupRolesDesc;

  /// No description provided for @permGroupAttendanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for reviewing and managing employee attendance records.'**
  String get permGroupAttendanceDesc;

  /// No description provided for @permGroupOvertimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for creating, approving, and managing overtime sessions.'**
  String get permGroupOvertimeDesc;

  /// No description provided for @permGroupInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for managing inventory items and stock quantities.'**
  String get permGroupInventoryDesc;

  /// No description provided for @permGroupAssetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for managing and tracking organization assets.'**
  String get permGroupAssetsDesc;

  /// No description provided for @permGroupMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for maintenance plans and related operations.'**
  String get permGroupMaintenanceDesc;

  /// No description provided for @permGroupServiceReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for viewing, generating, and downloading service reports.'**
  String get permGroupServiceReportsDesc;

  /// No description provided for @permGroupWorkOrdersDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for creating, managing, and completing work orders.'**
  String get permGroupWorkOrdersDesc;

  /// No description provided for @permGroupSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for system and organization configuration settings.'**
  String get permGroupSettingsDesc;

  /// No description provided for @permGroupProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for managing the signed-in user personal profile.'**
  String get permGroupProfileDesc;

  /// No description provided for @permGroupNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for sending, receiving, and managing notifications.'**
  String get permGroupNotificationsDesc;

  /// No description provided for @permGroupOrganizationDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for managing company structure, branches, and departments.'**
  String get permGroupOrganizationDesc;

  /// No description provided for @permGroupAuditDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions for reviewing activity history and system change logs.'**
  String get permGroupAuditDesc;

  /// No description provided for @permGroupGeneralDesc.
  ///
  /// In en, this message translates to:
  /// **'General platform permissions not tied to a specific module.'**
  String get permGroupGeneralDesc;

  /// No description provided for @permOrganizationView.
  ///
  /// In en, this message translates to:
  /// **'View organization'**
  String get permOrganizationView;

  /// No description provided for @permOrganizationViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows browsing company structure, branches, and directory screens.'**
  String get permOrganizationViewDesc;

  /// No description provided for @permOrganizationManageBranches.
  ///
  /// In en, this message translates to:
  /// **'Manage branches'**
  String get permOrganizationManageBranches;

  /// No description provided for @permOrganizationManageBranchesDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating and editing company branches used across the organization.'**
  String get permOrganizationManageBranchesDesc;

  /// No description provided for @permOrganizationManageRegions.
  ///
  /// In en, this message translates to:
  /// **'Manage regions'**
  String get permOrganizationManageRegions;

  /// No description provided for @permOrganizationManageRegionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating and editing geographic regions used for organization mapping.'**
  String get permOrganizationManageRegionsDesc;

  /// No description provided for @permOrganizationManageCities.
  ///
  /// In en, this message translates to:
  /// **'Manage cities'**
  String get permOrganizationManageCities;

  /// No description provided for @permOrganizationManageCitiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating and editing cities linked to branches and field operations.'**
  String get permOrganizationManageCitiesDesc;

  /// No description provided for @permOrganizationManageDepartments.
  ///
  /// In en, this message translates to:
  /// **'Manage departments'**
  String get permOrganizationManageDepartments;

  /// No description provided for @permOrganizationManageDepartmentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating and editing departments that organize users and teams.'**
  String get permOrganizationManageDepartmentsDesc;

  /// No description provided for @permOrganizationManageTeams.
  ///
  /// In en, this message translates to:
  /// **'Manage teams'**
  String get permOrganizationManageTeams;

  /// No description provided for @permOrganizationManageTeamsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating and editing operational teams and their membership.'**
  String get permOrganizationManageTeamsDesc;

  /// No description provided for @permOrganizationManageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage organization users'**
  String get permOrganizationManageUsers;

  /// No description provided for @permOrganizationManageUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows placing users into branches, departments, and teams.'**
  String get permOrganizationManageUsersDesc;

  /// No description provided for @permSettingsView.
  ///
  /// In en, this message translates to:
  /// **'View settings'**
  String get permSettingsView;

  /// No description provided for @permSettingsViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening system settings screens without changing any values.'**
  String get permSettingsViewDesc;

  /// No description provided for @permSettingsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage system settings'**
  String get permSettingsManage;

  /// No description provided for @permSettingsManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows changing general settings that affect all system users.'**
  String get permSettingsManageDesc;

  /// No description provided for @permSettingsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update system settings'**
  String get permSettingsUpdate;

  /// No description provided for @permSettingsUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows saving changes to system configuration values organization-wide.'**
  String get permSettingsUpdateDesc;

  /// No description provided for @permSettingsManageHolidays.
  ///
  /// In en, this message translates to:
  /// **'Manage holidays'**
  String get permSettingsManageHolidays;

  /// No description provided for @permSettingsManageHolidaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows defining company holidays that affect attendance and overtime.'**
  String get permSettingsManageHolidaysDesc;

  /// No description provided for @permAuditView.
  ///
  /// In en, this message translates to:
  /// **'View audit log'**
  String get permAuditView;

  /// No description provided for @permAuditViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows reviewing activity and security change logs across the organization.'**
  String get permAuditViewDesc;

  /// No description provided for @permDashboardView.
  ///
  /// In en, this message translates to:
  /// **'View dashboard'**
  String get permDashboardView;

  /// No description provided for @permDashboardViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing system statistics and key performance indicators.'**
  String get permDashboardViewDesc;

  /// No description provided for @permRbacManageRoles.
  ///
  /// In en, this message translates to:
  /// **'Manage roles & permissions'**
  String get permRbacManageRoles;

  /// No description provided for @permRbacManageRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows full control of roles and which permissions each role receives.'**
  String get permRbacManageRolesDesc;

  /// No description provided for @permRbacManagePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage permissions'**
  String get permRbacManagePermissions;

  /// No description provided for @permRbacManagePermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows controlling how permissions are assigned from the access catalog.'**
  String get permRbacManagePermissionsDesc;

  /// No description provided for @permRolesView.
  ///
  /// In en, this message translates to:
  /// **'View roles'**
  String get permRolesView;

  /// No description provided for @permRolesViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening the roles list and reviewing existing role definitions.'**
  String get permRolesViewDesc;

  /// No description provided for @permRolesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create roles'**
  String get permRolesCreate;

  /// No description provided for @permRolesCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating new roles and choosing the permissions they include.'**
  String get permRolesCreateDesc;

  /// No description provided for @permRolesUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update roles'**
  String get permRolesUpdate;

  /// No description provided for @permRolesUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows changing names and permissions of existing roles.'**
  String get permRolesUpdateDesc;

  /// No description provided for @permRolesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete roles'**
  String get permRolesDelete;

  /// No description provided for @permRolesDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows permanently removing roles that are no longer needed.'**
  String get permRolesDeleteDesc;

  /// No description provided for @permRolesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage roles & permissions'**
  String get permRolesManage;

  /// No description provided for @permRolesManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating, editing, and assigning roles and their permission sets.'**
  String get permRolesManageDesc;

  /// No description provided for @permAttendanceViewOwn.
  ///
  /// In en, this message translates to:
  /// **'View own attendance'**
  String get permAttendanceViewOwn;

  /// No description provided for @permAttendanceViewOwnDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows reviewing only personal attendance records.'**
  String get permAttendanceViewOwnDesc;

  /// No description provided for @permAttendanceViewTeam.
  ///
  /// In en, this message translates to:
  /// **'View team attendance'**
  String get permAttendanceViewTeam;

  /// No description provided for @permAttendanceViewTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing attendance records for members of the assigned team.'**
  String get permAttendanceViewTeamDesc;

  /// No description provided for @permAttendanceViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all attendance'**
  String get permAttendanceViewAll;

  /// No description provided for @permAttendanceViewAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing every attendance record across the organization.'**
  String get permAttendanceViewAllDesc;

  /// No description provided for @permAttendanceManageOwn.
  ///
  /// In en, this message translates to:
  /// **'Manage own attendance'**
  String get permAttendanceManageOwn;

  /// No description provided for @permAttendanceManageOwnDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating and updating only personal attendance punches.'**
  String get permAttendanceManageOwnDesc;

  /// No description provided for @permAttendanceView.
  ///
  /// In en, this message translates to:
  /// **'View attendance'**
  String get permAttendanceView;

  /// No description provided for @permAttendanceViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening attendance screens for records within the granted access scope.'**
  String get permAttendanceViewDesc;

  /// No description provided for @permAttendanceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Manage attendance'**
  String get permAttendanceUpdate;

  /// No description provided for @permAttendanceUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating, editing, approving, and managing attendance records.'**
  String get permAttendanceUpdateDesc;

  /// No description provided for @permAttendanceApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve attendance'**
  String get permAttendanceApprove;

  /// No description provided for @permAttendanceApproveDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows approving attendance records before they are finalized.'**
  String get permAttendanceApproveDesc;

  /// No description provided for @permOvertimeViewOwn.
  ///
  /// In en, this message translates to:
  /// **'View own overtime'**
  String get permOvertimeViewOwn;

  /// No description provided for @permOvertimeViewOwnDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows reviewing only personal overtime sessions and status.'**
  String get permOvertimeViewOwnDesc;

  /// No description provided for @permOvertimeViewTeam.
  ///
  /// In en, this message translates to:
  /// **'View team overtime'**
  String get permOvertimeViewTeam;

  /// No description provided for @permOvertimeViewTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing overtime sessions belonging to assigned team members.'**
  String get permOvertimeViewTeamDesc;

  /// No description provided for @permOvertimeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all overtime'**
  String get permOvertimeViewAll;

  /// No description provided for @permOvertimeViewAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing every overtime session across the organization.'**
  String get permOvertimeViewAllDesc;

  /// No description provided for @permOvertimeCreate.
  ///
  /// In en, this message translates to:
  /// **'Create overtime'**
  String get permOvertimeCreate;

  /// No description provided for @permOvertimeCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating new overtime requests for employees.'**
  String get permOvertimeCreateDesc;

  /// No description provided for @permOvertimeStart.
  ///
  /// In en, this message translates to:
  /// **'Start overtime'**
  String get permOvertimeStart;

  /// No description provided for @permOvertimeStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows starting an overtime session and recording its start time and location.'**
  String get permOvertimeStartDesc;

  /// No description provided for @permOvertimeEnd.
  ///
  /// In en, this message translates to:
  /// **'End overtime'**
  String get permOvertimeEnd;

  /// No description provided for @permOvertimeEndDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows finishing an active overtime session and submitting its end details.'**
  String get permOvertimeEndDesc;

  /// No description provided for @permOvertimeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel overtime'**
  String get permOvertimeCancel;

  /// No description provided for @permOvertimeCancelDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows canceling an overtime session so it is not counted as worked time.'**
  String get permOvertimeCancelDesc;

  /// No description provided for @permOvertimeApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve overtime'**
  String get permOvertimeApprove;

  /// No description provided for @permOvertimeApproveDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows approving overtime requests before they are counted.'**
  String get permOvertimeApproveDesc;

  /// No description provided for @permOvertimeReject.
  ///
  /// In en, this message translates to:
  /// **'Reject overtime'**
  String get permOvertimeReject;

  /// No description provided for @permOvertimeRejectDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows rejecting overtime requests while keeping a record of the decision.'**
  String get permOvertimeRejectDesc;

  /// No description provided for @permOvertimeArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive overtime'**
  String get permOvertimeArchive;

  /// No description provided for @permOvertimeArchiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows archiving completed overtime records to keep active lists focused.'**
  String get permOvertimeArchiveDesc;

  /// No description provided for @permWorkOrdersViewOwn.
  ///
  /// In en, this message translates to:
  /// **'View own work orders'**
  String get permWorkOrdersViewOwn;

  /// No description provided for @permWorkOrdersViewOwnDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing only work orders assigned to the signed-in user.'**
  String get permWorkOrdersViewOwnDesc;

  /// No description provided for @permWorkOrdersViewTeam.
  ///
  /// In en, this message translates to:
  /// **'View team work orders'**
  String get permWorkOrdersViewTeam;

  /// No description provided for @permWorkOrdersViewTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing work orders belonging to the assigned team.'**
  String get permWorkOrdersViewTeamDesc;

  /// No description provided for @permWorkOrdersViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all work orders'**
  String get permWorkOrdersViewAll;

  /// No description provided for @permWorkOrdersViewAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows viewing every work order across the organization.'**
  String get permWorkOrdersViewAllDesc;

  /// No description provided for @permWorkOrdersCreate.
  ///
  /// In en, this message translates to:
  /// **'Create work orders'**
  String get permWorkOrdersCreate;

  /// No description provided for @permWorkOrdersCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating new work orders and assigning them to staff.'**
  String get permWorkOrdersCreateDesc;

  /// No description provided for @permWorkOrdersUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update work orders'**
  String get permWorkOrdersUpdate;

  /// No description provided for @permWorkOrdersUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows editing details of existing work orders within allowed scope.'**
  String get permWorkOrdersUpdateDesc;

  /// No description provided for @permWorkOrdersAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign work orders'**
  String get permWorkOrdersAssign;

  /// No description provided for @permWorkOrdersAssignDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows assigning or reassigning technicians on work order screens.'**
  String get permWorkOrdersAssignDesc;

  /// No description provided for @permWorkOrdersComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete work orders'**
  String get permWorkOrdersComplete;

  /// No description provided for @permWorkOrdersCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows marking a work order as completed after the job is finished.'**
  String get permWorkOrdersCompleteDesc;

  /// No description provided for @permWorkOrdersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel work orders'**
  String get permWorkOrdersCancel;

  /// No description provided for @permWorkOrdersCancelDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows canceling work orders so they are no longer active for field staff.'**
  String get permWorkOrdersCancelDesc;

  /// No description provided for @permWorkOrdersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete work orders'**
  String get permWorkOrdersDelete;

  /// No description provided for @permWorkOrdersDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows permanently deleting work orders from the organization records.'**
  String get permWorkOrdersDeleteDesc;

  /// No description provided for @permInventoryView.
  ///
  /// In en, this message translates to:
  /// **'View inventory'**
  String get permInventoryView;

  /// No description provided for @permInventoryViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows browsing inventory items and available stock quantities.'**
  String get permInventoryViewDesc;

  /// No description provided for @permInventoryCreate.
  ///
  /// In en, this message translates to:
  /// **'Create inventory items'**
  String get permInventoryCreate;

  /// No description provided for @permInventoryCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows registering new inventory items in the stock catalog.'**
  String get permInventoryCreateDesc;

  /// No description provided for @permInventoryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update inventory'**
  String get permInventoryUpdate;

  /// No description provided for @permInventoryUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows editing inventory item details such as names and attributes.'**
  String get permInventoryUpdateDesc;

  /// No description provided for @permInventoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete inventory'**
  String get permInventoryDelete;

  /// No description provided for @permInventoryDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows removing inventory items from the organization catalog.'**
  String get permInventoryDeleteDesc;

  /// No description provided for @permInventoryStockManage.
  ///
  /// In en, this message translates to:
  /// **'Manage stock quantities'**
  String get permInventoryStockManage;

  /// No description provided for @permInventoryStockManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows updating available quantities and stock movements for items.'**
  String get permInventoryStockManageDesc;

  /// No description provided for @permAssetsView.
  ///
  /// In en, this message translates to:
  /// **'View assets'**
  String get permAssetsView;

  /// No description provided for @permAssetsViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows browsing registered asset records in the system.'**
  String get permAssetsViewDesc;

  /// No description provided for @permAssetsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create assets'**
  String get permAssetsCreate;

  /// No description provided for @permAssetsCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows registering new company assets in the asset register.'**
  String get permAssetsCreateDesc;

  /// No description provided for @permAssetsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update assets'**
  String get permAssetsUpdate;

  /// No description provided for @permAssetsUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows editing asset details such as status, location, and attributes.'**
  String get permAssetsUpdateDesc;

  /// No description provided for @permAssetsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete assets'**
  String get permAssetsDelete;

  /// No description provided for @permAssetsDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows permanently removing assets from the organization register.'**
  String get permAssetsDeleteDesc;

  /// No description provided for @permAssetsAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign assets'**
  String get permAssetsAssign;

  /// No description provided for @permAssetsAssignDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows assigning assets to users or locations within the organization.'**
  String get permAssetsAssignDesc;

  /// No description provided for @permPmView.
  ///
  /// In en, this message translates to:
  /// **'View maintenance'**
  String get permPmView;

  /// No description provided for @permPmViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening preventive maintenance plans and schedule screens.'**
  String get permPmViewDesc;

  /// No description provided for @permPmCreate.
  ///
  /// In en, this message translates to:
  /// **'Create maintenance plans'**
  String get permPmCreate;

  /// No description provided for @permPmCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating periodic maintenance schedules and plans for assets.'**
  String get permPmCreateDesc;

  /// No description provided for @permPmUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update maintenance'**
  String get permPmUpdate;

  /// No description provided for @permPmUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows editing existing maintenance plans, dates, and related details.'**
  String get permPmUpdateDesc;

  /// No description provided for @permPmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete maintenance'**
  String get permPmDelete;

  /// No description provided for @permPmDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows deleting maintenance plans that are no longer required.'**
  String get permPmDeleteDesc;

  /// No description provided for @permPmManage.
  ///
  /// In en, this message translates to:
  /// **'Manage maintenance'**
  String get permPmManage;

  /// No description provided for @permPmManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows full management of preventive maintenance plans and schedules.'**
  String get permPmManageDesc;

  /// No description provided for @permMaintenanceManage.
  ///
  /// In en, this message translates to:
  /// **'Manage maintenance operations'**
  String get permMaintenanceManage;

  /// No description provided for @permMaintenanceManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows managing maintenance operations and related work schedules.'**
  String get permMaintenanceManageDesc;

  /// No description provided for @permReportsView.
  ///
  /// In en, this message translates to:
  /// **'View service reports'**
  String get permReportsView;

  /// No description provided for @permReportsViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening and reading completed service reports in the system.'**
  String get permReportsViewDesc;

  /// No description provided for @permReportsGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate service reports'**
  String get permReportsGenerate;

  /// No description provided for @permReportsGenerateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows generating new service reports from completed field work.'**
  String get permReportsGenerateDesc;

  /// No description provided for @permReportsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download service reports'**
  String get permReportsDownload;

  /// No description provided for @permReportsDownloadDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows downloading service reports in shareable or printable formats.'**
  String get permReportsDownloadDesc;

  /// No description provided for @permUsersView.
  ///
  /// In en, this message translates to:
  /// **'View users'**
  String get permUsersView;

  /// No description provided for @permUsersViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening the users list and viewing account details organization-wide.'**
  String get permUsersViewDesc;

  /// No description provided for @permUsersCreate.
  ///
  /// In en, this message translates to:
  /// **'Create users'**
  String get permUsersCreate;

  /// No description provided for @permUsersCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows creating new user accounts inside the organization.'**
  String get permUsersCreateDesc;

  /// No description provided for @permUsersUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update users'**
  String get permUsersUpdate;

  /// No description provided for @permUsersUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows editing user profile, contact, and account details.'**
  String get permUsersUpdateDesc;

  /// No description provided for @permUsersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete users'**
  String get permUsersDelete;

  /// No description provided for @permUsersDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows permanently removing user accounts from the organization.'**
  String get permUsersDeleteDesc;

  /// No description provided for @permUsersRead.
  ///
  /// In en, this message translates to:
  /// **'View users'**
  String get permUsersRead;

  /// No description provided for @permUsersReadDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows opening the users list and viewing account details organization-wide.'**
  String get permUsersReadDesc;

  /// No description provided for @permUsersResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get permUsersResetPassword;

  /// No description provided for @permUsersResetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows resetting any user\'s password without knowing the current one.'**
  String get permUsersResetPasswordDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
