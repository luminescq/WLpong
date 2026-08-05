import 'package:isar/isar.dart';

part 'check_profile.g.dart';

@collection
class CheckProfile {
  Id id = Isar.autoIncrement;

  late String name;
  
  // Храним иконку профиля в виде числа (codePoint)
  late int iconCodePoint;
  
  late List<String> domains;
}
