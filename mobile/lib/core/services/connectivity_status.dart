import 'package:equatable/equatable.dart';

/// Multi-level connectivity state used for sync decisions and user-facing status.
enum ConnectivityLevel {
  unknown,
  networkUnavailable,
  internetUnavailable,
  apiUnavailable,
  online,
}

/// Snapshot of network / internet / API reachability at a point in time.
class ConnectivitySnapshot extends Equatable {
  const ConnectivitySnapshot({
    required this.level,
    this.networkAvailable = false,
    this.networkType = 'none',
    this.internetReachable = false,
    this.apiReachable = false,
    this.reason,
    this.checkedAt,
  });

  final ConnectivityLevel level;
  final bool networkAvailable;
  final String networkType;
  final bool internetReachable;
  final bool apiReachable;
  final String? reason;
  final DateTime? checkedAt;

  /// Sync is allowed only when the backend API responds successfully.
  bool get canSync => apiReachable;

  /// Legacy alias — true when API is reachable.
  bool get isOnline => apiReachable;

  static const unknown = ConnectivitySnapshot(
    level: ConnectivityLevel.unknown,
  );

  ConnectivitySnapshot copyWith({
    ConnectivityLevel? level,
    bool? networkAvailable,
    String? networkType,
    bool? internetReachable,
    bool? apiReachable,
    String? reason,
    DateTime? checkedAt,
    bool clearReason = false,
  }) {
    return ConnectivitySnapshot(
      level: level ?? this.level,
      networkAvailable: networkAvailable ?? this.networkAvailable,
      networkType: networkType ?? this.networkType,
      internetReachable: internetReachable ?? this.internetReachable,
      apiReachable: apiReachable ?? this.apiReachable,
      reason: clearReason ? null : reason ?? this.reason,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  List<Object?> get props => [
        level,
        networkAvailable,
        networkType,
        internetReachable,
        apiReachable,
        reason,
        checkedAt,
      ];
}
