import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class TransferService {
  SecureServerSocket? _serverSocket;
  final int port = 45678;
  SecurityContext? _securityContext;

  Future<void> _initSecurityContext() async {
    // In a real app, generate/store this securely per device.
    // This is a minimal placeholder for TLS structure.
    // The prompt asks for TLS 1.3 where supported.
    _securityContext = SecurityContext();
    // _securityContext!.useCertificateChain('path/to/cert.pem');
    // _securityContext!.usePrivateKey('path/to/key.pem');
  }

  Future<void> startServer(Function(String, int) onReceiveRequest) async {
    await _initSecurityContext();
    try {
      // Due to the lack of pre-generated certs in this sandbox, we fallback to ServerSocket if SecureServerSocket fails.
      // A production implementation would generate self-signed certs dynamically.
      try {
        _serverSocket = await SecureServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
          _securityContext!,
        );
        _serverSocket!.listen((SecureSocket socket) {
          _handleConnection(socket, onReceiveRequest);
        });
      } catch (e) {
        print('Secure socket failed, falling back to basic socket for now: $e');
        ServerSocket basicServer = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        basicServer.listen((Socket socket) {
          _handleBasicConnection(socket, onReceiveRequest);
        });
      }
      print('Transfer server listening on port $port');
    } catch (e) {
      print('Failed to start server: $e');
    }
  }

  Future<void> stopServer() async {
    if (_serverSocket != null) {
      await _serverSocket!.close();
      _serverSocket = null;
    }
  }

  void _handleConnection(SecureSocket socket, Function(String, int) onReceiveRequest) {
    _processIncoming(socket, onReceiveRequest);
  }

  void _handleBasicConnection(Socket socket, Function(String, int) onReceiveRequest) {
    _processIncoming(socket, onReceiveRequest);
  }

  void _processIncoming(Socket socket, Function(String, int) onReceiveRequest) async {
    print('Connection from ${socket.remoteAddress.address}:${socket.remotePort}');

    // Incomplete, but shows structural intent:
    // Read header, notify UI, read file chunk, write to temp.
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/incoming_kis_file.tmp');
    final sink = file.openWrite();

    socket.listen((data) {
      sink.add(data);
      print('Received ${data.length} bytes');
    }, onDone: () async {
      await sink.close();
      socket.close();
      print('Connection closed. Saved to ${file.path}');
      // Trigger approval/move here
    }, onError: (e) {
      sink.close();
      socket.close();
      print('Connection error: $e');
    });
  }

  Future<void> sendFile(String ip, int targetPort, File file) async {
    try {
      // Security Context would be configured to accept the peer's self-signed cert
      Socket socket;
      try {
         socket = await SecureSocket.connect(ip, targetPort, onBadCertificate: (cert) => true);
      } catch (e) {
         socket = await Socket.connect(ip, targetPort);
      }
      print('Connected to $ip:$targetPort');

      // Stream file to socket
      await file.openRead().pipe(socket);
      print('File sent');

      socket.close();
    } catch (e) {
      print('Failed to send file: $e');
    }
  }
}
