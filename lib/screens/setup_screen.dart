import 'package:flutter/material.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController(text: "My Device");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'KIS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Send files. Keep them yours.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 64),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
