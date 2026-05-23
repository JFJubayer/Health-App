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
      favoriteMealIds: (fields[1] as List).cast<String>(),
      dislikedIngredientIds: (fields[2] as List).cast<String>(),
      dietaryRestrictions: (fields[3] as List).cast<String>(),
      mealRatings: (fields[4] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserMealPreferenceEntity obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.favoriteMealIds)
      ..writeByte(2)
      ..write(obj.dislikedIngredientIds)
      ..writeByte(3)
      ..write(obj.dietaryRestrictions)
      ..writeByte(4)
      ..write(obj.mealRatings);
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
