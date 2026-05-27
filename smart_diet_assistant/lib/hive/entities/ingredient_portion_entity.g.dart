// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_portion_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientPortionAdapter extends TypeAdapter<IngredientPortion> {
  @override
  final int typeId = 3;

  @override
  IngredientPortion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientPortion(
      ingredientId: fields[0] as String,
      grams: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientPortion obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.ingredientId)
      ..writeByte(1)
      ..write(obj.grams);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientPortionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
