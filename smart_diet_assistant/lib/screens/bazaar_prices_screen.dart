import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../bd_food_db/models/food_models.dart';
import '../widgets/glass_card.dart';

class BazaarPricesScreen extends StatefulWidget {
  const BazaarPricesScreen({super.key});

  @override
  State<BazaarPricesScreen> createState() => _BazaarPricesScreenState();
}

class _BazaarPricesScreenState extends State<BazaarPricesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final prices = userProvider.bdIngredientPrices.values.toList();

    // Get unique categories for filtering
    final categories = ['All', ...prices.map((p) => p.category).toSet().toList()];

    // Filter prices based on search query and category
    final filteredPrices = prices.where((price) {
      final matchesSearch = price.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          price.nameBn.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || price.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Group filtered prices by category
    final Map<String, List<IngredientPrice>> grouped = {};
    for (var p in filteredPrices) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bazaar Prices',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search ingredients (e.g. Rice, Onion)...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, idx) {
                      final cat = categories[idx];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: filteredPrices.isEmpty
                ? Center(
                    child: Text(
                      'No ingredients found.',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, catIdx) {
                      final categoryName = grouped.keys.elementAt(catIdx);
                      final items = grouped[categoryName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
                            child: Text(
                              categoryName.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          GlassCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: items.map((price) {
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        price.nameEn,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        price.nameBn,
                                        style: GoogleFonts.outfit(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '৳${price.pricePerKgBDT.toStringAsFixed(0)}',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          Text(
                                            'per ${price.displayUnit}',
                                            style: GoogleFonts.outfit(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showEditPriceDialog(context, userProvider, price),
                                    ),
                                    if (price != items.last)
                                      Divider(
                                        height: 1,
                                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: (catIdx * 100).ms).slideY(begin: 0.05);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, UserProvider provider, IngredientPrice price) {
    final controller = TextEditingController(text: price.pricePerKgBDT.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            'Edit Price: ${price.nameEn}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the market price in BDT per ${price.displayUnit} for ${price.nameEn} (${price.nameBn}):',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price (BDT)',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newPrice = double.tryParse(controller.text);
                if (newPrice != null && newPrice >= 0) {
                  provider.updateIngredientPrice(price.id, newPrice);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated ${price.nameEn} price to ৳${newPrice.toStringAsFixed(0)}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
