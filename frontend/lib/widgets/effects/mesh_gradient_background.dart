import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class MeshGradientBackground extends ConsumerStatefulWidget {
  final Widget child;

  const MeshGradientBackground({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends ConsumerState<MeshGradientBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Ticker _ticker;
  double _time = 0.0;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShader();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/mesh_gradient.frag');
    setState(() {
      _shader = program.fragmentShader();
    });
  }

  void _onTick(Duration elapsed) {
    // В простом режиме время не идет, градиент замирает
    if (ref.read(settingsProvider).performanceMode) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }
    setState(() {
      _time = elapsed.inMilliseconds / 1000.0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      if (_ticker.isActive) {
        _ticker.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPerfMode = ref.watch(settingsProvider.select((s) => s.performanceMode));

    ref.listen(settingsProvider.select((s) => s.performanceMode), (prev, isPerformanceMode) {
      if (isPerformanceMode) {
        if (_ticker.isActive) _ticker.stop();
      } else {
        if (!_ticker.isActive) _ticker.start();
      }
    });

    if (_shader == null) {
      // Fallback пока шейдер загружается
      return Container(
        color: const Color(0xFF1A1520),
        child: widget.child,
      );
    }

    // Если включен простой режим, мы показываем красивый сгенерированный стоп-кадр шейдера,
    // но анимация не работает (тикер остановлен), что бережет батарею.
    final displayTime = isPerfMode ? 15.0 : _time;

    return CustomPaint(
      painter: _MeshGradientPainter(_shader!, displayTime),
      child: widget.child,
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _MeshGradientPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    
    shader.setFloat(0, size.width * dpr);  // uSize.x
    shader.setFloat(1, size.height * dpr); // uSize.y
    shader.setFloat(2, time);              // uTime
    shader.setFloat(3, 0.0);               // uState (0.0 = neutral)

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_MeshGradientPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
