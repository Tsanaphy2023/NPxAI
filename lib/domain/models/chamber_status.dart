enum ChamberConnectionState {
  disconnected,
  connecting,
  connectedBle,
  connectedUsb,
  simulatorMode,
}

enum StrobeWavelength {
  none(0, 'Standby'),
  whiteRef(0, 'White Reference (Color Chart)'),
  uv405(405, 'Violet 405 nm (Humus & Organics)'),
  blue465(465, 'Blue 465 nm (Soil Surface Reflection)'),
  green525(525, 'Green 525 nm (Iron & Soil Minerals)'),
  red630(630, 'Red 630 nm (Organic Nitrogen Bonds)'),
  nir850(850, 'NIR 850 nm (C-H/N-H & Moisture)'),
  nir940(940, 'NIR 940 nm (Phosphate Matrix)');

  final int nm;
  final String description;
  const StrobeWavelength(this.nm, this.description);
}

/// ข้อมูลสถานะฮาร์ดแวร์ชุดวิเคราะห์ดินแบบพกพา (Hardware Telemetry)
class ChamberStatus {
  final ChamberConnectionState connectionState;
  final String deviceName;
  final int batteryLevelPercent;
  final double chamberTemperatureC;
  final double chamberHumidityPercent;
  final StrobeWavelength currentStrobe;
  final bool isCalibrated;

  const ChamberStatus({
    this.connectionState = ChamberConnectionState.disconnected,
    this.deviceName = 'NPxAI-Chamber',
    this.batteryLevelPercent = 100,
    this.chamberTemperatureC = 27.5,
    this.chamberHumidityPercent = 55.0,
    this.currentStrobe = StrobeWavelength.none,
    this.isCalibrated = false,
  });

  bool get isConnected =>
      connectionState == ChamberConnectionState.connectedBle ||
      connectionState == ChamberConnectionState.connectedUsb ||
      connectionState == ChamberConnectionState.simulatorMode;

  ChamberStatus copyWith({
    ChamberConnectionState? connectionState,
    String? deviceName,
    int? batteryLevelPercent,
    double? chamberTemperatureC,
    double? chamberHumidityPercent,
    StrobeWavelength? currentStrobe,
    bool? isCalibrated,
  }) {
    return ChamberStatus(
      connectionState: connectionState ?? this.connectionState,
      deviceName: deviceName ?? this.deviceName,
      batteryLevelPercent: batteryLevelPercent ?? this.batteryLevelPercent,
      chamberTemperatureC: chamberTemperatureC ?? this.chamberTemperatureC,
      chamberHumidityPercent:
          chamberHumidityPercent ?? this.chamberHumidityPercent,
      currentStrobe: currentStrobe ?? this.currentStrobe,
      isCalibrated: isCalibrated ?? this.isCalibrated,
    );
  }
}
