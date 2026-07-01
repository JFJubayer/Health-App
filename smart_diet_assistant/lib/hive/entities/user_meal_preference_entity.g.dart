// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_meal_preference_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserMealPreferenceEntityAdapter
    extends TypeAdapter<UserMealPreferenceEntity> {
  @override
  final int typeId = 5;

  @override
  UserMealPreferenceEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserMealPreferenceEntity(
      userId: fields[0] as String,
      favoriteMealIds:
          fields[1] == null ? [] : (fields[1] as List).cast<String>(),
      dislikedIngredientIds:
          fields[2] == null ? [] : (fields[2] as List).cast<String>(),
      dietaryRestrictions:
          fields[3] == null ? [] : (fields[3] as List).cast<String>(),
      mealRatings:
          fields[4] == null ? {} : (fields[4] as Map).cast<String, double>(),
      preferredTags:
          fields[5] == null ? [] : (fields[5] as List).cast<String>(),
      avoidedMealIds:
          fields[6] == null ? [] : (fields[6] as List).cast<String>(),
      lastUpdated: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserMealPreferenceEntity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.favoriteMealIds)
      ..writeByte(2)
      ..write(obj.dislikedIngredientIds)
      ..writeByte(3)
      ..write(obj.dietaryRestrictions)
      ..writeByte(4)
      ..write(obj.mealRatings)
      ..writeByte(5)
      ..write(obj.preferredTags)
      ..writeByte(6)
      ..write(obj.avoidedMealIds)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMealPreferenceEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
