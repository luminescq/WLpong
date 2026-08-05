import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';

class GearButton extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;

  const GearButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  ConsumerState<GearButton> createState() => _GearButtonState();
}

class _GearButtonState extends ConsumerState<GearButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) _startRotation();
    if (widget.isDisabled) _startRotation();
  }

  @override
  void didUpdateWidget(GearButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldSpin = widget.isLoading || widget.isDisabled;
    final wasSpin = oldWidget.isLoading || oldWidget.isDisabled;

    if (shouldSpin && !_rotationController.isAnimating) {
      _startRotation();
    } else if (!shouldSpin && wasSpin) {
      _stopRotation();
    }
  }

  void _startRotation() {
    _rotationController.reset();
    _rotationController.repeat();
  }

  void _stopRotation() {
    _rotationController.stop();
    _rotationController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.isLoading && !widget.isDisabled) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (widget.isLoading || widget.isDisabled) 
          ? null 
          : () {
              if (ref.read(settingsProvider).hapticsEnabled) {
                HapticFeedback.lightImpact();
              }
              widget.onPressed();
            },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _rotationController,
                child: SvgPicture.asset(
                  'assets/Shape.svg',
                  width: 160,
                  height: 160,
                ),
              ),
              Icon(
                Icons.play_arrow_rounded,
                color: widget.isLoading
                    ? AppColors.textPrimary.withValues(alpha: 0.7)
                    : AppColors.textPrimary,
                size: 70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
