class AppSettings {
  const AppSettings({
    this.activePatientId,
    this.thresholdPercentAboveBaseline = 3,
    this.peakWindowSize = 10,
    this.notableSwingPercentOfMvsRange = 5,
    this.preferredDeviceName = 'PressureTX',
    this.serviceUuid = '12345678-1234-1234-1234-1234567890ab',
    this.characteristicUuid = 'abcd1234-5678-4321-abcd-1234567890ab',
  });

  final String? activePatientId;
  final double thresholdPercentAboveBaseline;
  final int peakWindowSize;
  final double notableSwingPercentOfMvsRange;
  final String preferredDeviceName;
  final String serviceUuid;
  final String characteristicUuid;

  AppSettings copyWith({
    String? activePatientId,
    bool clearActivePatient = false,
    double? thresholdPercentAboveBaseline,
    int? peakWindowSize,
    double? notableSwingPercentOfMvsRange,
    String? preferredDeviceName,
    String? serviceUuid,
    String? characteristicUuid,
  }) {
    return AppSettings(
      activePatientId: clearActivePatient
          ? null
          : activePatientId ?? this.activePatientId,
      thresholdPercentAboveBaseline:
          thresholdPercentAboveBaseline ?? this.thresholdPercentAboveBaseline,
      peakWindowSize: peakWindowSize ?? this.peakWindowSize,
      notableSwingPercentOfMvsRange:
          notableSwingPercentOfMvsRange ?? this.notableSwingPercentOfMvsRange,
      preferredDeviceName: preferredDeviceName ?? this.preferredDeviceName,
      serviceUuid: serviceUuid ?? this.serviceUuid,
      characteristicUuid: characteristicUuid ?? this.characteristicUuid,
    );
  }
}
