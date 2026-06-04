import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_model.dart';
import '../models/food_item_model.dart';
import '../providers/user_provider.dart';
import '../services/food_data_service.dart';
import 'add_ingredient_screen.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  
  MealType _selectedType = MealType.breakfast;
  final List<Map<String, dynamic>> _addedComponents = [];

  // Aggregated Values
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var comp in _addedComponents) {
      double weight = comp['weight'];
      FoodItemModel food = comp['food'];
      double factor = weight / 100;
      
      calories += food.caloriesPer100g * factor;
      protein += food.proteinPer100g * factor;
      carbs += food.carbsPer100g * factor;
      fat += food.fatPer100g * factor;
    }

    setState(() {
      _totalCalories = calories;
      _totalProtein = protein;
      _totalCarbs = carbs;
      _totalFat = fat;
    });
  }

  void _addComponent(FoodItemModel food) {
    double suggestedWeight = FoodDataService.getRecommendedPortion(food.name, _selectedType);
    
    setState(() {
      _addedComponents.add({
        'food': food,
        'weight': suggestedWeight,
      });
      if (_nameController.text.isEmpty) {
        _nameController.text = food.name;
      } else if (!_nameController.text.contains(food.name)) {
        _nameController.text += ' & ${food.name}';
      }
    });
    _calculateTotals();
    _searchController.clear();
  }

  void _removeComponent(int index) {
    setState(() {
      _addedComponents.removeAt(index);
    });
    _calculateTotals();
  }

  void _updateWeight(int index, double newWeight) {
    setState(() {
      _addedComponents[index]['weight'] = newWeight;
    });
    _calculateTotals();
  }

  void _submit() {
    if (_addedComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one food item.')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      final meal = MealModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        calories: _totalCalories.toInt(),
        type: _selectedType,
        protein: _totalProtein,
        carbs: _totalCarbs,
        fat: _totalFat,
        components: _addedComponents.map((c) => {
          'name': (c['food'] as FoodItemModel).name,
          'weight': c['weight'],
        }).toList(),
        isConsumed: false,
      );

      Provider.of<UserProvider>(context, listen: false).addCustomMeal(meal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF059669);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Smart Meal Builder', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              _buildSectionHeader('Meal Category', 'When are you eating this?'),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              
              _buildSectionHeader('Add Food Items', 'Search for food items to build your plate'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildFoodSearch(emerald)),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: emerald,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      tooltip: 'Add Custom Food Item',
                      onPressed: () async {
                        final newFood = await Navigator.push<FoodItemModel>(
                          context,
                          MaterialPageRoute(builder: (context) => const AddIngredientScreen()),
                        );
                        if (!context.mounted) return;
                        if (newFood != null) {
                           _addComponent(newFood);
                           // Force the autocomplete to refresh or close
                           FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              if (_addedComponents.isNotEmpty) ...[
                Text('Your Plate', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: emerald)),
                const SizedBox(height: 12),
                ...List.generate(_addedComponents.length, (index) => _buildComponentTile(index, emerald)),
                const Divider(height: 40),
              ],

              _buildNutritionalSummary(emerald),
              
              const SizedBox(height: 32),
              _buildLabel('Meal Name (Manual Edit)'),
              _buildNameField(emerald),
              
              const SizedBox(height: 40),
              _buildSubmitButton(emerald),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: MealType.values.map((type) {
        bool isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  type.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFoodSearch(Color emerald) {
    return Autocomplete<FoodItemModel>(
      displayStringForOption: (option) => option.name,
      optionsBuilder: (textEditingValue) {
        return FoodDataService.getSuggestions(textEditingValue.text);
      },
      onSelected: (food) => _addComponent(food),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search chicken, rice, eggs...',
            prefixIcon: Icon(Icons.search, color: emerald),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final food = options.elementAt(index);
                  return ListTile(
                    title: Text(food.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text('${food.caloriesPer100g.toInt()} kcal per 100g'),
                    onTap: () => onSelected(food),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComponentTile(int index, Color emerald) {
    final comp = _addedComponents[index];
    final FoodItemModel food = comp['food'];
    final weight = comp['weight'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${(food.caloriesPer100g * weight / 100).toInt()} kcal total', style: TextStyle(color: emerald, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateWeight(index, (weight - 10).clamp(10, 1000))),
              SizedBox(
                width: 60,
                child: Text('${weight.toInt()}g', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateWeight(index, (weight + 10).clamp(10, 1000))),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => _removeComponent(index)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildNutritionalSummary(Color emerald) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: emerald.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emerald.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Nutrition', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('${_totalCalories.toInt()} kcal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: emerald)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroInfo('Protein', _totalProtein, Colors.orange),
              _buildMacroInfo('Carbs', _totalCarbs, Colors.blue),
              _buildMacroInfo('Fat', _totalFat, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text('${value.toInt()}g', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildNameField(Color emerald) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Enter a name for this meal',
        filled: true,
        fillColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
    );
  }

  Widget _buildSubmitButton(Color emerald) {
    return SizedBox(
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
          'Add to Daily Plan',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
