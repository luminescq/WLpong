import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/check_history.dart';
import '../providers/check_provider.dart';
import '../providers/database_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common/screen_header.dart';
import '../modals/confirm_delete_modal.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final currentLimit = ref.read(historyLimitProvider);
      ref.read(historyLimitProvider.notifier).state = currentLimit + 50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(checkStatsProvider);
    final historyAsync = ref.watch(checkHistoryStreamProvider);
    final isPerfMode = ref.watch(settingsProvider).performanceMode;

    Widget content = Container(
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
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Заголовок ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
                  child: ScreenHeader(
                    title: 'Статистика',
                    subtitle: 'Мониторинг задержки и сессий',
                    trailing: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Сбросить статистику',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (ref.read(settingsProvider).hapticsEnabled) {
                          HapticFeedback.lightImpact();
                        }
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'Закрыть',
                          pageBuilder: (ctx, a1, a2) => Container(),
                          transitionBuilder: (ctx, a1, a2, child) {
                            final curve = CurvedAnimation(parent: a1, curve: Curves.easeOutCubic);
                            return Transform.scale(
                              scale: 0.95 + 0.05 * curve.value,
                              child: Opacity(
                                opacity: curve.value,
                                child: ConfirmDeleteModal(
                                  onConfirm: () async {
                                    final notifier = ref.read(checkProvider.notifier);
                                    await notifier.clearStats();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Статистика очищена',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: AppColors.bgCard,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 250),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),


                // ── Два KPI рядом ──────────────────────────────────────────
                _buildTopKpiRow(stats),

                const SizedBox(height: 24),

                // ── Последние проверки ─────────────────────────────────────
                const Text(
                  'Последние проверки',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: historyAsync.when(
              skipLoadingOnReload: true,
              data: (historyList) {
                if (historyList.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildCheckCard(
                      title: 'Нет данных',
                      subtitle: 'Запустите проверку',
                      score: '—',
                      isSuccess: true,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == historyList.length) {
                      final currentLimit = ref.read(historyLimitProvider);
                      if (historyList.length >= currentLimit) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGreen,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildHistoryRow(historyList[index]),
                    );
                  }, childCount: historyList.length + 1),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: _buildCheckCard(
                  title: 'Ошибка',
                  subtitle: err.toString(),
                  score: '—',
                  isSuccess: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget glassContainer = isPerfMode
        ? ClipRRect(borderRadius: BorderRadius.circular(32), child: content)
        : ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: content,
            ),
          );

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
          child: glassContainer,
        ),
      ),
    );
  }

  // ─── Два KPI-блока (Проверок | Успешность) ──────────────────────────────────

  Widget _buildTopKpiRow(({int total, int success}) stats) {
    final total = stats.total;
    final success = stats.success;
    final uptimePct = total > 0
        ? (success / total * 100).toStringAsFixed(0)
        : '—';
    final uptimeLabel = total > 0 ? '$success / $total успешно' : 'нет данных';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Блок «Проверок» со светящейся рамкой ──
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.6), // Чуть прозрачнее
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Проверок',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0 ? '—' : '$total',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'всего сессий',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ── Блок «Успешность» ──
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.6), // Чуть прозрачнее
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Успешность',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  uptimePct == '—' ? '—' : '$uptimePct%',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: AppColors.accentGreen.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      uptimeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Список последних проверок ───────────────────────────────────────────────

  Widget _buildHistoryRow(CheckHistory history) {
    final t = history.timestamp;
    final timeLabel =
        '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    String verdictLabel;
    Color statusColor;
    bool isSuccess;

    if (history.isCustom) {
      if (history.accessibleDomains == history.totalDomains &&
          history.totalDomains > 0) {
        verdictLabel = 'Все доступны';
        statusColor = AppColors.accentGreen;
        isSuccess = true;
      } else if (history.accessibleDomains == 0) {
        verdictLabel = 'Недоступны';
        statusColor = AppColors.accentRed;
        isSuccess = false;
      } else {
        verdictLabel = 'Частично доступны';
        statusColor = Colors.orangeAccent;
        isSuccess = true;
      }
    } else {
      final isBsDetected = history.isBsDetected;
      verdictLabel = isBsDetected ? 'БС - обнаружены' : 'БС - не обнаружены';
      statusColor = isBsDetected ? AppColors.accentRed : AppColors.accentGreen;
      isSuccess = !isBsDetected;
    }

    return _buildCheckRow(
      label: verdictLabel,
      timeLabel: timeLabel,
      score: '${history.accessibleDomains}/${history.totalDomains}',
      isSuccess: isSuccess,
      scoreColor: statusColor,
    );
  }

  /// Одна строка-карточка из списка «Последние проверки»
  Widget _buildCheckRow({
    required String label,
    required String timeLabel,
    required String score,
    required bool isSuccess,
    required Color scoreColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.6), // Тоже стекло
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isSuccess ? AppColors.accentGreen : AppColors.accentRed)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? AppColors.accentGreen : AppColors.accentRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Счётчик
          Text(
            score,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Вспомогательные виджеты ────────────────────────────────────────────────



  Widget _buildCheckCard({
    required String title,
    required String subtitle,
    required String score,
    required bool isSuccess,
  }) {
    final statusColor = isSuccess ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.6), // Стекло
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
