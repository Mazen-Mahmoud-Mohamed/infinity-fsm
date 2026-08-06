import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/overtime/domain/services/overtime_cellular_upload_prompt_service.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

/// Resolves overtime upload policy from cached company media config.
class OvertimeUploadPolicyService {
  OvertimeUploadPolicyService({
    required ConnectivityService connectivity,
    required SessionQueryCache sessionQueryCache,
    OvertimeCellularUploadPromptService? cellularPrompt,
  })  : _connectivity = connectivity,
        _sessionQueryCache = sessionQueryCache,
        _cellularPrompt = cellularPrompt;

  static const String cacheKey = 'settings:overtime:media_config';

  final ConnectivityService _connectivity;
  final SessionQueryCache _sessionQueryCache;
  final OvertimeCellularUploadPromptService? _cellularPrompt;

  OvertimeMediaConfigEntity _cachedOrDefault() {
    return _sessionQueryCache.get<OvertimeMediaConfigEntity>(cacheKey) ??
        OvertimeMediaConfigEntity.defaults();
  }

  String get uploadPolicy => _cachedOrDefault().uploadPolicy;

  Future<bool> get isWifi async {
    final types = await _connectivity.connectionTypes;
    return types.contains(ConnectivityResult.wifi) ||
        types.contains(ConnectivityResult.ethernet);
  }

  Future<bool> get isCellular async {
    final types = await _connectivity.connectionTypes;
    return types.contains(ConnectivityResult.mobile);
  }

  Future<bool> _resolveCellularUpload({required bool force}) async {
    if (force) {
      return _connectivity.isConnected;
    }
    if (await isWifi) {
      return true;
    }
    if (!await isCellular) {
      return false;
    }
    final prompt = _cellularPrompt;
    if (prompt == null) {
      return false;
    }
    switch (await prompt.prompt()) {
      case CellularUploadChoice.mobileData:
        return true;
      case CellularUploadChoice.wifiOnly:
      case CellularUploadChoice.later:
        return false;
    }
  }

  /// Whether a checkpoint/start/end should attempt immediate remote upload.
  Future<bool> shouldAttemptImmediateUpload({bool force = false}) async {
    if (!await _connectivity.isConnected) {
      return false;
    }
    if (force) {
      final policy = OvertimeMediaConfig.normalizeUploadPolicy(uploadPolicy);
      if (policy == 'wifi_only') {
        return isWifi;
      }
      return true;
    }
    switch (OvertimeMediaConfig.normalizeUploadPolicy(uploadPolicy)) {
      case 'immediately':
        return true;
      case 'wifi_preferred':
        return isWifi;
      case 'wifi_only':
        return isWifi;
      case 'manual':
        return false;
      case 'ask_every_time':
        return _resolveCellularUpload(force: false);
      default:
        return true;
    }
  }

  /// Whether background / automatic sync should run (timer, reconnect, post-queue).
  Future<bool> shouldAutoSync() async {
    if (!await _connectivity.isConnected) {
      return false;
    }
    switch (OvertimeMediaConfig.normalizeUploadPolicy(uploadPolicy)) {
      case 'immediately':
        return true;
      case 'wifi_preferred':
        return isWifi;
      case 'wifi_only':
        return isWifi;
      case 'manual':
        return false;
      case 'ask_every_time':
        return isWifi;
      default:
        return true;
    }
  }
}
