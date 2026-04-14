import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

class ExportService {
  static Future<void> exportToPdf(UserModel user, List<MealModel> meals) async {
    final pdf = pw.Document();

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
              ...meals.map((meal) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
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
              )).toList(),
              
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
}
