import 'package:flutter/foundation.dart';
import '../../../../data/repositories/soil_repository.dart';
import '../../../../data/services/hardware_chamber_service.dart';
import '../../../../domain/models/chamber_status.dart';
import '../../../../domain/models/nutrient_prediction.dart';
import '../../../../domain/models/soil_sample.dart';
import '../../../../domain/models/spectral_signature.dart';

class SoilScannerViewModel extends ChangeNotifier {
  final SoilRepository _soilRepository;
  final HardwareChamberService _chamberService;

  SoilScannerViewModel({
    required SoilRepository soilRepository,
    required HardwareChamberService chamberService,
  })  : _soilRepository = soilRepository,
        _chamberService = chamberService;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  double _scanProgress = 0.0;
  double get scanProgress => _scanProgress;

  String _currentStepText = 'พร้อมสำหรับการสแกน';
  String get currentStepText => _currentStepText;

  SoilSample? _lastSample;
  SoilSample? get lastSample => _lastSample;

  NutrientPrediction? _lastPrediction;
  NutrientPrediction? get lastPrediction => _lastPrediction;

  double _autoLatitude = 12.612845;
  double get autoLatitude => _autoLatitude;

  double _autoLongitude = 102.103982;
  double get autoLongitude => _autoLongitude;

  bool _isGpsLocked = true;
  bool get isGpsLocked => _isGpsLocked;

  // โหมดการทำงานและโมเดล AI ที่เลือกใช้
  String _selectedAiModel = 'SIMULATION';
  String get selectedAiModel => _selectedAiModel;

  final List<String> availableModels = const [
    'SIMULATION',
    'MobileNetV4-Soil',
    'EfficientNet-B0',
    'Soil-ViT',
    'ResNet18-DualBranch',
  ];

  void setAiModel(String model) {
    _selectedAiModel = model;
    notifyListeners();
  }

  /// ดึงพิกัด GPS อัตโนมัติ ณ ตำแหน่งแปลงดินที่ทำการตรวจวัด
  void refreshGpsLocation() {
    // สุ่ม drift เล็กน้อยในโซนแปลงเกษตรกรรมจันทบุรีเพื่อจำลองการเดินสำรวจจริง
    final rand = DateTime.now().millisecond;
    _autoLatitude = 12.612845 + ((rand % 100) - 50) * 0.00002;
    _autoLongitude = 102.103982 + ((rand % 80) - 40) * 0.00002;
    _isGpsLocked = true;
    notifyListeners();
  }

  /// ดำเนินการสแกนสเปกตรัมหลายช่วงคลื่น (Strobe Sequence Automation)
  Future<bool> startMultiSpectralScan({
    required String plotName,
    required String cropType,
    required String farmingType,
    double? latitude,
    double? longitude,
    String? aiModel,
  }) async {
    final String activeModel = aiModel ?? _selectedAiModel;
    _isScanning = true;
    _scanProgress = 0.0;
    _currentStepText = activeModel == 'SIMULATION'
        ? 'เตรียมความพร้อมอุปกรณ์ Chamber (SIMULATION)...'
        : 'เตรียมความพร้อมกล้องและโมเดล $activeModel...';
    notifyListeners();

    final double activeLat = latitude ?? _autoLatitude;
    final double activeLng = longitude ?? _autoLongitude;

    try {
      final wavelengths = [
        StrobeWavelength.whiteRef,
        StrobeWavelength.uv405,
        StrobeWavelength.blue465,
        StrobeWavelength.green525,
        StrobeWavelength.red630,
        StrobeWavelength.nir850,
        StrobeWavelength.nir940,
      ];

      for (int i = 0; i < wavelengths.length; i++) {
        final wl = wavelengths[i];
        _currentStepText = 'สโตรบแสง: ${wl.description}...';
        _scanProgress = (i + 1) / (wavelengths.length + 1);
        notifyListeners();

        // สั่งเปิดไฟ LED ตามความยาวคลื่น
        if (_chamberService.status.isConnected) {
          await _chamberService.triggerLedStrobe(wl, durationMs: 200);
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // ขั้นตอนการสกัดคุณลักษณะและการประมวลผลภาพ (ROI & Normalization)
      if (activeModel == 'SIMULATION') {
        _currentStepText = 'สกัดลายพิมพ์สเปกตรัมและประมวลผลจำลอง (SIMULATION)...';
      } else {
        _currentStepText = 'สกัดเวกเตอร์ลักษณะภาพและประมวลผลด้วยโมเดล $activeModel...';
      }
      _scanProgress = 0.95;
      notifyListeners();

      final SpectralSignature signature =
          await _soilRepository.captureSpectralSignature();

      // รันการทำนายผล Total N และ Available P ผ่าน AI Engine
      final NutrientPrediction prediction =
          await _soilRepository.analyzeSoilNutrients(
        signature,
        modelName: activeModel,
        farmingType: farmingType,
        cropType: cropType,
      );

      final String sampleId =
          'SOIL-JB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final sample = SoilSample(
        id: sampleId,
        plotName: plotName,
        cropType: cropType,
        farmingType: farmingType,
        latitude: activeLat,
        longitude: activeLng,
        measuredAt: DateTime.now(),
        spectralSignature: signature,
      );

      // บันทึกผลลงใน Local Cache / Storage
      await _soilRepository.saveSoilRecord(sample, prediction);

      _lastSample = sample;
      _lastPrediction = prediction;
      _currentStepText = 'การวิเคราะห์เสร็จสมบูรณ์!';
      _scanProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _currentStepText = 'เกิดข้อผิดพลาดในการวิเคราะห์: $e';
      notifyListeners();
      return false;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
}
