import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/nutrient_prediction.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/soil_scanner_view_model.dart';

class SoilScannerView extends StatefulWidget {
  final SoilScannerViewModel viewModel;
  final VoidCallback onScanCompleted;

  const SoilScannerView({
    super.key,
    required this.viewModel,
    required this.onScanCompleted,
  });

  @override
  State<SoilScannerView> createState() => _SoilScannerViewState();
}

class _SoilScannerViewState extends State<SoilScannerView> {
  final _plotController = TextEditingController(text: 'แปลงวิจัยดินสวนผลไม้ 1');
  
  // ลิสต์พืชที่ปลูกตามข้อกำหนด: ทุเรียน, มังคุด, สละ, ลำไย, มะม่วง, นาข้าว, พืชไร่, พืชผักสวนครัว
  String _selectedCrop = 'ทุเรียน';
  final List<String> _crops = [
    'ทุเรียน',
    'มังคุด',
    'สละ',
    'ลำไย',
    'มะม่วง',
    'นาข้าว',
    'พืชไร่',
    'พืชผักสวนครัว',
  ];

  // ลิสต์ประเภทสวน: อินทรีย์, เคมี, อินทรีย์เคมี
  String _selectedFarmingType = 'อินทรีย์เคมี';
  final List<String> _farmingTypes = [
    'อินทรีย์',
    'เคมี',
    'อินทรีย์เคมี',
  ];

  late DateTime _currentTime;
  Timer? _clockTimer;

