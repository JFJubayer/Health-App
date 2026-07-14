// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientQtyAdapter extends TypeAdapter<IngredientQty> {
  @override
  final int typeId = 23;

  @override
  IngredientQty read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientQty(
      ingredientId: fields[0] as String,
      grams: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientQty obj) {
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
      other is IngredientQtyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NutritionInfoAdapter extends TypeAdapter<NutritionInfo> {
  @override
  final int typeId = 24;

  @override
  NutritionInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionInfo(
      calories: fields[0] as double,
      proteinG: fields[1] as double,
      carbsG: fields[2] as double,
      fatG: fields[3] as double,
      fiberG: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.calories)
      ..writeByte(1)
      ..write(obj.proteinG)
      ..writeByte(2)
      ..write(obj.carbsG)
      ..writeByte(3)
      ..write(obj.fatG)
      ..writeByte(4)
      ..write(obj.fiberG);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final int typeId = 25;

  @override
  FoodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodItem(
      id: fields[0] as String,
      nameEn: fields[1] as String,
      nameBn: fields[2] as String,
      category: fields[3] as FoodCategory,
      region: fields[4] as Region,
      portionDescription: fields[5] as String,
      portionGrams: fields[6] as double,
      nutrition: fields[7] as NutritionInfo,
      ingredients: (fields[8] as List).cast<IngredientQty>(),
      isVegetarian: fields[9] as bool,
      tags: (fields[10] as List).cast<String>(),
      suitableSlots: (fields[11] as List).cast<MealSlot>(),
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameEn)
      ..writeByte(2)
      ..write(obj.nameBn)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.region)
      ..writeByte(5)
      ..write(obj.portionDescription)
      ..writeByte(6)
      ..write(obj.portionGrams)
      ..writeByte(7)
      ..write(obj.nutrition)
      ..writeByte(8)
      ..write(obj.ingredients)
      ..writeByte(9)
      ..write(obj.isVegetarian)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.suitableSlots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IngredientPriceAdapter extends TypeAdapter<IngredientPrice> {
  @override
  final int typeId = 26;

  @override
  IngredientPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientPrice(
      id: fields[0] as String,
      nameEn: fields[1] as String,
      nameBn: fields[2] as String,
      pricePerKgBDT: fields[3] as double,
      displayUnit: fields[4] as String,
      category: fields[5] as String,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientPrice obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameEn)
      ..writeByte(2)
      ..write(obj.nameBn)
      ..writeByte(3)
      ..write(obj.pricePerKgBDT)
      ..writeByte(4)
      ..write(obj.displayUnit)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodCategoryAdapter extends TypeAdapter<FoodCategory> {
  @override
  final int typeId = 20;

  @override
  FoodCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FoodCategory.riceBased;
      case 1:
        return FoodCategory.bhorta;
      case 2:
        return FoodCategory.dal;
      case 3:
        return FoodCategory.fishCurry;
      case 4:
        return FoodCategory.meatCurry;
      case 5:
        return FoodCategory.eggDish;
      case 6:
        return FoodCategory.vegetableCurry;
      case 7:
        return FoodCategory.shak;
      case 8:
        return FoodCategory.snack;
      case 9:
        return FoodCategory.breakfast;
      case 10:
        return FoodCategory.sweet;
      case 11:
        return FoodCategory.soupStew;
      default:
        return FoodCategory.riceBased;
    }
  }

  @override
  void write(BinaryWriter writer, FoodCategory obj) {
    switch (obj) {
      case FoodCategory.riceBased:
        writer.writeByte(0);
        break;
      case FoodCategory.bhorta:
        writer.writeByte(1);
        break;
      case FoodCategory.dal:
        writer.writeByte(2);
        break;
      case FoodCategory.fishCurry:
        writer.writeByte(3);
        break;
      case FoodCategory.meatCurry:
        writer.writeByte(4);
        break;
      case FoodCategory.eggDish:
        writer.writeByte(5);
        break;
      case FoodCategory.vegetableCurry:
        writer.writeByte(6);
        break;
      case FoodCategory.shak:
        writer.writeByte(7);
        break;
      case FoodCategory.snack:
        writer.writeByte(8);
        break;
      case FoodCategory.breakfast:
        writer.writeByte(9);
        break;
      case FoodCategory.sweet:
        writer.writeByte(10);
        break;
      case FoodCategory.soupStew:
        writer.writeByte(11);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RegionAdapter extends TypeAdapter<Region> {
  @override
  final int typeId = 21;

  @override
  Region read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Region.general;
      case 1:
        return Region.sylhet;
      case 2:
        return Region.chittagong;
      case 3:
        return Region.noakhali;
      case 4:
        return Region.barisal;
      case 5:
        return Region.rajshahi;
      case 6:
        return Region.khulna;
      case 7:
        return Region.mymensingh;
      case 8:
        return Region.dhaka;
      default:
        return Region.general;
    }
  }

  @override
  void write(BinaryWriter writer, Region obj) {
    switch (obj) {
      case Region.general:
        writer.writeByte(0);
        break;
      case Region.sylhet:
        writer.writeByte(1);
        break;
      case Region.chittagong:
        writer.writeByte(2);
        break;
      case Region.noakhali:
        writer.writeByte(3);
        break;
      case Region.barisal:
        writer.writeByte(4);
        break;
      case Region.rajshahi:
        writer.writeByte(5);
        break;
      case Region.khulna:
        writer.writeByte(6);
        break;
      case Region.mymensingh:
        writer.writeByte(7);
        break;
      case Region.dhaka:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealSlotAdapter extends TypeAdapter<MealSlot> {
  @override
  final int typeId = 22;

  @override
  MealSlot read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealSlot.breakfast;
      case 1:
        return MealSlot.lunch;
      case 2:
        return MealSlot.dinner;
      case 3:
        return MealSlot.snackTime;
      default:
        return MealSlot.breakfast;
    }
  }

  @override
  void write(BinaryWriter writer, MealSlot obj) {
    switch (obj) {
      case MealSlot.breakfast:
        writer.writeByte(0);
        break;
      case MealSlot.lunch:
        writer.writeByte(1);
        break;
      case MealSlot.dinner:
        writer.writeByte(2);
        break;
      case MealSlot.snackTime:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
