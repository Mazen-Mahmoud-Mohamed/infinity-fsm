import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_maps_launcher.dart';

enum _MapPointKind { start, end }

enum _TileStatus { loading, ready, error }

class OvertimeLocationSection extends StatefulWidget {
  const OvertimeLocationSection({
    super.key,
    required this.startGps,
    this.endGps,
    this.startAddress,
    this.endAddress,
  });

  final GpsSnapshot startGps;
  final GpsSnapshot? endGps;
  final String? startAddress;
  final String? endAddress;

  @override
  State<OvertimeLocationSection> createState() =>
      _OvertimeLocationSectionState();
}

class _OvertimeLocationSectionState extends State<OvertimeLocationSection> {
  static const Color _startColor = Color(0xFF16A34A);
  static const Color _endColor = Color(0xFFDC2626);
  static const Color _routeColor = Color(0xFF2563EB);

  /// Treat points closer than this as a single location (meters).
  static const double _nearDistanceMeters = 25;

  /// Unique app id for OSM tile User-Agent (generic "com.example.*" is blocked).
  static const String _tileUserAgent =
      'com.infinitytech.fsm.mobile';

  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  _MapPointKind? _selectedPoint;
  _TileStatus _tileStatus = _TileStatus.loading;
  String? _feedback;
  bool _didFitCamera = false;
  int _tileErrorCount = 0;
  Timer? _loadingTimer;
  int _tileLayerKey = 0;

  LatLng get _start =>
      LatLng(widget.startGps.latitude, widget.startGps.longitude);

  LatLng? get _endPoint {
    final end = widget.endGps;
    if (end == null) {
      return null;
    }
    return LatLng(end.latitude, end.longitude);
  }

  /// Distinct end point far enough from start to draw a second marker/route.
  LatLng? get _distinctEnd {
    final end = _endPoint;
    if (end == null) {
      return null;
    }
    final meters = _distance.as(LengthUnit.Meter, _start, end);
    if (meters < _nearDistanceMeters) {
      return null;
    }
    return end;
  }

  bool get _hasDistinctRoute => _distinctEnd != null;

  void _selectPoint(_MapPointKind kind) {
    setState(() => _selectedPoint = kind);
  }

