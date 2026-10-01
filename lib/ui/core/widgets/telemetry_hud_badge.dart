import 'package:flutter/material.dart';
import '../../../domain/models/chamber_status.dart';
import '../theme/app_theme.dart';

class TelemetryHudBadge extends StatelessWidget {
  final ChamberStatus status;

  const TelemetryHudBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = status.isConnected;
    final Color badgeColor = isOnline ? AppTheme.accentLime : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline ? AppTheme.borderDark : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status.deviceName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thermostat, size: 14, color: AppTheme.accentAmber),
                  const SizedBox(width: 2),
                  Text(
                    '${status.chamberTemperatureC}°C',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.water_drop, size: 14, color: Colors.lightBlueAccent),
                  const SizedBox(width: 2),
                  Text(
                    '${status.chamberHumidityPercent}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.battery_charging_full, size: 15, color: AppTheme.accentLime),
                  const SizedBox(width: 2),
                  Text(
                    '${status.batteryLevelPercent}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
