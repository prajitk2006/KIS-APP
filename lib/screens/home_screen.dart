import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/network_service.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkService _networkService = NetworkService();
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _networkService.devicesStream.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });
    _networkService.startDiscovery();
    _networkService.broadcastDevice('My Device', 45678);
  }

  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      // Handle file selection
      print('Selected files: ${result.files.map((f) => f.name).join(', ')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KIS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Open settings
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Who's nearby?",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Looking for devices on your network...",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Device list or empty state
              if (_devices.isEmpty) ...[
                const Icon(Icons.wifi_find, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No devices found yet.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  "Make sure KIS is open on the other device.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.computer),
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.ip),
                        trailing: ElevatedButton(
                          onPressed: _pickFiles,
                          child: const Text('Send'),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const Spacer(),

              // Drag and drop zone (simplified for now)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 48, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    Text(
                      "Drop files here to share",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickFiles,
                      child: const Text('Or select files'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Your files stay between your devices.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
