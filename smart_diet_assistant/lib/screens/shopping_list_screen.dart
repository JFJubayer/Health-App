import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _isWeekly = false;
  List<String> _weeklyList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWeeklyList();
  }

  Future<void> _loadWeeklyList() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<UserProvider>(context, listen: false);
    _weeklyList = await provider.getWeeklyShoppingList();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final shoppingList = _isWeekly ? _weeklyList : provider.shoppingList;
    final checkedItems = provider.checkedIngredients;

    // Filter list into to-buy and completed
    final toBuy = shoppingList.where((item) => !checkedItems.contains(item)).toList();
    final completed = shoppingList.where((item) => checkedItems.contains(item)).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shopping List',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (checkedItems.isNotEmpty)
            TextButton(
              onPressed: () => provider.clearCheckedIngredients(),
              child: Text(
                'Clear All',
                style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Today'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('This Week'),
                      ),
                    ],
                    selected: {_isWeekly},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isWeekly = newSelection.first;
                      });
                      if (_isWeekly && _weeklyList.isEmpty) {
                        _loadWeeklyList();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _isWeekly
                ? const Center(child: CircularProgressIndicator())
                : shoppingList.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        children: [
                          if (toBuy.isNotEmpty) ...[
                            _buildSectionHeader(context, 'To Buy', toBuy.length),
                            ...toBuy.map((item) => _buildShoppingItem(context, provider, item, false)),
                          ],
                          if (completed.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader(context, 'Completed', completed.length),
                            ...completed.map((item) => _buildShoppingItem(context, provider, item, true)),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(BuildContext context, UserProvider provider, String item, bool isChecked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (_) => provider.toggleIngredient(item),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Theme.of(context).colorScheme.primary,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          item,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: isChecked ? Colors.grey : Theme.of(context).colorScheme.onSurface,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Your shopping list is empty',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some meals to your plan first!',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
