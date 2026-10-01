import 'package:flutter/foundation.dart';
import '../../../../data/repositories/microbe_repository.dart';
import '../../../../domain/models/bio_fertilizer_recommendation.dart';
import '../../../../domain/models/nutrient_prediction.dart';

class FertilizerAdvisorViewModel extends ChangeNotifier {
  final MicrobeRepository _microbeRepository;

  FertilizerAdvisorViewModel({required MicrobeRepository microbeRepository})
      : _microbeRepository = microbeRepository;

  BioFertilizerRecommendation? _recommendation;
  BioFertilizerRecommendation? get recommendation => _recommendation;

  String _selectedGrowthStage = 'ระยะสะสมอาหารเพื่อเตรียมออกดอก';
  String get selectedGrowthStage => _selectedGrowthStage;

  final List<String> availableGrowthStages = [
    'ระยะฟื้นต้นหลังการเก็บเกี่ยว',
    'ระยะแตกใบอ่อนชุดที่ 1-2',
    'ระยะสะสมอาหารเพื่อเตรียมออกดอก',
    'ระยะติดผลอ่อน-ขยายผล',
    'ระยะก่อนเก็บเกี่ยวผลผลิต',
  ];

  void setGrowthStage(String stage, NutrientPrediction prediction, String crop) {
    _selectedGrowthStage = stage;
    computeRecommendation(prediction, crop);
  }

  void computeRecommendation(NutrientPrediction prediction, String crop) {
    _recommendation = _microbeRepository.getRecommendation(
      prediction: prediction,
      cropName: crop,
      growthStage: _selectedGrowthStage,
    );
    notifyListeners();
  }
}
