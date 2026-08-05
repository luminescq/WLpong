import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons/pressable_button.dart';

class ConfirmDeleteModal extends StatelessWidget {
  final VoidCallback onConfirm;
  final String title;
  final String message;

  const ConfirmDeleteModal({
    super.key,
    required this.onConfirm,
    this.title = 'Очистка',
    this.message = 'Удалить все данные статистики?',
  });

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

  @override
  Widget build(BuildContext context) {
    const glowColor = AppColors.accentRed;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(28),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
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
                          glowColor.withValues(alpha: 0.12),
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
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
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
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: glowColor,
                          size: 24,
                        ),
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

                      // Описание
                      Text(
                        message,
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

                      // Кнопки в ряд
                      Row(
                        children: [
                          Expanded(
                            child: PressableButton(
                              onTap: () => Navigator.of(context).pop(),
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
                                    'Отмена',
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
                              onTap: () {
                                Navigator.of(context).pop();
                                onConfirm();
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: glowColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Удалить',
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
}
