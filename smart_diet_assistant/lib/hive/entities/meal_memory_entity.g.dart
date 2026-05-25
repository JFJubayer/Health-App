// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_memory_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealMemoryEntityAdapter extends TypeAdapter<MealMemoryEntity> {
  @override
  final int typeId = 6;

  @override
  MealMemoryEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealMemoryEntity(
      id: fields[0] as String,
      userId: fields[1] as String,
      mealTemplateId: fields[2] as String,
      consumedAt: fields[3] as DateTime,
      notes: fields[4] as String?,
      satisfaction: fields[5] as double,
      wasConsumed: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MealMemoryEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.mealTemplateId)
      ..writeByte(3)
      ..write(obj.consumedAt)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.satisfaction)
      ..writeByte(6)
      ..write(obj.wasConsumed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealMemoryEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
