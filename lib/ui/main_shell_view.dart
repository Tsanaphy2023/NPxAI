import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/advisor/view_models/fertilizer_advisor_view_model.dart';
import 'features/advisor/views/fertilizer_advisor_view.dart';
import 'features/connection/view_models/connection_view_model.dart';
import 'features/connection/views/connection_view.dart';
import 'features/result/view_models/analysis_result_view_model.dart';
import 'features/result/views/analysis_result_view.dart';
import 'features/scanner/view_models/soil_scanner_view_model.dart';
import 'features/scanner/views/soil_scanner_view.dart';

class MainShellView extends StatefulWidget {
  final ConnectionViewModel connectionViewModel;
  final SoilScannerViewModel scannerViewModel;
  final AnalysisResultViewModel resultViewModel;
  final FertilizerAdvisorViewModel advisorViewModel;

  const MainShellView({
    super.key,
    required this.connectionViewModel,
    required this.scannerViewModel,
    required this.resultViewModel,
    required this.advisorViewModel,
  });

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView>
    with WidgetsBindingObserver {
  int _currentIndex = 1; // เริ่มต้นที่หน้าสแกนดิน

  @override
  void initState() {
    super.initState();
    // ติดตั้ง Observer เพื่อตรวจจับการพับ/เปิดแอป (Port Claim/Release)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // เมื่อแอปกลับมาเบื้องหน้า: ยึดพอร์ตฮาร์ดแวร์คืน
      widget.connectionViewModel.reconnectHardware();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // เมื่อแอปพับลงพื้นหลัง: ปล่อยสิทธิ์พอร์ตทันที ป้องกันพอร์ตชนกับแอปอื่น
      widget.connectionViewModel.releaseHardware();
    }
  }

  void _onScanCompleted() {
    final sample = widget.scannerViewModel.lastSample;
    final pred = widget.scannerViewModel.lastPrediction;
    if (sample != null && pred != null) {
      widget.resultViewModel.setResult(sample, pred);
      widget.advisorViewModel.computeRecommendation(pred, sample.cropType);
      setState(() => _currentIndex = 2); // นำทางไปหน้าแสดงผลทันที
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ConnectionView(viewModel: widget.connectionViewModel),
      SoilScannerView(
        viewModel: widget.scannerViewModel,
        onScanCompleted: _onScanCompleted,
      ),
      AnalysisResultView(
        viewModel: widget.resultViewModel,
        onNavigateToAdvisor: () => setState(() => _currentIndex = 3),
      ),
      FertilizerAdvisorView(viewModel: widget.advisorViewModel),
    ];

    final titles = [
      'เชื่อมต่อ Chamber',
      'สแกนสเปกตรัมดิน',
      'ผลการวิเคราะห์ N-P',
      'คำแนะนำปุ๋ย & ชีวภัณฑ์',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentLime,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NPxAI',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(titles[_currentIndex]),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppTheme.cardDark,
          indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: states.contains(WidgetState.selected)
                  ? AppTheme.accentLime
                  : AppTheme.textMuted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppTheme.accentLime
                  : AppTheme.textMuted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.settings_input_composite_outlined),
              selectedIcon: Icon(Icons.settings_input_composite),
              label: 'เชื่อมต่อ',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt),
              label: 'สแกนดิน',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'ผลวิเคราะห์',
            ),
            NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              selectedIcon: Icon(Icons.eco),
              label: 'คำแนะนำปุ๋ย',
            ),
          ],
        ),
      ),
    );
  }
}
