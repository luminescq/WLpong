import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/check_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons/gear_button.dart';
import '../modals/result_modal.dart';
import '../modals/network_status_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkState = ref.watch(checkProvider);

    ref.listen<CheckState>(checkProvider, (previous, next) {
      if (next is CheckSuccess) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierLabel: '',
          barrierColor: Colors.black.withValues(alpha: 0.5),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return ResultModal(result: next.result);
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ).drive(Tween<double>(begin: 0.85, end: 1.0)),
                child: child,
              ),
            );
          },
        ).then((_) => ref.read(checkProvider.notifier).reset());
      } else if (next is CheckNoNetwork) {
        _showStatusModal(context, NetworkStatusType.noNetwork, ref);
        ref.read(checkProvider.notifier).reset();
      } else if (next is CheckVpnDetected) {
        _showStatusModal(context, NetworkStatusType.vpnDetected, ref);
        ref.read(checkProvider.notifier).reset();
      } else if (next is CheckError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.accentRed,
          ),
        );
        ref.read(checkProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GearButton(
          onPressed: () => ref.read(checkProvider.notifier).runCheck(),
          isLoading: checkState is CheckLoading,
          isDisabled: checkState is CheckPreflighting,
        ),
      ),
    );
  }

  void _showStatusModal(
      BuildContext context, NetworkStatusType type, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return NetworkStatusModal(
          type: type,
          onIgnoreVpn: type == NetworkStatusType.vpnDetected
              ? () => ref.read(checkProvider.notifier).runCheckIgnoreVpn()
              : null,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ).drive(Tween<double>(begin: 0.85, end: 1.0)),
            child: child,
          ),
        );
      },
    );
  }
}
