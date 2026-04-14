import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'main_navigation.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _gender = 'Male';
  bool _useCm = true;
  final List<String> _selectedConditions = [];
  
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchesController = TextEditingController();

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      int age = int.parse(_ageController.text);
      double weight = double.parse(_weightController.text);
      
      double heightCm;
      if (_useCm) {
        heightCm = double.parse(_heightCmController.text);
      } else {
        int feet = int.parse(_heightFeetController.text);
        int inches = _heightInchesController.text.isEmpty ? 0 : int.parse(_heightInchesController.text);
        heightCm = (feet * 30.48) + (inches * 2.54);
      }

      UserModel user = UserModel(
        age: age,
        gender: _gender,
        heightCm: heightCm,
        weightKg: weight,
        conditions: _selectedConditions,
      );

      Provider.of<UserProvider>(context, listen: false).setUserData(user);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Health Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildGenderToggle(),
              const SizedBox(height: 24),
              _buildTextField(_ageController, 'Age', Icons.cake_outlined, 'years'),
              const SizedBox(height: 16),
              _buildTextField(_weightController, 'Current Weight', Icons.monitor_weight_outlined, 'kg'),
              const SizedBox(height: 24),
              _buildHeightSection(),
              const SizedBox(height: 32),
              _buildConditionsSection(),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Calculate My Plan'),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.analytics_outlined, size: 40, color: Color(0xFF059669)),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          'Personalize Your Diet',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          'Enter your details to generate a custom meal plan matching your body\'s needs.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7280)),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildGenderToggle() {
    return Row(
      children: [
        Expanded(child: _genderChip('Male', Icons.male_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _genderChip('Female', Icons.female_rounded)),
      ],
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1);
  }

  Widget _genderChip(String type, IconData icon) {
    bool isSelected = _gender == type;
    return GestureDetector(
      onTap: () => setState(() => _gender = type),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 20),
            const SizedBox(width: 8),
            Text(
              type,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String suffix) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildHeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Height', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            _buildUnitToggle(),
          ],
        ),
        const SizedBox(height: 12),
        _useCm 
          ? _buildTextField(_heightCmController, 'Height', Icons.height_rounded, 'cm')
          : Row(
              children: [
                Expanded(child: _buildTextField(_heightFeetController, 'Feet', Icons.height_rounded, 'ft')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_heightInchesController, 'Inches', Icons.height_rounded, 'in')),
              ],
            ),
      ],
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1);
  }

  Widget _buildUnitToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _unitOption('Cm', _useCm, () => setState(() => _useCm = true)),
          _unitOption('Ft/In', !_useCm, () => setState(() => _useCm = false)),
        ],
      ),
    );
  }

  Widget _unitOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Medical Considerations', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['Diabetes', 'Hypertension', 'PCOS'].map((c) => FilterChip(
            label: Text(c, style: GoogleFonts.outfit(fontSize: 13)),
            selected: _selectedConditions.contains(c),
            onSelected: (selected) {
              setState(() => selected ? _selectedConditions.add(c) : _selectedConditions.remove(c));
            },
            selectedColor: const Color(0xFF059669).withOpacity(0.2),
            checkmarkColor: const Color(0xFF059669),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }
}

