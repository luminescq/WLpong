import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'check_provider.dart';
import 'settings_provider.dart';
import 'database_provider.dart';
import '../bridge_generated.dart/checker.dart';

class DiagnosticReport {
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String deviceModel;
  final String osVersion;
  final String networkType;
  final String activeProfileName;
  final SettingsState settings;
  final CheckResult? lastResult;
  final DateTime timestamp;

  const DiagnosticReport({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.networkType,
    required this.activeProfileName,
    required this.settings,
    this.lastResult,
    required this.timestamp,
  });

  String toFormattedString() {
    final sb = StringBuffer();
    sb.writeln('ДИАГНОСТИЧЕСКИЙ ОТЧЁТ');
    sb.writeln();
    sb.writeln('УСТРОЙСТВО');
    sb.writeln('   Платформа: $platform');
    sb.writeln('   Модель: $deviceModel');
    sb.writeln('   ОС: $osVersion');
    sb.writeln('   Сеть: $networkType');
    sb.writeln();
    
    sb.writeln('ПРИЛОЖЕНИЕ');
    sb.writeln('   Версия: $appVersion ($buildNumber)');
    sb.writeln('   Дата отчёта: ${_formatDateTime(timestamp)}');
    sb.writeln();
    
    sb.writeln('НАСТРОЙКИ');
    sb.writeln('   Активный профиль: $activeProfileName');
    sb.writeln('   Таймаут: ${settings.timeoutSeconds} сек');
    final effectiveDns = settings.customDnsEnabled && settings.customDns.trim().isNotEmpty ? settings.customDns : "Авто";
    sb.writeln('   DNS сервер: $effectiveDns');
    sb.writeln('   Виброотклик: ${settings.hapticsEnabled ? "Вкл" : "Выкл"}');
    sb.writeln();
    
    if (lastResult != null) {
      sb.writeln('ПОСЛЕДНЯЯ ПРОВЕРКА');
      final r = lastResult!;
      sb.writeln('   Вердикт: ${_verdictLabel(r.verdict)}');
      sb.writeln('   Статистика:');
      if (r.stats != null) {
        sb.writeln('      WL доступно: ${r.stats!.wlAccessible}');
        sb.writeln('      BL доступно: ${r.stats!.blAccessible}');
        sb.writeln('      NT доступно: ${r.stats!.ntAccessible}');
      } else {
        sb.writeln('      Всего доступно: ${r.details.where((d) => d.accessible).length}');
      }
      sb.writeln();
      
      sb.writeln('   Детали:');
      for (final d in r.details) {
        final status = d.accessible ? '[+]' : '[-]';
        final latency = d.totalTimeMs != null ? ' (${d.totalTimeMs}ms)' : '';
        final error = d.error != null ? ' [${d.error}]' : '';
        sb.writeln('      $status ${d.domain}$latency$error');
      }
    } else {
      sb.writeln('ПОСЛЕДНЯЯ ПРОВЕРКА');
      sb.writeln('   Проверок ещё не было');
    }
    
    
    return sb.toString();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _verdictLabel(Verdict? v) {
    if (v == null) return 'Кастомная проверка (без вердикта)';
    switch (v) {
      case Verdict.bs:
        return 'Блокировок нет (BS)';
      case Verdict.cs:
        return 'Обнаружены блокировки (CS)';
    }
  }
}

class ReportNotifier extends StateNotifier<DiagnosticReport?> {
  final Ref _ref;

  // Кешируем device/package info — они не меняются за сессию
  static String? _cachedDeviceModel;
  static String? _cachedOsVersion;
  static String? _cachedAppVersion;
  static String? _cachedBuildNumber;

  ReportNotifier(this._ref) : super(null) {
    // Прогреваем кеш заранее — чтобы при открытии модалки было мгновенно
    _warmUp();
  }

  Future<void> _warmUp() async {
    await _fetchStaticInfo();
  }

  Future<void> _fetchStaticInfo() async {
    if (_cachedAppVersion != null) return; // уже кешировано

    final results = await Future.wait([
      PackageInfo.fromPlatform(),
      _fetchDeviceInfo(),
    ]);

    final packageInfo = results[0] as PackageInfo;
    final devicePair = results[1] as (String, String);

    _cachedAppVersion = packageInfo.version;
    _cachedBuildNumber = packageInfo.buildNumber;
    _cachedDeviceModel = devicePair.$1;
    _cachedOsVersion = devicePair.$2;
  }

  Future<(String, String)> _fetchDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return ('${info.manufacturer} ${info.model}',
          'Android ${info.version.release} (SDK ${info.version.sdkInt})');
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return (info.model, 'iOS ${info.systemVersion}');
    }
    return ('Unknown', Platform.operatingSystem);
  }

  Future<DiagnosticReport> generate() async {
    // Если кеш ещё не готов — ждём, иначе мгновенно
    await _fetchStaticInfo();

    final checkState = _ref.read(checkProvider);
    final lastResult = checkState is CheckSuccess
        ? checkState.result
        : _ref.read(lastCheckResultProvider);

    // Получаем тип сети
    final connectivityResult = await Connectivity().checkConnectivity();
    String networkType = 'Unknown';
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      networkType = 'Wi-Fi';
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      networkType = 'Mobile Data';
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      networkType = 'VPN';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      networkType = 'Ethernet';
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      networkType = 'No Connection';
    }

    // Получаем активный профиль
    final activeProfileId = _ref.read(activeProfileIdProvider);
    String activeProfileName = 'По умолчанию';
    if (activeProfileId != null) {
      final db = _ref.read(databaseProvider);
      await db.init();
      final profile = await db.getProfile(activeProfileId);
      if (profile != null) {
        activeProfileName = '${profile.name} (ID: ${profile.id})';
      }
    }

    final report = DiagnosticReport(
      appVersion: _cachedAppVersion!,
      buildNumber: _cachedBuildNumber!,
      platform: Platform.operatingSystem,
      deviceModel: _cachedDeviceModel!,
      osVersion: _cachedOsVersion!,
      networkType: networkType,
      activeProfileName: activeProfileName,
      settings: _ref.read(settingsProvider),
      lastResult: lastResult,
      timestamp: DateTime.now(),
    );

    state = report;
    return report;
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, DiagnosticReport?>(
  (ref) => ReportNotifier(ref),
);
