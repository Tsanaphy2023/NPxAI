import 'dart:async';
import 'dart:math';
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

  // โหมดสถาปัตยกรรมฮาร์ดแวร์ (Dual-Architecture)
  NPxAIMode _currentMode = NPxAIMode.liteFlash; // เริ่มต้นโหมดพกพาประหยัดเพื่อความสะดวก หรือสลับเป็น Pro ได้
  NPxAIMode get currentMode => _currentMode;

  void setMode(NPxAIMode mode) {
    _currentMode = mode;
    // หากสลับมาโหมด Lite Flash ในขณะที่กำลัง Live Stream ให้เปิดแฟลชเพื่อความถูกต้อง
    if (_isLiveVideoActive && _currentMode == NPxAIMode.liteFlash) {
      _isFlashlightOn = true;
    }
    notifyListeners();
  }

  // --- ระบบวิเคราะห์สตรีมวิดีโอสดแบบเรียลไทม์ (Live Video Edge AI Stream) ---
  bool _isLiveVideoActive = false;
  bool get isLiveVideoActive => _isLiveVideoActive;

  NutrientPrediction? _livePrediction;
  NutrientPrediction? get livePrediction => _livePrediction;

  bool _isFlashlightOn = false;
  bool get isFlashlightOn => _isFlashlightOn;

  Timer? _liveAnalysisTimer;

  void toggleFlashlight() {
    _isFlashlightOn = !_isFlashlightOn;
    notifyListeners();
  }

  void setFlashlight(bool on) {
    if (_isFlashlightOn != on) {
      _isFlashlightOn = on;
      notifyListeners();
    }
  }

  void toggleLiveVideoAnalysis({
    String plotName = 'แปลงตรวจวัด Live',
    String cropType = 'ทุเรียน',
    String farmingType = 'อินทรีย์เคมี',
  }) {
    if (_isLiveVideoActive) {
      stopLiveVideoAnalysis();
    } else {
      startLiveVideoAnalysis(
        plotName: plotName,
        cropType: cropType,
        farmingType: farmingType,
      );
    }
  }

  void startLiveVideoAnalysis({
    String plotName = 'แปลงตรวจวัด Live',
    String cropType = 'ทุเรียน',
    String farmingType = 'อินทรีย์เคมี',
  }) {
    _isLiveVideoActive = true;
    if (_currentMode == NPxAIMode.liteFlash) {
      _isFlashlightOn = true;
    }
    _runSingleLiveInference(cropType: cropType, farmingType: farmingType);
    _liveAnalysisTimer?.cancel();
    _liveAnalysisTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      _runSingleLiveInference(cropType: cropType, farmingType: farmingType);
    });
    notifyListeners();
  }

  void stopLiveVideoAnalysis() {
    _liveAnalysisTimer?.cancel();
    _liveAnalysisTimer = null;
    _isLiveVideoActive = false;
    _livePrediction = null;
    if (_currentMode == NPxAIMode.liteFlash) {
      _isFlashlightOn = false;
    }
    notifyListeners();
  }

  Future<void> _runSingleLiveInference({
    required String cropType,
    required String farmingType,
  }) async {
    try {
      final rand = Random();
      final jitter = (rand.nextDouble() - 0.5) * 0.03;
      final signature = SpectralSignature(
        r405nm: (0.16 + jitter).clamp(0.05, 0.95),
        r465nm: (0.24 + jitter).clamp(0.05, 0.95),
        r525nm: (0.33 + jitter).clamp(0.05, 0.95),
        r630nm: (0.42 + jitter).clamp(0.05, 0.95),
        r850nm: (0.68 + jitter).clamp(0.05, 0.95),
        r940nm: (0.64 + jitter).clamp(0.05, 0.95),
        hueMean: (24.5 + (rand.nextDouble() - 0.5) * 2.0).clamp(0.0, 360.0),
        saturationMean: (0.55 + jitter).clamp(0.0, 1.0),
        valueMean: (0.42 + jitter).clamp(0.0, 1.0),
        valueMedian: (0.41 + jitter).clamp(0.0, 1.0),
        calibrationGainFactor: 1.0,
      );

      final pred = await _soilRepository.analyzeSoilNutrients(
        signature,
        mode: _currentMode,
        modelName: _selectedAiModel,
        farmingType: farmingType,
        cropType: cropType,
      );

      _livePrediction = pred;
      notifyListeners();
    } catch (_) {}
  }

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

  /// ดำเนินการสแกนสเปกตรัมตามสถาปัตยกรรมที่เลือก (Dual-Mode: Lite Flash vs Pro Chamber)
  Future<bool> startMultiSpectralScan({
    required String plotName,
    required String cropType,
    required String farmingType,
    NPxAIMode? mode,
    double? latitude,
    double? longitude,
    String? aiModel,
  }) async {
    final NPxAIMode activeMode = mode ?? _currentMode;
    final String activeModel = aiModel ?? _selectedAiModel;
    _isScanning = true;
    _scanProgress = 0.0;
    
    if (activeMode == NPxAIMode.liteFlash) {
      _currentStepText = 'เปิดไฟฉายสมาร์ทโฟน สะท้อนผ่านท่อนำแสง 45° (NPxAI Lite)...';
    } else {
      _currentStepText = activeModel == 'SIMULATION'
          ? 'เตรียมความพร้อมอุปกรณ์ Chamber 7-Band (NPxAI Pro)...'
          : 'เตรียมความพร้อมกล้องและโมเดล $activeModel (NPxAI Pro)...';
    }
    notifyListeners();

    final double activeLat = latitude ?? _autoLatitude;
    final double activeLng = longitude ?? _autoLongitude;

    try {
      if (activeMode == NPxAIMode.liteFlash) {
        // --- 1. โหมด NPxAI Lite: ใช้แสงแฟลชมือถือ + ท่อนำแสง 45° ---
        _scanProgress = 0.35;
        _currentStepText = 'ฉายแสงแฟลชมือถือผ่านท่อนำแสง 45° ตกกระทบผิวหน้าดิน...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 350));

        _scanProgress = 0.70;
        _currentStepText = 'บันทึกภาพการสะท้อนสเปกตรัมในกล่อง 3D Dark Box...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // --- 2. โหมด NPxAI Pro: สโตรบ LED 7 แถบความยาวคลื่น ---
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
          _currentStepText = 'สโตรบแสง [Pro]: ${wl.description}...';
          _scanProgress = (i + 1) / (wavelengths.length + 1);
          notifyListeners();

          // สั่งเปิดไฟ LED ตามความยาวคลื่น
          if (_chamberService.status.isConnected) {
            await _chamberService.triggerLedStrobe(wl, durationMs: 180);
          } else {
            await Future.delayed(const Duration(milliseconds: 180));
          }
        }
      }

      // ขั้นตอนการสกัดคุณลักษณะและการประมวลผลภาพ (ROI & Normalization)
      if (activeMode == NPxAIMode.liteFlash) {
        _currentStepText = 'สกัดลายพิมพ์สเปกตรัมจากภาพถ่ายแฟลช 45° และคำนวณ N-P-K...';
      } else if (activeModel == 'SIMULATION') {
        _currentStepText = 'สกัดลายพิมพ์สเปกตรัม 7 แถบและประมวลผลจำลอง (SIMULATION)...';
      } else {
        _currentStepText = 'สกัดเวกเตอร์ลักษณะภาพ 7 แถบและประมวลผลด้วย $activeModel...';
      }
      _scanProgress = 0.95;
      notifyListeners();

      final SpectralSignature signature =
          await _soilRepository.captureSpectralSignature();

      // รันการทำนายผล Total N, Available P และ Available K ผ่าน AI Engine
      final NutrientPrediction prediction =
          await _soilRepository.analyzeSoilNutrients(
        signature,
        mode: activeMode,
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

  @override
  void dispose() {
    _liveAnalysisTimer?.cancel();
    super.dispose();
  }
}
