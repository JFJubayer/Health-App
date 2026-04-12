import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'input_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Center(child: Text('No Data'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.withOpacity(0.2),
              child: Icon(
                user.gender == 'Male' ? Icons.male : Icons.female,
                size: 50,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Health Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cake, color: Colors.orange),
                    title: const Text('Age'),
                    trailing: Text('${user.age} years', style: const TextStyle(fontSize: 16)),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.monitor_weight, color: Colors.green),
                    title: const Text('Weight'),
                    trailing: Text('${user.weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16)),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.height, color: Colors.blue),
                    title: const Text('Height'),
                    trailing: Text('${user.heightCm.toStringAsFixed(1)} cm', style: const TextStyle(fontSize: 16)),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Colors.purple),
                    title: const Text('Gender'),
                    trailing: Text(user.gender, style: const TextStyle(fontSize: 16)),
                  ),
                  if (user.conditions.isNotEmpty) ...[
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.medical_information, color: Colors.red),
                      title: const Text('Conditions'),
                      trailing: Text(user.conditions.join(', '), style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                userProvider.clearUser();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InputScreen()),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit / Recalculate'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
