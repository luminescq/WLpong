import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons/pressable_button.dart';

enum NetworkStatusType { noNetwork, vpnDetected }

class NetworkStatusModal extends StatelessWidget {
  final NetworkStatusType type;
  final VoidCallback? onIgnoreVpn;

  const NetworkStatusModal({
    super.key,
    required this.type,
    this.onIgnoreVpn,
  });

  @override
  Widget build(BuildContext context) {
    final isNoNetwork = type == NetworkStatusType.noNetwork;
    final glowColor = isNoNetwork ? AppColors.accentRed : AppColors.accentYellow;
    final title = isNoNetwork ? 'Нет подключения\nк сети' : 'Обнаружен\nактивный VPN';
    final subtitle = isNoNetwork
        ? 'Проверьте Wi-Fi или мобильные данные\nи попробуйте снова.'
        : 'Отключите VPN перед проверкой,\nчтобы получить точный результат.';
    final icon = isNoNetwork ? Icons.wifi_off_rounded : Icons.vpn_lock_rounded;
    final mainLabel = isNoNetwork ? 'Понятно' : 'Отключить VPN';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            gradient: AppColors.modalGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Radial glow
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.8),
                        radius: 1.1,
                        colors: [
                          glowColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Три точки + крестик
                      Row(
                        children: [
                          _buildCircle(),
                          const SizedBox(width: 6),
                          _buildCircle(),
                          const SizedBox(width: 6),
                          _buildCircle(),
                          const Spacer(),
                          PressableButton(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.overlayLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Иконка
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: glowColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: glowColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: glowColor, size: 24),
                      ),

                      const SizedBox(height: 18),

                      // Заголовок
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Подзаголовок
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Разделитель
                      Container(height: 1, color: AppColors.borderSubtle),

                      const SizedBox(height: 18),

                      // Кнопки
                      if (isNoNetwork || onIgnoreVpn == null)
                        // Одна кнопка во всю ширину
                        PressableButton(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                mainLabel,
                                style: const TextStyle(
                                  color: AppColors.bgBase,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        // Две кнопки в ряд (VPN с игнором)
                        Row(
                          children: [
                            Expanded(
                              child: PressableButton(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onIgnoreVpn!();
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.borderStrong,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Всё равно',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PressableButton(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Отключить',
                                      style: TextStyle(
                                        color: AppColors.bgBase,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
    );
  }
}
