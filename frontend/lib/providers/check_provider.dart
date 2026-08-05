import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bridge_generated.dart/api.dart';
import '../bridge_generated.dart/checker.dart';
import '../models/domains_config.dart';
import '../models/check_history.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

const _kTotalSessions   = 'check_total_sessions';
const _kSuccessSessions = 'check_success_sessions';

/// ID активного профиля (null = По умолчанию)
final activeProfileIdProvider = StateProvider<int?>((ref) => null);

/// Состояние проверки
sealed class CheckState {}

class CheckIdle extends CheckState {}

class CheckLoading extends CheckState {}

/// Предварительная проверка сети и VPN (без анимации кнопки)
class CheckPreflighting extends CheckState {}

class CheckSuccess extends CheckState {
  final CheckResult result;
  CheckSuccess(this.result);
}

class CheckError extends CheckState {
  final String message;
  CheckError(this.message);
}

/// Нет подключения к сети
class CheckNoNetwork extends CheckState {}

/// Обнаружен активный VPN
class CheckVpnDetected extends CheckState {}

/// Provider для управления проверкой
class CheckNotifier extends StateNotifier<CheckState> {
  final Ref _ref;
  CheckNotifier(this._ref) : super(CheckIdle()) {
    _init();
  }

  Future<void> _init() async {
    await _loadSessionStats();
    state = CheckIdle(); // Запуск перерисовки интерфейса (т.к. CheckIdle - новый объект)
  }

  /// Последний успешный результат — сохраняется между сбросами
  CheckResult? lastResult;

  /// Счётчики сессий (загружаются из SharedPreferences)
  int totalSessions   = 0;
  int successSessions = 0;

  Future<void> _loadSessionStats() async {
    final prefs = await SharedPreferences.getInstance();
    totalSessions   = prefs.getInt(_kTotalSessions)   ?? 0;
    successSessions = prefs.getInt(_kSuccessSessions) ?? 0;
  }

