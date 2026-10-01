import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/telemetry_hud_badge.dart';
import '../view_models/connection_view_model.dart';

class ConnectionView extends StatelessWidget {
  final ConnectionViewModel viewModel;

  const ConnectionView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final status = viewModel.status;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HUD สถานะการเชื่อมต่อและอุณหภูมิ/ความชื้น Chamber
              TelemetryHudBadge(status: status),
              const SizedBox(height: 14),

              // การ์ดแสดงสถานะหลักของเครื่อง
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: status.isConnected
                                  ? AppTheme.accentLime.withValues(alpha: 0.35)
                                  : Colors.black45,
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.cardDark,
                              child: Icon(
                                status.isConnected ? Icons.sensors : Icons.sensors_off,
                                size: 38,
                                color: status.isConnected ? AppTheme.accentLime : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        status.isConnected
                            ? 'เชื่อมต่อ Chamber แล้ว (${status.deviceName})'
                            : 'ยังไม่ได้เชื่อมต่ออุปกรณ์ Chamber',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        status.isConnected
                            ? 'ฮาร์ดแวร์พร้อมสำหรับการตรวจวัดสเปกตรัมการสะท้อนแสงและการดูดกลืน'
                            : 'เลือกช่องทางการเชื่อมต่อฮาร์ดแวร์ด้านล่างเพื่อเริ่มการวิเคราะห์',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            viewModel.errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // ส่วนการสอบเทียบมาตรฐานเครื่องมือ (System Calibration Section)
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: status.isCalibrated
                        ? AppTheme.accentLime.withValues(alpha: 0.4)
                        : AppTheme.accentAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, size: 17, color: AppTheme.accentAmber),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'การสอบเทียบมาตรฐานเครื่อง (Calibration)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: status.isCalibrated
                                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: status.isCalibrated ? AppTheme.accentLime : Colors.orange,
                            ),
                          ),
                          child: Text(
                            status.isCalibrated ? 'CALIBRATED' : 'UNCALIBRATED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: status.isCalibrated ? AppTheme.accentLime : Colors.orangeAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'การสอบเทียบความถูกต้องเชิงแสงก่อนวัดตัวอย่างดินจริง:\n'
                      '1. วางแผ่นเทียบสีขาวมาตรฐาน (PTFE 99% Reflectance) ลงในถาดมืด\n'
                      '2. ปิดฝาครอบกล่องมืด 0-Lux ให้สนิทเพื่อตัดแสงรบกวนภายนอก 100%\n'
                      '3. กดปุ่มสอบเทียบเพื่อคำนวณค่าชดเชยเกนสเปกตรัม (Gain Factor)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                        height: 1.45,
                      ),
                    ),
                    if (viewModel.calibrationMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.accentLime.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 15, color: AppTheme.accentLime),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                viewModel.calibrationMessage!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: (viewModel.isCalibrating || !status.isConnected)
                                ? null
                                : viewModel.calibrateWhiteReference,
                            icon: viewModel.isCalibrating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.wb_sunny, size: 15),
                            label: const Text(
                              'สอบเทียบแผ่นเทียบขาว',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textLight,
                              side: const BorderSide(color: AppTheme.borderDark),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: (viewModel.isCalibrating || !status.isConnected)
                                ? null
                                : viewModel.calibrateDarkReference,
                            icon: const Icon(Icons.nightlight_round, size: 15, color: Colors.cyanAccent),
                            label: const Text(
                              'สอบเทียบจุดมืด 0-Lux',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // ช่องทางการเชื่อมต่อฮาร์ดแวร์ (Chamber Port Channels)
              // -------------------------------------------------------------
              const Text(
                'ช่องทางการเชื่อมต่อฮาร์ดแวร์ (Chamber Port)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: viewModel.isConnecting
                    ? null
                    : () => viewModel.connectChamber(forceSimulator: false),
                icon: const Icon(Icons.bluetooth_searching, size: 18),
                label: const Text('เชื่อมต่อ Bluetooth LE (Wireless)'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textLight,
                  side: const BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: viewModel.isConnecting
                    ? null
                    : () => viewModel.connectChamber(forceSimulator: false),
                icon: const Icon(Icons.usb, color: AppTheme.accentLime, size: 18),
                label: const Text('เชื่อมต่อ USB-C OTG Serial (Wired)'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentAmber,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: viewModel.isConnecting
                    ? null
                    : () => viewModel.connectChamber(forceSimulator: true),
                icon: const Icon(Icons.developer_mode, size: 18),
                label: const Text('เปิดโหมดทดสอบฮาร์ดแวร์จำลอง (Simulator)'),
              ),
              if (status.isConnected) ...[
                const SizedBox(height: 14),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: viewModel.disconnectChamber,
                  child: const Text('ยกเลิกการเชื่อมต่อ (Release Port)'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
