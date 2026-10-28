class Device {
  final String id;
  final String name;
  final String ip;
  final int port;
  final bool isTrusted;

  Device({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    this.isTrusted = false,
  });
}
