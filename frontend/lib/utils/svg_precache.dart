import 'package:flutter_svg/flutter_svg.dart';

/// Предзагрузка всех SVG-иконок в кэш для избежания микрофризов при первом рендере
Future<void> precacheAllSvgs() async {
  final svgs = [
    'assets/icons/wifi.svg',
    'assets/icons/chart-bar.svg',
    'assets/icons/code.svg',
    'assets/icons/settings-2.svg',
    'assets/Shape.svg',
  ];
  
  for (final path in svgs) {
    try {
      final loader = SvgAssetLoader(path);
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    } catch (e) {
      // Игнорируем ошибки кэширования для отсутствующих файлов
    }
  }
}
