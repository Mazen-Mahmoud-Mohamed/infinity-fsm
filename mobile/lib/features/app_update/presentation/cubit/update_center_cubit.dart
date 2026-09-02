import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/app_update/data/repositories/app_update_repository_impl.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_install_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:mobile/features/app_update/domain/utils/version_comparator.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_state.dart';

class UpdateCenterCubit extends Cubit<UpdateCenterState> {
  UpdateCenterCubit({
    required AppUpdateRepository repository,
    required String releaseChannel,
  })  : _repository = repository,
        _releaseChannel = releaseChannel,
        super(const UpdateCenterState());

  final AppUpdateRepository _repository;
  final String _releaseChannel;

  Future<void> initialize() async {
    final installed = await _repository.getInstalledVersion();
    final cached = await _repository.getCachedRelease();
    final lastChecked = await _repository.getLastCheckedAt();
    final platformKey = _repository.currentPlatformKey;
    final downloadedPath = await _repository.getDownloadedArtifactPath();
    final downloadedVersion = await _repository.getDownloadedArtifactVersion();

    final availability = cached == null
        ? UpdateAvailability.unknown
        : _resolveAvailability(
            installedVersion: installed.version,
            installedBuild: installed.build,
            manifest: cached,
            platformKey: platformKey,
          );

    UpdateCenterStatus status = _statusForAvailability(availability);
    String? restoredDownloadPath;

    if (!kIsWeb &&
        availability == UpdateAvailability.updateAvailable &&
        downloadedPath != null &&
        downloadedVersion == cached?.version) {
      final file = File(downloadedPath);
      if (await file.exists()) {
        status = UpdateCenterStatus.downloadReady;
        restoredDownloadPath = downloadedPath;
      }
    }

    emit(
      state.copyWith(
        installedVersion: installed.version,
        installedBuild: installed.build,
        platformKey: platformKey,
        latestRelease: cached,
        lastCheckedAt: lastChecked,
        availability: availability,
        status: status,
        downloadedPath: restoredDownloadPath,
      ),
    );
  }

  Future<void> checkForUpdates() async {
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: UpdateCenterStatus.checking,
        clearErrorCode: true,
        clearDownloadProgress: true,
      ),
    );

    try {
      final manifest = await _repository.checkForUpdates(
        channel: _releaseChannel,
      );
      final lastChecked = await _repository.getLastCheckedAt();

      if (manifest == null) {
        emit(
          state.copyWith(
            status: UpdateCenterStatus.checkFailed,
            errorCode: 'invalid_response',
            lastCheckedAt: lastChecked,
          ),
        );
        return;
      }

      final availability = _resolveAvailability(
        installedVersion: state.installedVersion,
        installedBuild: state.installedBuild,
        manifest: manifest,
        platformKey: state.platformKey,
      );

      emit(
        state.copyWith(
          latestRelease: manifest,
          lastCheckedAt: lastChecked,
          availability: availability,
          status: _statusForAvailability(availability),
          clearErrorCode: true,
          clearDownloadedPath: availability != UpdateAvailability.updateAvailable,
        ),
      );
    } on AppUpdateCheckException catch (error) {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.checkFailed,
          errorCode: error.code,
        ),
      );
    } on DioException {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.checkFailed,
          errorCode: 'network',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.checkFailed,
          errorCode: 'unknown',
        ),
      );
    }
  }

  Future<void> downloadUpdate() async {
    final manifest = state.latestRelease;
    final artifact = state.platformArtifact;
    if (manifest == null ||
        artifact == null ||
        !artifact.available ||
        state.availability != UpdateAvailability.updateAvailable) {
      return;
    }
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: UpdateCenterStatus.downloading,
        downloadProgress: 0,
        clearErrorCode: true,
      ),
    );

    try {
      final path = await _repository.downloadUpdate(
        artifact: artifact,
        platformKey: state.platformKey,
        version: manifest.version,
        onProgress: (received, total) {
          if (isClosed || total == null || total <= 0) return;
          emit(
            state.copyWith(
              downloadProgress: received / total,
            ),
          );
        },
      );

      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadReady,
          downloadedPath: path,
          downloadProgress: 1,
        ),
      );
    } on AppUpdateDownloadException catch (error) {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadFailed,
          errorCode: error.code,
          clearDownloadProgress: true,
        ),
      );
    } on DioException {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadFailed,
          errorCode: 'network',
          clearDownloadProgress: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadFailed,
          errorCode: 'unknown',
          clearDownloadProgress: true,
        ),
      );
    }
  }

  Future<void> installDownloadedUpdate() async {
    final path = state.downloadedPath;
    if (path == null || path.isEmpty) return;
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: UpdateCenterStatus.installing,
        clearErrorCode: true,
      ),
    );

    try {
      await _repository.installDownloadedUpdate(
        filePath: path,
        platformKey: state.platformKey,
      );
    } on AppUpdateInstallException catch (error) {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadReady,
          errorCode: error.code,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadReady,
          errorCode: 'install_failed',
        ),
      );
    }
  }

  String? get releaseNotes {
    final notes = state.latestRelease?.releaseNotes?.trim();
    if (notes == null || notes.isEmpty) return null;
    return notes;
  }

  UpdateAvailability _resolveAvailability({
    required String installedVersion,
    required int installedBuild,
    required AppReleaseManifest manifest,
    required String platformKey,
  }) {
    final comparison = compareAppVersions(
      currentVersion: installedVersion,
      currentBuild: installedBuild,
      latestVersion: manifest.version,
      latestBuild: manifest.build,
    );

    switch (comparison) {
      case VersionComparison.equal:
        return UpdateAvailability.upToDate;
      case VersionComparison.currentIsNewer:
        return UpdateAvailability.aheadOfServer;
      case VersionComparison.updateAvailable:
        final artifact = manifest.artifactForPlatform(platformKey);
        if (!artifact.available || artifact.downloadUrl == null) {
          return UpdateAvailability.platformUnavailable;
        }
        return UpdateAvailability.updateAvailable;
    }
  }

  UpdateCenterStatus _statusForAvailability(UpdateAvailability availability) {
    switch (availability) {
      case UpdateAvailability.unknown:
        return UpdateCenterStatus.idle;
      case UpdateAvailability.upToDate:
        return UpdateCenterStatus.upToDate;
      case UpdateAvailability.updateAvailable:
        return UpdateCenterStatus.updateAvailable;
      case UpdateAvailability.aheadOfServer:
        return UpdateCenterStatus.aheadOfServer;
      case UpdateAvailability.platformUnavailable:
        return UpdateCenterStatus.platformUnavailable;
    }
  }
}