  Future<void> _incrementSession({required bool isSuccess}) async {
    totalSessions++;
    if (isSuccess) successSessions++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTotalSessions,   totalSessions);
    await prefs.setInt(_kSuccessSessions, successSessions);
  }

  /// Проверить наличие сети через быстрые TCP-соединения к публичным DNS-серверам (на порт 53).
  /// Использование сырых IP-адресов вместо `InternetAddress.lookup` избегает долгих зависаний 
  /// при заблокированном DNS (что актуально для РФ).
  Future<bool> _hasNetwork() async {
    final testIps = ['8.8.8.8', '1.1.1.1', '9.9.9.9']; // Google, Cloudflare, Quad9
    
    for (final ip in testIps) {
      try {
        // Короткий таймаут: если сеть есть, соединение установится за ~50-100 мс.
        // Суммарное время ожидания в худшем случае (оффлайн): 1.5с * 3 = 4.5с
        final socket = await Socket.connect(ip, 53, timeout: const Duration(milliseconds: 1500));
        socket.destroy();
        return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  /// Проверить наличие VPN интерфейса
  Future<bool> _hasVpn() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        // Расширенный список типичных имен VPN интерфейсов
        if (name.contains('tun') ||
            name.contains('tap') ||
            name.contains('ppp') ||
            name.contains('pptp') ||
            name.contains('l2tp') ||
            name.contains('ipsec') ||
            name.contains('vpn') ||
            name.startsWith('wg') ||   // WireGuard
            name.startsWith('utun')) { // macOS/iOS VPN
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Запустить проверку
  Future<void> runCheck() async {
    await _loadSessionStats();

    // Предварительные проверки — без анимации кнопки
    state = CheckPreflighting();

    // 1. Проверяем наличие сети
    final hasNetwork = await _hasNetwork();
    if (!hasNetwork) {
      state = CheckNoNetwork();
      return;
    }

    // 2. Проверяем наличие VPN
    final hasVpn = await _hasVpn();
    if (hasVpn) {
      state = CheckVpnDetected();
      return;
    }

    // 3. Запускаем основную проверку — теперь анимация кнопки
    state = CheckLoading();
    try {
      final timeoutMs = _ref.read(settingsProvider).timeoutSeconds * 1000;
      final activeProfileId = _ref.read(activeProfileIdProvider);
      final settings = _ref.read(settingsProvider);
      final customDnsRaw = settings.customDnsEnabled ? settings.customDns : '';
      final customDns = customDnsRaw.trim().isEmpty ? null : customDnsRaw.trim();
      
      CheckConfig config;
      if (activeProfileId == null) {
        final domainsConfig = await DomainsConfig.load();
        final baseConfig = domainsConfig.toCheckConfig(timeoutMs: timeoutMs);
        config = CheckConfig(
          groups: baseConfig.groups,
          timeoutMs: baseConfig.timeoutMs,
          port: baseConfig.port,
          verdictMode: baseConfig.verdictMode,
          customDns: customDns,
        );
      } else {
        final db = _ref.read(databaseProvider);
        await db.init();
        final profile = await db.getProfile(activeProfileId);
        if (profile == null || profile.domains.isEmpty) {
          throw Exception("Активный профиль не найден или не содержит доменов");
        }
        config = CheckConfig(
          groups: [
            DomainGroup(
              id: GroupType.wl,
              name: profile.name,
              domains: profile.domains,
            )
          ],
          timeoutMs: BigInt.from(timeoutMs),
          port: 443,
          verdictMode: null, // Кастомные профили не имеют вердикта
          customDns: customDns,
        );
      }

      final result = await checkNetworkRestrictions(config: config);
      lastResult = result;
      // Если вердикта нет (кастомный профиль), считаем сессию успешной, 
      // если хотя бы один домен доступен. Либо просто всегда success=true.
      final isSuccess = result.verdict == Verdict.cs || 
                       (result.verdict == null && result.details.isNotEmpty && result.details.every((d) => d.accessible));
      await _incrementSession(isSuccess: isSuccess);
      
      // Инициализируем БД на всякий случай и сохраняем историю
      final db = _ref.read(databaseProvider);
      await db.init();
      
      final history = CheckHistory()
        ..timestamp = DateTime.now()
        ..totalDomains = result.details.length
        ..accessibleDomains = result.details.where((d) => d.accessible).length
        ..isBsDetected = result.verdict == Verdict.bs
        ..isCustom = activeProfileId != null;
      await db.addCheckResult(history);
      
      state = CheckSuccess(result);
    } catch (e) {
      state = CheckError(e.toString());
    }
  }

  /// Сбросить состояние
  void reset() {
    state = CheckIdle();
  }

  /// Полностью очистить статистику (сессии и БД)
  Future<void> clearStats() async {
    // 1. Сброс счетчиков
    totalSessions = 0;
    successSessions = 0;
    lastResult = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTotalSessions);
    await prefs.remove(_kSuccessSessions);

    // 2. Очистка БД
    final db = _ref.read(databaseProvider);
    await db.init();
    await db.clearHistory();
    _ref.invalidate(checkHistoryStreamProvider); // Принудительно обновляем стрим после clear()

    // 3. Обновляем стейт для перерисовки UI
    state = CheckIdle();
  }

  /// Запустить проверку, игнорируя VPN
  Future<void> runCheckIgnoreVpn() async {
    await _loadSessionStats();
    state = CheckLoading();
    try {
      final timeoutMs = _ref.read(settingsProvider).timeoutSeconds * 1000;
      final activeProfileId = _ref.read(activeProfileIdProvider);
      
      CheckConfig config;
      if (activeProfileId == null) {
        final domainsConfig = await DomainsConfig.load();
        config = domainsConfig.toCheckConfig(timeoutMs: timeoutMs);
      } else {
        final db = _ref.read(databaseProvider);
        await db.init();
        final profile = await db.getProfile(activeProfileId);
        if (profile == null || profile.domains.isEmpty) {
          throw Exception("Активный профиль не найден или не содержит доменов");
        }
        config = CheckConfig(
          groups: [
            DomainGroup(
              id: GroupType.wl,
              name: profile.name,
              domains: profile.domains,
            )
          ],
          timeoutMs: BigInt.from(timeoutMs),
          port: 443,
          verdictMode: null,
        );
      }
      
      final result = await checkNetworkRestrictions(config: config);
      lastResult = result;
      final isSuccess = result.verdict == Verdict.cs || 
                       (result.verdict == null && result.details.isNotEmpty && result.details.every((d) => d.accessible));
      await _incrementSession(isSuccess: isSuccess);

      final db = _ref.read(databaseProvider);
      await db.init();
      
      final history = CheckHistory()
        ..timestamp = DateTime.now()
        ..totalDomains = result.details.length
        ..accessibleDomains = result.details.where((d) => d.accessible).length
        ..isBsDetected = result.verdict == Verdict.bs
        ..isCustom = activeProfileId != null;
      await db.addCheckResult(history);

      state = CheckSuccess(result);
    } catch (e) {
      state = CheckError(e.toString());
    }
  }
}

/// Provider экземпляр
final checkProvider = StateNotifierProvider<CheckNotifier, CheckState>(
  (ref) => CheckNotifier(ref),
);


/// Последний успешный результат проверки.
/// Не сбрасывается вместе с checkProvider.reset() — живёт до нового результата.
final lastCheckResultProvider = Provider<CheckResult?>((ref) {
  final notifier = ref.watch(checkProvider.notifier);
  // Пересчитывается при каждом изменении состояния
  ref.watch(checkProvider);
  return notifier.lastResult;
});

/// Статистика сессий: (totalSessions, successSessions).
/// Пересчитывается при каждом изменении checkProvider.
final checkStatsProvider = Provider<({int total, int success})>((ref) {
  final notifier = ref.watch(checkProvider.notifier);
  ref.watch(checkProvider);
  return (total: notifier.totalSessions, success: notifier.successSessions);
});
