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

  @HiveField(12, defaultValue: [])
  List<String> breakfastExtraIds;

  @HiveField(13, defaultValue: [])
  List<String> lunchExtraIds;

  @HiveField(14, defaultValue: [])
  List<String> dinnerExtraIds;

  DayPlanEntity({
    required this.id,
    required this.date,
    this.breakfastId,
    this.lunchId,
    this.dinnerId,
    this.snackIds = const [],
    List<String>? breakfastExtraIds,
    List<String>? lunchExtraIds,
    List<String>? dinnerExtraIds,
    this.isLocked = false,
    this.breakfastLocked = false,
    this.lunchLocked = false,
    this.dinnerLocked = false,
    this.lastModified,
    Map<String, bool>? consumedSlots,
  })  : breakfastExtraIds = breakfastExtraIds ?? [],
        lunchExtraIds = lunchExtraIds ?? [],
        dinnerExtraIds = dinnerExtraIds ?? [],
        consumedSlots = consumedSlots ?? {};

  List<String> get allBreakfastIds {
    final list = <String>[];
    if (breakfastId != null) list.add(breakfastId!);
    for (var id in breakfastExtraIds) {
      if (!list.contains(id)) list.add(id);
    }
    return list;
  }

  List<String> get allLunchIds {
    final list = <String>[];
    if (lunchId != null) list.add(lunchId!);
    for (var id in lunchExtraIds) {
      if (!list.contains(id)) list.add(id);
    }
    return list;
  }

  List<String> get allDinnerIds {
    final list = <String>[];
    if (dinnerId != null) list.add(dinnerId!);
    for (var id in dinnerExtraIds) {
      if (!list.contains(id)) list.add(id);
    }
    return list;
  }
}
