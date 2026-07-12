import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../models/sugar_reading.dart';
import 'persistence_service.dart';

class ExportService {
  static Future<void> exportToPdf(UserModel user, List<MealModel> meals) async {
    final pdf = pw.Document();
    
    // Fetch blood sugar readings
    final readings = await PersistenceService.getSugarReadings();
    final String dateStr = DateTime.now().toIso8601String().substring(0, 10);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0, 
                child: pw.Text(
                  'Smart Diet Assistant - Daily Plan', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Profile Section
              pw.Text('User Profile', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Text('Gender: ${user.gender}'),
                       pw.Text('Age: ${user.age} years'),
                       pw.Text('Weight: ${user.weightKg} kg'),
                     ]
                   ),
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Text('Height: ${user.heightCm.round()} cm'),
                       pw.Text('Medical Conditions:'),
                       pw.Text(user.conditions.isEmpty ? 'None' : user.conditions.join(", "), style: const pw.TextStyle(fontSize: 10)),
                     ]
                   )
                ]
              ),
              
              pw.SizedBox(height: 40),
              
              // Meals Section
              pw.Text('Daily Meal Plan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              ...meals.map((meal) {
                final key = '${meal.id}_$dateStr';
                final reading = readings[key];
                final hasSugar = user.conditions.contains('Diabetes') &&
                    reading != null &&
                    (reading.preMeal != null || reading.postMeal != null);

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(meal.type.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                              pw.Text(meal.name, style: const pw.TextStyle(fontSize: 14)),
                            ]
                          ),
                          pw.Text('${meal.calories} kcal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      if (hasSugar) ...[
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text('Glucose Target Reports: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            if (reading.preMeal != null) ...[
                              pw.Text('Pre-Meal: ${reading.preMeal!.toInt()} mg/dL (${reading.isPreMealSpike ? "Spike ⚠️" : "Normal"})', 
                                style: pw.TextStyle(fontSize: 10, color: reading.isPreMealSpike ? PdfColors.red800 : PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                              if (reading.postMeal != null) pw.Text('  |  ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                            ],
                            if (reading.postMeal != null) ...[
                              pw.Text('Post-Meal: ${reading.postMeal!.toInt()} mg/dL (${reading.isPostMealSpike ? "Spike ⚠️" : "Normal"})', 
                                style: pw.TextStyle(fontSize: 10, color: reading.isPostMealSpike ? PdfColors.red800 : PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
              
              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Stay Healthy with Smart Diet Assistant', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> exportWeeklyShoppingListPdf(List<String> ingredients) async {
    final pdf = pw.Document();

    // Group ingredients by category heuristic
    final Map<String, List<String>> grouped = {
      'Proteins': [],
      'Grains & Carbs': [],
      'Vegetables': [],
      'Dairy & Others': [],
    };

    for (var item in ingredients) {
      final lower = item.toLowerCase();
      if (lower.contains('chicken') || lower.contains('beef') || lower.contains('fish') ||
          lower.contains('egg') || lower.contains('prawn') || lower.contains('tofu') ||
          lower.contains('lentil') || lower.contains('dal')) {
        grouped['Proteins']!.add(item);
      } else if (lower.contains('rice') || lower.contains('oat') || lower.contains('roti') ||
          lower.contains('potato') || lower.contains('banana') || lower.contains('bread')) {
        grouped['Grains & Carbs']!.add(item);
      } else if (lower.contains('broccoli') || lower.contains('spinach') || lower.contains('cabbage') ||
          lower.contains('tomato') || lower.contains('onion') || lower.contains('garlic') ||
          lower.contains('pepper') || lower.contains('carrot') || lower.contains('vegetable')) {
        grouped['Vegetables']!.add(item);
      } else {
        grouped['Dairy & Others']!.add(item);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Weekly Shopping List',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('${ingredients.length} total items', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              pw.SizedBox(height: 20),
              ...grouped.entries.where((e) => e.value.isNotEmpty).map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(entry.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.teal)),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  pw.SizedBox(height: 6),
                  ...entry.value.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
                    child: pw.Row(
                      children: [
                        pw.Container(width: 6, height: 6, decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.grey400)),
                        pw.SizedBox(width: 8),
                        pw.Text(item, style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),
                  pw.SizedBox(height: 12),
                ],
              )),
              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Generated by Smart Diet Assistant', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
