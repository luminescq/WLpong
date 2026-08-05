import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Таймаут ──────────────────────────────────────────────────────────────────
const _kTimeoutKey = 'timeout_seconds';
const kTimeoutMin = 4;
const kTimeoutMax = 10;
const kTimeoutDefault = 5;

// ── Виброотклик ───────────────────────────────────────────────────────────────
const _kHapticsKey = 'haptics_enabled';

// ── Режим энергосбережения / Простой режим ──────────────────────────────────
const _kPerformanceModeKey = 'performance_mode_enabled';

// ── DNS ───────────────────────────────────────────────────────────────────────
const _kCustomDnsKey = 'custom_dns';
const _kCustomDnsEnabledKey = 'custom_dns_enabled';

/// Доступные интервалы (в минутах)
const kIntervalOptions = [15, 30, 60, 180];
const kIntervalDefault = 30;

// ── State ─────────────────────────────────────────────────────────────────────
class SettingsState {
  final int timeoutSeconds;
  final bool hapticsEnabled;
  final bool performanceMode;
  final bool customDnsEnabled;
  final String customDns;

  const SettingsState({
    required this.timeoutSeconds,
    required this.hapticsEnabled,
    required this.performanceMode,
    required this.customDnsEnabled,
    required this.customDns,
  });

  SettingsState copyWith({
    int? timeoutSeconds,
    bool? hapticsEnabled,
    bool? performanceMode,
    bool? customDnsEnabled,
    String? customDns,
  }) {
    return SettingsState(
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      performanceMode: performanceMode ?? this.performanceMode,
      customDnsEnabled: customDnsEnabled ?? this.customDnsEnabled,
      customDns: customDns ?? this.customDns,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
    : super(
        const SettingsState(
          timeoutSeconds: kTimeoutDefault,
          hapticsEnabled: true,
          performanceMode: false,
          customDnsEnabled: false,
          customDns: '',
        ),
      ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Миграция: если раньше был сохранен DNS, включаем переключатель автоматически
    final savedDns = prefs.getString(_kCustomDnsKey) ?? '';
    final defaultEnabled = savedDns.isNotEmpty;
    
    state = SettingsState(
      timeoutSeconds: (prefs.getInt(_kTimeoutKey) ?? kTimeoutDefault).clamp(
        kTimeoutMin,
        kTimeoutMax,
      ),
      hapticsEnabled: prefs.getBool(_kHapticsKey) ?? true,
      performanceMode: prefs.getBool(_kPerformanceModeKey) ?? false,
      customDnsEnabled: prefs.getBool(_kCustomDnsEnabledKey) ?? defaultEnabled,
      customDns: savedDns,
    );
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    final v = seconds.clamp(kTimeoutMin, kTimeoutMax);
    state = state.copyWith(timeoutSeconds: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimeoutKey, v);
  }

  Future<void> setHaptics(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticsKey, enabled);
  }

  Future<void> setPerformanceMode(bool enabled) async {
    state = state.copyWith(performanceMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPerformanceModeKey, enabled);
  }

  Future<void> setCustomDnsEnabled(bool enabled) async {
    state = state.copyWith(customDnsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCustomDnsEnabledKey, enabled);
  }

  Future<void> setCustomDns(String dns) async {
    state = state.copyWith(customDns: dns);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCustomDnsKey, dns);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
