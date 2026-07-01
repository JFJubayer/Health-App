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

  @HiveField(5, defaultValue: [])
  List<String> snackIds;

  @HiveField(6, defaultValue: false)
  bool isLocked;

  @HiveField(7, defaultValue: {})
  Map<String, bool> consumedSlots;

  @HiveField(8, defaultValue: false)
  bool breakfastLocked;

  @HiveField(9, defaultValue: false)
  bool lunchLocked;

  @HiveField(10, defaultValue: false)
  bool dinnerLocked;

  @HiveField(11)
  DateTime? lastModified;

  DayPlanEntity({
    required this.id,
    required this.date,
    this.breakfastId,
    this.lunchId,
    this.dinnerId,
    this.snackIds = const [],
    this.isLocked = false,
    this.breakfastLocked = false,
    this.lunchLocked = false,
    this.dinnerLocked = false,
    this.lastModified,
    Map<String, bool>? consumedSlots,
  }) : consumedSlots = consumedSlots ?? {};
}