  void _fitCamera() {
    if (_didFitCamera) {
      return;
    }
    _didFitCamera = true;

    final end = _distinctEnd;
    if (end == null) {
      _mapController.move(_start, 16);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(_start, end),
        padding: const EdgeInsets.fromLTRB(48, 56, 48, 48),
        maxZoom: 17,
      ),
    );
  }

  void _onMapReady() {
    _fitCamera();
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      if (_tileStatus == _TileStatus.loading && _tileErrorCount == 0) {
        setState(() => _tileStatus = _TileStatus.ready);
      } else if (_tileStatus == _TileStatus.loading && _tileErrorCount > 0) {
        setState(() => _tileStatus = _TileStatus.error);
      }
    });
  }

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    _tileErrorCount += 1;
    if (!mounted) {
      return;
    }
    // A few transient failures are fine; repeated failures show the error UI.
    if (_tileErrorCount >= 4 && _tileStatus != _TileStatus.error) {
      setState(() => _tileStatus = _TileStatus.error);
    }
  }

  void _retryTiles() {
    _loadingTimer?.cancel();
    setState(() {
      _tileStatus = _TileStatus.loading;
      _tileErrorCount = 0;
      _didFitCamera = false;
      _tileLayerKey += 1;
      _selectedPoint = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onMapReady();
      }
    });
  }

  Future<void> _openMaps({
    required double latitude,
    required double longitude,
    required String label,
    String? address,
  }) async {
    final opened = await OvertimeMapsLauncher.openCoordinates(
      latitude: latitude,
      longitude: longitude,
      label: address ?? label,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _feedback = opened ? null : 'overtimeUnableOpenGoogleMaps';
    });
    if (!opened) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.overtimeUnableOpenGoogleMaps),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final end = _distinctEnd;
    const mapHeight = 240.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.overtimeLocation,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: end == null
                            ? _start
                            : LatLng(
                                (_start.latitude + end.latitude) / 2,
                                (_start.longitude + end.longitude) / 2,
                              ),
                        initialZoom: end == null ? 16 : 13,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onMapReady: _onMapReady,
                        onTap: (_, _) {
                          if (_selectedPoint != null) {
                            setState(() => _selectedPoint = null);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          key: ValueKey<int>(_tileLayerKey),
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          fallbackUrl:
                              'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                          userAgentPackageName: _tileUserAgent,
                          maxNativeZoom: 19,
                          maxZoom: 20,
                          keepBuffer: 2,
                          panBuffer: 1,
                          errorTileCallback: _onTileError,
                          tileProvider: NetworkTileProvider(),
                        ),
                        if (_hasDistinctRoute)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [_start, end!],
                                color: _routeColor,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _start,
                              width: 44,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: _MapPin(
                                color: _startColor,
                                selected:
                                    _selectedPoint == _MapPointKind.start,
                                onTap: () =>
                                    _selectPoint(_MapPointKind.start),
                              ),
                            ),
                            if (end != null)
                              Marker(
                                point: end,
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: _MapPin(
                                  color: _endColor,
                                  selected:
                                      _selectedPoint == _MapPointKind.end,
                                  onTap: () =>
                                      _selectPoint(_MapPointKind.end),
                                ),
                              ),
                          ],
                        ),
                        SimpleAttributionWidget(
                          source: Text(
                            'OpenStreetMap',
                            style: theme.textTheme.labelSmall,
                          ),
                          alignment: Alignment.bottomRight,
                          backgroundColor: theme.colorScheme.surface
                              .withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                    if (_tileStatus == _TileStatus.loading)
                      ColoredBox(
                        color: theme.colorScheme.surface.withValues(alpha: 0.55),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    if (_tileStatus == _TileStatus.error)
                      ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 36,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.overtimeMapLoadFailed,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.overtimeMapCheckConnection,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.tonal(
                                  onPressed: _retryTiles,
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_selectedPoint != null &&
                        _tileStatus != _TileStatus.error)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 12,
                        child: _MarkerPopup(
                          title: _selectedPoint == _MapPointKind.start
                              ? (_hasDistinctRoute
                                  ? l10n.overtimeStartLocation
                                  : l10n.overtimeLocation)
                              : l10n.overtimeEndLocation,
                          address: _selectedPoint == _MapPointKind.start
                              ? widget.startAddress
                              : widget.endAddress,
                          accent: _selectedPoint == _MapPointKind.start
                              ? _startColor
                              : _endColor,
                          onClose: () =>
                              setState(() => _selectedPoint = null),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LegendChip(color: _startColor, label: l10n.labelStart),
              if (_hasDistinctRoute) ...[
                _LegendChip(color: _endColor, label: l10n.labelEnd),
                _LegendChip(color: _routeColor, label: l10n.overtimeRoute),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _AddressActionCard(
            title: l10n.overtimeStartAddress,
            address: widget.startAddress,
            accent: _startColor,
            openMapsLabel: l10n.overtimeOpenInGoogleMaps,
            onOpenMaps: () => _openMaps(
              latitude: widget.startGps.latitude,
              longitude: widget.startGps.longitude,
              label: l10n.overtimeStartLocation,
              address: widget.startAddress,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AddressActionCard(
            title: l10n.overtimeEndAddress,
            address: widget.endAddress,
            accent: _endColor,
            openMapsLabel: l10n.overtimeOpenInGoogleMaps,
            enabled: widget.endGps != null,
            onOpenMaps: widget.endGps == null
                ? null
                : () => _openMaps(
                      latitude: widget.endGps!.latitude,
                      longitude: widget.endGps!.longitude,
                      label: l10n.overtimeEndLocation,
                      address: widget.endAddress,
                    ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              localizeAppMessage(l10n, _feedback),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.location_on,
        color: color,
        size: selected ? 44 : 40,
        shadows: const [
          Shadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _MarkerPopup extends StatelessWidget {
  const _MarkerPopup({
    required this.title,
    required this.address,
    required this.accent,
    required this.onClose,
  });

  final String title;
  final String? address;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved =
        address != null && address!.trim().isNotEmpty ? address!.trim() : '-';

    return Material(
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place, color: accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resolved,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressActionCard extends StatelessWidget {
  const _AddressActionCard({
    required this.title,
    required this.address,
    required this.accent,
    required this.openMapsLabel,
    this.onOpenMaps,
    this.enabled = true,
  });

  final String title;
  final String? address;
  final Color accent;
  final String openMapsLabel;
  final VoidCallback? onOpenMaps;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedAddress =
        address != null && address!.trim().isNotEmpty ? address!.trim() : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            resolvedAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: enabled ? onOpenMaps : null,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(openMapsLabel),
            ),
          ),
        ],
      ),
    );
  }
}
