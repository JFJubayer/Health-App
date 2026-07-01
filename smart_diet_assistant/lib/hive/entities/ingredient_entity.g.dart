// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientEntityAdapter extends TypeAdapter<IngredientEntity> {
  @override
  final int typeId = 0;

  @override
  IngredientEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientEntity(
      id: fields[0] as String,
      name: fields[1] as String,
      caloriesPer100g: fields[2] as double,
      protein: fields[3] as double,
      carbs: fields[4] as double,
      fat: fields[5] as double,
      tags: fields[6] == null ? [] : (fields[6] as List).cast<String>(),
      isCustom: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientEntity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.caloriesPer100g)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fat)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.isCustom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
