import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/advanced_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screeen.dart';
import '../theme/app_colors.dart';
import '../widgets/effects/mesh_gradient_background.dart';
import '../providers/settings_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _activeIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(), // 1 — Статистика
    const AdvancedScreen(), // 2 — Расширенный режим
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshGradientBackground(
        child: Stack(
          children: [
            // Экраны
            SafeArea(
              child: IndexedStack(
                index: _activeIndex,
                children: _screens,
              ),
            ),

            // Нижний бар
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isPerfMode = ref.watch(settingsProvider).performanceMode;

    Widget content = Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isPerfMode ? Colors.black.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / 4;
          final double indicatorLeft = itemWidth * _activeIndex;

          return Stack(
            children: [
              // Белая плашка
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: indicatorLeft,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),

              // Иконки
              Row(
                children: [
                  Expanded(
                    child: _buildNavItem(iconPath: 'assets/icons/wifi.svg', index: 0),
                  ),
                  Expanded(
                    child: _buildNavItem(iconPath: 'assets/icons/chart-bar.svg', index: 1),
                  ),
                  Expanded(
                    child: _buildNavItem(iconPath: 'assets/icons/code.svg', index: 2),
                  ),
                  Expanded(
                    child: _buildNavItem(iconPath: 'assets/icons/settings-2.svg', index: 3),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (isPerfMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: content,
        ),
      ),
    );
  }

  Widget _buildNavItem({required String iconPath, required int index}) {
    final isActive = _activeIndex == index;
    return GestureDetector(
      onTap: () {
        if (ref.read(settingsProvider).hapticsEnabled) {
          HapticFeedback.lightImpact();
        }
        setState(() => _activeIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: ColorTween(
            begin: Colors.white.withValues(alpha: 0.4),
            end: isActive ? AppColors.bgBase : Colors.white.withValues(alpha: 0.4),
          ),
          builder: (context, color, child) {
            return SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: color != null
                  ? ColorFilter.mode(color, BlendMode.srcIn)
                  : null,
            );
          },
        ),
      ),
    );
  }
}
