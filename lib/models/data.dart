import 'package:hive/hive.dart';

part 'data.g.dart';

/// Part 1 (Hive Basics) practice model.
///
/// Demonstrates the three Hive annotations:
///  - @HiveType(typeId) marks the class as storable. typeId must be unique
///    (0..223). We use 1 here; the real [Post] model uses 0.
///  - @HiveField(n) marks each field to persist. Never renumber a field index
///    after data has been saved; only add new numbers.
@HiveType(typeId: 1)
class Data {
  @HiveField(0)
  String name;

  @HiveField(1)
  String id;

  Data({required this.name, required this.id});
}
