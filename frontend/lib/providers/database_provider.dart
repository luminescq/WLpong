import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/check_history.dart';
import '../models/check_profile.dart';

class DatabaseProvider {
  late Isar isar;

  Future<void> init() async {
    // В реальном приложении нужно инициализировать Isar 
    // Обычно это делается в main.dart перед runApp
    // Но так как мы работаем через Provider, мы можем сделать это здесь.
    // Важно не открыть его дважды.
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [CheckHistorySchema, CheckProfileSchema],
        directory: dir.path,
      );
    } else {
      isar = Isar.getInstance()!;
    }
  }

  /// Добавить новую проверку в историю
  Future<void> addCheckResult(CheckHistory history) async {
    await isar.writeTxn(() async {
      await isar.checkHistorys.put(history);
    });
  }

  // ─── Профили ───────────────────────────────────────────────────────────────

  /// Следить за изменениями профилей (Stream)
  Stream<List<CheckProfile>> watchProfiles() {
    return isar.checkProfiles.where().watch(fireImmediately: true);
  }

  /// Получить профиль по ID
  Future<CheckProfile?> getProfile(int id) async {
    return await isar.checkProfiles.get(id);
  }

  /// Сохранить профиль (добавление или обновление)
  Future<void> saveProfile(CheckProfile profile) async {
    await isar.writeTxn(() async {
      await isar.checkProfiles.put(profile);
    });
  }

  /// Удалить профиль
  Future<void> deleteProfile(int id) async {
    await isar.writeTxn(() async {
      await isar.checkProfiles.delete(id);
    });
  }

  // ─── История проверок ──────────────────────────────────────────────────────

  /// Получить список всех проверок (отсортировано от новых к старым)
  Future<List<CheckHistory>> getAllChecks() async {
    return await isar.checkHistorys.where().sortByTimestampDesc().findAll();
  }

  /// Очистить историю проверок
  Future<void> clearHistory() async {
    await isar.writeTxn(() async {
      await isar.checkHistorys.clear();
    });
  }

  /// Добавить 1000 тестовых записей для проверки пагинации (Только для дебага!)
  Future<void> generateDummyData() async {
    final List<CheckHistory> dummy = [];
    final now = DateTime.now();
    for (int i = 0; i < 1000; i++) {
      dummy.add(CheckHistory()
        ..timestamp = now.subtract(Duration(minutes: i))
        ..totalDomains = 10
        ..accessibleDomains = (i % 10 == 0) ? 5 : 10
        ..isBsDetected = (i % 15 == 0)
        ..isCustom = false
      );
    }
    await isar.writeTxn(() async {
      await isar.checkHistorys.putAll(dummy);
    });
  }

  /// Следить за изменениями в БД (Stream) с лимитом
  Stream<List<CheckHistory>> watchChecks({int limit = 50}) {
    return isar.checkHistorys.where().sortByTimestampDesc().limit(limit).watch(fireImmediately: true);
  }
}

final databaseProvider = Provider<DatabaseProvider>((ref) {
  return DatabaseProvider();
});

/// Провайдер лимита загружаемых элементов
final historyLimitProvider = StateProvider<int>((ref) => 50);

/// Провайдер, который отдает стрим истории проверок с учетом лимита
final checkHistoryStreamProvider = StreamProvider<List<CheckHistory>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final limit = ref.watch(historyLimitProvider);
  await db.init(); // Ждем инициализации
  yield* db.watchChecks(limit: limit); // Пробрасываем поток с лимитом
});

/// Провайдер, который отдает стрим профилей
final profilesStreamProvider = StreamProvider<List<CheckProfile>>((ref) async* {
  final db = ref.watch(databaseProvider);
  await db.init();
  yield* db.watchProfiles();
});
