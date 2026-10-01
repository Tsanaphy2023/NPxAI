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
              TelemetryHudBadge(status: status),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: status.isConnected
                                  ? AppTheme.accentLime.withValues(alpha: 0.35)
                                  : Colors.black45,
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.cardDark,
                              child: Icon(
                                status.isConnected ? Icons.sensors : Icons.sensors_off,
                                size: 40,
                                color: status.isConnected ? AppTheme.accentLime : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status.isConnected
                            ? 'เชื่อมต่อ Chamber แล้ว'
                            : 'ยังไม่ได้เชื่อมต่ออุปกรณ์ Chamber',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status.isConnected
                            ? 'อุปกรณ์พร้อมสำหรับการตรวจวัดสเปกตรัมการสะท้อนแสง'
                            : 'เลือกช่องทางการเชื่อมต่อฮาร์ดแวร์เพื่อเริ่มการวิเคราะห์',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 20),
              const Text(
                'ช่องทางการเชื่อมต่อฮาร์ดแวร์ (Chamber Port)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: viewModel.isConnecting
                    ? null
                    : () => viewModel.connectChamber(forceSimulator: false),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('เชื่อมต่อ Bluetooth LE (Wireless)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textLight,
                  side: const BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: viewModel.isConnecting
                    ? null
                    : () => viewModel.connectChamber(forceSimulator: false),
                icon: const Icon(Icons.usb, color: AppTheme.accentLime),
                label: const Text('เชื่อมต่อ USB-C OTG Serial (Wired)'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentAmber,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: viewModel.isConnecting
                    ? null
                    : () => viewModel.connectChamber(forceSimulator: true),
                icon: const Icon(Icons.developer_mode),
                label: const Text('เปิดโหมดทดสอบฮาร์ดแวร์จำลอง (Simulator)'),
              ),
              if (status.isConnected) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
