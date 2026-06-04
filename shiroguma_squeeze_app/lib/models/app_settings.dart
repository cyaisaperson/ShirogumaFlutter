enum DataMode {
  liveBle,
  sdCard;

  String get label {
    return switch (this) {
      DataMode.liveBle => 'Live BLE',
      DataMode.sdCard => 'SD Card Sync',
    };
  }

  String get storageValue {
    return switch (this) {
      DataMode.liveBle => 'live_ble',
      DataMode.sdCard => 'sd_card',
    };
  }

  static DataMode fromStorageValue(String? value) {
    return switch (value) {
      'sd_card' => DataMode.sdCard,
      _ => DataMode.liveBle,
    };
  }
}

class AppSettings {
  const AppSettings({
    this.activePatientId,
    this.dataMode = DataMode.liveBle,
    this.thresholdPercentAboveBaseline = 3,
    this.peakWindowSize = 10,
    this.stableWindowSize = 10,
    this.notableSwingPercentOfMvsRange = 5,
    this.preferredDeviceName = 'PressureTX',
    this.serviceUuid = '12345678-1234-1234-1234-1234567890ab',
    this.characteristicUuid = 'abcd1234-5678-4321-abcd-1234567890ab',
    this.batteryCharacteristicUuid = 'abcd1234-5678-4321-abcd-1234567890ac',
    this.lastSdSyncAt,
  });

  final String? activePatientId;
  final DataMode dataMode;
  final double thresholdPercentAboveBaseline;
  final int peakWindowSize;
  final int stableWindowSize;
  final double notableSwingPercentOfMvsRange;
  final String preferredDeviceName;
  final String serviceUuid;
  final String characteristicUuid;
  final String batteryCharacteristicUuid;
  final DateTime? lastSdSyncAt;

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      activePatientId: json['activePatientId'] as String?,
      dataMode: DataMode.fromStorageValue(json['dataMode'] as String?),
      thresholdPercentAboveBaseline:
          (json['thresholdPercentAboveBaseline'] as num?)?.toDouble() ?? 3,
      peakWindowSize: json['peakWindowSize'] as int? ?? 10,
      stableWindowSize: json['stableWindowSize'] as int? ?? 10,
      notableSwingPercentOfMvsRange:
          (json['notableSwingPercentOfMvsRange'] as num?)?.toDouble() ?? 5,
      preferredDeviceName:
          json['preferredDeviceName'] as String? ?? 'PressureTX',
      serviceUuid:
          json['serviceUuid'] as String? ??
          '12345678-1234-1234-1234-1234567890ab',
      characteristicUuid:
          json['characteristicUuid'] as String? ??
          'abcd1234-5678-4321-abcd-1234567890ab',
      batteryCharacteristicUuid:
          json['batteryCharacteristicUuid'] as String? ??
          'abcd1234-5678-4321-abcd-1234567890ac',
      lastSdSyncAt: json['lastSdSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSdSyncAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'activePatientId': activePatientId,
      'dataMode': dataMode.storageValue,
      'thresholdPercentAboveBaseline': thresholdPercentAboveBaseline,
      'peakWindowSize': peakWindowSize,
      'stableWindowSize': stableWindowSize,
      'notableSwingPercentOfMvsRange': notableSwingPercentOfMvsRange,
      'preferredDeviceName': preferredDeviceName,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'batteryCharacteristicUuid': batteryCharacteristicUuid,
      'lastSdSyncAt': lastSdSyncAt?.toIso8601String(),
    };
  }

  AppSettings copyWith({
    String? activePatientId,
    bool clearActivePatient = false,
    DataMode? dataMode,
    double? thresholdPercentAboveBaseline,
    int? peakWindowSize,
    int? stableWindowSize,
    double? notableSwingPercentOfMvsRange,
    String? preferredDeviceName,
    String? serviceUuid,
    String? characteristicUuid,
    String? batteryCharacteristicUuid,
    DateTime? lastSdSyncAt,
    bool clearLastSdSyncAt = false,
  }) {
    return AppSettings(
      activePatientId: clearActivePatient
          ? null
          : activePatientId ?? this.activePatientId,
      dataMode: dataMode ?? this.dataMode,
      thresholdPercentAboveBaseline:
          thresholdPercentAboveBaseline ?? this.thresholdPercentAboveBaseline,
      peakWindowSize: peakWindowSize ?? this.peakWindowSize,
      stableWindowSize: stableWindowSize ?? this.stableWindowSize,
      notableSwingPercentOfMvsRange:
          notableSwingPercentOfMvsRange ?? this.notableSwingPercentOfMvsRange,
      preferredDeviceName: preferredDeviceName ?? this.preferredDeviceName,
      serviceUuid: serviceUuid ?? this.serviceUuid,
      characteristicUuid: characteristicUuid ?? this.characteristicUuid,
      batteryCharacteristicUuid:
          batteryCharacteristicUuid ?? this.batteryCharacteristicUuid,
      lastSdSyncAt: clearLastSdSyncAt
          ? null
          : lastSdSyncAt ?? this.lastSdSyncAt,
    );
  }
}
