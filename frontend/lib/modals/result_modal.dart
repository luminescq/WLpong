import 'dart:ui';
import 'package:flutter/material.dart';
import '../bridge_generated.dart/checker.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons/pressable_button.dart';

class ResultModal extends StatefulWidget {
  final CheckResult result;

  const ResultModal({
    super.key,
    required this.result,
  });

  @override
  State<ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<ResultModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isVerticalScrolling = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildPageDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.textPrimary 
            : AppColors.textTertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomProfile = widget.result.verdict == null;
    final isBlocked = widget.result.verdict == Verdict.bs;
    
    // Для кастомного профиля определяем "glowColor" по доступности (зеленый если все ок, иначе красный)
    final totalAccessible = widget.result.details.where((d) => d.accessible).length;
    final totalDomains = widget.result.details.length;
    
    final glowColor = isCustomProfile 
        ? (totalAccessible == totalDomains ? AppColors.accentGreen : AppColors.accentRed)
        : (isBlocked ? AppColors.accentRed : AppColors.accentGreen);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          // Компактная высота, как у остальных модалок
          height: 400,
          decoration: BoxDecoration(
            gradient: AppColors.modalGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Радиальное свечение с анимацией затухания
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _currentPage == 0 ? 0 : -200,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _currentPage == 0 ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.4, -0.8),
                          radius: 1.1,
                          colors: [
                            glowColor.withValues(alpha: isBlocked ? 0.18 : 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Контент - PageView
                PageView(
                  controller: _pageController,
                  physics: _isVerticalScrolling 
                      ? const NeverScrollableScrollPhysics() 
                      : const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildSummaryPage(isBlocked, glowColor),
                    _buildDomainListPage(),
                  ],
                ),

                // Точки пагинации (индикаторы свайпа)
                Positioned(
                  bottom: 34,
                  left: 0,
                  right: 0,
                  child: IgnorePointer( // Чтобы не перехватывали клики
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPageDot(0),
                        const SizedBox(width: 8),
                        _buildPageDot(1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPage(bool isBlocked, Color glowColor) {
    final isCustomProfile = widget.result.verdict == null;
    final stats = widget.result.stats;
    final int totalAccessible;
    if (stats != null) {
      totalAccessible = stats.wlAccessible + stats.blAccessible + stats.ntAccessible;
    } else {
      totalAccessible = widget.result.details.where((d) => d.accessible).length;
    }
    final totalDomains = widget.result.details.length;
    final blockedCount = totalDomains - totalAccessible;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
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

          const Spacer(),

          // Иконка статуса
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: glowColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              isBlocked ? Icons.shield_rounded : Icons.verified_user_rounded,
              color: glowColor,
              size: 32,
            ),
          ),

          const SizedBox(height: 12),

          // Заголовок
          Text(
            isCustomProfile
                ? (totalAccessible == totalDomains 
                    ? 'Все сервисы\nдоступны' 
                    : (totalAccessible == 0 ? 'Все сервисы\nнедоступны' : 'Некоторые сервисы\nнедоступны'))
                : (isBlocked
                    ? 'Белые списки\nобнаружены'
                    : 'Белые списки\nне обнаружены'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Подзаголовок
          Text(
            isCustomProfile
                ? (totalAccessible == totalDomains
                    ? 'Указанные домены отвечают штатно.'
                    : (totalAccessible == 0
                        ? 'Все $totalDomains сервисов из вашего списка не отвечают.'
                        : '$blockedCount из $totalDomains сервисов не отвечают.'))
                : (isBlocked
                    ? '$blockedCount из $totalDomains сервисов недоступны.\nВключите VPN для обхода ограничений.'
                    : totalAccessible == totalDomains
                        ? 'Все $totalDomains сервисов отвечают штатно.\nОграничения доступа не выявлены.'
                        : '$totalAccessible из $totalDomains узлов доступны.\nЧастичные ограничения обнаружены.'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),

          const Spacer(),

          // Разделитель
          Container(height: 1, color: AppColors.borderSubtle),

          const SizedBox(height: 16),

          // Счётчик + кнопка далее
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalAccessible/$totalDomains',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Доменов отвечают',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              PressableButton(
                onTap: _nextPage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.bgBase,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainListPage() {
    final details = widget.result.details;
    final totalDomains = details.length;
    final failedCount = details.where((d) => !d.accessible).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка
          Row(
            children: [
              GestureDetector(
                onTap: _prevPage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.overlayLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Проверенные домены',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
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

          const SizedBox(height: 16),

          // Список
          Expanded(
            child: RawScrollbar(
              thumbColor: AppColors.scrollThumb,
              radius: const Radius.circular(8),
              thickness: 4,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification && notification.dragDetails != null) {
                    if (!_isVerticalScrolling) setState(() => _isVerticalScrolling = true);
                  } else if (notification is ScrollEndNotification) {
                    if (_isVerticalScrolling) setState(() => _isVerticalScrolling = false);
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: details.length,
                  padding: const EdgeInsets.only(right: 4),
                  itemBuilder: (context, index) =>
                      _buildDomainItem(details[index]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(height: 1, color: AppColors.borderSubtle),

          const SizedBox(height: 16),

          // Подвал
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Всего $totalDomains доменов',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      failedCount == 0
                          ? 'Без ошибок'
                          : '$failedCount недоступно',
                      style: TextStyle(
                        color: failedCount == 0
                            ? AppColors.textTertiary
                            : AppColors.accentRed,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.bgBase,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Готово',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainItem(DomainResult item) {
    final bool isSuccess = item.accessible;
    final int? pingMs = item.totalTimeMs;
    final statusColor = isSuccess ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.overlayFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.overlayFaint),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.domain,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            isSuccess ? '${pingMs ?? 0} ms' : 'Ошибка',
            style: TextStyle(
              color: statusColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
