import '../../domain/models/nutrient_prediction.dart';
import '../../domain/models/soil_sample.dart';
import '../../domain/models/spectral_signature.dart';
import '../../domain/use_cases/edge_ai_inference_use_case.dart';
import '../services/camera_vision_service.dart';
import '../services/hardware_chamber_service.dart';
import '../services/storage_export_service.dart';

abstract class SoilRepository {
  Future<SpectralSignature> captureSpectralSignature();
  Future<NutrientPrediction> analyzeSoilNutrients(
    SpectralSignature signature, {
    String? modelName,
    String? farmingType,
    String? cropType,
  });
  Future<void> saveSoilRecord(SoilSample sample, NutrientPrediction prediction);
  String generateCsvReport();
  List<Map<String, dynamic>> getRecords();
}

class SoilRepositoryImpl implements SoilRepository {
  final HardwareChamberService _chamberService;
  final CameraVisionService _visionService;
  final EdgeAiInferenceUseCase _aiUseCase;
  final StorageExportService _storageService;

  SoilRepositoryImpl({
    required HardwareChamberService chamberService,
    required CameraVisionService visionService,
    required EdgeAiInferenceUseCase aiUseCase,
    required StorageExportService storageService,
  })  : _chamberService = chamberService,
        _visionService = visionService,
        _aiUseCase = aiUseCase,
        _storageService = storageService;

  @override
  Future<SpectralSignature> captureSpectralSignature() async {
    // ดึงค่าการอ่านจาก Chamber และคำนวณสเปกตรัม
    final status = _chamberService.status;
    return await _visionService.extractSpectralSignature(
      calibObservedRed: 238.0,
      calibObservedGreen: 239.5,
      calibObservedBlue: 241.0,
      soilMoistureEstimate: status.chamberHumidityPercent,
    );
  }

  @override
  Future<NutrientPrediction> analyzeSoilNutrients(
    SpectralSignature signature, {
    String? modelName,
    String? farmingType,
    String? cropType,
  }) async {
    return _aiUseCase.predictNutrients(
      signature,
      modelName: modelName,
      farmingType: farmingType,
      cropType: cropType,
    );
  }

  @override
  Future<void> saveSoilRecord(
      SoilSample sample, NutrientPrediction prediction) async {
    _storageService.saveRecord(sample, prediction);
  }

  @override
  String generateCsvReport() {
    return _storageService.exportToCsv();
  }

  @override
  List<Map<String, dynamic>> getRecords() {
    return _storageService.historyRecords;
  }
}
