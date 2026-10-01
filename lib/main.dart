import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/microbe_repository.dart';
import 'data/repositories/soil_repository.dart';
import 'data/services/camera_vision_service.dart';
import 'data/services/hardware_chamber_service.dart';
import 'data/services/storage_export_service.dart';
import 'domain/use_cases/color_normalization_use_case.dart';
import 'domain/use_cases/edge_ai_inference_use_case.dart';
import 'domain/use_cases/integrated_advisor_use_case.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/advisor/view_models/fertilizer_advisor_view_model.dart';
import 'ui/features/connection/view_models/connection_view_model.dart';
import 'ui/features/result/view_models/analysis_result_view_model.dart';
import 'ui/features/scanner/view_models/soil_scanner_view_model.dart';
import 'ui/main_shell_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Services
  final hardwareChamberService = HardwareChamberService();
  final colorNormalizationUseCase = ColorNormalizationUseCase();
  final cameraVisionService = CameraVisionService(
    colorNormalizer: colorNormalizationUseCase,
  );
  final storageExportService = StorageExportService();

  // 2. Use Cases
  final edgeAiInferenceUseCase = EdgeAiInferenceUseCase();
  final integratedAdvisorUseCase = IntegratedAdvisorUseCase();

  // 3. Repositories
  final soilRepository = SoilRepositoryImpl(
    chamberService: hardwareChamberService,
    visionService: cameraVisionService,
    aiUseCase: edgeAiInferenceUseCase,
    storageService: storageExportService,
  );
  final microbeRepository = MicrobeRepositoryImpl(
    advisorUseCase: integratedAdvisorUseCase,
  );

  // 4. ViewModels
  final connectionViewModel = ConnectionViewModel(
    chamberService: hardwareChamberService,
  );
  final scannerViewModel = SoilScannerViewModel(
    soilRepository: soilRepository,
    chamberService: hardwareChamberService,
  );
  final resultViewModel = AnalysisResultViewModel(
    soilRepository: soilRepository,
  );
  final advisorViewModel = FertilizerAdvisorViewModel(
    microbeRepository: microbeRepository,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectionViewModel),
        ChangeNotifierProvider.value(value: scannerViewModel),
        ChangeNotifierProvider.value(value: resultViewModel),
        ChangeNotifierProvider.value(value: advisorViewModel),
      ],
      child: NPxAIApp(
        connectionViewModel: connectionViewModel,
        scannerViewModel: scannerViewModel,
        resultViewModel: resultViewModel,
        advisorViewModel: advisorViewModel,
      ),
    ),
  );
}

class NPxAIApp extends StatelessWidget {
  final ConnectionViewModel connectionViewModel;
  final SoilScannerViewModel scannerViewModel;
  final AnalysisResultViewModel resultViewModel;
  final FertilizerAdvisorViewModel advisorViewModel;

  const NPxAIApp({
    super.key,
    required this.connectionViewModel,
    required this.scannerViewModel,
    required this.resultViewModel,
    required this.advisorViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NPxAI Soil Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainShellView(
        connectionViewModel: connectionViewModel,
        scannerViewModel: scannerViewModel,
        resultViewModel: resultViewModel,
        advisorViewModel: advisorViewModel,
      ),
    );
  }
}
