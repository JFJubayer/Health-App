import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_item_model.dart';
import '../services/persistence_service.dart';
import '../hive/entities/ingredient_entity.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddIngredientScreen extends StatefulWidget {
  const AddIngredientScreen({super.key});

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final ingredient = IngredientEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        caloriesPer100g: double.parse(_caloriesController.text),
        protein: double.parse(_proteinController.text),
        carbs: double.parse(_carbsController.text),
        fat: double.parse(_fatController.text),
        isCustom: true,
      );

      await PersistenceService.saveIngredient(ingredient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ingredient.name} added successfully!')),
        );
        Navigator.pop(context, FoodItemModel(
          name: ingredient.name,
          caloriesPer100g: ingredient.caloriesPer100g,
          proteinPer100g: ingredient.protein,
          carbsPer100g: ingredient.carbs,
          fatPer100g: ingredient.fat,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF059669);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add Custom Food', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Food Details', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              Text('Enter nutritional info per 100g', style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),

              _buildLabel('Food Name'),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. Quinoa, Almond Milk',
                validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Calories (per 100g)'),
              _buildTextField(
                controller: _caloriesController,
                hint: 'kcal',
                isNumber: true,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Please enter valid calories' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Protein (g)'),
                        _buildTextField(
                          controller: _proteinController,
                          hint: 'g',
                          isNumber: true,
                          validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Carbs (g)'),
                        _buildTextField(
                          controller: _carbsController,
                          hint: 'g',
                          isNumber: true,
                          validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Fat (g)'),
                        _buildTextField(
                          controller: _fatController,
                          hint: 'g',
                          isNumber: true,
                          validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Food Item',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: validator,
    );
  }
}
