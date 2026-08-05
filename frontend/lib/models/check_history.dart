import 'package:isar/isar.dart';

part 'check_history.g.dart';

@collection
class CheckHistory {
  Id id = Isar.autoIncrement; // Автоматический ID

  /// Дата и время проверки
  late DateTime timestamp;

  /// Общее число проверенных доменов
  late int totalDomains;

  /// Число доступных доменов
  late int accessibleDomains;

  /// Найдены ли белые списки (ограничения)
  late bool isBsDetected;

  /// Был ли это кастомный профиль
  bool isCustom = false;
}
