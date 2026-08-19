import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/config/api_endpoint_service.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/router/auth_router_refresh.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/app_runtime_info.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/services/biometric_auth_service.dart';
import 'package:mobile/features/settings/presentation/utils/admin_settings_unlock_session.dart';
import 'package:mobile/core/services/checkpoint_telemetry_service.dart';
import 'package:mobile/core/services/api_reachability_probe.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/services/device_time_guard_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/services/monotonic_clock_service.dart';
import 'package:mobile/core/services/overtime_session_reminder_service.dart';
import 'package:mobile/core/services/selfie_capture_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/storage/token_manager.dart';
import 'package:mobile/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:mobile/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mobile/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mobile/features/attendance/domain/usecases/clock_in_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/clock_out_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/end_break_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/get_admin_attendance_detail_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/get_attendance_history_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/get_attendance_status_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/get_attendance_today_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/list_admin_attendance_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/start_break_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/sync_pending_attendance_usecase.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_admin_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_admin_detail_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_history_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_sync_cubit.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/organization/data/cache/organization_memory_cache.dart';
import 'package:mobile/features/organization/data/datasources/organization_local_datasource.dart';
import 'package:mobile/features/organization/data/datasources/organization_remote_datasource.dart';
import 'package:mobile/features/organization/data/repositories/organization_repository_impl.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/organization/presentation/cubit/profile_cubit.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_cellular_upload_prompt_service.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/end_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_running_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/export_overtime_excel_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/list_my_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/record_overtime_checkpoint_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/start_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/sync_pending_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_history_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/work_orders/data/datasources/work_order_local_datasource.dart';
import 'package:mobile/features/work_orders/data/datasources/work_order_remote_datasource.dart';
import 'package:mobile/features/work_orders/data/repositories/work_order_repository_impl.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:mobile/features/work_orders/domain/usecases/accept_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_after_photos_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_progress_note_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_progress_photos_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/assign_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/cancel_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/complete_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/create_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/delete_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/reject_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/remove_work_order_photo_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/save_before_work_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/start_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/sync_pending_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/update_work_order_usecase.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_form_cubit.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_orders_list_cubit.dart';
import 'package:mobile/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:mobile/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:mobile/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:mobile/features/inventory/domain/usecases/get_inventory_dashboard_usecase.dart';
import 'package:mobile/features/inventory/domain/usecases/list_warehouses_usecase.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';
import 'package:mobile/features/inventory/domain/usecases/stock_movement_usecases.dart';
import 'package:mobile/features/inventory/domain/usecases/warehouse_mutations_usecase.dart';
import 'package:mobile/features/inventory/presentation/cubit/inventory_dashboard_cubit.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_part_detail_cubit.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_part_form_cubit.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_parts_list_cubit.dart';
import 'package:mobile/features/inventory/presentation/cubit/stock_history_cubit.dart';
import 'package:mobile/features/inventory/presentation/cubit/warehouses_list_cubit.dart';
import 'package:mobile/features/assets/data/datasources/assets_local_datasource.dart';
import 'package:mobile/features/assets/data/datasources/assets_remote_datasource.dart';
import 'package:mobile/features/assets/data/repositories/assets_repository_impl.dart';
import 'package:mobile/features/assets/domain/repositories/assets_repository.dart';
import 'package:mobile/features/assets/domain/services/asset_qr_scanner.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/assets/presentation/cubit/asset_categories_cubit.dart';
import 'package:mobile/features/assets/presentation/cubit/asset_detail_form_history_cubits.dart';
import 'package:mobile/features/assets/presentation/cubit/assets_dashboard_cubit.dart';
import 'package:mobile/features/assets/presentation/cubit/assets_list_cubit.dart';
import 'package:mobile/features/pm/data/datasources/pm_local_datasource.dart';
import 'package:mobile/features/pm/data/datasources/pm_remote_datasource.dart';
import 'package:mobile/features/pm/data/repositories/pm_repository_impl.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/repositories/pm_repository.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_dashboard_cubit.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plan_detail_form_checklist_cubits.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plans_cubit.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_schedules_history_cubits.dart';
import 'package:mobile/features/service_reports/data/datasources/service_reports_local_datasource.dart';
import 'package:mobile/features/service_reports/data/datasources/service_reports_remote_datasource.dart';
import 'package:mobile/features/service_reports/data/repositories/service_reports_repository_impl.dart';
import 'package:mobile/features/service_reports/domain/repositories/service_reports_repository.dart';
import 'package:mobile/features/service_reports/domain/usecases/service_reports_usecases.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';
import 'package:mobile/features/users/data/datasources/users_local_datasource.dart';
import 'package:mobile/features/users/data/datasources/users_remote_datasource.dart';
import 'package:mobile/features/users/data/repositories/users_repository_impl.dart';
import 'package:mobile/features/users/domain/repositories/users_repository.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';
import 'package:mobile/features/roles/data/datasources/roles_local_datasource.dart';
import 'package:mobile/features/roles/data/datasources/roles_remote_datasource.dart';
import 'package:mobile/features/roles/data/repositories/roles_repository_impl.dart';
import 'package:mobile/features/roles/domain/repositories/roles_repository.dart';
import 'package:mobile/features/roles/domain/usecases/roles_usecases.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';
import 'package:mobile/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:mobile/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:mobile/features/settings/domain/usecases/settings_usecases.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';
import 'package:mobile/features/settings/presentation/cubit/server_management_cubit.dart';
import 'package:mobile/features/settings/data/datasources/server_health_datasource.dart';
import 'package:mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:mobile/features/dashboard/presentation/cubit/executive_dashboard_cubit.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/global_search/data/repositories/global_search_repository_impl.dart';
import 'package:mobile/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:mobile/features/global_search/domain/usecases/search_globally_usecase.dart';
import 'package:mobile/features/global_search/presentation/cubit/global_search_cubit.dart';
import 'package:mobile/features/reports_center/presentation/cubit/reports_center_cubit.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<EnvConfig>()) {
    return;
  }

  final envConfig = EnvConfig.current;
  getIt.registerSingleton<EnvConfig>(envConfig);

  final logBuffer = AppLogBuffer();
  getIt.registerSingleton<AppLogBuffer>(logBuffer);

  final loggerService = LoggerService(logBuffer: logBuffer);
  getIt.registerSingleton<LoggerService>(loggerService);

  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(sharedPreferences);
  getIt.registerSingleton<PreferencesService>(preferencesService);

  final syncConfigurationService = SyncConfigurationService(preferencesService);
  await syncConfigurationService.load();
  getIt.registerSingleton<SyncConfigurationService>(syncConfigurationService);

  getIt.registerSingleton<AppRuntimeInfo>(AppRuntimeInfo());
  getIt.registerLazySingleton<BiometricAuthService>(BiometricAuthService.new);
  getIt.registerSingleton<AdminSettingsUnlockSession>(
    AdminSettingsUnlockSession(),
  );

  final secureStorageService = SecureStorageService();
  getIt.registerSingleton<SecureStorageService>(secureStorageService);

  final tokenManager = TokenManager(secureStorageService);
  getIt.registerSingleton<TokenManager>(tokenManager);

  final connectivityService = ConnectivityService(
    envConfig: envConfig,
    logger: loggerService,
  );
  getIt.registerSingleton<ConnectivityService>(connectivityService);

  if (!getIt.isRegistered<SessionQueryCache>()) {
    getIt.registerLazySingleton<SessionQueryCache>(SessionQueryCache.new);
  }

  final authSessionService = AuthSessionService();
  getIt.registerSingleton<AuthSessionService>(authSessionService);

  final dioClient = DioClient(
    envConfig: envConfig,
    tokenManager: tokenManager,
    preferencesService: preferencesService,
    logger: loggerService,
    authSessionService: authSessionService,
  );
  getIt.registerSingleton<DioClient>(dioClient);

  final apiEndpointService = ApiEndpointService(
    envConfig: envConfig,
    dioClient: dioClient,
    preferences: preferencesService,
    logger: loggerService,
  );
  getIt.registerSingleton<ApiEndpointService>(apiEndpointService);
  await apiEndpointService.bootstrap();

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(
      tokenManager: getIt<TokenManager>(),
      preferencesService: getIt<PreferencesService>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => RestoreSessionUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));

  getIt.registerLazySingleton<OrganizationMemoryCache>(
    OrganizationMemoryCache.new,
  );

  getIt.registerLazySingleton<OrganizationRemoteDataSource>(
    () => OrganizationRemoteDataSource(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<OrganizationLocalDataSource>(
    () => OrganizationLocalDataSource(getIt<PreferencesService>()),
  );

  getIt.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepositoryImpl(
      remote: getIt<OrganizationRemoteDataSource>(),
      local: getIt<OrganizationLocalDataSource>(),
      memoryCache: getIt<OrganizationMemoryCache>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      repository: getIt<OrganizationRepository>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      restoreSessionUseCase: getIt<RestoreSessionUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      authSessionService: getIt<AuthSessionService>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerLazySingleton<AppCubit>(
    () => AppCubit(
      getIt<ConnectivityService>(),
      getIt<PreferencesService>(),
      getIt<SyncConfigurationService>(),
    ),
  );

  getIt.registerLazySingleton<GpsService>(GpsService.new);
  getIt.registerLazySingleton<SelfieCaptureService>(SelfieCaptureService.new);
  getIt.registerLazySingleton<AddressResolverService>(AddressResolverService.new);
  getIt.registerLazySingleton<CheckpointTelemetryService>(
    () => CheckpointTelemetryService(
      connectivityService: getIt<ConnectivityService>(),
    ),
  );
  getIt.registerLazySingleton<MonotonicClockService>(MonotonicClockService.new);
  getIt.registerLazySingleton<DeviceTimeGuardService>(
    () => DeviceTimeGuardService(
      dioClient: getIt<DioClient>(),
      preferences: getIt<PreferencesService>(),
      connectivity: getIt<ConnectivityService>(),
      monotonicClock: getIt<MonotonicClockService>(),
    ),
  );
  getIt.registerLazySingleton<GpsAddressSyncService>(
    () => GpsAddressSyncService(
      dioClient: getIt<DioClient>(),
      preferences: getIt<PreferencesService>(),
      connectivity: getIt<ConnectivityService>(),
      addressResolver: getIt<AddressResolverService>(),
    ),
  );

  getIt.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSource(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSource(getIt<PreferencesService>()),
  );

  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remote: getIt<AttendanceRemoteDataSource>(),
      local: getIt<AttendanceLocalDataSource>(),
      connectivity: getIt<ConnectivityService>(),
      addressResolver: getIt<AddressResolverService>(),
      gpsAddressSync: getIt<GpsAddressSyncService>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetAttendanceStatusUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAttendanceTodayUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAttendanceHistoryUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListAdminAttendanceUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAdminAttendanceDetailUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => ClockInUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => ClockOutUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => StartBreakUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => EndBreakUseCase(getIt<AttendanceRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerFactory<AttendanceCubit>(
    () => AttendanceCubit(
      getStatusUseCase: getIt<GetAttendanceStatusUseCase>(),
      getTodayUseCase: getIt<GetAttendanceTodayUseCase>(),
      clockInUseCase: getIt<ClockInUseCase>(),
      clockOutUseCase: getIt<ClockOutUseCase>(),
      startBreakUseCase: getIt<StartBreakUseCase>(),
      endBreakUseCase: getIt<EndBreakUseCase>(),
      syncPendingUseCase: getIt<SyncPendingAttendanceUseCase>(),
      gpsService: getIt<GpsService>(),
      selfieCaptureService: getIt<SelfieCaptureService>(),
      addressResolverService: getIt<AddressResolverService>(),
      deviceTimeGuard: getIt<DeviceTimeGuardService>(),
      gpsAddressSync: getIt<GpsAddressSyncService>(),
      preferencesService: getIt<PreferencesService>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
      localDataSource: getIt<AttendanceLocalDataSource>(),
    ),
  );

  getIt.registerFactory<AttendanceHistoryCubit>(
    () => AttendanceHistoryCubit(
      useCase: getIt<GetAttendanceHistoryUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
      localDataSource: getIt<AttendanceLocalDataSource>(),
    ),
  );

  getIt.registerFactory<AttendanceAdminCubit>(
    () => AttendanceAdminCubit(
      listAdmin: getIt<ListAdminAttendanceUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerFactoryParam<AttendanceAdminDetailCubit, String, void>(
    (attendanceId, _) => AttendanceAdminDetailCubit(
      getDetail: getIt<GetAdminAttendanceDetailUseCase>(),
      attendanceId: attendanceId,
    ),
  );

  getIt.registerLazySingleton<AttendanceSyncCubit>(
    () => AttendanceSyncCubit(
      syncUseCase: getIt<SyncPendingAttendanceUseCase>(),
      repository: getIt<AttendanceRepository>(),
      connectivity: getIt<ConnectivityService>(),
      gpsAddressSync: getIt<GpsAddressSyncService>(),
      syncConfiguration: getIt<SyncConfigurationService>(),
    ),
  );

  getIt.registerLazySingleton<OvertimeRemoteDataSource>(
    () => OvertimeRemoteDataSource(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<OvertimeLocalDataSource>(
    () => OvertimeLocalDataSource(getIt<PreferencesService>()),
  );

  OvertimeOfflineTrace.bindLogger(getIt<LoggerService>());

  getIt.registerLazySingleton<OvertimeCellularUploadPromptService>(
    OvertimeCellularUploadPromptService.new,
  );

  getIt.registerLazySingleton<OvertimeUploadPolicyService>(
    () => OvertimeUploadPolicyService(
      connectivity: getIt<ConnectivityService>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
      cellularPrompt: getIt<OvertimeCellularUploadPromptService>(),
    ),
  );

  getIt.registerLazySingleton<OvertimeRepository>(
    () => OvertimeRepositoryImpl(
      remote: getIt<OvertimeRemoteDataSource>(),
      local: getIt<OvertimeLocalDataSource>(),
      connectivity: getIt<ConnectivityService>(),
      addressResolver: getIt<AddressResolverService>(),
      gpsAddressSync: getIt<GpsAddressSyncService>(),
      uploadPolicy: getIt<OvertimeUploadPolicyService>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetRunningOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => StartOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => EndOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => RecordOvertimeCheckpointUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListAdminOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => ExportOvertimeExcelUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListMyOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetOvertimeByIdUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => ApproveOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => RejectOvertimeUseCase(getIt<OvertimeRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingOvertimeUseCase(getIt<OvertimeRepository>()),
  );

  getIt.registerLazySingleton<OvertimeSyncCubit>(
    () => OvertimeSyncCubit(
      syncUseCase: getIt<SyncPendingOvertimeUseCase>(),
      repository: getIt<OvertimeRepository>(),
      connectivity: getIt<ConnectivityService>(),
      gpsAddressSync: getIt<GpsAddressSyncService>(),
      uploadPolicy: getIt<OvertimeUploadPolicyService>(),
      syncConfiguration: getIt<SyncConfigurationService>(),
    ),
  );

  getIt.registerLazySingleton<OvertimeSessionReminderService>(
    () => OvertimeSessionReminderService(getIt<PreferencesService>()),
  );

  getIt.registerFactory<OvertimeCubit>(
    () => OvertimeCubit(
      getRunningOvertimeUseCase: getIt<GetRunningOvertimeUseCase>(),
      startOvertimeUseCase: getIt<StartOvertimeUseCase>(),
      endOvertimeUseCase: getIt<EndOvertimeUseCase>(),
      recordCheckpointUseCase: getIt<RecordOvertimeCheckpointUseCase>(),
      gpsService: getIt<GpsService>(),
      selfieCaptureService: getIt<SelfieCaptureService>(),
      addressResolverService: getIt<AddressResolverService>(),
      deviceTimeGuard: getIt<DeviceTimeGuardService>(),
      gpsAddressSync: getIt<GpsAddressSyncService>(),
      preferencesService: getIt<PreferencesService>(),
      connectivityService: getIt<ConnectivityService>(),
      checkpointTelemetryService: getIt<CheckpointTelemetryService>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
      localDataSource: getIt<OvertimeLocalDataSource>(),
      overtimeSyncCubit: getIt<OvertimeSyncCubit>(),
      getMediaConfigUseCase: getIt<GetOvertimeMediaConfigUseCase>(),
      uploadPolicyService: getIt<OvertimeUploadPolicyService>(),
      loggerService: getIt<LoggerService>(),
      reminderService: getIt<OvertimeSessionReminderService>(),
    ),
  );

  getIt.registerFactory<OvertimeAdminCubit>(
    () => OvertimeAdminCubit(
      listAdmin: getIt<ListAdminOvertimeUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerFactory<OvertimeHistoryCubit>(
    () => OvertimeHistoryCubit(
      listMine: getIt<ListMyOvertimeUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
      localDataSource: getIt<OvertimeLocalDataSource>(),
    ),
  );

  getIt.registerFactoryParam<OvertimeDetailCubit, String, void>(
    (sessionId, _) => OvertimeDetailCubit(
      getById: getIt<GetOvertimeByIdUseCase>(),
      approve: getIt<ApproveOvertimeUseCase>(),
      reject: getIt<RejectOvertimeUseCase>(),
      sessionId: sessionId,
    ),
  );

  getIt.registerLazySingleton<WorkOrderRemoteDataSource>(
    () => WorkOrderRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<WorkOrderLocalDataSource>(
    () => WorkOrderLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<WorkOrderRepository>(
    () => WorkOrderRepositoryImpl(
      remote: getIt<WorkOrderRemoteDataSource>(),
      local: getIt<WorkOrderLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => ListWorkOrdersUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListMyWorkOrdersUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWorkOrderByIdUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => AssignWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => AcceptWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => RejectWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => StartWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => CompleteWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => CancelWorkOrderUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveBeforeWorkUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => AddProgressNoteUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => AddProgressPhotosUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => AddAfterPhotosUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => RemoveWorkOrderPhotoUseCase(getIt<WorkOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingWorkOrdersUseCase(getIt<WorkOrderRepository>()),
  );

  getIt.registerFactory<WorkOrdersListCubit>(
    () => WorkOrdersListCubit(
      listWorkOrders: getIt<ListWorkOrdersUseCase>(),
      listMyWorkOrders: getIt<ListMyWorkOrdersUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerFactoryParam<WorkOrderDetailCubit, String, void>(
    (workOrderId, _) => WorkOrderDetailCubit(
      getById: getIt<GetWorkOrderByIdUseCase>(),
      accept: getIt<AcceptWorkOrderUseCase>(),
      reject: getIt<RejectWorkOrderUseCase>(),
      start: getIt<StartWorkOrderUseCase>(),
      complete: getIt<CompleteWorkOrderUseCase>(),
      cancel: getIt<CancelWorkOrderUseCase>(),
      delete: getIt<DeleteWorkOrderUseCase>(),
      assign: getIt<AssignWorkOrderUseCase>(),
      saveBeforeWork: getIt<SaveBeforeWorkUseCase>(),
      addProgressNote: getIt<AddProgressNoteUseCase>(),
      addProgressPhotos: getIt<AddProgressPhotosUseCase>(),
      addAfterPhotos: getIt<AddAfterPhotosUseCase>(),
      removePhoto: getIt<RemoveWorkOrderPhotoUseCase>(),
      gpsService: getIt<GpsService>(),
      addressResolverService: getIt<AddressResolverService>(),
      workOrderId: workOrderId,
    ),
  );

  getIt.registerFactoryParam<WorkOrderFormCubit, String, void>(
    (workOrderId, _) => WorkOrderFormCubit(
      create: getIt<CreateWorkOrderUseCase>(),
      update: getIt<UpdateWorkOrderUseCase>(),
      getById: getIt<GetWorkOrderByIdUseCase>(),
      organizationRepository: getIt<OrganizationRepository>(),
      workOrderId: workOrderId.isEmpty ? null : workOrderId,
    ),
  );

  getIt.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<InventoryLocalDataSource>(
    () => InventoryLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      remote: getIt<InventoryRemoteDataSource>(),
      local: getIt<InventoryLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetInventoryDashboardUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListWarehousesUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWarehouseByIdUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateWarehouseUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateWarehouseUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteWarehouseUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListSparePartsUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSparePartByIdUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateSparePartUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateSparePartUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteSparePartUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListStockMovementsUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => StockInUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => StockOutUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => TransferStockUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => AdjustmentStockUseCase(getIt<InventoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingInventoryUseCase(getIt<InventoryRepository>()),
  );

  getIt.registerFactory<InventoryDashboardCubit>(
    () => InventoryDashboardCubit(
      getDashboard: getIt<GetInventoryDashboardUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<WarehousesListCubit>(
    () => WarehousesListCubit(
      listWarehouses: getIt<ListWarehousesUseCase>(),
      createWarehouse: getIt<CreateWarehouseUseCase>(),
      updateWarehouse: getIt<UpdateWarehouseUseCase>(),
      deleteWarehouse: getIt<DeleteWarehouseUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<SparePartsListCubit>(
    () => SparePartsListCubit(
      listSpareParts: getIt<ListSparePartsUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<SparePartDetailCubit, String, void>(
    (partId, _) => SparePartDetailCubit(
      partId: partId,
      getById: getIt<GetSparePartByIdUseCase>(),
      deletePart: getIt<DeleteSparePartUseCase>(),
      listWarehouses: getIt<ListWarehousesUseCase>(),
      stockIn: getIt<StockInUseCase>(),
      stockOut: getIt<StockOutUseCase>(),
      transfer: getIt<TransferStockUseCase>(),
      adjustment: getIt<AdjustmentStockUseCase>(),
    ),
  );
  getIt.registerFactoryParam<SparePartFormCubit, String, void>(
    (partId, _) => SparePartFormCubit(
      create: getIt<CreateSparePartUseCase>(),
      update: getIt<UpdateSparePartUseCase>(),
      getById: getIt<GetSparePartByIdUseCase>(),
      partId: partId.isEmpty ? null : partId,
    ),
  );
  getIt.registerFactoryParam<StockHistoryCubit, String, void>(
    (sparePartId, _) => StockHistoryCubit(
      listMovements: getIt<ListStockMovementsUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
      sparePartId: sparePartId.isEmpty ? null : sparePartId,
    ),
  );

  getIt.registerLazySingleton<AssetsRemoteDataSource>(
    () => AssetsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<AssetsLocalDataSource>(
    () => AssetsLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<AssetsRepository>(
    () => AssetsRepositoryImpl(
      remote: getIt<AssetsRemoteDataSource>(),
      local: getIt<AssetsLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<AssetQrScanner>(() => StubAssetQrScanner());

  getIt.registerLazySingleton(
    () => GetAssetsDashboardUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListAssetCategoriesUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateAssetCategoryUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateAssetCategoryUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteAssetCategoryUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListAssetsUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAssetByIdUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateAssetUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateAssetUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteAssetUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListAssetHistoryUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => AddAssetHistoryUseCase(getIt<AssetsRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingAssetsUseCase(getIt<AssetsRepository>()),
  );

  getIt.registerFactory<AssetsDashboardCubit>(
    () => AssetsDashboardCubit(
      getDashboard: getIt<GetAssetsDashboardUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<AssetCategoriesCubit>(
    () => AssetCategoriesCubit(
      listCategories: getIt<ListAssetCategoriesUseCase>(),
      createCategory: getIt<CreateAssetCategoryUseCase>(),
      updateCategory: getIt<UpdateAssetCategoryUseCase>(),
      deleteCategory: getIt<DeleteAssetCategoryUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<AssetsListCubit>(
    () => AssetsListCubit(
      listAssets: getIt<ListAssetsUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<AssetDetailCubit, String, void>(
    (assetId, _) => AssetDetailCubit(
      assetId: assetId,
      getById: getIt<GetAssetByIdUseCase>(),
      deleteAsset: getIt<DeleteAssetUseCase>(),
      listHistory: getIt<ListAssetHistoryUseCase>(),
      addHistory: getIt<AddAssetHistoryUseCase>(),
      qrScanner: getIt<AssetQrScanner>(),
    ),
  );
  getIt.registerFactoryParam<AssetFormCubit, String, void>(
    (assetId, _) => AssetFormCubit(
      create: getIt<CreateAssetUseCase>(),
      update: getIt<UpdateAssetUseCase>(),
      getById: getIt<GetAssetByIdUseCase>(),
      listCategories: getIt<ListAssetCategoriesUseCase>(),
      organizationRepository: getIt<OrganizationRepository>(),
      qrScanner: getIt<AssetQrScanner>(),
      assetId: assetId.isEmpty ? null : assetId,
    ),
  );
  getIt.registerFactoryParam<AssetHistoryCubit, String, void>(
    (assetId, _) => AssetHistoryCubit(
      listHistory: getIt<ListAssetHistoryUseCase>(),
      sessionCache: getIt<SessionQueryCache>(),
      assetId: assetId.isEmpty ? null : assetId,
    ),
  );

  getIt.registerLazySingleton<PmRemoteDataSource>(
    () => PmRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<PmLocalDataSource>(
    () => PmLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<PmRepository>(
    () => PmRepositoryImpl(
      remote: getIt<PmRemoteDataSource>(),
      local: getIt<PmLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetPmDashboardUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListPmPlansUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPmPlanByIdUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreatePmPlanUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdatePmPlanUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeletePmPlanUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdatePmChecklistUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => GeneratePmSchedulesUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListPmSchedulesUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPmScheduleByIdUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => CompletePmScheduleUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => CancelPmScheduleUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListPmHistoryUseCase(getIt<PmRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingPmUseCase(getIt<PmRepository>()),
  );

  getIt.registerFactory<PmDashboardCubit>(
    () => PmDashboardCubit(
      getDashboard: getIt<GetPmDashboardUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<PmPlansCubit>(
    () => PmPlansCubit(
      listPlans: getIt<ListPmPlansUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<PmPlanDetailCubit, String, void>(
    (planId, _) => PmPlanDetailCubit(
      planId: planId,
      getById: getIt<GetPmPlanByIdUseCase>(),
      deletePlan: getIt<DeletePmPlanUseCase>(),
      generateSchedules: getIt<GeneratePmSchedulesUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<PmPlanFormCubit, String, void>(
    (planId, _) => PmPlanFormCubit(
      create: getIt<CreatePmPlanUseCase>(),
      update: getIt<UpdatePmPlanUseCase>(),
      getById: getIt<GetPmPlanByIdUseCase>(),
      organizationRepository: getIt<OrganizationRepository>(),
      listAssets: getIt<ListAssetsUseCase>(),
      planId: planId.isEmpty ? null : planId,
    ),
  );
  getIt.registerFactoryParam<PmChecklistBuilderCubit, String, void>(
    (planId, _) => PmChecklistBuilderCubit(
      planId: planId,
      getById: getIt<GetPmPlanByIdUseCase>(),
      updateChecklist: getIt<UpdatePmChecklistUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<PmSchedulesCubit, String, String>(
    (planId, statusApi) => PmSchedulesCubit(
      listSchedules: getIt<ListPmSchedulesUseCase>(),
      completeSchedule: getIt<CompletePmScheduleUseCase>(),
      cancelSchedule: getIt<CancelPmScheduleUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
      planId: planId.isEmpty ? null : planId,
      initialStatus:
          statusApi.isEmpty ? null : PmScheduleStatus.fromApi(statusApi),
    ),
  );
  getIt.registerFactoryParam<PmHistoryCubit, String, void>(
    (planId, _) => PmHistoryCubit(
      listHistory: getIt<ListPmHistoryUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
      planId: planId.isEmpty ? null : planId,
    ),
  );

  getIt.registerLazySingleton<ServiceReportsRemoteDataSource>(
    () => ServiceReportsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ServiceReportsLocalDataSource>(
    () => ServiceReportsLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<ServiceReportsRepository>(
    () => ServiceReportsRepositoryImpl(
      remote: getIt<ServiceReportsRemoteDataSource>(),
      local: getIt<ServiceReportsLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetServiceReportsDashboardUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListServiceReportsUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetServiceReportByIdUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GenerateServiceReportUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => DownloadServiceReportUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListCustomerSignaturesUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCustomerSignatureByIdUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateCustomerSignatureUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteCustomerSignatureUseCase(getIt<ServiceReportsRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingReportsUseCase(getIt<ServiceReportsRepository>()),
  );

  getIt.registerFactory<ServiceReportsDashboardCubit>(
    () => ServiceReportsDashboardCubit(
      getDashboard: getIt<GetServiceReportsDashboardUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<ServiceReportsListCubit>(
    () => ServiceReportsListCubit(
      listReports: getIt<ListServiceReportsUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<ServiceReportDetailCubit, String, void>(
    (reportId, _) => ServiceReportDetailCubit(
      reportId: reportId,
      getById: getIt<GetServiceReportByIdUseCase>(),
      download: getIt<DownloadServiceReportUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<SignatureCaptureCubit>(
    () => SignatureCaptureCubit(
      create: getIt<CreateCustomerSignatureUseCase>(),
    ),
  );
  getIt.registerFactory<GenerateReportCubit>(
    () => GenerateReportCubit(
      listSignatures: getIt<ListCustomerSignaturesUseCase>(),
      generate: getIt<GenerateServiceReportUseCase>(),
    ),
  );

  getIt.registerLazySingleton<UsersRemoteDataSource>(
    () => UsersRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<UsersLocalDataSource>(
    () => UsersLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(
      remote: getIt<UsersRemoteDataSource>(),
      local: getIt<UsersLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetUsersDashboardUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListManagedUsersUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetManagedUserByIdUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateManagedUserUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateManagedUserUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => SetManagedUserStatusUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteManagedUserUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => ResetManagedUserPasswordUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => ChangeOwnPasswordUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => UploadUserAvatarUseCase(getIt<UsersRepository>()),
  );
  getIt.registerLazySingleton(
    () => SyncPendingUsersUseCase(getIt<UsersRepository>()),
  );

  getIt.registerFactory<UsersDashboardCubit>(
    () => UsersDashboardCubit(
      getDashboard: getIt<GetUsersDashboardUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<UsersListCubit>(
    () => UsersListCubit(
      listUsers: getIt<ListManagedUsersUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<UserDetailCubit, String, void>(
    (userId, _) => UserDetailCubit(
      userId: userId,
      getById: getIt<GetManagedUserByIdUseCase>(),
      setStatus: getIt<SetManagedUserStatusUseCase>(),
      deleteUser: getIt<DeleteManagedUserUseCase>(),
      resetPassword: getIt<ResetManagedUserPasswordUseCase>(),
      uploadAvatar: getIt<UploadUserAvatarUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactoryParam<UserFormCubit, String, void>(
    (userId, _) => UserFormCubit(
      create: getIt<CreateManagedUserUseCase>(),
      update: getIt<UpdateManagedUserUseCase>(),
      getById: getIt<GetManagedUserByIdUseCase>(),
      organizationRepository: getIt<OrganizationRepository>(),
      userId: userId.isEmpty ? null : userId,
    ),
  );
  getIt.registerFactory<ChangePasswordCubit>(
    () => ChangePasswordCubit(
      changePassword: getIt<ChangeOwnPasswordUseCase>(),
    ),
  );

  getIt.registerLazySingleton<RolesRemoteDataSource>(
    () => RolesRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<RolesLocalDataSource>(
    () => RolesLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<RolesRepository>(
    () => RolesRepositoryImpl(
      remote: getIt<RolesRemoteDataSource>(),
      local: getIt<RolesLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetRolesDashboardUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListRolesUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetRoleByIdUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPermissionCatalogUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateRoleUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateRoleUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => SetRoleStatusUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteRoleUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => CloneRoleUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => ListRoleUsersUseCase(getIt<RolesRepository>()),
  );
  getIt.registerLazySingleton(
    () => AssignRoleToUsersUseCase(getIt<RolesRepository>()),
  );

  getIt.registerFactory<RolesDashboardCubit>(
    () => RolesDashboardCubit(
      getDashboard: getIt<GetRolesDashboardUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<RolesListCubit>(
    () => RolesListCubit(
      listRoles: getIt<ListRolesUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<RoleDetailCubit>(
    () => RoleDetailCubit(
      getRole: getIt<GetRoleByIdUseCase>(),
      listUsers: getIt<ListRoleUsersUseCase>(),
      setStatus: getIt<SetRoleStatusUseCase>(),
      deleteRole: getIt<DeleteRoleUseCase>(),
      cloneRole: getIt<CloneRoleUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<RoleFormCubit>(
    () => RoleFormCubit(
      getRole: getIt<GetRoleByIdUseCase>(),
      getCatalog: getIt<GetPermissionCatalogUseCase>(),
      createRole: getIt<CreateRoleUseCase>(),
      updateRole: getIt<UpdateRoleUseCase>(),
    ),
  );
  getIt.registerFactory<AssignUsersCubit>(
    () => AssignUsersCubit(
      listUsers: getIt<ListManagedUsersUseCase>(),
      assignUsers: getIt<AssignRoleToUsersUseCase>(),
      queryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      remote: getIt<SettingsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetOrganizationSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateOrganizationSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UploadOrganizationLogoUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSystemInfoUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetOvertimeSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateOvertimeSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetOvertimeMediaConfigUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTechnicianInterfaceSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateTechnicianInterfaceSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTechnicianInterfaceConfigUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<TechnicianInterfaceCubit>(
    () => TechnicianInterfaceCubit(
      getConfig: getIt<GetTechnicianInterfaceConfigUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<OrganizationSettingsCubit>(
    () => OrganizationSettingsCubit(
      getSettings: getIt<GetOrganizationSettingsUseCase>(),
      updateSettings: getIt<UpdateOrganizationSettingsUseCase>(),
      uploadLogo: getIt<UploadOrganizationLogoUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<SystemInfoCubit>(
    () => SystemInfoCubit(
      getSystemInfo: getIt<GetSystemInfoUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<OvertimeSettingsCubit>(
    () => OvertimeSettingsCubit(
      getSettings: getIt<GetOvertimeSettingsUseCase>(),
      updateSettings: getIt<UpdateOvertimeSettingsUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerFactory<TechnicianInterfaceSettingsCubit>(
    () => TechnicianInterfaceSettingsCubit(
      getSettings: getIt<GetTechnicianInterfaceSettingsUseCase>(),
      updateSettings: getIt<UpdateTechnicianInterfaceSettingsUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );
  getIt.registerLazySingleton<ServerHealthDataSource>(
    ServerHealthDataSource.new,
  );
  getIt.registerFactory<ServerManagementCubit>(
    () => ServerManagementCubit(
      apiEndpointService: getIt<ApiEndpointService>(),
      healthDataSource: getIt<ServerHealthDataSource>(),
      tokenManager: getIt<TokenManager>(),
      connectivityService: getIt<ConnectivityService>(),
      appRuntimeInfo: getIt<AppRuntimeInfo>(),
    ),
  );

  getIt.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remote: getIt<DashboardRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
    () => GetDashboardSummaryUseCase(getIt<DashboardRepository>()),
  );
  getIt.registerFactory<ExecutiveDashboardCubit>(
    () => ExecutiveDashboardCubit(
      getDashboardSummary: getIt<GetDashboardSummaryUseCase>(),
      sessionQueryCache: getIt<SessionQueryCache>(),
    ),
  );

  getIt.registerLazySingleton<NotificationsLocalDataSource>(
    () => NotificationsLocalDataSource(getIt<PreferencesService>()),
  );
  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(getIt<GetDashboardSummaryUseCase>()),
  );
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      remote: getIt<NotificationsRemoteDataSource>(),
      local: getIt<NotificationsLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetNotificationsUseCase(getIt<NotificationsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetNotificationsUnreadCountUseCase(getIt<NotificationsRepository>()),
  );
  getIt.registerLazySingleton(
    () => MarkNotificationReadUseCase(getIt<NotificationsRepository>()),
  );
  getIt.registerLazySingleton(
    () => MarkAllNotificationsReadUseCase(getIt<NotificationsRepository>()),
  );
  getIt.registerLazySingleton<NotificationsUnreadCubit>(
    () => NotificationsUnreadCubit(
      getUnreadCount: getIt<GetNotificationsUnreadCountUseCase>(),
    ),
  );
  getIt.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      getNotifications: getIt<GetNotificationsUseCase>(),
      markNotificationRead: getIt<MarkNotificationReadUseCase>(),
      markAllNotificationsRead: getIt<MarkAllNotificationsReadUseCase>(),
      unreadCubit: getIt<NotificationsUnreadCubit>(),
    ),
  );

  getIt.registerLazySingleton<GlobalSearchRepository>(
    () => GlobalSearchRepositoryImpl(
      listUsers: getIt<ListManagedUsersUseCase>(),
      listAssets: getIt<ListAssetsUseCase>(),
      listSpareParts: getIt<ListSparePartsUseCase>(),
      listWorkOrders: getIt<ListWorkOrdersUseCase>(),
      listMyWorkOrders: getIt<ListMyWorkOrdersUseCase>(),
      listAdminOvertime: getIt<ListAdminOvertimeUseCase>(),
      listPmPlans: getIt<ListPmPlansUseCase>(),
      listServiceReports: getIt<ListServiceReportsUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => SearchGloballyUseCase(getIt<GlobalSearchRepository>()),
  );
  getIt.registerFactory<GlobalSearchCubit>(
    () => GlobalSearchCubit(
      searchGlobally: getIt<SearchGloballyUseCase>(),
      permissionsProvider: () {
        final user = getIt<AuthCubit>().state.user;
        return user?.permissionChecker ?? const PermissionChecker([]);
      },
    ),
  );

  getIt.registerFactoryParam<ReportsCenterCubit, PermissionChecker, void>(
    (permissions, _) => ReportsCenterCubit(
      permissions: permissions,
      listAttendance: getIt<ListAdminAttendanceUseCase>(),
      listOvertime: getIt<ListAdminOvertimeUseCase>(),
      listWorkOrders: getIt<ListWorkOrdersUseCase>(),
      listMyWorkOrders: getIt<ListMyWorkOrdersUseCase>(),
      listAssets: getIt<ListAssetsUseCase>(),
      listSpareParts: getIt<ListSparePartsUseCase>(),
      listPmPlans: getIt<ListPmPlansUseCase>(),
      listServiceReports: getIt<ListServiceReportsUseCase>(),
      listUsers: getIt<ListManagedUsersUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AuthRouterRefresh>(
    () => AuthRouterRefresh(
      authCubit: getIt<AuthCubit>(),
      technicianInterfaceCubit: getIt<TechnicianInterfaceCubit>(),
    ),
  );

  getIt.registerLazySingleton<GoRouter>(
    () => createAppRouter(
      authCubit: getIt<AuthCubit>(),
      refreshListenable: getIt<AuthRouterRefresh>(),
    ),
  );
}
