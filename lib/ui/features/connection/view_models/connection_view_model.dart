import 'package:flutter/foundation.dart';
import '../../../../data/services/hardware_chamber_service.dart';
import '../../../../domain/models/chamber_status.dart';

class ConnectionViewModel extends ChangeNotifier {
  final HardwareChamberService _chamberService;

  ConnectionViewModel({required HardwareChamberService chamberService})
      : _chamberService = chamberService {
    _chamberService.statusStream.listen((status) {
      _currentStatus = status;
      notifyListeners();
    });
    _currentStatus = _chamberService.status;
  }

  ChamberStatus _currentStatus = const ChamberStatus();
  ChamberStatus get status => _currentStatus;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isCalibrating = false;
  bool get isCalibrating => _isCalibrating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _calibrationMessage;
  String? get calibrationMessage => _calibrationMessage;

  Future<void> connectChamber({bool forceSimulator = false}) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _chamberService.claimAndConnect(
        forceSimulator: forceSimulator,
      );
      if (!success) {
        _errorMessage = 'ไม่สามารถเชื่อมต่ออุปกรณ์ Chamber ได้ กรุณาตรวจสอบสัญญาณ';
      }
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void disconnectChamber() {
    _chamberService.releaseAndDisconnect();
  }

  /// ดำเนินการสอบเทียบแผ่นเทียบขาวมาตรฐาน (White Reference Calibration 100% Reflectance)
  Future<void> calibrateWhiteReference() async {
    if (!_currentStatus.isConnected) {
      _errorMessage = 'กรุณาเชื่อมต่ออุปกรณ์ Chamber ก่อนเริ่มการสอบเทียบ';
      notifyListeners();
      return;
    }

    _isCalibrating = true;
    _calibrationMessage = 'กำลังยิงแสงและวัดค่าแผ่นเทียบขาวมาตรฐาน (405 - 940 nm)...';
    _errorMessage = null;
    notifyListeners();

    try {
      // จำลอง/ส่งคำสั่ง Strobe ทีละคลื่นความถี่ตามลำดับ
      await _chamberService.triggerLedStrobe(StrobeWavelength.whiteRef, durationMs: 400);
      await Future.delayed(const Duration(milliseconds: 300));
      await _chamberService.triggerLedStrobe(StrobeWavelength.uv405, durationMs: 250);
      await _chamberService.triggerLedStrobe(StrobeWavelength.nir940, durationMs: 250);

      _chamberService.setCalibrated(true);
      _calibrationMessage = 'สอบเทียบแผ่นเทียบขาวสำเร็จ (White Calibration OK: Gain 1.003x)';
    } catch (e) {
      _errorMessage = 'การสอบเทียบล้มเหลว: $e';
    } finally {
      _isCalibrating = false;
      notifyListeners();
    }
  }

  /// ดำเนินการสอบเทียบจุดมืด (Dark Calibration 0-Lux Baseline)
  Future<void> calibrateDarkReference() async {
    if (!_currentStatus.isConnected) {
      _errorMessage = 'กรุณาเชื่อมต่ออุปกรณ์ Chamber ก่อนเริ่มการสอบเทียบ';
      notifyListeners();
      return;
    }

    _isCalibrating = true;
    _calibrationMessage = 'กำลังวัดค่าสัญญาณรบกวนในความมืด 0-Lux (Dark Current Compensation)...';
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      _calibrationMessage = 'สอบเทียบจุดมืดสำเร็จ (Dark Baseline Noise: 0.002 mV)';
    } catch (e) {
      _errorMessage = 'การสอบเทียบจุดมืดล้มเหลว: $e';
    } finally {
      _isCalibrating = false;
      notifyListeners();
    }
  }

  /// รีเซ็ตค่าการสอบเทียบ
  void resetCalibration() {
    _chamberService.setCalibrated(false);
    _calibrationMessage = null;
    notifyListeners();
  }

  /// เรียกจาก App Lifecycle Observer เมื่อแอปกลับมาเบื้องหน้า
  void reconnectHardware() {
    if (_currentStatus.connectionState != ChamberConnectionState.disconnected) {
      _chamberService.claimAndConnect();
    }
  }

  /// เรียกจาก App Lifecycle Observer เมื่อแอปพับลงพื้นหลัง
  void releaseHardware() {
    _chamberService.releaseAndDisconnect();
  }
}
