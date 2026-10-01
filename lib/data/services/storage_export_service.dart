import '../../domain/models/nutrient_prediction.dart';
import '../../domain/models/soil_sample.dart';

/// Service: จัดเก็บและส่งออกข้อมูลการวิเคราะห์ดิน (Storage & Export Service)
/// สอดคล้องกับข้อกำหนด Open Cloud & Drive Ingestion ของ soil-pht-aiot-architect
class StorageExportService {
  final List<Map<String, dynamic>> _historyRecords = [];

  List<Map<String, dynamic>> get historyRecords =>
      List.unmodifiable(_historyRecords);

  void saveRecord(SoilSample sample, NutrientPrediction prediction) {
    _historyRecords.insert(0, {
      'sample': sample,
      'prediction': prediction,
      'recordedAt': DateTime.now(),
    });
  }

  /// สร้างชุดข้อมูลในรูปแบบ CSV มาตรฐานพร้อม Geotagging
  String exportToCsv() {
    final buffer = StringBuffer();
    // ส่วนหัวของคอลัมน์ (Headers)
    buffer.writeln(
        'Sample_ID,Plot_Name,Crop_Type,Farming_Type,Hardware_Mode,Latitude,Longitude,Measured_At,Total_N_g_kg,N_Level,Available_P_mg_kg,P_Level,Available_K_mg_kg,K_Level,Confidence,R405,R465,R525,R630,R850,R940');

    for (final record in _historyRecords) {
      final sample = record['sample'] as SoilSample;
      final pred = record['prediction'] as NutrientPrediction;
      final sig = sample.spectralSignature;

      buffer.writeln([
        sample.id,
        '"${sample.plotName}"',
        '"${sample.cropType}"',
        '"${sample.farmingType}"',
        pred.hardwareMode.shortLabelTh,
        sample.latitude.toStringAsFixed(6),
        sample.longitude.toStringAsFixed(6),
        sample.measuredAt.toIso8601String(),
        pred.totalNitrogen.toStringAsFixed(2),
        pred.nitrogenLevel.name,
        pred.availablePhosphorus.toStringAsFixed(2),
        pred.phosphorusLevel.name,
        pred.availablePotassium.toStringAsFixed(1),
        pred.potassiumLevel.name,
        pred.confidenceScore.toStringAsFixed(3),
        sig?.r405nm ?? 0.0,
        sig?.r465nm ?? 0.0,
        sig?.r525nm ?? 0.0,
        sig?.r630nm ?? 0.0,
        sig?.r850nm ?? 0.0,
        sig?.r940nm ?? 0.0,
      ].join(','));
    }

    return buffer.toString();
  }
}