  // กล้องจริงสำหรับสแกนดินในโหมดจำลอง (Live Smartphone Camera)
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
    // ดึงพิกัด GPS อัตโนมัติเมื่อเปิดหน้าสแกน
    widget.viewModel.refreshGpsLocation();
    // เริ่มต้นเชื่อมต่อกล้องสมาร์ทโฟนจริง
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraErrorMessage = 'ไม่พบโมดูลกล้องบนอุปกรณ์');
        return;
      }
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'เปิดกล้องไม่สำเร็จ: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _cameraController?.dispose();
    _plotController.dispose();
    super.dispose();
  }

  bool _isRecordingVideo = false;

  void _triggerScan() async {
    final success = await widget.viewModel.startMultiSpectralScan(
      plotName: _plotController.text.trim(),
      cropType: _selectedCrop,
      farmingType: _selectedFarmingType,
      mode: widget.viewModel.currentMode,
      latitude: widget.viewModel.autoLatitude,
      longitude: widget.viewModel.autoLongitude,
      aiModel: widget.viewModel.selectedAiModel,
    );
    if (success && mounted) {
      widget.onScanCompleted();
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile file = await _cameraController!.takePicture();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.accentLime),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ถ่ายภาพตัวอย่างดินสำเร็จ (${file.name})'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ถ่ายภาพตัวอย่างดินสำเร็จ (Snapshot Stored)'),
            backgroundColor: Color(0xFF1E293B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ถ่ายภาพ: $e')),
        );
      }
    }
  }

  Future<void> _toggleVideoRecord() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        if (_isRecordingVideo) {
          final XFile file = await _cameraController!.stopVideoRecording();
          setState(() => _isRecordingVideo = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('บันทึกวิดีโอตัวอย่างดินเรียบร้อย (${file.name})'),
                backgroundColor: const Color(0xFF1E293B),
              ),
            );
          }
        } else {
          await _cameraController!.startVideoRecording();
          setState(() => _isRecordingVideo = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กำลังบันทึกวิดีโอสแกนพื้นผิวดิน...'),
                backgroundColor: Color(0xFFC62828),
              ),
            );
          }
        }
      } else {
        setState(() => _isRecordingVideo = !_isRecordingVideo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isRecordingVideo
                  ? 'เริ่มบันทึกวิดีโอจำลอง...'
                  : 'สิ้นสุดการบันทึกวิดีโอ'),
              backgroundColor: _isRecordingVideo
                  ? const Color(0xFFC62828)
                  : const Color(0xFF1E293B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกวิดีโอ: $e')),
        );
      }
    }
  }

  void _showModelSelectorDialog(SoilScannerViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppTheme.accentLime, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'การตั้งค่าสถาปัตยกรรมและโมเดล AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. ส่วนเลือกสถาปัตยกรรมฮาร์ดแวร์ (Dual-Architecture)
                const Text(
                  '1. สถาปัตยกรรมฮาร์ดแวร์ (Dual-Architecture)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentLime,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: vm.currentMode == NPxAIMode.liteFlash
                          ? Colors.deepOrangeAccent
                          : AppTheme.borderDark,
                    ),
                  ),
                  tileColor: vm.currentMode == NPxAIMode.liteFlash
                      ? Colors.deepOrangeAccent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  leading: const Icon(Icons.flash_on_rounded, color: Colors.deepOrangeAccent),
                  title: const Text(
                    'NPxAI Lite (Flash Mode)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight, fontSize: 13.5),
                  ),
                  subtitle: const Text(
                    'กล่อง 3D Box ดึงแสงแฟลชมือถือผ่านท่อนำแสง 45° สะดวกรวดเร็ว ต้นทุนต่ำ (R² ≈ 0.86 - 0.88)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  trailing: vm.currentMode == NPxAIMode.liteFlash
                      ? const Icon(Icons.check_circle, color: Colors.deepOrangeAccent)
                      : null,
                  onTap: () {
                    vm.setMode(NPxAIMode.liteFlash);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: vm.currentMode == NPxAIMode.proChamber
                          ? AppTheme.accentLime
                          : AppTheme.borderDark,
                    ),
                  ),
                  tileColor: vm.currentMode == NPxAIMode.proChamber
                      ? AppTheme.primaryGreen.withValues(alpha: 0.18)
                      : Colors.transparent,
                  leading: const Icon(Icons.biotech_rounded, color: AppTheme.accentLime),
                  title: const Text(
                    'NPxAI Pro (Multi-Spectral Chamber)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight, fontSize: 13.5),
                  ),
                  subtitle: const Text(
                    'กล่อง 3D Box ร่วมกับชุดวงจรสโตรบ LED 7 แถบความยาวคลื่น และ 0-Lux Dark Chamber (R² ≈ 0.94 - 0.97)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  trailing: vm.currentMode == NPxAIMode.proChamber
                      ? const Icon(Icons.check_circle, color: AppTheme.accentLime)
                      : null,
                  onTap: () {
                    vm.setMode(NPxAIMode.proChamber);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),

                // 2. ส่วนเลือกโมเดล AI (Backbone Edge ML)
                const Text(
                  '2. โมเดลประมวลผล (Edge AI / Simulation)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentLime,
                  ),
                ),
                const SizedBox(height: 8),
                ...vm.availableModels.map((model) {
                  final isSelected = vm.selectedAiModel == model;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(
                      model == 'SIMULATION' ? Icons.science : Icons.psychology,
                      color: isSelected ? AppTheme.accentLime : AppTheme.textMuted,
                      size: 20,
                    ),
                    title: Text(
                      model == 'SIMULATION'
                          ? 'SIMULATION (โหมดจำลองเชิงสถิติ)'
                          : '$model (Edge ML Model)',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.accentLime : AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.accentLime, size: 18)
                        : null,
                    onTap: () {
                      vm.setAiModel(model);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getWavelengthStrobeColor(String stepText) {
    if (stepText.contains('405nm')) {
      return const Color(0xFF7B1FA2).withValues(alpha: 0.35); // Violet
    } else if (stepText.contains('465nm')) {
      return const Color(0xFF1976D2).withValues(alpha: 0.35); // Blue
    } else if (stepText.contains('525nm')) {
      return const Color(0xFF388E3C).withValues(alpha: 0.35); // Green
    } else if (stepText.contains('630nm')) {
      return const Color(0xFFD32F2F).withValues(alpha: 0.35); // Red
    } else if (stepText.contains('850nm')) {
      return const Color(0xFF880E4F).withValues(alpha: 0.30); // NIR
    } else if (stepText.contains('940nm')) {
      return const Color(0xFF4A148C).withValues(alpha: 0.30); // NIR
    }
    return AppTheme.accentLime.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss น.');

    return LayoutBuilder(
      builder: (context, constraints) {
        // คำนวณความสูง Viewfinder แบบไดนามิกตามพื้นที่จอ (Dynamic responsive sizing)
        final double screenWidth = constraints.maxWidth;
        final double viewfinderHeight = (constraints.maxHeight * 0.28).clamp(160.0, 240.0);
        final double reticleSize = (viewfinderHeight * 0.65).clamp(90.0, 130.0);

        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 12.0 : 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. ช่องมองภาพกล้องตรวจวิเคราะห์ (Chamber Viewfinder) - เปิดกล้องจริงในโหมดจำลอง
                  Container(
                    height: viewfinderHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: vm.isScanning
                            ? AppTheme.accentLime
                            : AppTheme.borderDark,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1.1 ภาพจากกล้องสมาร์ทโฟนจริง หรือพื้นผิวจำลองกรณีกล้องยังไม่พร้อม
                          if (_isCameraInitialized &&
                              _cameraController != null &&
                              _cameraController!.value.isInitialized)
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _cameraController!.value.previewSize?.height ?? 100,
                                  height: _cameraController!.value.previewSize?.width ?? 100,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.85,
                                  colors: [
                                    const Color(0xFF5D4037).withValues(alpha: 0.9),
                                    const Color(0xFF3E2723),
                                    Colors.black,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _cameraErrorMessage ?? 'กำลังเปิดกล้องสมาร์ทโฟน...',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                          // 1.2 (ก) ป้ายแสดงสถานะสถาปัตยกรรม (NPxAI Lite vs Pro) ด้านซ้ายบน
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: vm.isScanning ? null : () => _showModelSelectorDialog(vm),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: vm.currentMode == NPxAIMode.liteFlash
                                        ? Colors.deepOrange.withValues(alpha: 0.92)
                                        : const Color(0xFF1B5E20).withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: vm.currentMode == NPxAIMode.liteFlash
                                          ? Colors.orangeAccent
                                          : AppTheme.accentLime,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        vm.currentMode == NPxAIMode.liteFlash
                                            ? Icons.flash_on_rounded
                                            : Icons.biotech_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        vm.currentMode == NPxAIMode.liteFlash
                                            ? 'Lite (Flash 45°)'
                                            : 'Pro (Chamber)',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 1.2 (ข) ป้ายแสดงสถานะโหมดและโมเดล AI (SIMULATION หรือชื่อโมเดล AI ที่เลือก) ด้านขวาบน
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: vm.isScanning ? null : () => _showModelSelectorDialog(vm),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: vm.selectedAiModel == 'SIMULATION'
                                        ? const Color(0xFFE65100).withValues(alpha: 0.95) // ส้มเตือน SIMULATION
                                        : const Color(0xFF00796B).withValues(alpha: 0.95), // สีเขียวมรกต AI Model
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: vm.selectedAiModel == 'SIMULATION'
                                          ? Colors.amberAccent
                                          : AppTheme.accentLime,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        vm.selectedAiModel == 'SIMULATION'
                                            ? Icons.science
                                            : Icons.psychology,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        vm.selectedAiModel == 'SIMULATION'
                                            ? 'SIMULATION'
                                            : vm.selectedAiModel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.arrow_drop_down,
                                          size: 13, color: Colors.white70),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 1.3 แสง Strobe จำลอง Vis-NIR LED ฉายแสงตามความยาวคลื่นขณะสแกน
                          if (vm.isScanning)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              color: _getWavelengthStrobeColor(vm.currentStepText),
                            ),

                          // 1.4 Reticle วงกลมเล็งพื้นที่ตัวอย่างดิน
                          Container(
                            width: reticleSize,
                            height: reticleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: vm.isScanning
                                    ? AppTheme.accentLime
                                    : Colors.white.withValues(alpha: 0.75),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (vm.isScanning ? AppTheme.accentLime : Colors.black)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: AppTheme.accentLime,
                                size: 24,
                              ),
                            ),
                          ),

                          // 1.5 แถบ HUD ด้านซ้ายบน แสดงสถานะกล้อง & ROI
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                _isCameraInitialized
                                    ? 'CAM: LIVE FEED | ROI: 120px'
                                    : 'ROI: 120px | LED: READY',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 9 : 10,
                                  color: AppTheme.accentLime,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // 1.6 แถบคำอธิบายเน้นข้อความจำลอง หรือชื่อโมเดล AI ใต้ Reticle
                          if (!vm.isScanning)
                            Positioned(
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.70),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  vm.selectedAiModel == 'SIMULATION'
                                      ? 'กล้องสมาร์ทโฟนจริง • ผลการวิเคราะห์ในโหมดจำลอง'
                                      : 'กล้องสมาร์ทโฟนจริง • ประมวลผลด้วยโมเดล ${vm.selectedAiModel}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),

                          // 1.7 แถบแสดงความคืบหน้าระหว่างสแกน 6 สเปกตรัม
                          if (vm.isScanning)
                            Positioned(
                              bottom: 10,
                              left: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      vm.currentStepText,
                                      style: TextStyle(
                                        fontSize: screenWidth < 360 ? 11 : 12,
                                        color: AppTheme.accentLime,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: vm.scanProgress,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppTheme.accentLime),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. แถบปุ่มควบคุมด่วน: สแกนดิน, ถ่ายภาพ, บันทึกวิดีโอ (สัญลักษณ์ Icons ระหว่างจอ Live กับพิกัด GPS)
                  Row(
                    children: [
                      // 2.1 ปุ่มสแกนดิน (Start Scan)
                      Expanded(
                        flex: 3,
                        child: Material(
                          color: vm.isScanning
                              ? AppTheme.cardDark
                              : AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                          elevation: vm.isScanning ? 0 : 3,
                          child: InkWell(
                            onTap: vm.isScanning ? null : _triggerScan,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    vm.isScanning
                                        ? Icons.hourglass_top_rounded
                                        : Icons.document_scanner_rounded,
                                    color: vm.isScanning
                                        ? AppTheme.accentLime
                                        : Colors.black,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    vm.isScanning ? 'กำลังสแกน...' : 'สแกนดิน',
                                    style: TextStyle(
                                      fontSize: screenWidth < 360 ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: vm.isScanning
                                          ? AppTheme.accentLime
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2.2 ปุ่มถ่ายภาพ (Capture Snapshot)
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: vm.isScanning ? null : _capturePhoto,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppTheme.accentLime,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ถ่ายภาพ',
                                    style: TextStyle(
                                      fontSize: screenWidth < 360 ? 11 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2.3 ปุ่มบันทึกวิดีโอ (Record Video)
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: _isRecordingVideo
                              ? const Color(0xFFC62828)
                              : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: vm.isScanning ? null : _toggleVideoRecord,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isRecordingVideo
                                      ? Colors.redAccent
                                      : AppTheme.borderDark,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isRecordingVideo
                                        ? Icons.stop_circle_rounded
                                        : Icons.videocam_rounded,
                                    color: _isRecordingVideo
                                        ? Colors.white
                                        : AppTheme.accentAmber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isRecordingVideo ? 'หยุดอัด' : 'วิดีโอ',
                                    style: TextStyle(
                                      fontSize: screenWidth < 360 ? 11 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isRecordingVideo
                                          ? Colors.white
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. การ์ดแสดง พิกัด GPS อัตโนมัติ (แสดงเฉพาะค่า Lat | Lng บรรทัดเดียวกัน) และ วันเวลา
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.satellite_alt,
                                color: AppTheme.accentLime, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                screenWidth < 360
                                    ? 'พิกัด GPS แปลงดิน'
                                    : 'พิกัด GPS ดินที่วิเคราะห์ (อัตโนมัติ)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 12 : 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: vm.isScanning ? null : vm.refreshGpsLocation,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh,
                                        size: 13, color: AppTheme.accentLime),
                                    SizedBox(width: 3),
                                    Text(
                                      'ดึงพิกัดใหม่',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentLime,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location,
                                  size: 14, color: AppTheme.accentAmber),
                              const SizedBox(width: 6),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${vm.autoLatitude.abs().toStringAsFixed(6)}° ${vm.autoLatitude >= 0 ? "N" : "S"} | ${vm.autoLongitude.abs().toStringAsFixed(6)}° ${vm.autoLongitude >= 0 ? "E" : "W"}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textLight,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 15, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            const Text(
                              'วันเวลาตรวจวัด: ',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                            Expanded(
                              child: Text(
                                dateFormat.format(_currentTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentLime,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. ฟอร์มข้อมูลแปลง ชนิดพืชที่ปลูก ประเภทสวน และ การเลือกโมเดล AI
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลตัวอย่างดินและระบบการจัดการ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // สถาปัตยกรรมฮาร์ดแวร์ Dual-Mode (Lite Flash 45° vs Pro Chamber)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 12, top: 10, right: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.architecture_rounded, size: 16, color: AppTheme.accentLime),
                                      SizedBox(width: 6),
                                      Text(
                                        'สถาปัตยกรรมฮาร์ดแวร์ (Dual-Architecture)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: vm.isScanning ? null : () => vm.setMode(NPxAIMode.liteFlash),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: vm.currentMode == NPxAIMode.liteFlash
                                                ? Colors.deepOrangeAccent.withValues(alpha: 0.22)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: vm.currentMode == NPxAIMode.liteFlash
                                                  ? Colors.deepOrangeAccent
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.flash_on_rounded,
                                                    size: 14,
                                                    color: vm.currentMode == NPxAIMode.liteFlash
                                                        ? Colors.deepOrangeAccent
                                                        : AppTheme.textMuted,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'NPxAI Lite',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: vm.currentMode == NPxAIMode.liteFlash
                                                          ? Colors.deepOrangeAccent
                                                          : AppTheme.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'แฟลช 45° พกพา (R² ~0.87)',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color: vm.currentMode == NPxAIMode.liteFlash
                                                      ? AppTheme.textLight
                                                      : AppTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: vm.isScanning ? null : () => vm.setMode(NPxAIMode.proChamber),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: vm.currentMode == NPxAIMode.proChamber
                                                ? AppTheme.primaryGreen.withValues(alpha: 0.28)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: vm.currentMode == NPxAIMode.proChamber
                                                  ? AppTheme.accentLime
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.biotech_rounded,
                                                    size: 14,
                                                    color: vm.currentMode == NPxAIMode.proChamber
                                                        ? AppTheme.accentLime
                                                        : AppTheme.textMuted,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'NPxAI Pro',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: vm.currentMode == NPxAIMode.proChamber
                                                          ? AppTheme.accentLime
                                                          : AppTheme.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'สโตรบ 7-Band (R² ~0.96)',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color: vm.currentMode == NPxAIMode.proChamber
                                                      ? AppTheme.textLight
                                                      : AppTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Dropdown สำหรับเลือกโหมดจำลองหรือสแกนจริงพร้อมเลือกโมเดล AI
                          DropdownButtonFormField<String>(
                            initialValue: vm.selectedAiModel,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'โหมดตรวจวัดและโมเดล AI',
                              labelStyle: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13),
                              prefixIcon: Icon(
                                vm.selectedAiModel == 'SIMULATION'
                                    ? Icons.science
                                    : Icons.psychology,
                                color: vm.selectedAiModel == 'SIMULATION'
                                    ? AppTheme.accentAmber
                                    : AppTheme.accentLime,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.borderDark),
                              ),
                            ),
                            items: vm.availableModels
                                .map((model) => DropdownMenuItem(
                                      value: model,
                                      child: Text(
                                        model == 'SIMULATION'
                                            ? 'SIMULATION (โหมดจำลอง)'
                                            : '$model (สแกนจริง Edge AI)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: model == 'SIMULATION'
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: model == 'SIMULATION'
                                              ? AppTheme.textLight
                                              : AppTheme.accentLime,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: vm.isScanning
                                ? null
                                : (val) {
                                    if (val != null) {
                                      vm.setAiModel(val);
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _plotController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'ชื่อแปลง / รหัสตัวอย่างดิน',
                              labelStyle:
                                  const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              prefixIcon: const Icon(Icons.drive_file_rename_outline,
                                  color: AppTheme.accentLime, size: 20),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppTheme.borderDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ชนิดพืชที่ปลูก และ ประเภทสวน (จัดวาง Responsive ตามความกว้างหน้าจอ)
                          if (screenWidth < 390) ...[
                            // บนจอสมาร์ทโฟนทั่วไป แสดงเป็น 2 แถวเพื่อความชัดเจน ไม่ตกขอบ
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCrop,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'พืชที่ปลูก',
                                labelStyle: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13),
                                prefixIcon: const Icon(Icons.eco,
                                    color: AppTheme.accentLime, size: 20),
                                filled: true,
                                fillColor: AppTheme.backgroundDark,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppTheme.borderDark),
                                ),
                              ),
                              items: _crops
                                  .map((crop) => DropdownMenuItem(
                                        value: crop,
                                        child: Text(crop,
                                            style: const TextStyle(
                                                fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCrop = val);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedFarmingType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'ประเภทสวน',
                                labelStyle: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13),
                                prefixIcon: const Icon(Icons.grass,
                                    color: AppTheme.accentAmber, size: 20),
                                filled: true,
                                fillColor: AppTheme.backgroundDark,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppTheme.borderDark),
                                ),
                              ),
                              items: _farmingTypes
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type,
                                            style: const TextStyle(
                                                fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedFarmingType = val);
                                }
                              },
                            ),
                          ] else ...[
                            // บนจอขนาดกว้างหรือแท็บเล็ต จัดวางคู่กันในแถวเดียว
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCrop,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'พืชที่ปลูก',
                                      labelStyle: const TextStyle(
                                          color: AppTheme.textMuted, fontSize: 13),
                                      prefixIcon: const Icon(Icons.eco,
                                          color: AppTheme.accentLime, size: 18),
                                      filled: true,
                                      fillColor: AppTheme.backgroundDark,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppTheme.borderDark),
                                      ),
                                    ),
                                    items: _crops
                                        .map((crop) => DropdownMenuItem(
                                              value: crop,
                                              child: Text(crop,
                                                  style: const TextStyle(
                                                      fontSize: 13)),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCrop = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedFarmingType,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'ประเภทสวน',
                                      labelStyle: const TextStyle(
                                          color: AppTheme.textMuted, fontSize: 13),
                                      prefixIcon: const Icon(Icons.grass,
                                          color: AppTheme.accentAmber, size: 18),
                                      filled: true,
                                      fillColor: AppTheme.backgroundDark,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppTheme.borderDark),
                                      ),
                                    ),
                                    items: _farmingTypes
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type,
                                                  style: const TextStyle(
                                                      fontSize: 13)),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedFarmingType = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. ปุ่มเริ่มสแกนสเปกตรัมหลายช่วงคลื่น
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: vm.isScanning ? null : _triggerScan,
                    icon: vm.isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.flash_on),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        vm.isScanning
                            ? 'กำลังตรวจวัดสเปกตรัม...'
                            : 'เริ่มสแกนสเปกตรัมหลายช่วงคลื่น (Vis-NIR)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
