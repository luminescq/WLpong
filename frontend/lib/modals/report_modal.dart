import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/report_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons/pressable_button.dart';
import '../bridge_generated.dart/checker.dart';

class ReportModal extends ConsumerStatefulWidget {
  const ReportModal({super.key});

  @override
  ConsumerState<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends ConsumerState<ReportModal> {
  bool _isGenerating = true;
  DiagnosticReport? _report;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final report = await ref.read(reportProvider.notifier).generate();
    if (mounted) {
      setState(() {
        _report = report;
        _isGenerating = false;
      });
    }
  }

  Future<void> _copy() async {
    if (_report == null) return;
    await Clipboard.setData(ClipboardData(text: _report!.toFormattedString()));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _share() async {
    if (_report == null) return;
    await SharePlus.instance.share(
      ShareParams(text: _report!.toFormattedString()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Glow
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.8),
                        radius: 1.1,
                        colors: [
                          AppColors.accentBlue.withValues(alpha: 0.10),
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
                      // Шапка
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
                          color: AppColors.accentBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.accentBlue.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: AppColors.accentBlue,
                          size: 24,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Диагностический\nотчёт',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Версия приложения, устройство, настройки\nи результаты последней проверки.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 28),

                      Container(height: 1, color: AppColors.borderSubtle),

                      const SizedBox(height: 18),

                      // Содержимое отчёта
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isGenerating
                            ? _buildLoading()
                            : _buildContent(),
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

  Widget _buildLoading() {
    return const SizedBox(
      key: ValueKey('loading'),
      height: 80,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _report!;
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Секции
        _buildSection('Устройство', [
          _buildRow('Платформа', r.platform),
          _buildRow('Модель', r.deviceModel),
          _buildRow('ОС', r.osVersion),
          _buildRow('Сеть', r.networkType),
        ]),

        const SizedBox(height: 16),

        _buildSection('Приложение', [
          _buildRow('Версия', '${r.appVersion} (${r.buildNumber})'),
          _buildRow('Дата', _fmt(r.timestamp)),
        ]),

        const SizedBox(height: 16),

        _buildSection('Настройки', [
          _buildRow('Профиль', r.activeProfileName),
          _buildRow('Таймаут', '${r.settings.timeoutSeconds} сек'),
        ]),

        if (r.lastResult != null) ...[
          const SizedBox(height: 16),
          _buildResultSection(r.lastResult!),
        ],

        const SizedBox(height: 18),

        // Кнопки
        Row(
          children: [
            Expanded(
              child: PressableButton(
                onTap: _copy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  decoration: BoxDecoration(
                    color: _copied
                        ? AppColors.accentGreen.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _copied
                          ? AppColors.accentGreen.withValues(alpha: 0.4)
                          : AppColors.borderStrong,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        _copied ? 'Скопировано' : 'Скопировать',
                        key: ValueKey(_copied),
                        style: TextStyle(
                          color: _copied
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PressableButton(
                onTap: _share,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Поделиться',
                      style: TextStyle(
                        color: AppColors.bgBase,
                        fontSize: 14,
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
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlayLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(CheckResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlayLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Проверка',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (result.verdict == Verdict.bs || result.verdict == null)
                      ? AppColors.accentGreen.withValues(alpha: 0.12)
                      : AppColors.accentRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (result.verdict == Verdict.bs || result.verdict == null) ? 'Чисто' : 'Блокировки',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (result.verdict == Verdict.bs || result.verdict == null)
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...result.details.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Icon(
                  d.accessible ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                  size: 13,
                  color: d.accessible ? AppColors.accentGreen : AppColors.accentRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    d.domain,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (d.totalTimeMs != null)
                  Text(
                    '${d.totalTimeMs}ms',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _buildCircle() => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
        ),
      );
}
