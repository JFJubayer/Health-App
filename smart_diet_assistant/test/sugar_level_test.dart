import 'package:flutter_test/flutter_test.dart';
import 'package:smart_diet_assistant/models/sugar_reading.dart';

void main() {
  group('SugarReading Model', () {
    test('isPreMealSpike returns true when preMeal >= 130', () {
      final reading = SugarReading(preMeal: 130.0, postMeal: 100.0);
      expect(reading.isPreMealSpike, true);
    });

    test('isPreMealSpike returns false when preMeal < 130', () {
      final reading = SugarReading(preMeal: 129.0, postMeal: 100.0);
      expect(reading.isPreMealSpike, false);
    });

    test('isPreMealSpike returns false when preMeal is null', () {
      final reading = SugarReading(postMeal: 100.0);
      expect(reading.isPreMealSpike, false);
    });

    test('isPostMealSpike returns true when postMeal >= 180', () {
      final reading = SugarReading(preMeal: 100.0, postMeal: 180.0);
      expect(reading.isPostMealSpike, true);
    });

    test('isPostMealSpike returns false when postMeal < 180', () {
      final reading = SugarReading(preMeal: 100.0, postMeal: 179.0);
      expect(reading.isPostMealSpike, false);
    });

    test('isPostMealSpike returns false when postMeal is null', () {
      final reading = SugarReading(preMeal: 100.0);
      expect(reading.isPostMealSpike, false);
    });

    test('toMap serializes both values correctly', () {
      final reading = SugarReading(preMeal: 110.0, postMeal: 145.0);
      final map = reading.toMap();
      expect(map['preMeal'], 110.0);
      expect(map['postMeal'], 145.0);
    });

    test('toMap serializes null values as null', () {
      final reading = SugarReading();
      final map = reading.toMap();
      expect(map['preMeal'], isNull);
      expect(map['postMeal'], isNull);
    });

    test('fromMap deserializes values correctly', () {
      final reading = SugarReading.fromMap({'preMeal': 120.0, 'postMeal': 200.0});
      expect(reading.preMeal, 120.0);
      expect(reading.postMeal, 200.0);
      expect(reading.isPreMealSpike, false);
      expect(reading.isPostMealSpike, true);
    });

    test('fromMap handles null values', () {
      final reading = SugarReading.fromMap({'preMeal': null, 'postMeal': null});
      expect(reading.preMeal, isNull);
      expect(reading.postMeal, isNull);
      expect(reading.isPreMealSpike, false);
      expect(reading.isPostMealSpike, false);
    });

    test('roundtrip toMap -> fromMap preserves spike classification', () {
      final original = SugarReading(preMeal: 135.0, postMeal: 190.0);
      final restored = SugarReading.fromMap(original.toMap());
      expect(restored.preMeal, original.preMeal);
      expect(restored.postMeal, original.postMeal);
      expect(restored.isPreMealSpike, original.isPreMealSpike);
      expect(restored.isPostMealSpike, original.isPostMealSpike);
    });

    test('copyWith updates individual fields', () {
      final reading = SugarReading(preMeal: 100.0, postMeal: 150.0);
      final updated = reading.copyWith(preMeal: 140.0);
      expect(updated.preMeal, 140.0);
      expect(updated.postMeal, 150.0);
    });

    test('copyWith with clearPreMeal sets preMeal to null', () {
      final reading = SugarReading(preMeal: 100.0, postMeal: 150.0);
      final updated = reading.copyWith(clearPreMeal: true);
      expect(updated.preMeal, isNull);
      expect(updated.postMeal, 150.0);
    });

    test('copyWith with clearPostMeal sets postMeal to null', () {
      final reading = SugarReading(preMeal: 100.0, postMeal: 150.0);
      final updated = reading.copyWith(clearPostMeal: true);
      expect(updated.preMeal, 100.0);
      expect(updated.postMeal, isNull);
    });
  });

  group('SugarReading Spike Classification Boundary', () {
    test('pre-meal exactly at 130 is a spike', () {
      expect(SugarReading(preMeal: 130.0).isPreMealSpike, true);
    });

    test('pre-meal at 129.9 is not a spike', () {
      expect(SugarReading(preMeal: 129.9).isPreMealSpike, false);
    });

    test('post-meal exactly at 180 is a spike', () {
      expect(SugarReading(postMeal: 180.0).isPostMealSpike, true);
    });

    test('post-meal at 179.9 is not a spike', () {
      expect(SugarReading(postMeal: 179.9).isPostMealSpike, false);
    });
  });
}
