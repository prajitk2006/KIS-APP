import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/network_service.dart';
import '../services/transfer_service.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkService _networkService = NetworkService();
  final TransferService _transferService = TransferService();
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

    _transferService.startServer(_onReceiveRequest);
  }

  void _onReceiveRequest(TransferRequest req) {
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => AlertDialog(
         title: const Text('Incoming File'),
         content: Text('Someone wants to send you "${req.filename}" (${req.size} bytes). Do you accept?'),
         actions: [
           TextButton(
             onPressed: () {
               _transferService.declineTransfer(req);
               Navigator.of(context).pop();
             },
             child: const Text('Decline'),
           ),
           ElevatedButton(
             onPressed: () async {
               Navigator.of(context).pop();
               final dir = await getApplicationDocumentsDirectory();
               String savePath = '${dir.path}/${req.filename}';
               await _transferService.acceptTransfer(req, savePath);
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Saved to $savePath')),
               );
             },
             child: const Text('Accept'),
           ),
         ],
       )
     );
  }

  @override
  void dispose() {
    _networkService.dispose();
    _transferService.stopServer();
    super.dispose();
  }

  Future<void> _pickFilesAndSend(Device device) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _transferService.sendFile(device.ip, device.port, file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File sent successfully')),
      );
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
            onPressed: () {},
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
                          onPressed: () => _pickFilesAndSend(device),
                          child: const Text('Send'),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const Spacer(),

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
                      "Your files stay between your devices.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
