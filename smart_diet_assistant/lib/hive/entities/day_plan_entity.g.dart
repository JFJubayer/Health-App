// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_plan_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayPlanEntityAdapter extends TypeAdapter<DayPlanEntity> {
  @override
  final int typeId = 2;

  @override
  DayPlanEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayPlanEntity(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      breakfastId: fields[2] as String?,
      lunchId: fields[3] as String?,
      dinnerId: fields[4] as String?,
      snackIds: fields[5] == null ? [] : (fields[5] as List).cast<String>(),
      isLocked: fields[6] == null ? false : fields[6] as bool,
      breakfastLocked: fields[8] == null ? false : fields[8] as bool,
      lunchLocked: fields[9] == null ? false : fields[9] as bool,
      dinnerLocked: fields[10] == null ? false : fields[10] as bool,
      lastModified: fields[11] as DateTime?,
      consumedSlots:
          fields[7] == null ? {} : (fields[7] as Map?)?.cast<String, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, DayPlanEntity obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.breakfastId)
      ..writeByte(3)
      ..write(obj.lunchId)
      ..writeByte(4)
      ..write(obj.dinnerId)
      ..writeByte(5)
      ..write(obj.snackIds)
      ..writeByte(6)
      ..write(obj.isLocked)
      ..writeByte(7)
      ..write(obj.consumedSlots)
      ..writeByte(8)
      ..write(obj.breakfastLocked)
      ..writeByte(9)
      ..write(obj.lunchLocked)
      ..writeByte(10)
      ..write(obj.dinnerLocked)
      ..writeByte(11)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayPlanEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
