import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/app_update/data/models/app_release_manifest_model.dart';

class AppUpdateRemoteDataSource {
  AppUpdateRemoteDataSource(this._client);

  final DioClient _client;

  Future<AppReleaseManifestModel?> fetchLatestRelease({
    required String channel,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.releasesLatest,
      queryParameters: {'channel': channel},
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final manifest = AppReleaseManifestModel.fromJson(data);
    if (!manifest.isConfigured) {
      return null;
    }
    return manifest;
  }
}
