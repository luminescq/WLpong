import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../providers/report_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common/screen_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  // Вспомогательная функция для открытия внешних ссылок
  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Не удалось открыть ссылку: $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 96,
          ),
          child: _buildGlassContainer(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                // Шапка
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 4, top: 8),
                  child: ScreenHeader(
                    title: 'Настройки',
                    subtitle: 'Версия, параметры и поддержка',
                  ),
                ),
                const SizedBox(height: 24),
                // Донат с переходом по ссылке
                _buildCardTile(
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.accentRed,
                      size: 22,
                    ),
                  ),
                  title: 'Донат',
                  subtitle: 'Поддержать разработчика.',
                  onTap: () => _openUrl(
                    'https://pay.cloudtips.ru/p/1ea077ba',
                  ), // Укажите вашу ссылку
                ),
                const SizedBox(height: 12),

                // GitHub и Отчет
                Row(
                  children: [
                    Expanded(
                      child: _buildGridCard(
                        icon: Icons.code_rounded,
                        title: 'GitHub',
                        subtitle: 'Исходный код',
                        onTap: () => _openUrl('https://github.com/luminescq/WLpong'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGridCard(
                        icon: Icons.assignment_outlined,
                        title: 'Отчет',
                        subtitle: 'Собрать лог',
                        onTap: () async {
                          final report = await ref
                              .read(reportProvider.notifier)
                              .generate();
                          await Clipboard.setData(
                            ClipboardData(text: report.toFormattedString()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Отчет скопирован в буфер обмена',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: AppColors.accentGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: 24,
                                  left: 24,
                                  right: 24,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Информация о версии
                _buildCardTile(
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.new_releases_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  title: 'У вас установлена Beta',
                  subtitle: 'Версия $_version',
                  onTap: () {
                    if (ref.read(settingsProvider).hapticsEnabled) {
                      HapticFeedback.selectionClick();
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Блок настроек (Таймаут + Автопроверка)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Таймаут
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Таймаут соединения',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ref.watch(settingsProvider).timeoutSeconds} сек',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          padding: EdgeInsets.zero,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 9,
                            elevation: 2,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                          activeTrackColor: AppColors.textPrimary,
                          inactiveTrackColor: AppColors.bgElevated,
                          thumbColor: AppColors.textPrimary,
                        ),
                        child: Slider(
                          value: ref
                              .watch(settingsProvider)
                              .timeoutSeconds
                              .toDouble(),
                          min: kTimeoutMin.toDouble(),
                          max: kTimeoutMax.toDouble(),
                          divisions: kTimeoutMax - kTimeoutMin,
                          onChanged: (val) {
                            if (ref.read(settingsProvider).hapticsEnabled) {
                              HapticFeedback.selectionClick();
                            }
                            ref
                                .read(settingsProvider.notifier)
                                .setTimeoutSeconds(val.round());
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        color: AppColors.bgElevated,
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 12),

                      // Виброотклик (Haptic Feedback)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Виброотклик',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Тактильная отдача при нажатиях',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: ref.watch(settingsProvider).hapticsEnabled,
                            activeThumbColor: AppColors.textPrimary,
                            activeTrackColor: AppColors.bgElevated,
                            inactiveThumbColor: AppColors.textSecondary,
                            inactiveTrackColor: AppColors.bgElevated.withValues(
                              alpha: 0.5,
                            ),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            onChanged: (val) {
                              if (ref.read(settingsProvider).hapticsEnabled ||
                                  val) {
                                // Включаем вибрацию, если она включена, либо если пользователь ее только что включил (val = true)
                                HapticFeedback.lightImpact();
                              }
                              ref
                                  .read(settingsProvider.notifier)
                                  .setHaptics(val);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(
                        color: AppColors.bgElevated,
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 12),

                      // Энергосбережение (Performance Mode)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Простой интерфейс',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Отключает анимацию фона и эффекты стекла',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: ref.watch(settingsProvider).performanceMode,
                            activeThumbColor: AppColors.textPrimary,
                            activeTrackColor: AppColors.bgElevated,
                            inactiveThumbColor: AppColors.textSecondary,
                            inactiveTrackColor: AppColors.bgElevated.withValues(
                              alpha: 0.5,
                            ),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            onChanged: (val) {
                              if (ref.read(settingsProvider).hapticsEnabled) {
                                HapticFeedback.lightImpact();
                              }
                              ref
                                  .read(settingsProvider.notifier)
                                  .setPerformanceMode(val);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(
                        color: AppColors.bgElevated,
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 16),

                      // Кастомный DNS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Кастомный DNS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Использовать свой DNS сервер',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: ref.watch(settingsProvider).customDnsEnabled,
                            activeThumbColor: AppColors.textPrimary,
                            activeTrackColor: AppColors.bgElevated,
                            inactiveThumbColor: AppColors.textSecondary,
                            inactiveTrackColor: AppColors.bgElevated.withValues(
                              alpha: 0.5,
                            ),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            onChanged: (val) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setCustomDnsEnabled(val);
                            },
                          ),
                        ],
                      ),
                      if (ref.watch(settingsProvider).customDnsEnabled) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: ref.watch(settingsProvider).customDns,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Например: 8.8.8.8',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppColors.bgElevated,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .setCustomDns(val.trim());
                          },
                        ),
                      ],
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

  // Виджет прозрачной подложки (Glass)
  Widget _buildGlassContainer({required Widget child}) {
    final isPerfMode = ref.watch(settingsProvider).performanceMode;

    Widget container = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isPerfMode
            ? Colors.black.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (isPerfMode) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: container,
      ),
    );
  }

  // Широкие карточки (Донат, Обновления)
  Widget _buildCardTile({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (ref.read(settingsProvider).hapticsEnabled) {
              HapticFeedback.lightImpact();
            }
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Квадратные карточки в сетке без стрелочек справа
  Widget _buildGridCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (ref.read(settingsProvider).hapticsEnabled) {
              HapticFeedback.lightImpact();
            }
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.textPrimary, size: 22),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
