import 'dart:async';
import 'package:nsd/nsd.dart';
import '../models/device.dart';

class NetworkService {
  final _devicesController = StreamController<List<Device>>.broadcast();
  Stream<List<Device>> get devicesStream => _devicesController.stream;

  List<Device> _devices = [];
  Discovery? _discovery;
  Registration? _registration;

  final String _serviceType = '_kis._tcp';

  Future<void> startDiscovery() async {
    try {
      _discovery = await startDiscovery(_serviceType, autoResolve: true);
      _discovery!.addListener(() {
        _devices = _discovery!.services.map((service) {
          return Device(
            id: service.name ?? 'unknown',
            name: service.name ?? 'Unknown Device',
            ip: service.host ?? '0.0.0.0',
            port: service.port ?? 0,
          );
        }).toList();
        _devicesController.add(_devices);
      });
    } catch (e) {
      print('Discovery error: $e');
    }
  }

  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
  }

  Future<void> broadcastDevice(String name, int port) async {
    try {
      _registration = await register(Service(
        name: name,
        type: _serviceType,
        port: port,
      ));
    } catch (e) {
      print('Broadcast error: $e');
    }
  }

  Future<void> stopBroadcast() async {
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
  }

  void dispose() {
    _devicesController.close();
    stopDiscovery();
    stopBroadcast();
  }
}
