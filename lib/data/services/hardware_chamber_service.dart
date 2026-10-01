import 'dart:async';
import 'dart:math';
import '../../domain/models/chamber_status.dart';

/// Service: ควบคุมการเชื่อมต่อและสั่งการชุดวิเคราะห์ดินแบบพกพา (Hardware Chamber Service)
/// ปฏิบัติตามมาตรฐาน soil-pht-aiot-architect:
/// - วงจรชีวิตการถือครองพอร์ต (Foreground Claim / Background Release) ป้องกันพอร์ตชนกัน
/// - สั่งยิงแสง Multi-Wavelength LED ทีละคลื่นความถี่ (Strobe Sequence)
/// - มี Hardware Simulator ในตัวสำหรับการทดสอบ
class HardwareChamberService {
  ChamberStatus _status = const ChamberStatus();
  ChamberStatus get status => _status;

  final _statusController = StreamController<ChamberStatus>.broadcast();
  Stream<ChamberStatus> get statusStream => _statusController.stream;

  Timer? _telemetryTimer;
  bool _isClaimed = false;

  HardwareChamberService() {
    // ปล่อยสถานะเริ่มต้น
    _emitStatus(_status);
  }

  void _emitStatus(ChamberStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  /// ยึดครองพอร์ตเมื่อแอปพลิเคชันขึ้นสู่เบื้องหน้า (Foreground Claim)
  Future<bool> claimAndConnect({bool forceSimulator = false}) async {
    _isClaimed = true;
    _emitStatus(_status.copyWith(connectionState: ChamberConnectionState.connecting));

    await Future.delayed(const Duration(milliseconds: 600));

    if (forceSimulator) {
      _emitStatus(_status.copyWith(
        connectionState: ChamberConnectionState.simulatorMode,
        deviceName: 'NPxAI-Chamber-SIM-01',
        batteryLevelPercent: 94,
        chamberTemperatureC: 28.2,
        chamberHumidityPercent: 58.0,
      ));
      _startTelemetrySimulation();
      return true;
    }

    // สมมติการเชื่อมต่อผ่าน Bluetooth Low Energy หรือ USB-OTG Serial
    _emitStatus(_status.copyWith(
      connectionState: ChamberConnectionState.connectedBle,
      deviceName: 'NPxAI-Chamber-BLE-01',
      batteryLevelPercent: 88,
      chamberTemperatureC: 28.0,
      chamberHumidityPercent: 55.4,
    ));
    _startTelemetrySimulation();
    return true;
  }

  /// ปล่อยพอร์ตทันทีเมื่อแอปพลิเคชันลงสู่เบื้องหลัง (Background Release)
  /// เพื่อป้องกันปัญหา Port Claiming / Device Conflict ตามกฎข้อ 3 ของ soil-pht-aiot-architect
  void releaseAndDisconnect() {
    _isClaimed = false;
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _emitStatus(_status.copyWith(
      connectionState: ChamberConnectionState.disconnected,
      currentStrobe: StrobeWavelength.none,
    ));
    print('[NPxAI] Hardware port gracefully released to system.');
  }

  /// จำลองการอ่านค่าอุณหภูมิและความชื้นภายในกล่องเซนเซอร์
  void _startTelemetrySimulation() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isClaimed || !_status.isConnected) return;
      final rand = Random();
      final double tempDrift = (rand.nextDouble() - 0.5) * 0.2;
      final double humDrift = (rand.nextDouble() - 0.5) * 0.4;
      _emitStatus(_status.copyWith(
        chamberTemperatureC:
            double.parse((_status.chamberTemperatureC + tempDrift).toStringAsFixed(1)),
        chamberHumidityPercent:
            double.parse((_status.chamberHumidityPercent + humDrift).toStringAsFixed(1)),
      ));
    });
  }

  /// สั่งเปิด LED ตามความยาวคลื่นที่ต้องการ (Duration ms)
  Future<void> triggerLedStrobe(StrobeWavelength wavelength, {int durationMs = 250}) async {
    if (!_status.isConnected) throw Exception('Chamber is not connected.');

    _emitStatus(_status.copyWith(currentStrobe: wavelength));
    print('[NPxAI-MCU] Strobe command: LED ${wavelength.nm} nm for ${durationMs}ms');

    await Future.delayed(Duration(milliseconds: durationMs));
    _emitStatus(_status.copyWith(currentStrobe: StrobeWavelength.none));
  }

  /// กำหนดสถานะ Calibrated หลังเทียบแผ่นสี
  void setCalibrated(bool value) {
    _emitStatus(_status.copyWith(isCalibrated: value));
  }

  void dispose() {
    _telemetryTimer?.cancel();
    _statusController.close();
  }
}
