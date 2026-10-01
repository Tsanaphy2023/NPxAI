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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
