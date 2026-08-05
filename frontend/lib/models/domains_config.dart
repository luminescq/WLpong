import 'dart:convert';
import 'package:flutter/services.dart';
import '../bridge_generated.dart/checker.dart';

class DomainsConfig {
  final List<DomainGroupData> groups;
  final int timeoutMs;
  final int port;

  DomainsConfig({
    required this.groups,
    required this.timeoutMs,
    required this.port,
  });

  factory DomainsConfig.fromJson(Map<String, dynamic> json) {
    return DomainsConfig(
      groups: (json['groups'] as List)
          .map((g) => DomainGroupData.fromJson(g))
          .toList(),
      timeoutMs: json['config']['timeout_ms'] as int,
      port: json['config']['port'] as int,
    );
  }

  /// Загрузить конфигурацию из assets
  static Future<DomainsConfig> load() async {
    final jsonString = await rootBundle.loadString('assets/domains.json');
    final jsonData = json.decode(jsonString);
    return DomainsConfig.fromJson(jsonData);
  }

  /// Конвертировать в CheckConfig для Rust FFI
  /// [timeoutMs] — переопределить таймаут из настроек (если не передан — берётся из JSON)
  CheckConfig toCheckConfig({int? timeoutMs}) {
    return CheckConfig(
      groups: groups.map((g) => g.toDomainGroup()).toList(),
      timeoutMs: BigInt.from(timeoutMs ?? this.timeoutMs),
      port: port,
      verdictMode: VerdictMode.defaultRules,
    );
  }
}

class DomainGroupData {
  final String id;
  final String name;
  final List<String> domains;

  DomainGroupData({
    required this.id,
    required this.name,
    required this.domains,
  });

  factory DomainGroupData.fromJson(Map<String, dynamic> json) {
    return DomainGroupData(
      id: json['id'] as String,
      name: json['name'] as String,
      domains: (json['domains'] as List).cast<String>(),
    );
  }

  /// Конвертировать в DomainGroup для Rust FFI
  DomainGroup toDomainGroup() {
    final groupType = switch (id) {
      'wl' => GroupType.wl,
      'bl' => GroupType.bl,
      'nt' => GroupType.nt,
      _ => throw Exception('Unknown group type: $id'),
    };

    return DomainGroup(
      id: groupType,
      name: name,
      domains: domains,
    );
  }
}
