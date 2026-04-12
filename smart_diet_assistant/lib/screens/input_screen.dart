import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _useCm = true; // true for cm, false for feet/inches
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

      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Diet Assistant'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Gender Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('Male'),
                        selected: _gender == 'Male',
                        onSelected: (selected) {
                          setState(() => _gender = 'Male');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Female'),
                        selected: _gender == 'Female',
                        onSelected: (selected) {
                          setState(() => _gender = 'Female');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Age Input
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age (years)',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Weight Input
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid weight in kg';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Height Toggle & Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Height Format:', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      const Text('Cm'),
                      Switch(
                        value: !_useCm,
                        onChanged: (val) {
                          setState(() => _useCm = !val);
                        },
                      ),
                      const Text('Ft/In'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              _useCm 
                ? TextFormField(
                    controller: _heightCmController,
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: const Icon(Icons.height),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_useCm && (value == null || value.isEmpty || double.tryParse(value) == null)) {
                        return 'Please enter a valid height';
                      }
                      return null;
                    },
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightFeetController,
                          decoration: InputDecoration(
                            labelText: 'Feet',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!_useCm && (value == null || value.isEmpty || int.tryParse(value) == null)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _heightInchesController,
                          decoration: InputDecoration(
                            labelText: 'Inches',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
              
              const SizedBox(height: 30),
              
              // Phase 2: Medical Conditions
              const Text('Medical Conditions (Optional)', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  _buildConditionChip('Diabetes'),
                  _buildConditionChip('Hypertension'),
                  _buildConditionChip('PCOS'),
                ],
              ),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Calculate Plan', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    bool isSelected = _selectedConditions.contains(condition);
    return FilterChip(
      label: Text(condition),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedConditions.add(condition);
          } else {
            _selectedConditions.remove(condition);
          }
        });
      },
    );
  }
}
