import '../../domain/models/bio_fertilizer_recommendation.dart';
import '../../domain/models/nutrient_prediction.dart';
import '../../domain/use_cases/integrated_advisor_use_case.dart';

abstract class MicrobeRepository {
  List<MicrobeStrainInfo> getAllStrains();
  BioFertilizerRecommendation getRecommendation({
    required NutrientPrediction prediction,
    required String cropName,
    required String growthStage,
  });
}

class MicrobeRepositoryImpl implements MicrobeRepository {
  final IntegratedAdvisorUseCase _advisorUseCase;

  MicrobeRepositoryImpl({IntegratedAdvisorUseCase? advisorUseCase})
      : _advisorUseCase = advisorUseCase ?? IntegratedAdvisorUseCase();

  @override
  List<MicrobeStrainInfo> getAllStrains() {
    return IntegratedAdvisorUseCase.localMicrobeStrains;
  }

  @override
  BioFertilizerRecommendation getRecommendation({
    required NutrientPrediction prediction,
    required String cropName,
    required String growthStage,
  }) {
    return _advisorUseCase.generateRecommendation(
      prediction: prediction,
      cropName: cropName,
      growthStage: growthStage,
    );
  }
}
