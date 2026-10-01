import 'package:flutter/foundation.dart';
import '../../../../data/repositories/soil_repository.dart';
import '../../../../domain/models/nutrient_prediction.dart';
import '../../../../domain/models/soil_sample.dart';

class AnalysisResultViewModel extends ChangeNotifier {
  final SoilRepository _soilRepository;

  AnalysisResultViewModel({required SoilRepository soilRepository})
      : _soilRepository = soilRepository;

  SoilSample? _sample;
  SoilSample? get sample => _sample;

  NutrientPrediction? _prediction;
  NutrientPrediction? get prediction => _prediction;

  void setResult(SoilSample sample, NutrientPrediction prediction) {
    _sample = sample;
    _prediction = prediction;
    notifyListeners();
  }

  String getCsvExport() {
    return _soilRepository.generateCsvReport();
  }
}
