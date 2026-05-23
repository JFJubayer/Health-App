import 'package:hive/hive.dart';

part 'day_plan_entity.g.dart';

@HiveType(typeId: 2)
class DayPlanEntity {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String? breakfastId;

  @HiveField(3)
  String? lunchId;

  @HiveField(4)
  String? dinnerId;

  @HiveField(5)
  List<String> snackIds;

  @HiveField(6)
  bool isLocked;

  @HiveField(7)
  Map<String, bool> consumedSlots;

  DayPlanEntity({
    required this.id,
    required this.date,
    this.breakfastId,
    this.lunchId,
    this.dinnerId,
    this.snackIds = const [],
    this.isLocked = false,
    Map<String, bool>? consumedSlots,
  }) : consumedSlots = consumedSlots ?? {};
}
